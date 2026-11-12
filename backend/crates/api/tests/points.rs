//! Points ledger over the real router and DB: earn, spend, refund-returns-points, expiry and
//! the append-only guarantee. Same DB and fakes as flows.rs (needs DATABASE_URL, sqlx::test).

mod common;

use api::{
    auth::{self, Role},
    points,
};
use axum::http::StatusCode;
use common::{Customer, SECRET, book, call, call_keyed, customer, seed_catalog};
use domain::Won;
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

async fn enable_points(pool: &PgPool) {
    let policy = json!({ "enabled": true, "earn_bps": 1000, "welcome_points": 0, "referral_points": 0,
                         "expiry_days": 365, "notify_days": 30, "max_use_bps": 10000 });
    sqlx::query("INSERT INTO settings (key, value) VALUES ('points_policy', $1) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value")
        .bind(policy)
        .execute(pool)
        .await
        .expect("policy");
}

async fn balance(app: &axum::Router, c: &Customer) -> i64 {
    let (st, b) = call(app, "GET", "/v1/me/points", Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    b["balance"].as_i64().expect("balance")
}

async fn grant(pool: &PgPool, user: Uuid, amount: i64, key: &str) {
    let mut conn = pool.acquire().await.expect("conn");
    points::grant(&mut conn, user, "grant", amount, key.to_string()).await.expect("grant");
}

#[sqlx::test(migrations = "../../migrations")]
async fn earn_then_spend_takes_points_before_the_pg(pool: PgPool) {
    seed_catalog(&pool).await;
    enable_points(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6100-0001").await;
    let (id, _) = book(&app, &c, 10, None).await;
    sqlx::query("UPDATE bookings SET paid_amount = 52000, list_price = 52000 WHERE id = $1").bind(id).execute(&pool).await.expect("paid");

    let mut conn = pool.acquire().await.expect("conn");
    points::on_completed(&mut conn, id).await.expect("noop: not completed yet");
    assert_eq!(balance(&app, &c).await, 0, "no earn before completion is paid");

    grant(&pool, c.user, 20_000, "seed:1").await;
    let split = points::spend(&mut conn, c.user, id, Won(52_000), 10_000).await.expect("spend");
    assert_eq!((split.points, split.pg), (10_000, Won(42_000)));
    assert_eq!(balance(&app, &c).await, 10_000);

    let again = points::spend(&mut conn, c.user, id, Won(52_000), 5_000).await;
    assert!(again.is_err(), "a booking can be paid with points only once");
    assert_eq!(balance(&app, &c).await, 10_000);
}

#[sqlx::test(migrations = "../../migrations")]
async fn refund_returns_spent_points_once(pool: PgPool) {
    seed_catalog(&pool).await;
    enable_points(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6100-0002").await;
    let (id, _) = book(&app, &c, 10, None).await;
    grant(&pool, c.user, 8_000, "seed:2").await;
    let mut conn = pool.acquire().await.expect("conn");
    points::spend(&mut conn, c.user, id, Won(52_000), 8_000).await.expect("spend");
    assert_eq!(balance(&app, &c).await, 0);

    assert_eq!(points::reverse_spend(&mut conn, id, 52_000, 52_000).await.expect("refund"), 8_000);
    assert_eq!(points::reverse_spend(&mut conn, id, 52_000, 52_000).await.expect("retry"), 0, "already returned, no second lot");
    assert_eq!(balance(&app, &c).await, 8_000);
}

#[sqlx::test(migrations = "../../migrations")]
async fn partial_refund_returns_points_in_proportion(pool: PgPool) {
    seed_catalog(&pool).await;
    enable_points(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6100-0009").await;
    let (id, _) = book(&app, &c, 11, None).await;
    grant(&pool, c.user, 8_000, "seed:9").await;
    let mut conn = pool.acquire().await.expect("conn");
    points::spend(&mut conn, c.user, id, Won(52_000), 8_000).await.expect("spend");
    assert_eq!(points::reverse_spend(&mut conn, id, 13_000, 52_000).await.expect("quarter"), 2_000);
    assert_eq!(points::reverse_spend(&mut conn, id, 13_000, 52_000).await.expect("same share"), 0);
    assert_eq!(points::reverse_spend(&mut conn, id, 52_000, 52_000).await.expect("rest"), 6_000);
    assert_eq!(balance(&app, &c).await, 8_000);
}

#[sqlx::test(migrations = "../../migrations")]
async fn lapsed_lots_expire_once_and_stop_counting(pool: PgPool) {
    seed_catalog(&pool).await;
    enable_points(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6100-0003").await;
    sqlx::query(
        "INSERT INTO points_ledger (id, user_id, kind, amount, lot_id, expires_at, idempotency_key)
         VALUES ($1, $2, 'earn', 3000, $1, now() - interval '1 day', 'test:old')",
    )
    .bind(Uuid::now_v7())
    .bind(c.user)
    .execute(&pool)
    .await
    .expect("old lot");
    grant(&pool, c.user, 1_000, "test:fresh").await;
    assert_eq!(balance(&app, &c).await, 1_000, "lapsed lot is not spendable even before the sweep");

    assert_eq!(points::expire_lapsed(&pool).await.expect("sweep"), 1);
    assert_eq!(points::expire_lapsed(&pool).await.expect("again"), 0, "idempotent");
    assert_eq!(balance(&app, &c).await, 1_000);
}

#[sqlx::test(migrations = "../../migrations")]
async fn ledger_rows_are_append_only(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6100-0004").await;
    grant(&pool, c.user, 500, "test:immutable").await;
    let edit = sqlx::query("UPDATE points_ledger SET amount = 999999").execute(&pool).await;
    assert!(edit.is_err(), "UPDATE must be refused");
    let wipe = sqlx::query("DELETE FROM points_ledger").execute(&pool).await;
    assert!(wipe.is_err(), "DELETE must be refused");
    let (st, body): (StatusCode, Value) = call(&app, "GET", "/v1/me/points", Some(c.token.as_str()), None).await;
    assert_eq!((st, body["balance"].as_i64()), (StatusCode::OK, Some(500)));
}

// ---- Checkout spend: validated at create, debited once at settlement, returned on cancel ----

async fn set_cap(pool: &PgPool, max_use_bps: i64) {
    sqlx::query("UPDATE settings SET value = jsonb_set(value, '{max_use_bps}', to_jsonb($1::bigint)) WHERE key = 'points_policy'")
        .bind(max_use_bps)
        .execute(pool)
        .await
        .expect("cap");
}

fn checkout_body(c: &Customer, days: i64, points: i64) -> Value {
    // KST, like the API: a UTC date is "today" in Korea after 15:00 UTC.
    let visit = api::util::today_kst() + chrono::Duration::days(days);
    json!({ "kind": "booking", "method": "card", "points": points,
            "booking": { "service_code": "studio", "address_id": c.address, "visit_date": visit, "start_hour": 9, "visit_notes": {} } })
}

async fn spend_rows(pool: &PgPool, user: Uuid) -> (i64, i64) {
    sqlx::query_as("SELECT COUNT(DISTINCT booking_id), COALESCE(-SUM(amount), 0)::bigint FROM points_ledger WHERE user_id = $1 AND kind = 'spend'")
        .bind(user)
        .fetch_one(pool)
        .await
        .expect("spend rows")
}

#[sqlx::test(migrations = "../../migrations")]
async fn checkout_debits_points_once_and_cancel_returns_them(pool: PgPool) {
    seed_catalog(&pool).await;
    enable_points(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6100-0011").await;
    grant(&pool, c.user, 20_000, "seed:11").await;
    let token = Some(c.token.as_str());

    // Same Idempotency-Key twice: one checkout.
    let body = checkout_body(&c, 10, 10_000);
    let (st, intent) = call_keyed(&app, "POST", "/v1/checkouts", token, Some(body.clone()), Some("ck-create-11")).await;
    assert_eq!(st, StatusCode::OK, "{intent}");
    let (_, replay) = call_keyed(&app, "POST", "/v1/checkouts", token, Some(body), Some("ck-create-11")).await;
    assert_eq!(replay["id"], intent["id"], "replayed, not a second checkout");
    let total = intent["total"].as_i64().expect("total");
    assert_eq!((intent["points"].as_i64(), intent["amount"].as_i64()), (Some(10_000), Some(total - 10_000)), "PG charges the rest");
    assert_eq!(balance(&app, &c).await, 20_000, "nothing is debited before the payment settles");

    // Confirm three times (same key, then no key): one debit, one payment.
    let uri = format!("/v1/checkouts/{}/confirm", intent["id"].as_str().expect("id"));
    let pay = json!({ "payment_id": "dev:paid" });
    let (st, done) = call_keyed(&app, "POST", &uri, token, Some(pay.clone()), Some("ck-confirm-11")).await;
    assert_eq!((st, done["status"].as_str()), (StatusCode::OK, Some("paid")), "{done}");
    let (_, again) = call_keyed(&app, "POST", &uri, token, Some(pay.clone()), Some("ck-confirm-11")).await;
    let (_, third) = call(&app, "POST", &uri, token, Some(pay)).await;
    assert_eq!((again["booking_id"].clone(), third["booking_id"].clone()), (done["booking_id"].clone(), done["booking_id"].clone()));
    assert_eq!(spend_rows(&pool, c.user).await, (1, 10_000), "exactly one debit");
    assert_eq!(balance(&app, &c).await, 10_000);

    let booking: Uuid = done["booking_id"].as_str().expect("booking").parse().expect("uuid");
    let (paid_amount, cash, payments): (i64, i64, i64) = sqlx::query_as(
        "SELECT b.paid_amount, COALESCE(SUM(p.amount), 0)::bigint, COUNT(p.id) FROM bookings b LEFT JOIN payments p ON p.booking_id = b.id WHERE b.id = $1 GROUP BY b.id",
    )
    .bind(booking)
    .fetch_one(&pool)
    .await
    .expect("booking money");
    assert_eq!((paid_amount, cash, payments), (total, total - 10_000, 1), "booking is paid in full; the PG took only the cash part");

    // A free cancel refunds the cash and gives every point back, once.
    let (st, cancelled) = call(&app, "POST", &format!("/v1/bookings/{booking}/cancel"), token, Some(json!({}))).await;
    assert_eq!(st, StatusCode::OK, "{cancelled}");
    let refunded: i64 = sqlx::query_scalar("SELECT COALESCE(SUM(refunded_amount), 0)::bigint FROM payments WHERE booking_id = $1").bind(booking).fetch_one(&pool).await.expect("refund");
    assert_eq!(refunded, total - 10_000);
    assert_eq!(balance(&app, &c).await, 20_000, "spent points are back");
    let mut conn = pool.acquire().await.expect("conn");
    assert_eq!(points::reverse_spend(&mut conn, booking, refunded, refunded).await.expect("retry"), 0);
}

#[sqlx::test(migrations = "../../migrations")]
async fn checkout_refuses_points_over_balance_cap_or_total(pool: PgPool) {
    seed_catalog(&pool).await;
    enable_points(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6100-0012").await;
    grant(&pool, c.user, 5_000, "seed:12").await;
    let token = Some(c.token.as_str());
    let code = |b: &Value| b["error"]["code"].as_str().map(str::to_string);

    let (st, b) = call(&app, "POST", "/v1/checkouts", token, Some(checkout_body(&c, 10, 5_001))).await;
    assert_eq!((st, code(&b)), (StatusCode::CONFLICT, Some("points_insufficient".into())), "{b}");
    let (st, b) = call(&app, "POST", "/v1/checkouts", token, Some(checkout_body(&c, 10, -1))).await;
    assert_eq!((st, code(&b)), (StatusCode::BAD_REQUEST, Some("points_non_positive".into())), "{b}");

    set_cap(&pool, 500).await; // 5% of the total
    let (st, b) = call(&app, "POST", "/v1/checkouts", token, Some(checkout_body(&c, 10, 5_000))).await;
    assert_eq!((st, code(&b)), (StatusCode::CONFLICT, Some("points_over_cap".into())), "{b}");

    set_cap(&pool, 10_000).await;
    grant(&pool, c.user, 500_000, "seed:12b").await;
    let (_, free) = call(&app, "POST", "/v1/checkouts", token, Some(checkout_body(&c, 10, 0))).await;
    let total = free["total"].as_i64().expect("total");
    let (st, b) = call(&app, "POST", "/v1/checkouts", token, Some(checkout_body(&c, 10, total))).await;
    assert_eq!((st, code(&b)), (StatusCode::BAD_REQUEST, Some("points_cover_total".into())), "the PG cannot charge zero: {b}");
    assert_eq!(spend_rows(&pool, c.user).await, (0, 0));
}

#[sqlx::test(migrations = "../../migrations")]
async fn checkout_fails_whole_when_the_balance_is_gone_at_settlement(pool: PgPool) {
    seed_catalog(&pool).await;
    enable_points(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6100-0013").await;
    grant(&pool, c.user, 6_000, "seed:13").await;
    let token = Some(c.token.as_str());
    let (st, first) = call(&app, "POST", "/v1/checkouts", token, Some(checkout_body(&c, 10, 6_000))).await;
    assert_eq!(st, StatusCode::OK, "{first}");
    let (_, second) = call(&app, "POST", "/v1/checkouts", token, Some(checkout_body(&c, 12, 6_000))).await;

    // Both checkouts were quoted against the same 6,000 points; only the first to settle gets them.
    let confirm = |id: &Value| format!("/v1/checkouts/{}/confirm", id.as_str().expect("id"));
    let (st, _) = call(&app, "POST", &confirm(&first["id"]), token, Some(json!({ "payment_id": "dev:paid" }))).await;
    assert_eq!(st, StatusCode::OK);
    let (st, b) = call(&app, "POST", &confirm(&second["id"]), token, Some(json!({ "payment_id": "dev:paid" }))).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::CONFLICT, Some("points_insufficient")), "{b}");
    assert_eq!(spend_rows(&pool, c.user).await, (1, 6_000), "the failed checkout debits nothing");
    let (status, booked): (String, Option<Uuid>) =
        sqlx::query_as("SELECT status, result_booking_id FROM checkouts WHERE id = $1::uuid").bind(second["id"].as_str()).fetch_one(&pool).await.expect("checkout");
    assert_eq!((status.as_str(), booked), ("failed", None), "no booking without its points");
}

#[sqlx::test(migrations = "../../migrations")]
async fn cancel_fee_is_kept_from_points_and_cash_alike(pool: PgPool) {
    seed_catalog(&pool).await;
    enable_points(&pool).await;
    sqlx::query("INSERT INTO settings (key, value) VALUES ('cancel_policy', $1) ON CONFLICT (key) DO UPDATE SET value = $1")
        .bind(json!({ "tiers": [{ "min_days": 3, "percent": 0 }, { "min_days": -100, "percent": 50 }], "min_fee": 0, "reschedule_min_days": 2 }))
        .execute(&pool)
        .await
        .expect("policy");
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6100-0014").await;
    grant(&pool, c.user, 10_000, "seed:14").await;
    let token = Some(c.token.as_str());
    let (st, intent) = call(&app, "POST", "/v1/checkouts", token, Some(checkout_body(&c, 1, 10_000))).await;
    assert_eq!(st, StatusCode::OK, "{intent}");
    let total = intent["total"].as_i64().expect("total");
    let uri = format!("/v1/checkouts/{}/confirm", intent["id"].as_str().expect("id"));
    let (st, done) = call(&app, "POST", &uri, token, Some(json!({ "payment_id": "dev:paid" }))).await;
    assert_eq!(st, StatusCode::OK, "{done}");
    let booking = done["booking_id"].as_str().expect("booking").to_string();

    let (_, preview) = call(&app, "GET", &format!("/v1/bookings/{booking}/cancel-preview"), token, None).await;
    let fee = preview["fee"].as_i64().expect("fee");
    assert_eq!(fee, total / 2, "{preview}");
    let (st, b) = call(&app, "POST", &format!("/v1/bookings/{booking}/cancel"), token, Some(json!({ "accepted_fee": fee }))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let refunded: i64 =
        sqlx::query_scalar("SELECT COALESCE(SUM(refunded_amount), 0)::bigint FROM payments WHERE booking_id = $1::uuid").bind(&booking).fetch_one(&pool).await.expect("refund");
    let back = balance(&app, &c).await;
    assert!((4_999..=5_000).contains(&back), "half the points come back, not all: {back}");
    assert!(refunded + back <= total - fee && refunded + back >= total - fee - 2, "cash {refunded} + points {back} is the policy refund {}", total - fee);
}

// ---- Console: per-customer ledger and audited manual adjustment (admin only) ----

async fn staff_token(pool: &PgPool, email: &str, role: &str, as_role: Role) -> (String, Uuid) {
    let id: Uuid = sqlx::query_scalar("INSERT INTO staff (email, name, password_hash, role) VALUES ($1, 'Staff', 'unused', $2) RETURNING id")
        .bind(email)
        .bind(role)
        .fetch_one(pool)
        .await
        .expect("staff row");
    (auth::issue_access(SECRET, id, as_role).expect("token"), id)
}

#[sqlx::test(migrations = "../../migrations")]
async fn admin_adjusts_points_with_a_reason_and_it_is_audited(pool: PgPool) {
    seed_catalog(&pool).await;
    enable_points(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6100-0015").await;
    let (admin, admin_id) = staff_token(&pool, "points-admin@test.local", "admin", Role::StaffAdmin).await;
    let (consultant, _) = staff_token(&pool, "points-consultant@test.local", "consultant", Role::StaffConsultant).await;
    let adjust = |amount: i64, reason: &str| json!({ "user_id": c.user, "amount": amount, "reason": reason });

    let (st, _) = call(&app, "POST", "/v1/admin/growth/points/adjust", Some(consultant.as_str()), Some(adjust(1_000, "nope"))).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "consultants cannot move points");
    let (st, _) = call(&app, "GET", &format!("/v1/admin/growth/points/{}", c.user), Some(consultant.as_str()), None).await;
    assert_eq!(st, StatusCode::FORBIDDEN);

    let (st, b) = call(&app, "POST", "/v1/admin/growth/points/adjust", Some(admin.as_str()), Some(adjust(3_000, "  "))).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::BAD_REQUEST, Some("points_adjust_reason")), "{b}");
    let (st, b) = call(&app, "POST", "/v1/admin/growth/points/adjust", Some(admin.as_str()), Some(adjust(3_000, "service recovery"))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (st, b) = call(&app, "POST", "/v1/admin/growth/points/adjust", Some(admin.as_str()), Some(adjust(-1_000, "granted twice"))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (st, b) = call(&app, "POST", "/v1/admin/growth/points/adjust", Some(admin.as_str()), Some(adjust(-2_001, "too much"))).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::CONFLICT, Some("points_insufficient")), "{b}");

    let (st, ledger) = call(&app, "GET", &format!("/v1/admin/growth/points/{}", c.user), Some(admin.as_str()), None).await;
    assert_eq!((st, ledger["balance"].as_i64()), (StatusCode::OK, Some(2_000)), "{ledger}");
    let rows = ledger["entries"].as_array().expect("entries");
    assert_eq!(rows.len(), 2);
    assert_eq!((rows[0]["kind"].as_str(), rows[0]["amount"].as_i64(), rows[0]["reason"].as_str()), (Some("deduct"), Some(-1_000), Some("granted twice")));
    assert_eq!(rows[1]["actor_id"].as_str(), Some(admin_id.to_string().as_str()));

    let (_, mine) = call(&app, "GET", "/v1/me/points", Some(c.token.as_str()), None).await;
    assert!(mine["entries"][0].get("reason").is_none(), "staff notes stay in the console: {mine}");

    let audited: Vec<(Option<Uuid>, Value)> =
        sqlx::query_as("SELECT actor_id, data FROM audit_log WHERE action = 'points.adjust' AND target = $1 ORDER BY created_at, id").bind(c.user.to_string()).fetch_all(&pool).await.expect("audit");
    assert_eq!(audited.len(), 2, "one audit row per applied adjustment, none for the refused ones");
    assert_eq!((audited[0].0, audited[0].1["amount"].as_i64(), audited[0].1["reason"].as_str()), (Some(admin_id), Some(3_000), Some("service recovery")));
}
