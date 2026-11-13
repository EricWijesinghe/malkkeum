//! Checkout payment binding (one PortOne payment backs exactly one checkout) and durable
//! compensating refunds (a failed refund is queued and retried, never reported as done).
//! Same DB and dev fakes as flows.rs (needs DATABASE_URL, sqlx::test).

mod common;

use axum::{Router, http::StatusCode};
use common::{Customer, call, customer, seed_catalog};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

fn checkout_body(c: &Customer, days: i64) -> Value {
    let visit = api::util::today_kst() + chrono::Duration::days(days);
    json!({ "kind": "booking", "method": "card",
            "booking": { "service_code": "studio", "address_id": c.address, "visit_date": visit, "start_hour": 9, "visit_notes": {} } })
}

async fn new_checkout(app: &Router, c: &Customer, days: i64) -> Uuid {
    let (st, intent) = call(app, "POST", "/v1/checkouts", Some(c.token.as_str()), Some(checkout_body(c, days))).await;
    assert_eq!(st, StatusCode::OK, "{intent}");
    intent["id"].as_str().expect("id").parse().expect("uuid")
}

async fn confirm(app: &Router, c: &Customer, checkout: Uuid, payment_id: &str) -> (StatusCode, Value) {
    call(app, "POST", &format!("/v1/checkouts/{checkout}/confirm"), Some(c.token.as_str()), Some(json!({ "payment_id": payment_id }))).await
}

fn code(b: &Value) -> &str {
    b["error"]["code"].as_str().unwrap_or_default()
}

async fn checkout_status(pool: &PgPool, id: Uuid) -> String {
    sqlx::query_scalar("SELECT status FROM checkouts WHERE id = $1").bind(id).fetch_one(pool).await.expect("checkout")
}

async fn refunds(pool: &PgPool) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM refund_queue").fetch_one(pool).await.expect("refund queue")
}

async fn notices(pool: &PgPool, user: Uuid, kind: &str) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM notifications WHERE owner_role = 'customer' AND owner_id = $1 AND kind = $2")
        .bind(user)
        .bind(kind)
        .fetch_one(pool)
        .await
        .expect("notices")
}

/// Checkout A paid with its own id (the app's PortOne paymentId). Returns (checkout A, booking A).
async fn paid_checkout(app: &Router, pool: &PgPool, c: &Customer) -> (Uuid, Uuid) {
    let a = new_checkout(app, c, 10).await;
    let (st, done) = confirm(app, c, a, &a.to_string()).await;
    assert_eq!((st, done["status"].as_str()), (StatusCode::OK, Some("paid")), "{done}");
    let booking = done["booking_id"].as_str().expect("booking").parse().expect("uuid");
    assert_eq!(refunds(pool).await, 0);
    (a, booking)
}

async fn assert_a_untouched(pool: &PgPool, a: Uuid, booking: Uuid, user: Uuid) {
    assert_eq!(checkout_status(pool, a).await, "paid");
    let (status, refunded): (String, i64) = sqlx::query_as("SELECT status, refunded_amount FROM payments WHERE booking_id = $1")
        .bind(booking)
        .fetch_one(pool)
        .await
        .expect("payment A");
    assert_eq!((status.as_str(), refunded), ("paid", 0), "A's payment is not refunded");
    let bookings: i64 = sqlx::query_scalar("SELECT count(*) FROM bookings WHERE user_id = $1").bind(user).fetch_one(pool).await.expect("bookings");
    assert_eq!(bookings, 1, "no second booking");
    assert_eq!(refunds(pool).await, 0, "no provider refund was attempted");
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_foreign_payment_with_another_amount_is_refused_without_refunding_it(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-7100-0001").await;
    let (a, booking) = paid_checkout(&app, &pool, &c).await;
    let b = new_checkout(&app, &c, 12).await;
    // B is for a different amount, so the old code took the mismatch branch and refunded A's payment.
    sqlx::query("UPDATE checkouts SET amount = amount + 1000 WHERE id = $1").bind(b).execute(&pool).await.expect("amount");

    let (st, body) = confirm(&app, &c, b, &a.to_string()).await;
    assert_eq!((st, code(&body)), (StatusCode::BAD_REQUEST, "payment_not_for_checkout"), "{body}");
    assert_eq!(checkout_status(&pool, b).await, "pending", "B is left as it was");
    assert_a_untouched(&pool, a, booking, c.user).await;
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_foreign_payment_with_the_same_amount_books_nothing(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-7100-0002").await;
    let (a, booking) = paid_checkout(&app, &pool, &c).await;
    let b = new_checkout(&app, &c, 12).await;

    let (st, body) = confirm(&app, &c, b, &a.to_string()).await;
    assert_eq!((st, code(&body)), (StatusCode::BAD_REQUEST, "payment_not_for_checkout"), "{body}");
    // A dev id bound to another checkout is refused the same way.
    let (st, body) = confirm(&app, &c, b, &format!("dev:paid:{a}")).await;
    assert_eq!((st, code(&body)), (StatusCode::BAD_REQUEST, "payment_not_for_checkout"), "{body}");
    assert_eq!(checkout_status(&pool, b).await, "pending");
    assert_a_untouched(&pool, a, booking, c.user).await;
}

#[sqlx::test(migrations = "../../migrations")]
async fn dev_payment_ids_are_bound_to_their_checkout(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-7100-0003").await;
    let first = new_checkout(&app, &c, 10).await;
    let second = new_checkout(&app, &c, 12).await;
    for ck in [first, second] {
        let (st, done) = confirm(&app, &c, ck, "dev:paid").await;
        assert_eq!(st, StatusCode::OK, "{done}");
        // Re-confirming with the same dev id is idempotent.
        let (st, again) = confirm(&app, &c, ck, "dev:paid").await;
        assert_eq!((st, &again["booking_id"]), (StatusCode::OK, &done["booking_id"]), "{again}");
    }
    let ids: Vec<String> = sqlx::query_scalar("SELECT provider_tx_id FROM payments p JOIN bookings b ON b.id = p.booking_id WHERE b.user_id = $1 ORDER BY 1")
        .bind(c.user)
        .fetch_all(&pool)
        .await
        .expect("payments");
    let mut want = vec![format!("dev:paid:{first}"), format!("dev:paid:{second}")];
    want.sort();
    assert_eq!(ids, want, "one stored payment id per checkout");
}

#[sqlx::test(migrations = "../../migrations")]
async fn one_portone_payment_cannot_be_recorded_twice(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-7100-0004").await;
    let (a, booking) = paid_checkout(&app, &pool, &c).await;
    let dup = sqlx::query("INSERT INTO payments (booking_id, amount, kind, status, provider, provider_tx_id, idempotency_key) VALUES ($1, 1000, 'full', 'paid', 'portone', $2, 'dup')")
        .bind(booking)
        .bind(a.to_string())
        .execute(&pool)
        .await;
    let err = dup.expect_err("the unique index refuses a second row for one PortOne payment");
    assert_eq!(err.as_database_error().and_then(|e| e.code()).as_deref(), Some("23505"), "{err}");
}

/// A late payment whose slot is gone: the compensating refund path (`apply` -> FulfilLate).
async fn late_payment_on_full_slot(pool: &PgPool, app: &Router, c: &Customer) -> Uuid {
    let ck = new_checkout(app, c, 10).await;
    sqlx::query("UPDATE checkouts SET expires_at = now() - interval '1 minute' WHERE id = $1").bind(ck).execute(pool).await.expect("expire");
    sqlx::query("INSERT INTO slot_capacity (start_hour, capacity) VALUES (9, 0) ON CONFLICT (start_hour) DO UPDATE SET capacity = 0")
        .execute(pool)
        .await
        .expect("full slot");
    ck
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_failed_compensating_refund_is_pending_then_retried_until_refunded(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let state = api::build_state(pool.clone(), common::test_config()).expect("state");
    let c = customer(&app, &pool, "010-7100-0005").await;
    let ck = late_payment_on_full_slot(&pool, &app, &c).await;
    api::util::fail_dev_refunds(&ck.to_string(), 2);

    let (st, body) = confirm(&app, &c, ck, &ck.to_string()).await;
    assert_eq!((st, code(&body)), (StatusCode::CONFLICT, "checkout_refund_pending"), "{body}");
    assert_eq!(checkout_status(&pool, ck).await, "refund_pending", "never 'refunded' before the money went back");
    assert_eq!(notices(&pool, c.user, "payment.refunded").await, 0, "no 'refunded' push");
    assert_eq!(notices(&pool, c.user, "payment.refund_pending").await, 1, "told the refund is in progress");
    assert_eq!(refunds(&pool).await, 1, "one queued refund");

    // A retry of the same confirm queues nothing new and calls no refund.
    let (st, body) = confirm(&app, &c, ck, &ck.to_string()).await;
    assert_eq!((st, code(&body)), (StatusCode::CONFLICT, "checkout_closed"), "{body}");
    assert_eq!(refunds(&pool).await, 1);

    let due = || sqlx::query("UPDATE refund_queue SET next_at = now()").execute(&pool);
    // Not due yet: the drain leaves it alone.
    assert_eq!(api::routes::checkout_recon::drain_refunds(&state).await.expect("drain"), 0);
    due().await.expect("due");
    assert_eq!(api::routes::checkout_recon::drain_refunds(&state).await.expect("drain"), 1, "second failure");
    let (attempts, done): (i32, bool) = sqlx::query_as("SELECT attempts, done_at IS NOT NULL FROM refund_queue").fetch_one(&pool).await.expect("row");
    assert_eq!((attempts, done), (2, false));
    assert_eq!(checkout_status(&pool, ck).await, "refund_pending");

    due().await.expect("due");
    assert_eq!(api::routes::checkout_recon::drain_refunds(&state).await.expect("drain"), 1, "provider recovered");
    let (attempts, done): (i32, bool) = sqlx::query_as("SELECT attempts, done_at IS NOT NULL FROM refund_queue").fetch_one(&pool).await.expect("row");
    assert_eq!((attempts, done), (3, true));
    assert_eq!(checkout_status(&pool, ck).await, "refunded");
    assert_eq!(notices(&pool, c.user, "payment.refunded").await, 1, "told once when it landed");

    due().await.expect("due");
    assert_eq!(api::routes::checkout_recon::drain_refunds(&state).await.expect("drain"), 0, "done rows are never retried");
    assert_eq!(notices(&pool, c.user, "payment.refunded").await, 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_compensating_refund_that_lands_is_refunded_at_once(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-7100-0006").await;
    let ck = late_payment_on_full_slot(&pool, &app, &c).await;

    let (st, body) = confirm(&app, &c, ck, &ck.to_string()).await;
    assert_eq!((st, code(&body)), (StatusCode::CONFLICT, "checkout_refunded"), "{body}");
    assert_eq!(checkout_status(&pool, ck).await, "refunded");
    assert_eq!(notices(&pool, c.user, "payment.refunded").await, 1);
    let done: bool = sqlx::query_scalar("SELECT done_at IS NOT NULL FROM refund_queue").fetch_one(&pool).await.expect("row");
    assert!(done, "the refund is recorded as done");
    // A replay refunds nothing again.
    let (st, _) = confirm(&app, &c, ck, &ck.to_string()).await;
    assert_eq!(st, StatusCode::CONFLICT);
    assert_eq!(refunds(&pool).await, 1);
}
