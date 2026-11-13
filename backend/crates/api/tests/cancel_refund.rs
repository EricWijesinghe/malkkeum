//! Cancellation refunds against a PortOne mock with DEV_MODE off: concurrent cancels refund once, a
//! cancel that loses to a completion refunds nothing, a retry after a lost commit does not refund twice,
//! staff money actions check the live role, and the saved-card routes (booking, tip, waitlist accept)
//! charge through PortOne in production. Needs DATABASE_URL (sqlx::test).

mod common;

use api::auth::Role;
use axum::{
    Json, Router,
    extract::{Path, State},
    http::{HeaderMap, StatusCode, header::AUTHORIZATION},
    routing::{get, post},
};
use common::{Customer, PORTONE_SECRET, book, call, customer, prod_app, seed_catalog, staff_token, verified_pro};
use serde_json::{Value, json};
use sqlx::PgPool;
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
    time::Duration,
};
use uuid::Uuid;

/// What the mock gateway saw: payment id -> (total, cancelled), and every cancel request in order.
#[derive(Default)]
struct Gateway {
    payments: HashMap<String, (i64, i64)>,
    cancels: Vec<(String, Value)>,
}

type Shared = Arc<Mutex<Gateway>>;
type Reply = (StatusCode, Json<Value>);

fn authorized(h: &HeaderMap) -> bool {
    h.get(AUTHORIZATION).and_then(|v| v.to_str().ok()) == Some(format!("PortOne {PORTONE_SECRET}").as_str())
}

fn refused(status: StatusCode, kind: &str) -> Reply {
    (status, Json(json!({ "type": kind })))
}

/// `POST /payments/{id}/billing-key`, answered like PortOne V2 (`{ payment: { pgTxId, paidAt } }`).
async fn pay(State(g): State<Shared>, Path(id): Path<String>, h: HeaderMap, Json(b): Json<Value>) -> Reply {
    if !authorized(&h) {
        return refused(StatusCode::UNAUTHORIZED, "UnauthorizedError");
    }
    let mut g = g.lock().expect("gateway");
    if g.payments.contains_key(&id) {
        return refused(StatusCode::CONFLICT, "AlreadyPaidError");
    }
    g.payments.insert(id, (b["amount"]["total"].as_i64().unwrap_or(0), 0));
    (
        StatusCode::OK,
        Json(json!({ "payment": { "pgTxId": "pg-tx", "paidAt": "2026-11-13T00:00:00Z" } })),
    )
}

/// `POST /payments/{id}/cancel` with PortOne's `currentCancellableAmount` check.
async fn cancel(State(g): State<Shared>, Path(id): Path<String>, h: HeaderMap, Json(b): Json<Value>) -> Reply {
    if !authorized(&h) {
        return refused(StatusCode::UNAUTHORIZED, "UnauthorizedError");
    }
    let mut g = g.lock().expect("gateway");
    g.cancels.push((id.clone(), b.clone()));
    let Some(entry) = g.payments.get_mut(&id) else {
        return refused(StatusCode::NOT_FOUND, "PaymentNotFoundError");
    };
    let left = entry.0 - entry.1;
    if b["currentCancellableAmount"].as_i64().is_some_and(|c| c != left) {
        return refused(StatusCode::CONFLICT, "CancellableAmountConsistencyBrokenError");
    }
    let amount = b["amount"].as_i64().unwrap_or(left);
    if amount > left {
        return refused(StatusCode::CONFLICT, "CancelAmountExceedsCancellableAmountError");
    }
    entry.1 += amount;
    (
        StatusCode::OK,
        Json(json!({ "cancellation": { "status": "SUCCEEDED", "id": "cancel-1", "totalAmount": amount } })),
    )
}

async fn payment(State(g): State<Shared>, Path(id): Path<String>, h: HeaderMap) -> Reply {
    if !authorized(&h) {
        return refused(StatusCode::UNAUTHORIZED, "UnauthorizedError");
    }
    let g = g.lock().expect("gateway");
    let Some(&(total, cancelled)) = g.payments.get(&id) else {
        return refused(StatusCode::NOT_FOUND, "PaymentNotFoundError");
    };
    let status = match cancelled {
        0 => "PAID",
        c if c == total => "CANCELLED",
        _ => "PARTIAL_CANCELLED",
    };
    let body = json!({ "status": status, "amount": { "total": total, "cancelled": cancelled }, "currency": "KRW", "method": {} });
    (StatusCode::OK, Json(body))
}

async fn start_gateway() -> (String, Shared) {
    let g = Shared::default();
    let app = Router::new()
        .route("/payments/{id}/billing-key", post(pay))
        .route("/payments/{id}/cancel", post(cancel))
        .route("/payments/{id}", get(payment))
        .with_state(g.clone());
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.expect("bind mock");
    let addr = listener.local_addr().expect("mock addr");
    tokio::spawn(async move { axum::serve(listener, app).await.expect("mock serves") });
    (format!("http://{addr}"), g)
}

struct World {
    prod: Router,
    gateway: Shared,
    c: Customer,
}

/// A customer signed in on the dev router (OTP), then everything else on the production router.
async fn world(pool: &PgPool, phone: &str) -> World {
    seed_catalog(pool).await;
    let dev = common::app(pool.clone());
    let c = customer(&dev, pool, phone).await;
    let (base, gateway) = start_gateway().await;
    World {
        prod: prod_app(pool.clone(), &base),
        gateway,
        c,
    }
}

/// Free 3+ days ahead; 50% for anything closer.
async fn fee_inside_three_days(db: &PgPool) {
    let policy = json!({ "tiers": [{ "min_days": 3, "percent": 0 }, { "min_days": -100, "percent": 50 }], "min_fee": 0, "reschedule_min_days": 2 });
    sqlx::query("INSERT INTO settings (key, value) VALUES ('cancel_policy', $1) ON CONFLICT (key) DO UPDATE SET value = $1")
        .bind(sqlx::types::Json(policy))
        .execute(db)
        .await
        .expect("policy");
}

/// (paid, refunded, provider payment id) of the booking's one payment.
async fn payment_row(db: &PgPool, booking: Uuid) -> (i64, i64, String) {
    sqlx::query_as("SELECT amount, refunded_amount, provider_tx_id FROM payments WHERE booking_id = $1 AND provider = 'portone'")
        .bind(booking)
        .fetch_one(db)
        .await
        .expect("payment")
}

async fn status_of(db: &PgPool, booking: Uuid) -> i16 {
    sqlx::query_scalar("SELECT status FROM bookings WHERE id = $1")
        .bind(booking)
        .fetch_one(db)
        .await
        .expect("booking")
}

async fn cancel_audits(db: &PgPool, booking: Uuid) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM audit_log WHERE action = 'booking.cancel' AND target = $1")
        .bind(booking.to_string())
        .fetch_one(db)
        .await
        .expect("audit")
}

fn cancels(g: &Shared) -> Vec<(String, Value)> {
    g.lock().expect("gateway").cancels.clone()
}

fn ok_and_refused(a: StatusCode, b: StatusCode) {
    let oks = [a, b].iter().filter(|s| **s == StatusCode::OK).count();
    assert_eq!(oks, 1, "exactly one cancel wins: {a} / {b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn concurrent_late_cancels_refund_the_capped_amount_once(pool: PgPool) {
    let w = world(&pool, "010-7100-0001").await;
    fee_inside_three_days(&pool).await;
    let (id, _) = book(&w.prod, &w.c, 2, None).await;
    let (paid, _, pid) = payment_row(&pool, id).await;
    let (_, preview) = call(&w.prod, "GET", &format!("/v1/bookings/{id}/cancel-preview"), Some(w.c.token.as_str()), None).await;
    let fee = preview["fee"].as_i64().expect("fee");
    assert!(fee > 0, "late cancel carries a fee: {preview}");

    let uri = format!("/v1/bookings/{id}/cancel");
    let body = json!({ "accepted_fee": fee });
    let tok = Some(w.c.token.as_str());
    let ((a, _), (b, _)) = tokio::join!(
        call(&w.prod, "POST", &uri, tok, Some(body.clone())),
        call(&w.prod, "POST", &uri, tok, Some(body))
    );

    ok_and_refused(a, b);
    let sent = cancels(&w.gateway);
    assert_eq!(sent.len(), 1, "one provider cancel: {sent:?}");
    assert_eq!(sent[0].0, pid);
    assert_eq!(sent[0].1["amount"].as_i64(), Some(paid - fee), "the capped refund");
    assert_eq!(
        sent[0].1["currentCancellableAmount"].as_i64(),
        Some(paid),
        "amount - refunded_amount before this cancel"
    );
    assert_eq!(payment_row(&pool, id).await.1, paid - fee);
    assert_eq!(cancel_audits(&pool, id).await, 1);
    assert_eq!(status_of(&pool, id).await, -1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn customer_and_staff_cancelling_at_once_refund_once(pool: PgPool) {
    let w = world(&pool, "010-7100-0002").await;
    fee_inside_three_days(&pool).await;
    let (id, _) = book(&w.prod, &w.c, 2, None).await;
    let (paid, _, _) = payment_row(&pool, id).await;
    let (_, preview) = call(&w.prod, "GET", &format!("/v1/bookings/{id}/cancel-preview"), Some(w.c.token.as_str()), None).await;
    let fee = preview["fee"].as_i64().expect("fee");
    let (staff, _) = staff_token(&pool, Role::StaffConsultant).await;

    let (customer_uri, staff_uri) = (format!("/v1/bookings/{id}/cancel"), format!("/v1/admin/bookings/{id}/cancel"));
    let customer_cancel = call(&w.prod, "POST", &customer_uri, Some(w.c.token.as_str()), Some(json!({ "accepted_fee": fee })));
    let staff_cancel = call(&w.prod, "POST", &staff_uri, Some(staff.as_str()), Some(json!({})));
    let ((a, _), (b, _)) = tokio::join!(customer_cancel, staff_cancel);

    ok_and_refused(a, b);
    assert_eq!(cancels(&w.gateway).len(), 1, "one provider cancel");
    let refunded = payment_row(&pool, id).await.1;
    assert!(refunded == paid || refunded == paid - fee, "one of the two refunds, never both: {refunded}");
    assert_eq!(cancel_audits(&pool, id).await, 1);
}

/// Waits until some backend of this test database is blocked on a row lock.
async fn until_lock_waiter(db: &PgPool) {
    for _ in 0..200 {
        let waiting: i64 = sqlx::query_scalar("SELECT count(*) FROM pg_stat_activity WHERE datname = current_database() AND wait_event_type = 'Lock'")
            .fetch_one(db)
            .await
            .expect("activity");
        if waiting > 0 {
            return;
        }
        tokio::time::sleep(Duration::from_millis(25)).await;
    }
    panic!("the cancel never reached the booking lock");
}

#[sqlx::test(migrations = "../../migrations")]
async fn cancel_that_loses_to_a_completion_refunds_nothing(pool: PgPool) {
    let w = world(&pool, "010-7100-0003").await;
    let (id, _) = book(&w.prod, &w.c, 10, None).await;
    // The completion holds the booking row; the cancel queues behind it.
    let mut completion = pool.begin().await.expect("tx");
    sqlx::query("SELECT 1 FROM bookings WHERE id = $1 FOR UPDATE")
        .bind(id)
        .execute(&mut *completion)
        .await
        .expect("lock");
    let (app, token) = (w.prod.clone(), w.c.token.clone());
    let pending = tokio::spawn(async move { call(&app, "POST", &format!("/v1/bookings/{id}/cancel"), Some(token.as_str()), Some(json!({}))).await });
    until_lock_waiter(&pool).await;
    sqlx::query("UPDATE bookings SET status = 3, completed_at = now() WHERE id = $1")
        .bind(id)
        .execute(&mut *completion)
        .await
        .expect("complete");
    completion.commit().await.expect("commit");

    let (st, body) = pending.await.expect("cancel task");
    assert_eq!(st, StatusCode::CONFLICT, "{body}");
    assert_eq!(body["error"]["code"], "booking_changed", "{body}");
    assert!(cancels(&w.gateway).is_empty(), "no money moved");
    assert_eq!(payment_row(&pool, id).await.1, 0);
    assert_eq!(status_of(&pool, id).await, 3);
}

#[sqlx::test(migrations = "../../migrations")]
async fn retry_after_a_lost_commit_does_not_refund_twice(pool: PgPool) {
    let w = world(&pool, "010-7100-0004").await;
    let (id, _) = book(&w.prod, &w.c, 10, None).await;
    let (paid, _, pid) = payment_row(&pool, id).await;
    // An earlier cancel landed at PortOne, but its DB commit was lost.
    w.gateway.lock().expect("gateway").payments.get_mut(&pid).expect("charged").1 = paid;

    let (st, body) = call(&w.prod, "POST", &format!("/v1/bookings/{id}/cancel"), Some(w.c.token.as_str()), Some(json!({}))).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    assert_eq!(cancels(&w.gateway).len(), 1, "the stale cancel was refused by the balance check");
    assert_eq!(w.gateway.lock().expect("gateway").payments[&pid].1, paid, "refunded once at the provider");
    assert_eq!(payment_row(&pool, id).await.1, paid, "and recorded once");
    assert_eq!(status_of(&pool, id).await, -1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn deactivated_or_demoted_staff_cannot_move_money(pool: PgPool) {
    let w = world(&pool, "010-7100-0005").await;
    let (id, _) = book(&w.prod, &w.c, 10, None).await;
    let before = status_of(&pool, id).await;
    let (consultant, consultant_id) = staff_token(&pool, Role::StaffConsultant).await;
    sqlx::query("UPDATE staff SET active = false WHERE id = $1")
        .bind(consultant_id)
        .execute(&pool)
        .await
        .expect("deactivate");
    let (st, _) = call(
        &w.prod,
        "POST",
        &format!("/v1/admin/bookings/{id}/cancel"),
        Some(consultant.as_str()),
        Some(json!({})),
    )
    .await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "a deactivated token is refused within its TTL");
    assert!(cancels(&w.gateway).is_empty());
    assert_eq!(status_of(&pool, id).await, before);

    let (admin, admin_id) = staff_token(&pool, Role::StaffAdmin).await;
    sqlx::query("UPDATE staff SET role = 'consultant' WHERE id = $1")
        .bind(admin_id)
        .execute(&pool)
        .await
        .expect("demote");
    let today = api::util::today_kst();
    let (st, _) = call(
        &w.prod,
        "POST",
        "/v1/admin/settlements/run-payouts",
        Some(admin.as_str()),
        Some(json!({ "date": today })),
    )
    .await;
    assert_eq!(st, StatusCode::FORBIDDEN, "a demoted owner's admin token cannot run payouts");
}

#[sqlx::test(migrations = "../../migrations")]
async fn tip_charges_the_saved_card_through_portone(pool: PgPool) {
    let w = world(&pool, "010-7100-0006").await;
    let (id, _) = book(&w.prod, &w.c, 20, None).await;
    let (_, pro) = verified_pro(&common::app(pool.clone()), &pool, "010-7100-0106").await;
    sqlx::query("UPDATE bookings SET status = 3, pro_id = $2, completed_at = now() WHERE id = $1")
        .bind(id)
        .bind(pro)
        .execute(&pool)
        .await
        .expect("complete");
    sqlx::query(
        "INSERT INTO settlements (pro_id, booking_id, gross, fee, net, payout_date, state) VALUES ($1, $2, 100000, 20000, 80000, '2026-03-10', 'pending')",
    )
    .bind(pro)
    .bind(id)
    .execute(&pool)
    .await
    .expect("settlement");

    let (st, body) = call(
        &w.prod,
        "POST",
        &format!("/v1/bookings/{id}/tip"),
        Some(w.c.token.as_str()),
        Some(json!({ "amount": 5000, "payment_method_id": w.c.card })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{body}");
    let tip_pid: String = sqlx::query_scalar("SELECT provider_tx_id FROM payments WHERE booking_id = $1 AND kind = 'tip' AND provider = 'portone'")
        .bind(id)
        .fetch_one(&pool)
        .await
        .expect("tip payment");
    assert_eq!(w.gateway.lock().expect("gateway").payments.get(&tip_pid), Some(&(5000, 0)));
}

#[sqlx::test(migrations = "../../migrations")]
async fn waitlist_accept_charges_the_saved_card_through_portone(pool: PgPool) {
    let w = world(&pool, "010-7100-0007").await;
    sqlx::query("INSERT INTO slot_capacity (start_hour, capacity) VALUES (9, 1) ON CONFLICT (start_hour) DO UPDATE SET capacity = 1")
        .execute(&pool)
        .await
        .expect("capacity");
    let (first, _) = book(&w.prod, &w.c, 20, None).await;
    let second = customer(&common::app(pool.clone()), &pool, "010-7100-0107").await;
    let visit = api::util::today_kst() + chrono::Duration::days(20);
    let join = json!({ "service_code": "studio", "address_id": second.address, "visit_date": visit, "start_hour": 9, "visit_notes": {}, "payment_method_id": second.card });
    let (st, joined) = call(&w.prod, "POST", "/v1/waitlist", Some(second.token.as_str()), Some(join)).await;
    assert_eq!(st, StatusCode::OK, "{joined}");
    let entry = joined["id"].as_str().expect("entry").to_string();
    let (st, body) = call(
        &w.prod,
        "POST",
        &format!("/v1/bookings/{first}/cancel"),
        Some(w.c.token.as_str()),
        Some(json!({})),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{body}");

    let (st, accepted) = call(
        &w.prod,
        "POST",
        &format!("/v1/waitlist/{entry}/accept"),
        Some(second.token.as_str()),
        Some(json!({ "payment_method_id": second.card })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{accepted}");
    let booking: Uuid = accepted["booking_id"].as_str().expect("booking").parse().expect("uuid");
    let (paid, _, pid) = payment_row(&pool, booking).await;
    assert_eq!(w.gateway.lock().expect("gateway").payments.get(&pid), Some(&(paid, 0)));
}
