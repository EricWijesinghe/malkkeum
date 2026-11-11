//! Cancellation fee preview, fee acceptance, refunds and household copy over the real router.
//! Visit dates are counted in KST days, the same unit the policy uses.

mod common;

use axum::http::StatusCode;
use chrono::{Duration, FixedOffset, Utc};
use common::{Customer, call, customer, seed_catalog};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

/// Books a studio clean exactly `days` KST calendar days ahead (the policy's unit).
async fn book_kst_days(app: &axum::Router, c: &Customer, days: i64) -> (Uuid, Value) {
    let kst = FixedOffset::east_opt(9 * 3600).expect("kst");
    let visit = (Utc::now().with_timezone(&kst) + Duration::days(days)).date_naive();
    let (st, b) = call(
        app,
        "POST",
        "/v1/bookings",
        Some(c.token.as_str()),
        Some(json!({
            "service_code": "studio",
            "address_id": c.address,
            "visit_date": visit,
            "start_hour": 9,
            "visit_notes": {},
            "payment_method_id": c.card
        })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "booking: {b}");
    (b["id"].as_str().expect("id").parse().expect("uuid"), b)
}

async fn set_policy(db: &PgPool, policy: Value) {
    sqlx::query("INSERT INTO settings (key, value) VALUES ('cancel_policy', $1) ON CONFLICT (key) DO UPDATE SET value = $1")
        .bind(sqlx::types::Json(policy))
        .execute(db)
        .await
        .expect("policy");
}

async fn refunded_total(db: &PgPool, booking: Uuid) -> (i64, i64) {
    sqlx::query_as("SELECT COALESCE(SUM(amount), 0)::bigint, COALESCE(SUM(refunded_amount), 0)::bigint FROM payments WHERE booking_id = $1")
        .bind(booking)
        .fetch_one(db)
        .await
        .expect("payments")
}

/// Free 3+ days ahead; 50% for anything closer (tier with no lower bound).
fn fee_after_two_days() -> Value {
    json!({ "tiers": [{ "min_days": 3, "percent": 0 }, { "min_days": -100, "percent": 50 }], "min_fee": 0, "reschedule_min_days": 2 })
}

#[sqlx::test(migrations = "../../migrations")]
async fn default_policy_closes_self_serve_cancel_inside_two_days(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6000-0001").await;
    let (id, _) = book_kst_days(&app, &c, 1).await;

    let (st, preview) = call(&app, "GET", &format!("/v1/bookings/{id}/cancel-preview"), Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{preview}");
    assert_eq!(preview["can_cancel"], false);
    assert_eq!(preview["reschedule_allowed"], false);

    let (st, body) = call(&app, "POST", &format!("/v1/bookings/{id}/cancel"), Some(c.token.as_str()), Some(json!({}))).await;
    assert_eq!(st, StatusCode::CONFLICT, "{body}");
    assert_eq!(body["error"]["code"], "cancellation_window_closed", "{body}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn far_booking_cancels_free_with_full_refund_and_no_fee_ack(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6000-0002").await;
    set_policy(&pool, fee_after_two_days()).await;
    let (id, b) = book_kst_days(&app, &c, 10).await;

    let (_, preview) = call(&app, "GET", &format!("/v1/bookings/{id}/cancel-preview"), Some(c.token.as_str()), None).await;
    assert_eq!((preview["fee"].as_i64(), preview["refund"].as_i64()), (Some(0), Some(b["paid_amount"].as_i64().unwrap_or(0))), "{preview}");

    let (st, body) = call(&app, "POST", &format!("/v1/bookings/{id}/cancel"), Some(c.token.as_str()), Some(json!({}))).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    let (paid, refunded) = refunded_total(&pool, id).await;
    assert!(paid > 0 && refunded == paid, "full refund: paid={paid} refunded={refunded}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn fee_must_be_accepted_and_refund_is_paid_minus_fee(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6000-0003").await;
    set_policy(&pool, fee_after_two_days()).await;
    let (id, _) = book_kst_days(&app, &c, 1).await;
    let (paid, _) = refunded_total(&pool, id).await;
    let fee = paid / 2;

    let (_, preview) = call(&app, "GET", &format!("/v1/bookings/{id}/cancel-preview"), Some(c.token.as_str()), None).await;
    assert_eq!(preview["fee"].as_i64(), Some(fee), "{preview}");
    assert_eq!(preview["percent"].as_u64(), Some(50), "{preview}");

    // Cancelling without the fee the customer saw is refused and nothing is refunded.
    let (st, body) = call(&app, "POST", &format!("/v1/bookings/{id}/cancel"), Some(c.token.as_str()), Some(json!({}))).await;
    assert_eq!(st, StatusCode::CONFLICT, "{body}");
    assert_eq!(body["error"]["code"], "fee_changed", "{body}");
    assert_eq!(refunded_total(&pool, id).await.1, 0);

    let (st, body) = call(&app, "POST", &format!("/v1/bookings/{id}/cancel"), Some(c.token.as_str()), Some(json!({ "accepted_fee": fee }))).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    let (paid, refunded) = refunded_total(&pool, id).await;
    assert_eq!(refunded, paid - fee, "refund is what remains after the fee");
}

#[sqlx::test(migrations = "../../migrations")]
async fn household_is_copied_from_address_and_editable_per_booking(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6000-0004").await;
    let address = json!({
        "kind": "home", "label": "집", "road_address": "서울특별시 강남구 테헤란로 1", "detail": "", "district_code": "11680", "size_pyeong": 8,
        "household": { "pets": [{ "kind": "cat", "count": 2 }], "allergies": "향수", "floor": 12, "elevator": true }
    });
    let (st, saved) = call(&app, "PUT", &format!("/v1/me/addresses/{}", c.address), Some(c.token.as_str()), Some(address)).await;
    assert_eq!(st, StatusCode::OK, "{saved}");
    assert_eq!(saved["household"]["pets"][0]["count"], 2);

    let (id, b) = book_kst_days(&app, &c, 10).await;
    assert_eq!(b["household"]["allergies"], "향수", "{b}");

    let (st, bad) = call(&app, "PUT", &format!("/v1/bookings/{id}/household"), Some(c.token.as_str()), Some(json!({ "pets": [{ "kind": "lizard", "count": 1 }] }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{bad}");

    let (st, edited) = call(&app, "PUT", &format!("/v1/bookings/{id}/household"), Some(c.token.as_str()), Some(json!({ "parking": "지하 주차장", "pets": [] }))).await;
    assert_eq!(st, StatusCode::OK, "{edited}");
    assert_eq!(edited["household"]["parking"], "지하 주차장");
    assert_eq!(edited["household"]["pets"], json!([]));
}

#[sqlx::test(migrations = "../../migrations")]
async fn public_policy_reports_default_until_owner_saves(pool: PgPool) {
    let app = common::app(pool.clone());
    let (st, p) = call(&app, "GET", "/v1/policy/cancellation", None, None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(p["is_default"], true);
    assert_eq!(p["policy"]["tiers"][0]["min_days"], 2);
    set_policy(&pool, fee_after_two_days()).await;
    let (_, p) = call(&app, "GET", "/v1/policy/cancellation", None, None).await;
    assert_eq!(p["is_default"], false);
}
