//! Payout flow over a migrated Postgres: request -> reveal -> confirm, with the double-pay guard,
//! failure and retry. Needs DATABASE_URL (sqlx::test).

mod common;

use api::{
    auth::{self, Role},
    crypto,
};
use axum::http::StatusCode;
use common::{SECRET, app, call, seed_catalog};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

const DATE: &str = "2026-03-12";
const KEY: [u8; 32] = [7u8; 32];

fn admin_token() -> String {
    auth::issue_access(SECRET, Uuid::now_v7(), Role::StaffAdmin).expect("token")
}

/// One verified pro with a verified bank account and one pending settlement due by `DATE`.
/// Returns (settlement id, pro id).
async fn seed(db: &PgPool) -> (Uuid, Uuid) {
    seed_catalog(db).await;
    let user: Uuid = sqlx::query_scalar("INSERT INTO users (phone, name) VALUES ('01071000001', 'pay') RETURNING id").fetch_one(db).await.expect("user");
    let pro: Uuid = sqlx::query_scalar(
        "INSERT INTO pros (phone, name, team_name, status) VALUES ('01071000101', 'pro', 'team', 'verified') RETURNING id",
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
    let booking: Uuid = sqlx::query_scalar(
        "INSERT INTO bookings (number, user_id, service_code, address, district_code, visit_date, start_hour, status, final_price, list_price, discount)
         VALUES ('BKP-1', $1, 'studio', '{}'::jsonb, '11680', '2026-03-05', 10, 3, 100000, 100000, 0) RETURNING id",
    )
    .bind(user)
    .fetch_one(db)
    .await
    .expect("booking");
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

async fn settlement_state(db: &PgPool, id: Uuid) -> String {
    sqlx::query_scalar("SELECT state FROM settlements WHERE id = $1").bind(id).fetch_one(db).await.expect("state")
}

async fn request_payouts(app: &axum::Router, token: &str) -> (StatusCode, serde_json::Value) {
    call(app, "POST", "/v1/admin/settlements/run-payouts", Some(token), Some(json!({ "date": DATE }))).await
}

#[sqlx::test(migrations = "../../migrations")]
async fn manual_payout_is_requested_then_confirmed_exactly_once(pool: PgPool) {
    let (settlement, _pro) = seed(&pool).await;
    let app = app(pool.clone());
    let token = admin_token();

    let (code, rows) = request_payouts(&app, &token).await;
    assert_eq!(code, StatusCode::OK);
    let p = &rows[0];
    assert_eq!((p["state"].as_str(), p["provider"].as_str(), p["amount"].as_i64()), (Some("requested"), Some("manual"), Some(80_000)));
    let id = p["id"].as_str().expect("id").to_string();
    assert_eq!(settlement_state(&pool, settlement).await, "pending", "money has not moved yet");

    // Asking again must not create a second payout for the same settlement.
    let (_, again) = request_payouts(&app, &token).await;
    assert_eq!(again.as_array().map(Vec::len), Some(0));

    // Manual payouts never go to the provider.
    let (code, _) = call(&app, "POST", &format!("/v1/admin/settlements/payouts/{id}/send"), Some(&token), Some(json!({}))).await;
    assert_eq!(code, StatusCode::CONFLICT);

    let (code, revealed) = call(&app, "GET", &format!("/v1/admin/settlements/payouts/{id}/account"), Some(&token), None).await;
    assert_eq!(code, StatusCode::OK);
    assert_eq!(revealed["account"], "110-123-456789");
    let audited: i64 = sqlx::query_scalar("SELECT count(*) FROM audit_log WHERE action = 'payout.reveal' AND target = $1").bind(&id).fetch_one(&pool).await.expect("audit");
    assert_eq!(audited, 1, "every reveal is audit-logged");

    let (code, done) = call(&app, "POST", &format!("/v1/admin/settlements/payouts/{id}/confirm"), Some(&token), Some(json!({}))).await;
    assert_eq!((code, done["state"].as_str()), (StatusCode::OK, Some("paid")));
    assert_eq!(settlement_state(&pool, settlement).await, "paid");

    // Second confirm, or any other action on a paid payout, is refused and changes nothing.
    let (code, _) = call(&app, "POST", &format!("/v1/admin/settlements/payouts/{id}/confirm"), Some(&token), Some(json!({}))).await;
    assert_eq!(code, StatusCode::CONFLICT);
    let (code, _) = call(&app, "POST", &format!("/v1/admin/settlements/payouts/{id}/fail"), Some(&token), Some(json!({ "reason": "late" }))).await;
    assert_eq!(code, StatusCode::CONFLICT);
    let (code, _) = call(&app, "POST", &format!("/v1/admin/settlements/{settlement}/hold"), Some(&token), Some(json!({ "hold": true }))).await;
    assert_eq!(code, StatusCode::CONFLICT, "a settlement inside a payout cannot be held");
}

#[sqlx::test(migrations = "../../migrations")]
async fn failed_payout_needs_a_reason_and_retries_without_a_second_row(pool: PgPool) {
    let (settlement, _pro) = seed(&pool).await;
    let app = app(pool.clone());
    let token = admin_token();
    let (_, rows) = request_payouts(&app, &token).await;
    let id = rows[0]["id"].as_str().expect("id").to_string();

    let (code, _) = call(&app, "POST", &format!("/v1/admin/settlements/payouts/{id}/fail"), Some(&token), Some(json!({ "reason": "  " }))).await;
    assert_eq!(code, StatusCode::BAD_REQUEST);

    let (code, failed) = call(&app, "POST", &format!("/v1/admin/settlements/payouts/{id}/fail"), Some(&token), Some(json!({ "reason": "계좌 오류" }))).await;
    assert_eq!((code, failed["state"].as_str()), (StatusCode::OK, Some("failed")));
    assert_eq!(settlement_state(&pool, settlement).await, "pending", "a failed payout leaves the settlement unpaid");

    let (code, _) = call(&app, "POST", &format!("/v1/admin/settlements/payouts/{id}/confirm"), Some(&token), Some(json!({}))).await;
    assert_eq!(code, StatusCode::CONFLICT, "failed cannot be confirmed without a retry");

    let (code, _) = call(&app, "POST", &format!("/v1/admin/settlements/payouts/{id}/retry"), Some(&token), Some(json!({}))).await;
    assert_eq!(code, StatusCode::OK);
    let (code, done) = call(&app, "POST", &format!("/v1/admin/settlements/payouts/{id}/confirm"), Some(&token), Some(json!({}))).await;
    assert_eq!((code, done["state"].as_str()), (StatusCode::OK, Some("paid")));

    let rows_for_settlement: i64 = sqlx::query_scalar("SELECT count(*) FROM payouts WHERE id IN (SELECT payout_id FROM settlements WHERE id = $1)")
        .bind(settlement)
        .fetch_one(&pool)
        .await
        .expect("count");
    assert_eq!(rows_for_settlement, 1);
}
