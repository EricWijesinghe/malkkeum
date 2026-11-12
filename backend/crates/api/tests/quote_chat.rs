//! Quote card in chat: staff send-quote posts a structured card copied from the booking row, the
//! customer pays the server-computed 10% deposit once (bound to the amount on the card they
//! tapped), and a free-window cancel refunds it.

mod common;

use api::auth::{self, Role};
use axum::{
    Router,
    body::{Body, to_bytes},
    extract::ConnectInfo,
    http::{HeaderMap, Request, StatusCode, header},
};
use chrono::Duration;
use common::{Customer, SECRET, call, call_keyed, customer, seed_catalog, verified_pro};
use serde_json::{Value, json};
use sqlx::PgPool;
use std::net::SocketAddr;
use tower::ServiceExt;
use uuid::Uuid;

/// `call_keyed` that also returns the response headers.
async fn send(app: &Router, uri: &str, token: &str, key: &str, body: Value) -> (StatusCode, HeaderMap, Value) {
    let mut req = Request::builder()
        .method("POST")
        .uri(uri)
        .header(header::CONTENT_TYPE, "application/json")
        .header(header::AUTHORIZATION, format!("Bearer {token}"))
        .header("idempotency-key", key)
        .body(Body::from(body.to_string()))
        .expect("request");
    req.extensions_mut().insert(ConnectInfo(SocketAddr::from(([127, 0, 0, 1], 40_000))));
    let res = app.clone().oneshot(req).await.expect("router is infallible");
    let status = res.status();
    let headers = res.headers().clone();
    let bytes = to_bytes(res.into_body(), usize::MAX).await.expect("body");
    (status, headers, serde_json::from_slice(&bytes).unwrap_or(Value::Null))
}

async fn staff(pool: &PgPool, email: &str, role: Role) -> (String, Uuid) {
    let hash = auth::hash_password("staff-pass-12345").expect("hash");
    let db_role = if role == Role::StaffAdmin { "admin" } else { "consultant" };
    let id: Uuid = sqlx::query_scalar("INSERT INTO staff (email, name, password_hash, role) VALUES ($1, 'Desk', $2, $3) RETURNING id")
        .bind(email)
        .bind(hash)
        .bind(db_role)
        .fetch_one(pool)
        .await
        .expect("staff row");
    (auth::issue_access(SECRET, id, role).expect("token"), id)
}

async fn consultant(pool: &PgPool) -> String {
    staff(pool, "desk@test.local", Role::StaffConsultant).await.0
}

const MOVE_ANSWERS: &str = r#"{"cleaning_type":"standard","luggage":"empty","building":"apartment","layout":"two_rooms",
  "duplex":false,"bathrooms":1,"balconies":1,"elevator":true,"floor_3_or_higher":true}"#;

/// A move-out consultation `days` out. Returns (booking id, estimate).
async fn quote_booking(app: &Router, c: &Customer, days: i64) -> (String, i64) {
    let visit = api::util::today_kst() + Duration::days(days);
    let answers: Value = serde_json::from_str(MOVE_ANSWERS).expect("answers");
    let (st, b) = call(
        app,
        "POST",
        "/v1/bookings",
        Some(c.token.as_str()),
        Some(json!({
            "service_code": "move_out", "address_id": c.address, "visit_date": visit, "start_hour": 8,
            "answers": answers, "visit_notes": {}
        })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "quote request: {b}");
    assert_eq!(b["status"], 0, "consultation until the deposit: {b}");
    (b["id"].as_str().expect("booking id").to_string(), b["estimate"].as_i64().expect("estimate"))
}

async fn send_quote(app: &Router, token: &str, id: &str, body: Value) -> (StatusCode, Value) {
    call(app, "POST", &format!("/v1/admin/bookings/{id}/send-quote"), Some(token), Some(body)).await
}

async fn charged(pool: &PgPool, id: &str) -> (i64, i64) {
    sqlx::query_as("SELECT COALESCE(SUM(amount), 0)::bigint, COALESCE(SUM(refunded_amount), 0)::bigint FROM payments WHERE booking_id = $1::uuid")
        .bind(id)
        .fetch_one(pool)
        .await
        .expect("payments")
}

fn code(b: &Value) -> &str {
    b["error"]["code"].as_str().unwrap_or_default()
}

#[sqlx::test(migrations = "../../migrations")]
async fn quote_card_carries_the_booking_and_the_deposit_is_paid_once_then_refunded(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0001").await;
    let (id, estimate) = quote_booking(&app, &c, 10).await;
    let visit = api::util::today_kst() + Duration::days(10);

    let desk = consultant(&pool).await;
    let (st, msg) = send_quote(&app, &desk, &id, json!({ "final_price": 350_000 })).await;
    assert_eq!(st, StatusCode::OK, "send-quote: {msg}");
    assert_eq!(msg["kind"], "quote");
    let body = &msg["body"];
    assert_eq!(body["booking_id"], id.as_str());
    assert_eq!(body["final_price"], 350_000);
    assert_eq!(body["deposit"], 35_000, "round100(10%) of the confirmed price");
    assert_eq!(body["balance"], 315_000);
    assert_eq!(body["service_code"], "move_out");
    assert_eq!(body["visit_date"], visit.to_string());
    assert_eq!(body["start_hour"], 8);
    assert_eq!(body["estimate"], estimate);
    assert_eq!(body["answers"]["building"], "apartment");
    assert_eq!(body["answers"]["layout"], "two_rooms");

    let pay = json!({ "payment_method_id": c.card, "expected_deposit": 35_000 });
    let uri = format!("/v1/bookings/{id}/deposit");
    let (st, h1, paid) = send(&app, &uri, &c.token, "u4-deposit-1", pay.clone()).await;
    assert_eq!(st, StatusCode::OK, "deposit: {paid}");
    assert!(h1.get("idempotent-replayed").is_none(), "first call is not a replay");
    assert_eq!(paid["status"], 1, "confirmed after the deposit: {paid}");
    assert_eq!(paid["paid_amount"], 35_000);
    // Same key: the stored response is replayed, nothing is charged twice.
    let (st, h2, again) = send(&app, &uri, &c.token, "u4-deposit-1", pay.clone()).await;
    assert_eq!(st, StatusCode::OK, "replay: {again}");
    assert_eq!(h2.get("idempotent-replayed").map(|v| v.to_str().unwrap_or_default()), Some("true"));
    assert_eq!(again, paid, "identical replayed body");
    // A new key is a second attempt: refused.
    let (st, _, second) = send(&app, &uri, &c.token, "u4-deposit-2", pay).await;
    assert_eq!((st, code(&second)), (StatusCode::CONFLICT, "already_confirmed"), "second deposit: {second}");
    assert_eq!(charged(&pool, &id).await, (35_000, 0), "one deposit charge");

    // A paid booking takes no further quote.
    let (st, b) = send_quote(&app, &desk, &id, json!({ "final_price": 400_000 })).await;
    assert_eq!((st, code(&b)), (StatusCode::CONFLICT, "not_open_quote"), "{b}");

    // 10 days out is inside the free-cancel window: the whole deposit comes back.
    let (st, cancelled) = call(&app, "POST", &format!("/v1/bookings/{id}/cancel"), Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{cancelled}");
    assert_eq!(cancelled["status"], -1);
    assert_eq!(charged(&pool, &id).await, (35_000, 35_000));
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_re_quote_after_the_card_was_shown_is_refused_with_the_new_amount(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0003").await;
    let (id, _) = quote_booking(&app, &c, 10).await;
    let desk = consultant(&pool).await;
    assert_eq!(send_quote(&app, &desk, &id, json!({ "final_price": 350_000 })).await.0, StatusCode::OK);
    // Re-quote while the customer still looks at the 35,000 card.
    assert_eq!(send_quote(&app, &desk, &id, json!({ "final_price": 500_000 })).await.0, StatusCode::OK);

    let uri = format!("/v1/bookings/{id}/deposit");
    let stale = json!({ "payment_method_id": c.card, "expected_deposit": 35_000 });
    let (st, b) = call_keyed(&app, "POST", &uri, Some(c.token.as_str()), Some(stale), Some("u4-stale")).await;
    assert_eq!((st, code(&b)), (StatusCode::CONFLICT, "price_changed"), "{b}");
    assert_eq!(b["error"]["current"], 50_000, "the amount now due");
    assert_eq!(charged(&pool, &id).await, (0, 0), "nothing charged");

    // The checkout path (PortOne channels) binds the same way.
    let ck = |expected: i64| json!({ "kind": "deposit", "method": "card", "booking_id": id, "expected_deposit": expected });
    let (st, b) = call(&app, "POST", "/v1/checkouts", Some(c.token.as_str()), Some(ck(35_000))).await;
    assert_eq!((st, code(&b)), (StatusCode::CONFLICT, "price_changed"), "{b}");
    let (st, intent) = call_keyed(&app, "POST", "/v1/checkouts", Some(c.token.as_str()), Some(ck(50_000)), Some("u4-ck")).await;
    assert_eq!(st, StatusCode::OK, "{intent}");
    assert_eq!(intent["amount"], 50_000);
    let confirm = format!("/v1/checkouts/{}/confirm", intent["id"].as_str().expect("checkout id"));
    let (st, done) = call_keyed(&app, "POST", &confirm, Some(c.token.as_str()), Some(json!({ "payment_id": "dev:paid" })), Some("u4-ck-ok")).await;
    assert_eq!((st, done["status"].as_str()), (StatusCode::OK, Some("paid")), "{done}");
    let status: i16 = sqlx::query_scalar("SELECT status FROM bookings WHERE id = $1::uuid").bind(&id).fetch_one(&pool).await.expect("status");
    assert_eq!(status, 1, "confirmed by the checkout deposit");
    assert_eq!(charged(&pool, &id).await, (50_000, 0));
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_re_quote_racing_the_deposit_write_is_booking_changed_and_charges_nothing(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0004").await;
    let (id, _) = quote_booking(&app, &c, 10).await;
    let (_, pro) = verified_pro(&app, &pool, "010-5400-0104").await;
    let quote: Uuid = sqlx::query_scalar("INSERT INTO quotes (booking_id, pro_id, amount) VALUES ($1::uuid, $2, 350000) RETURNING id")
        .bind(&id)
        .bind(pro)
        .fetch_one(&pool)
        .await
        .expect("pro quote");
    let desk = consultant(&pool).await;
    let (st, b) = send_quote(&app, &desk, &id, json!({ "final_price": 350_000, "quote_id": quote })).await;
    assert_eq!(st, StatusCode::OK, "{b}");

    // Hold the booking row, as send_quote does: the deposit reads 35,000 due, then blocks in take_deposit.
    let mut hold = pool.begin().await.expect("tx");
    sqlx::query("SELECT 1 FROM bookings WHERE id = $1::uuid FOR UPDATE").bind(&id).execute(&mut *hold).await.expect("lock");
    let (app2, token, card, uri) = (app.clone(), c.token.clone(), c.card, format!("/v1/bookings/{id}/deposit"));
    let pay = tokio::spawn(async move {
        call_keyed(&app2, "POST", &uri, Some(token.as_str()), Some(json!({ "payment_method_id": card, "expected_deposit": 35_000 })), Some("u4-race")).await
    });
    let mut waited = 0;
    loop {
        let blocked: i64 = sqlx::query_scalar("SELECT count(*) FROM pg_stat_activity WHERE datname = current_database() AND wait_event_type = 'Lock'").fetch_one(&pool).await.expect("locks");
        if blocked > 0 {
            break;
        }
        waited += 1;
        assert!(waited < 200, "the deposit never reached the quote lock");
        tokio::time::sleep(std::time::Duration::from_millis(25)).await;
    }
    // Lock order: booking first, so while it waits the deposit holds no quote lock (no deadlock with send_quote).
    let mut probe = pool.begin().await.expect("probe tx");
    sqlx::query("SELECT 1 FROM quotes WHERE id = $1 FOR UPDATE NOWAIT").bind(quote).execute(&mut *probe).await.expect("quote row is free");
    probe.rollback().await.expect("rollback");
    // The re-quote lands between the deposit's read and its write.
    sqlx::query("UPDATE bookings SET final_price = 500000, deposit = 50000 WHERE id = $1::uuid").bind(&id).execute(&mut *hold).await.expect("re-quote");
    hold.commit().await.expect("commit");

    let (st, b) = pay.await.expect("join");
    assert_eq!((st, code(&b)), (StatusCode::CONFLICT, "booking_changed"), "{b}");
    assert_eq!(charged(&pool, &id).await, (0, 0), "the card is never charged");
    let status: i16 = sqlx::query_scalar("SELECT status FROM bookings WHERE id = $1::uuid").bind(&id).fetch_one(&pool).await.expect("status");
    assert_eq!(status, 0, "still a consultation");
}

#[sqlx::test(migrations = "../../migrations")]
async fn send_quote_validates_price_note_ratio_and_who_may_send(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0002").await;
    let (id, estimate) = quote_booking(&app, &c, 12).await;
    let desk = consultant(&pool).await;

    for (price, why) in [(0, "zero"), (49, "rounds to 0"), (9_900, "under the minimum"), (50_000_100, "over the maximum")] {
        let (st, b) = send_quote(&app, &desk, &id, json!({ "final_price": price })).await;
        assert_eq!((st, code(&b)), (StatusCode::BAD_REQUEST, "invalid_amount"), "{why}: {b}");
    }
    let long = "가".repeat(301);
    let (st, b) = send_quote(&app, &desk, &id, json!({ "final_price": estimate, "note": long })).await;
    assert_eq!((st, code(&b)), (StatusCode::BAD_REQUEST, "note_too_long"), "{b}");

    // More than 3x the estimate: consultants can't, admins only with override.
    let far = estimate * 4;
    let (st, b) = send_quote(&app, &desk, &id, json!({ "final_price": far })).await;
    assert_eq!((st, code(&b)), (StatusCode::CONFLICT, "quote_override_required"), "{b}");
    let (st, _) = send_quote(&app, &desk, &id, json!({ "final_price": far, "override": true })).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "consultant override");
    let (admin, _) = staff(&pool, "admin@test.local", Role::StaffAdmin).await;
    let (st, b) = send_quote(&app, &admin, &id, json!({ "final_price": estimate / 4 })).await;
    assert_eq!((st, code(&b)), (StatusCode::CONFLICT, "quote_override_required"), "under 0.3x: {b}");
    let (st, b) = send_quote(&app, &admin, &id, json!({ "final_price": far, "override": true })).await;
    assert_eq!(st, StatusCode::OK, "admin override: {b}");

    // Not staff: refused.
    let (st, _) = send_quote(&app, &c.token, &id, json!({ "final_price": estimate })).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "customer token");
    let (pro, _) = verified_pro(&app, &pool, "010-5400-0102").await;
    let (st, _) = send_quote(&app, &pro, &id, json!({ "final_price": estimate })).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "pro token");

    // A deactivated account's still-valid access token can't send.
    let (gone, gone_id) = staff(&pool, "gone@test.local", Role::StaffConsultant).await;
    sqlx::query("UPDATE staff SET active = FALSE WHERE id = $1").bind(gone_id).execute(&pool).await.expect("deactivate");
    let (st, _) = send_quote(&app, &gone, &id, json!({ "final_price": estimate })).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "deactivated staff");

    // A quote id from nowhere rolls the whole send back.
    let before: Option<i64> = sqlx::query_scalar("SELECT final_price FROM bookings WHERE id = $1::uuid").bind(&id).fetch_one(&pool).await.expect("price");
    let cards: i64 = sqlx::query_scalar("SELECT count(*) FROM chat_messages WHERE kind = 'quote'").fetch_one(&pool).await.expect("cards");
    let (st, b) = send_quote(&app, &desk, &id, json!({ "final_price": estimate, "quote_id": Uuid::now_v7() })).await;
    assert_eq!((st, code(&b)), (StatusCode::CONFLICT, "quote_unavailable"), "{b}");
    let after: Option<i64> = sqlx::query_scalar("SELECT final_price FROM bookings WHERE id = $1::uuid").bind(&id).fetch_one(&pool).await.expect("price");
    assert_eq!(after, before, "price unchanged");
    let cards_after: i64 = sqlx::query_scalar("SELECT count(*) FROM chat_messages WHERE kind = 'quote'").fetch_one(&pool).await.expect("cards");
    assert_eq!(cards_after, cards, "no card posted");
}

#[sqlx::test(migrations = "../../migrations")]
async fn send_quote_ignores_card_fields_in_the_request(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0005").await;
    let (id, estimate) = quote_booking(&app, &c, 12).await;
    let visit = api::util::today_kst() + Duration::days(12);
    let desk = consultant(&pool).await;
    let price = (estimate / 100) * 100 + 49;
    let (st, msg) = send_quote(
        &app,
        &desk,
        &id,
        json!({ "final_price": price, "deposit": 1, "balance": 1, "visit_date": "2000-01-01", "start_hour": 3, "estimate": 1 }),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "send-quote: {msg}");
    let body = &msg["body"];
    assert_eq!(body["final_price"], price - 49, "rounded to 100 won");
    assert_ne!(body["deposit"], 1);
    assert_eq!(body["visit_date"], visit.to_string(), "from the booking, not the request");
    assert_eq!(body["start_hour"], 8);
    assert_eq!(body["estimate"], estimate);
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_small_re_quote_or_a_newer_quote_message_is_price_changed(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0006").await;
    let (id, _) = quote_booking(&app, &c, 10).await;
    let desk = consultant(&pool).await;
    let (_, first) = send_quote(&app, &desk, &id, json!({ "final_price": 350_000 })).await;
    // Same deposit (round100 of 10%), different price.
    let (_, second) = send_quote(&app, &desk, &id, json!({ "final_price": 350_400 })).await;
    assert_eq!(second["body"]["deposit"], 35_000);
    let uri = format!("/v1/bookings/{id}/deposit");
    let seen = |price: i64, msg: &Value| {
        json!({ "payment_method_id": c.card, "expected_deposit": 35_000, "expected_final_price": price, "expected_quote_message_id": msg["id"] })
    };
    let (st, b) = call(&app, "POST", &uri, Some(c.token.as_str()), Some(seen(350_000, &first))).await;
    assert_eq!((st, code(&b)), (StatusCode::CONFLICT, "price_changed"), "{b}");
    assert_eq!((b["error"]["current"].clone(), b["error"]["final_price"].clone()), (json!(35_000), json!(350_400)));
    assert_eq!(b["error"]["quote_message_id"], second["id"]);

    // Same price again but a newer card (e.g. another pro): the older card's id is refused.
    let (_, third) = send_quote(&app, &desk, &id, json!({ "final_price": 350_400 })).await;
    let (st, b) = call(&app, "POST", &uri, Some(c.token.as_str()), Some(seen(350_400, &second))).await;
    assert_eq!((st, code(&b)), (StatusCode::CONFLICT, "price_changed"), "{b}");
    assert_eq!(b["error"]["quote_message_id"], third["id"]);
    assert_eq!(charged(&pool, &id).await, (0, 0));

    let (st, b) = call(&app, "POST", &uri, Some(c.token.as_str()), Some(seen(350_400, &third))).await;
    assert_eq!(st, StatusCode::OK, "the newest card pays: {b}");
    assert_eq!(charged(&pool, &id).await, (35_000, 0));
}

#[sqlx::test(migrations = "../../migrations")]
async fn override_rights_come_from_the_staff_row_not_the_token(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0007").await;
    let (id, estimate) = quote_booking(&app, &c, 10).await;
    // A consultant row carrying an admin token (e.g. demoted after sign-in).
    let (_, demoted) = staff(&pool, "demoted@test.local", Role::StaffConsultant).await;
    let stale_admin = auth::issue_access(SECRET, demoted, Role::StaffAdmin).expect("token");
    let (st, _) = send_quote(&app, &stale_admin, &id, json!({ "final_price": estimate * 4, "override": true })).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "override checks the staff row's role");
}

#[sqlx::test(migrations = "../../migrations")]
async fn an_old_app_without_expected_fields_still_pays(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0008").await;
    let (id, _) = quote_booking(&app, &c, 10).await;
    let desk = consultant(&pool).await;
    assert_eq!(send_quote(&app, &desk, &id, json!({ "final_price": 350_000 })).await.0, StatusCode::OK);
    let uri = format!("/v1/bookings/{id}/deposit");
    let (st, b) = call(&app, "POST", &uri, Some(c.token.as_str()), Some(json!({ "payment_method_id": c.card }))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert_eq!(charged(&pool, &id).await, (35_000, 0));
}
