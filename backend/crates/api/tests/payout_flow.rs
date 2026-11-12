//! Payout reconciliation and money safety over a migrated Postgres: background sync (status only,
//! never a second send), owner alerts, batch amount checks, booking cancel vs batches, future-date
//! refusal, and no-store on account reveal. Needs DATABASE_URL (sqlx::test).

mod common;

use api::{
    auth::{self, Role},
    crypto,
};
use axum::{
    body::Body,
    http::{Request, StatusCode, header},
};
use chrono::{Duration, Utc};
use common::{SECRET, app, call, seed_catalog, test_config};
use serde_json::json;
use sqlx::PgPool;
use tower::ServiceExt;
use uuid::Uuid;

const DATE: &str = "2026-03-12";
const KEY: [u8; 32] = [7u8; 32];

fn admin_token() -> String {
    auth::issue_access(SECRET, Uuid::now_v7(), Role::StaffAdmin).expect("token")
}

/// Verified pro with a bank account and one pending settlement due by `DATE`. Returns (settlement, pro).
async fn seed(db: &PgPool) -> (Uuid, Uuid) {
    seed_catalog(db).await;
    let user: Uuid = sqlx::query_scalar("INSERT INTO users (phone, name) VALUES ('01072000001', 'pay') RETURNING id").fetch_one(db).await.expect("user");
    let pro: Uuid = sqlx::query_scalar(
        "INSERT INTO pros (phone, name, team_name, status) VALUES ('01072000101', 'pro', 'team', 'verified') RETURNING id",
    )
    .fetch_one(db)
    .await
    .expect("pro");
    let enc = crypto::encrypt(&KEY, "110-123-456789");
    sqlx::query("INSERT INTO payout_accounts (pro_id, bank, account_enc, account_last4, holder, verified_at) VALUES ($1, '국민은행', $2, '6789', '홍길동', now())")
        .bind(pro)
        .bind(enc)
        .execute(db)
        .await
        .expect("account");
    let booking = insert_booking(db, user, "BKP-1", "2026-03-05").await;
    let settlement: Uuid = sqlx::query_scalar(
        "INSERT INTO settlements (pro_id, booking_id, gross, fee, net, payout_date, state)
         VALUES ($1, $2, 100000, 20000, 80000, '2026-03-10', 'pending') RETURNING id",
    )
    .bind(pro)
    .bind(booking)
    .fetch_one(db)
    .await
    .expect("settlement");
    (settlement, pro)
}

async fn insert_booking(db: &PgPool, user: Uuid, number: &str, visit: &str) -> Uuid {
    sqlx::query_scalar(
        "INSERT INTO bookings (number, user_id, service_code, address, district_code, visit_date, start_hour, status, final_price, list_price, discount)
         VALUES ($1, $2, 'studio', '{}'::jsonb, '11680', $3::date, 10, 3, 100000, 100000, 0) RETURNING id",
    )
    .bind(number)
    .bind(user)
    .bind(visit)
    .fetch_one(db)
    .await
    .expect("booking")
}

/// A second pending settlement for the same pro and payout date, on its own booking.
async fn second_settlement(db: &PgPool, pro: Uuid) -> Uuid {
    let user: Uuid = sqlx::query_scalar("SELECT id FROM users WHERE phone = '01072000001'").fetch_one(db).await.expect("user");
    let booking = insert_booking(db, user, "BKP-2", "2026-03-06").await;
    sqlx::query_scalar(
        "INSERT INTO settlements (pro_id, booking_id, gross, fee, net, payout_date, state)
         VALUES ($1, $2, 100000, 20000, 80000, '2026-03-10', 'pending') RETURNING id",
    )
    .bind(pro)
    .bind(booking)
    .fetch_one(db)
    .await
    .expect("settlement")
}

async fn settlement_state(db: &PgPool, id: Uuid) -> String {
    sqlx::query_scalar("SELECT state FROM settlements WHERE id = $1").bind(id).fetch_one(db).await.expect("state")
}

async fn request_payouts(app: &axum::Router, token: &str) -> (StatusCode, serde_json::Value) {
    call(app, "POST", "/v1/admin/settlements/run-payouts", Some(token), Some(json!({ "date": DATE }))).await
}

/// Turns a requested payout into a Toss transfer in the given state, `days` old.
async fn make_toss(db: &PgPool, id: &str, state: &str, transfer: Option<&str>, failure: Option<&str>, days: i32) {
    sqlx::query(
        "UPDATE payouts SET provider = 'toss', state = $2, provider_transfer_id = $3, failure_reason = $4, attempts = 1,
           updated_at = now() - make_interval(days => $5) WHERE id = $1::uuid",
    )
    .bind(id)
    .bind(state)
    .bind(transfer)
    .bind(failure)
    .bind(days)
    .execute(db)
    .await
    .expect("toss row");
}

async fn first_payout_id(app: &axum::Router, token: &str) -> String {
    let (_, rows) = request_payouts(app, token).await;
    rows[0]["id"].as_str().expect("id").to_string()
}

#[sqlx::test(migrations = "../../migrations")]
async fn background_sync_settles_open_transfers_and_never_resends(pool: PgPool) {
    let (settlement, _pro) = seed(&pool).await;
    let app = app(pool.clone());
    let id = first_payout_id(&app, &admin_token()).await;
    make_toss(&pool, &id, "sent", Some("tp_1"), None, 2).await;

    let state = api::build_state(pool.clone(), test_config()).expect("state");
    assert_eq!(api::payout_sync::sync_pass(&state).await.expect("pass"), 1);

    let (st, attempts, transfer): (String, i32, Option<String>) =
        sqlx::query_as("SELECT state, attempts, provider_transfer_id FROM payouts WHERE id = $1::uuid").bind(&id).fetch_one(&pool).await.expect("row");
    assert_eq!((st.as_str(), attempts, transfer.as_deref()), ("paid", 1, Some("tp_1")), "paid by status only, no second send");
    assert_eq!(settlement_state(&pool, settlement).await, "paid");
    let audited: i64 = sqlx::query_scalar("SELECT count(*) FROM audit_log WHERE action = 'payout.sync' AND actor_role = 'system'").fetch_one(&pool).await.expect("audit");
    assert_eq!(audited, 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn background_sync_leaves_an_ambiguous_send_for_a_same_key_resend(pool: PgPool) {
    seed(&pool).await;
    let app = app(pool.clone());
    let id = first_payout_id(&app, &admin_token()).await;
    make_toss(&pool, &id, "requested", None, Some("timeout"), 0).await;
    let key_before: String = sqlx::query_scalar("SELECT idempotency_key FROM payouts WHERE id = $1::uuid").bind(&id).fetch_one(&pool).await.expect("key");

    // Toss looks transfers up by its own id; a send that never returned one cannot be asked about.
    let state = api::build_state(pool.clone(), test_config()).expect("state");
    api::payout_sync::sync_pass(&state).await.expect("pass");
    let (st, key): (String, String) =
        sqlx::query_as("SELECT state, idempotency_key FROM payouts WHERE id = $1::uuid").bind(&id).fetch_one(&pool).await.expect("row");
    assert_eq!(st, "requested", "never marked paid without the provider confirming");
    assert_eq!(key, key_before, "the resend reuses the key, so it cannot pay twice");
}

#[sqlx::test(migrations = "../../migrations")]
async fn background_sync_ignores_manual_requested_payouts(pool: PgPool) {
    seed(&pool).await;
    let app = app(pool.clone());
    request_payouts(&app, &admin_token()).await;
    let state = api::build_state(pool.clone(), test_config()).expect("state");
    assert_eq!(api::payout_sync::sync_pass(&state).await.expect("pass"), 0);
}

#[sqlx::test(migrations = "../../migrations")]
async fn owner_alerts_count_stuck_and_failed_transfers(pool: PgPool) {
    seed(&pool).await;
    let app = app(pool.clone());
    let id = first_payout_id(&app, &admin_token()).await;
    assert_eq!(api::payout_sync::alert_counts(&pool).await.expect("counts"), (0, 0));

    make_toss(&pool, &id, "sent", Some("tp_2"), None, 1).await;
    assert_eq!(api::payout_sync::alert_counts(&pool).await.expect("counts"), (1, 0), "open for over 24 h");

    make_toss(&pool, &id, "failed", None, Some("잔액 부족"), 0).await;
    assert_eq!(api::payout_sync::alert_counts(&pool).await.expect("counts"), (0, 1), "failed today");
}

#[sqlx::test(migrations = "../../migrations")]
async fn amount_that_no_longer_matches_its_settlements_is_not_paid(pool: PgPool) {
    let (settlement, _pro) = seed(&pool).await;
    let app = app(pool.clone());
    let token = admin_token();
    let id = first_payout_id(&app, &token).await;
    sqlx::query("UPDATE settlements SET fee = fee + 1000, net = net - 1000 WHERE id = $1").bind(settlement).execute(&pool).await.expect("change");

    let (code, body) = call(&app, "POST", &format!("/v1/admin/settlements/payouts/{id}/confirm"), Some(&token), Some(json!({}))).await;
    assert_eq!((code, body["error"]["code"].as_str()), (StatusCode::CONFLICT, Some("payout_amount_changed")), "{body}");
    assert_eq!(settlement_state(&pool, settlement).await, "pending");
}

#[sqlx::test(migrations = "../../migrations")]
async fn cancelling_a_booking_takes_it_out_of_an_unsent_batch(pool: PgPool) {
    let (settlement, pro) = seed(&pool).await;
    let app = app(pool.clone());
    let token = admin_token();
    let id = first_payout_id(&app, &token).await;
    let other = second_settlement(&pool, pro).await;
    let batch = Uuid::parse_str(&id).expect("uuid");
    sqlx::query("UPDATE settlements SET payout_id = $2 WHERE id = $1").bind(other).bind(batch).execute(&pool).await.expect("join batch");
    sqlx::query("UPDATE payouts SET amount = 160000, items = 2 WHERE id = $1").bind(batch).execute(&pool).await.expect("batch total");

    let booking: Uuid = sqlx::query_scalar("SELECT booking_id FROM settlements WHERE id = $1").bind(settlement).fetch_one(&pool).await.expect("booking");
    sqlx::query("UPDATE bookings SET status = 1 WHERE id = $1").bind(booking).execute(&pool).await.expect("status");
    let (code, body) = call(&app, "POST", &format!("/v1/admin/bookings/{booking}/cancel"), Some(&token), Some(json!({}))).await;
    assert_eq!(code, StatusCode::OK, "{body}");

    assert_eq!(settlement_state(&pool, settlement).await, "held");
    let (amount, items): (i64, i32) = sqlx::query_as("SELECT amount, items FROM payouts WHERE id = $1").bind(batch).fetch_one(&pool).await.expect("batch");
    assert_eq!((amount, items), (80_000, 1), "batch shrinks to the remaining job");
    let linked: Option<Uuid> = sqlx::query_scalar("SELECT payout_id FROM settlements WHERE id = $1").bind(settlement).fetch_one(&pool).await.expect("link");
    assert_eq!(linked, None, "cancelled job is detached");
}

#[sqlx::test(migrations = "../../migrations")]
async fn cancel_is_refused_while_the_transfer_is_at_the_provider(pool: PgPool) {
    let (settlement, _pro) = seed(&pool).await;
    let app = app(pool.clone());
    let token = admin_token();
    let id = first_payout_id(&app, &token).await;
    make_toss(&pool, &id, "sent", Some("tp_3"), None, 0).await;
    let booking: Uuid = sqlx::query_scalar("SELECT booking_id FROM settlements WHERE id = $1").bind(settlement).fetch_one(&pool).await.expect("booking");
    sqlx::query("UPDATE bookings SET status = 1 WHERE id = $1").bind(booking).execute(&pool).await.expect("status");

    let (code, body) = call(&app, "POST", &format!("/v1/admin/bookings/{booking}/cancel"), Some(&token), Some(json!({}))).await;
    assert_eq!((code, body["error"]["code"].as_str()), (StatusCode::CONFLICT, Some("settlement_in_transfer")), "{body}");
    assert_eq!(settlement_state(&pool, settlement).await, "pending", "nothing changed");
}

#[sqlx::test(migrations = "../../migrations")]
async fn run_refuses_future_dates_and_skips_pros_already_in_a_batch(pool: PgPool) {
    let (_settlement, pro) = seed(&pool).await;
    let app = app(pool.clone());
    let token = admin_token();
    let future = (Utc::now() + Duration::days(2)).date_naive().to_string();
    let (code, _) = call(&app, "POST", "/v1/admin/settlements/run-payouts", Some(&token), Some(json!({ "date": future }))).await;
    assert_eq!(code, StatusCode::BAD_REQUEST, "future payout dates are refused");

    request_payouts(&app, &token).await;
    second_settlement(&pool, pro).await;
    let (code, rows) = request_payouts(&app, &token).await;
    assert_eq!(code, StatusCode::OK, "{rows}");
    assert_eq!(rows.as_array().map(Vec::len), Some(0), "the pro already has a batch for that date");
    let batches: i64 = sqlx::query_scalar("SELECT count(*) FROM payouts WHERE pro_id = $1").bind(pro).fetch_one(&pool).await.expect("count");
    assert_eq!(batches, 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn revealed_account_is_never_cached(pool: PgPool) {
    seed(&pool).await;
    let app = app(pool.clone());
    let token = admin_token();
    let id = first_payout_id(&app, &token).await;
    let req = Request::builder()
        .method("GET")
        .uri(format!("/v1/admin/settlements/payouts/{id}/account"))
        .header(header::AUTHORIZATION, format!("Bearer {token}"))
        .body(Body::empty())
        .expect("request");
    let res = app.clone().oneshot(req).await.expect("router is infallible");
    assert_eq!(res.status(), StatusCode::OK);
    assert_eq!(res.headers().get(header::CACHE_CONTROL).and_then(|v| v.to_str().ok()), Some("no-store"));
}
