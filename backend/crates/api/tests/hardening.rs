//! Abuse and pagination hardening over the real router and a migrated database: lockout and rate
//! limits that survive a restart, and cursor pagination on the partner and payout lists.
//! Needs DATABASE_URL (sqlx::test).

mod common;

use api::{
    auth::{self, Role},
    build_state,
    lockout::{self, Lockout, PAIR_FREE_FAILURES},
    routes,
};
use axum::{
    Router,
    body::Body,
    extract::ConnectInfo,
    http::{Request, StatusCode, header},
};
use common::{SECRET, book, call, customer, seed_catalog, test_config, verified_pro};
use serde_json::{Value, json};
use sqlx::PgPool;
use std::net::{IpAddr, Ipv4Addr, SocketAddr};
use tower::ServiceExt;
use uuid::Uuid;

const PASSWORD: &str = "staff-password-123";
const IP: IpAddr = IpAddr::V4(Ipv4Addr::new(10, 0, 0, 1));
const OTHER: IpAddr = IpAddr::V4(Ipv4Addr::new(10, 0, 0, 2));

async fn insert_consultant(db: &PgPool, email: &str) {
    let hash = auth::hash_password(PASSWORD).expect("hash");
    sqlx::query("INSERT INTO staff (email, name, password_hash, role) VALUES ($1, 'Test', $2, 'consultant')")
        .bind(email)
        .bind(hash)
        .execute(db)
        .await
        .expect("insert staff");
}

async fn staff_login(app: &Router, email: &str, password: &str) -> StatusCode {
    call(app, "POST", "/v1/auth/staff/login", None, Some(json!({ "email": email, "password": password })))
        .await
        .0
}

/// A second router over the same database stands for a process restart or another replica.
fn restarted(db: &PgPool) -> Router {
    common::app(db.clone())
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_login_lockout_survives_a_restart(db: PgPool) {
    insert_consultant(&db, "restart@test.local").await;
    let before = common::app(db.clone());
    for _ in 0..PAIR_FREE_FAILURES {
        assert_eq!(staff_login(&before, "restart@test.local", "wrong-password-123").await, StatusCode::UNAUTHORIZED);
    }
    drop(before);
    let after = restarted(&db);
    assert_eq!(
        staff_login(&after, "restart@test.local", PASSWORD).await,
        StatusCode::TOO_MANY_REQUESTS,
        "still locked on a fresh process"
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn the_pair_unlocks_when_its_lock_expires_and_the_account_stays_open_to_other_clients(db: PgPool) {
    let lo = Lockout::new(db.clone());
    let ks = lockout::keys("login", IP, "a@x.test");
    for _ in 0..PAIR_FREE_FAILURES {
        lo.failure(&ks).await.expect("failure");
    }
    assert!(lo.check(&ks).await.is_err(), "locked");
    assert!(
        lo.check(&lockout::keys("login", OTHER, "a@x.test")).await.is_ok(),
        "another client still gets a try"
    );
    sqlx::query("UPDATE auth_lockouts SET locked_until = now() - interval '1 second'")
        .execute(&db)
        .await
        .expect("expire");
    assert!(lo.check(&ks).await.is_ok(), "lock expired");
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_staff_account_lock_delays_new_clients_but_never_refuses_them(db: PgPool) {
    let lo = Lockout::new(db);
    for i in 0..lockout::ACCOUNT_FREE_FAILURES {
        let ip = IpAddr::V4(Ipv4Addr::new(10, 1, 0, u8::try_from(i).unwrap_or(0)));
        lo.failure(&lockout::keys("staff", ip, "a@x.test")).await.expect("failure");
    }
    let fresh = lockout::keys("staff", IpAddr::V4(Ipv4Addr::new(10, 9, 9, 9)), "a@x.test");
    assert!(lo.check(&fresh).await.is_ok(), "a staff account lock delays, it does not refuse");
    assert!(
        lo.locked_for(&fresh).await.expect("query").is_some(),
        "but the account is locked for a new client"
    );
    assert!(
        lo.locked_for(&lockout::keys("staff", IP, "b@x.test")).await.expect("query").is_none(),
        "other accounts unaffected"
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn success_clears_the_counters_and_old_failures_are_forgotten(db: PgPool) {
    let lo = Lockout::new(db.clone());
    let ks = lockout::keys("login", IP, "a@x.test");
    for _ in 0..PAIR_FREE_FAILURES - 1 {
        lo.failure(&ks).await.expect("failure");
    }
    lo.success(&ks).await.expect("success");
    lo.failure(&ks).await.expect("failure");
    assert!(lo.check(&ks).await.is_ok(), "the budget came back after the success");

    // A quiet hour later the count starts over instead of continuing toward a lock.
    sqlx::query("UPDATE auth_lockouts SET expires_at = now() - interval '1 second'")
        .execute(&db)
        .await
        .expect("age");
    lo.failure(&ks).await.expect("failure");
    let fails: i32 = sqlx::query_scalar("SELECT fails FROM auth_lockouts WHERE key = $1")
        .bind(&ks[0].name)
        .fetch_one(&db)
        .await
        .expect("row");
    assert_eq!(fails, 1);
}

fn limited_app(db: &PgPool, auth_per_min: u32) -> Router {
    let mut cfg = test_config();
    cfg.rate_auth_per_min = auth_per_min;
    routes::router(build_state(db.clone(), cfg).expect("state"))
}

#[sqlx::test(migrations = "../../migrations")]
async fn the_auth_rate_limit_survives_a_restart(db: PgPool) {
    let before = limited_app(&db, 3);
    for n in 0..3 {
        let (st, _) = call(&before, "POST", "/v1/auth/otp", None, Some(json!({ "phone": "not-a-phone" }))).await;
        assert_eq!(st, StatusCode::BAD_REQUEST, "request {n} is within the budget");
    }
    let (st, b) = call(&before, "POST", "/v1/auth/otp", None, Some(json!({ "phone": "not-a-phone" }))).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::TOO_MANY_REQUESTS, Some("rate_limited")));

    let after = limited_app(&db, 3);
    let (st, _) = call(&after, "POST", "/v1/auth/otp", None, Some(json!({ "phone": "not-a-phone" }))).await;
    assert_eq!(st, StatusCode::TOO_MANY_REQUESTS, "a fresh process shares the same window");

    sqlx::query("UPDATE rate_limits SET window_start = now() - interval '61 seconds'")
        .execute(&db)
        .await
        .expect("age");
    let (st, _) = call(&limited_app(&db, 3), "POST", "/v1/auth/otp", None, Some(json!({ "phone": "not-a-phone" }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "the window rolled over");
}

#[sqlx::test(migrations = "../../migrations")]
async fn the_general_bucket_stays_out_of_the_database(db: PgPool) {
    let app = common::app(db.clone());
    call(&app, "GET", "/v1/catalog", None, None).await;
    let n: i64 = sqlx::query_scalar("SELECT count(*) FROM rate_limits").fetch_one(&db).await.expect("count");
    assert_eq!(n, 0);
}

/// GET with the response headers: (status, body, `X-Next-Cursor`).
async fn get_page(app: &Router, uri: &str, token: &str) -> (StatusCode, Value, Option<String>) {
    let mut req = Request::builder()
        .method("GET")
        .uri(uri)
        .header(header::AUTHORIZATION, format!("Bearer {token}"))
        .body(Body::empty())
        .expect("request");
    req.extensions_mut().insert(ConnectInfo(SocketAddr::from(([127, 0, 0, 1], 40_000))));
    let res = app.clone().oneshot(req).await.expect("router is infallible");
    let status = res.status();
    let next = res.headers().get("x-next-cursor").and_then(|v| v.to_str().ok()).map(str::to_owned);
    let bytes = axum::body::to_bytes(res.into_body(), usize::MAX).await.expect("body");
    (status, serde_json::from_slice(&bytes).unwrap_or(Value::Null), next)
}

/// Reads every page at `limit=2` and returns the `key` of each row in order.
async fn walk(app: &Router, base: &str, token: &str, key: &str) -> Vec<String> {
    let sep = if base.contains('?') { '&' } else { '?' };
    let mut ids = Vec::new();
    let mut cursor: Option<String> = None;
    for page in 0..10 {
        let uri = match &cursor {
            Some(c) => format!("{base}{sep}limit=2&cursor={c}"),
            None => format!("{base}{sep}limit=2"),
        };
        let (st, body, next) = get_page(app, &uri, token).await;
        assert_eq!(st, StatusCode::OK, "{uri}: {body}");
        let rows = body.as_array().expect("array body");
        assert!(rows.len() <= 2, "{uri} returned {} rows", rows.len());
        ids.extend(rows.iter().map(|r| r[key].as_str().expect("key").to_string()));
        match next {
            Some(c) => cursor = Some(c),
            None => {
                assert!(page >= 1, "{base}: 3 rows at limit 2 need a second page");
                return ids;
            }
        }
    }
    panic!("{base}: the cursor never ended");
}

async fn assert_pages(app: &Router, base: &str, token: &str, key: &str, expected: &[String]) {
    assert_eq!(walk(app, base, token, key).await, expected, "{base}");
    let (st, _, _) = get_page(app, &format!("{}{}limit=0", base, if base.contains('?') { '&' } else { '?' }), token).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{base}: limit 0 is refused");
    let (st, b, _) = get_page(
        app,
        &format!("{}{}cursor=not-a-cursor", base, if base.contains('?') { '&' } else { '?' }),
        token,
    )
    .await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::BAD_REQUEST, Some("invalid_cursor")), "{base}");
    let (st, all, next) = get_page(app, base, token).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(all.as_array().map(Vec::len), Some(expected.len()), "{base}: default page holds all three");
    assert!(next.is_none(), "{base}: no cursor on a short page");
}

#[sqlx::test(migrations = "../../migrations")]
async fn partner_lists_and_admin_payouts_page_by_cursor(db: PgPool) {
    seed_catalog(&db).await;
    let app = common::app(db.clone());
    let (pro, pro_id) = verified_pro(&app, &db, "010-5400-0101").await;
    let c = customer(&app, &db, "010-5400-0001").await;
    // Three bookings of one pro, each with a settlement, review, quote and payout, newest created last.
    let (mut settlements, mut reviews, mut quotes, mut payouts) = (Vec::new(), Vec::new(), Vec::new(), Vec::new());
    for (i, days) in [10_i64, 11, 12].into_iter().enumerate() {
        let (booking, _) = book(&app, &c, days, None).await;
        let age = format!("{} minutes", 30 - i * 10);
        sqlx::query("UPDATE bookings SET pro_id = $1, status = 3 WHERE id = $2")
            .bind(pro_id)
            .bind(booking)
            .execute(&db)
            .await
            .expect("assign");
        let sid: Uuid = sqlx::query_scalar(
            "INSERT INTO settlements (pro_id, booking_id, gross, fee, net, state, created_at) VALUES ($1, $2, 100000, 20000, 80000, 'pending', now() - $3::interval) RETURNING id",
        )
        .bind(pro_id)
        .bind(booking)
        .bind(&age)
        .fetch_one(&db)
        .await
        .expect("settlement");
        sqlx::query("INSERT INTO reviews (booking_id, user_id, pro_id, rating, body, created_at) VALUES ($1, $2, $3, 5, 'ok', now() - $4::interval)")
            .bind(booking)
            .bind(c.user)
            .bind(pro_id)
            .bind(&age)
            .execute(&db)
            .await
            .expect("review");
        let qid: Uuid = sqlx::query_scalar(
            "INSERT INTO quotes (booking_id, pro_id, amount, state, updated_at) VALUES ($1, $2, 90000, 'selected', now() - $3::interval) RETURNING id",
        )
        .bind(booking)
        .bind(pro_id)
        .bind(&age)
        .fetch_one(&db)
        .await
        .expect("quote");
        let pid: Uuid = sqlx::query_scalar(
            "INSERT INTO payouts (pro_id, payout_date, amount, items, provider, state, bank, holder, account_enc, account_last4, created_at)
             VALUES ($1, current_date - $2::int, 80000, 1, 'manual', 'paid', 'bank', 'holder', 'enc', '1234', now() - $3::interval) RETURNING id",
        )
        .bind(pro_id)
        .bind(i32::try_from(i).expect("small"))
        .bind(&age)
        .fetch_one(&db)
        .await
        .expect("payout");
        settlements.push(sid.to_string());
        reviews.push(booking.to_string());
        quotes.push(qid.to_string());
        payouts.push(pid.to_string());
    }
    // Newest first: the loop inserted the oldest row first.
    for list in [&mut settlements, &mut reviews, &mut quotes, &mut payouts] {
        list.reverse();
    }
    assert_pages(&app, "/v1/partner/settlements", &pro, "id", &settlements).await;
    assert_pages(&app, "/v1/partner/reviews", &pro, "booking_id", &reviews).await;
    assert_pages(&app, "/v1/partner/quotes", &pro, "id", &quotes).await;

    let admin = auth::issue_access(SECRET, Uuid::now_v7(), Role::StaffAdmin).expect("token");
    assert_pages(&app, "/v1/admin/settlements/payouts", &admin, "id", &payouts).await;
    assert_pages(&app, "/v1/admin/settlements/payouts?state=paid", &admin, "id", &payouts).await;
}

#[sqlx::test(migrations = "../../migrations")]
async fn points_ledger_pages_newest_first_by_cursor(db: PgPool) {
    let app = common::app(db.clone());
    let c = customer(&app, &db, "010-5420-0001").await;
    // Three earned lots, the newest last inserted; each lot is its own id, as `grant` writes them.
    let mut ids = Vec::new();
    for (i, minutes) in [30_i64, 20, 10].into_iter().enumerate() {
        let id = Uuid::now_v7();
        sqlx::query(
            "INSERT INTO points_ledger (id, user_id, kind, amount, lot_id, expires_at, idempotency_key, created_at)
             VALUES ($1, $2, 'earn', 100, $1, now() + interval '1 year', $3, now() - $4::interval)",
        )
        .bind(id)
        .bind(c.user)
        .bind(format!("test-earn-{i}"))
        .bind(format!("{minutes} minutes"))
        .execute(&db)
        .await
        .expect("ledger row");
        ids.push(id.to_string());
    }
    ids.reverse();
    assert_pages(&app, "/v1/me/points/ledger", &c.token, "id", &ids).await;
}

#[sqlx::test(migrations = "../../migrations")]
async fn quotes_page_marks_only_the_rows_it_returned_as_seen(db: PgPool) {
    seed_catalog(&db).await;
    let app = common::app(db.clone());
    let (pro, pro_id) = verified_pro(&app, &db, "010-5410-0101").await;
    let c = customer(&app, &db, "010-5410-0001").await;
    for (i, days) in [10_i64, 11, 12].into_iter().enumerate() {
        let (booking, _) = book(&app, &c, days, None).await;
        sqlx::query(
            "INSERT INTO quotes (booking_id, pro_id, amount, state, seen_by_pro, updated_at) VALUES ($1, $2, 90000, 'waiting', FALSE, now() - $3::interval)",
        )
        .bind(booking)
        .bind(pro_id)
        .bind(format!("{} minutes", 30 - i * 10))
        .execute(&db)
        .await
        .expect("quote");
    }
    let (st, body, next) = get_page(&app, "/v1/partner/quotes?limit=2", &pro).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    assert!(next.is_some());
    let unseen: i64 = sqlx::query_scalar("SELECT count(*) FROM quotes WHERE pro_id = $1 AND NOT seen_by_pro")
        .bind(pro_id)
        .fetch_one(&db)
        .await
        .expect("count");
    assert_eq!(unseen, 1, "the quote beyond the first page is still unseen");
}

#[sqlx::test(migrations = "../../migrations")]
async fn chat_threads_page_by_cursor_for_customers_and_partners(db: PgPool) {
    seed_catalog(&db).await;
    let app = common::app(db.clone());
    let (pro, _) = verified_pro(&app, &db, "010-5420-0101").await;
    let c = customer(&app, &db, "010-5420-0001").await;
    let (mut mine, mut theirs) = (Vec::new(), Vec::new());
    for i in 0..3 {
        let (st, b) = call(
            &app,
            "POST",
            "/v1/chat/threads",
            Some(c.token.as_str()),
            Some(json!({ "topic": format!("topic {i}") })),
        )
        .await;
        assert_eq!(st, StatusCode::OK, "{b}");
        mine.push(b["id"].as_str().expect("id").to_string());
        let (st, b) = call(
            &app,
            "POST",
            "/v1/chat/threads",
            Some(pro.as_str()),
            Some(json!({ "topic": format!("pro topic {i}") })),
        )
        .await;
        assert_eq!(st, StatusCode::OK, "{b}");
        theirs.push(b["id"].as_str().expect("id").to_string());
    }
    mine.reverse();
    theirs.reverse();
    assert_pages(&app, "/v1/chat/threads", &c.token, "id", &mine).await;
    assert_pages(&app, "/v1/partner/threads", &pro, "id", &theirs).await;
}
