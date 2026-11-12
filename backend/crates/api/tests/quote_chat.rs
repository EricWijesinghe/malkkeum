//! Quote card in chat: staff send-quote posts a structured card copied from the booking row, the
//! customer pays the server-computed 10% deposit once, and a free-window cancel refunds it.

mod common;

use api::auth::{self, Role};
use axum::http::StatusCode;
use chrono::{Duration, Utc};
use common::{SECRET, call, call_keyed, customer, seed_catalog};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

async fn consultant(pool: &PgPool) -> String {
    let hash = auth::hash_password("consultant-pass-123").expect("hash");
    let id: Uuid = sqlx::query_scalar(
        "INSERT INTO staff (email, name, password_hash, role) VALUES ('desk@test.local', 'Desk', $1, 'consultant') RETURNING id",
    )
    .bind(hash)
    .fetch_one(pool)
    .await
    .expect("staff row");
    auth::issue_access(SECRET, id, Role::StaffConsultant).expect("token")
}

#[sqlx::test(migrations = "../../migrations")]
async fn quote_card_carries_the_booking_and_the_deposit_is_paid_once_then_refunded(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0001").await;
    let visit = (Utc::now() + Duration::days(10)).date_naive();
    let answers = json!({
        "cleaning_type": "standard", "luggage": "empty", "building": "apartment", "layout": "two_rooms",
        "duplex": false, "bathrooms": 1, "balconies": 1, "elevator": true, "floor_3_or_higher": true
    });
    let (st, b) = call(
        &app,
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
    let id = b["id"].as_str().expect("booking id").to_string();
    let estimate = b["estimate"].as_i64().expect("estimate");

    let staff = consultant(&pool).await;
    let (st, msg) = call(
        &app,
        "POST",
        &format!("/v1/admin/bookings/{id}/send-quote"),
        Some(staff.as_str()),
        Some(json!({ "final_price": 350_000 })),
    )
    .await;
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

    let pay = json!({ "payment_method_id": c.card });
    let uri = format!("/v1/bookings/{id}/deposit");
    let (st, paid) = call_keyed(&app, "POST", &uri, Some(c.token.as_str()), Some(pay.clone()), Some("u4-deposit-1")).await;
    assert_eq!(st, StatusCode::OK, "deposit: {paid}");
    assert_eq!(paid["status"], 1, "confirmed after the deposit: {paid}");
    assert_eq!(paid["paid_amount"], 35_000);
    // Same key: the stored response is replayed, nothing is charged twice.
    let (st, again) = call_keyed(&app, "POST", &uri, Some(c.token.as_str()), Some(pay.clone()), Some("u4-deposit-1")).await;
    assert_eq!(st, StatusCode::OK, "replay: {again}");
    // A new key is a second attempt: refused.
    let (st, second) = call_keyed(&app, "POST", &uri, Some(c.token.as_str()), Some(pay), Some("u4-deposit-2")).await;
    assert_eq!(st, StatusCode::CONFLICT, "second deposit: {second}");
    let charged: i64 = sqlx::query_scalar("SELECT COALESCE(SUM(amount), 0)::bigint FROM payments WHERE booking_id = $1::uuid")
        .bind(&id)
        .fetch_one(&pool)
        .await
        .expect("payments");
    assert_eq!(charged, 35_000, "one deposit charge");

    // 10 days out is inside the free-cancel window: the whole deposit comes back.
    let (st, cancelled) = call(&app, "POST", &format!("/v1/bookings/{id}/cancel"), Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{cancelled}");
    assert_eq!(cancelled["status"], -1);
    let refunded: i64 = sqlx::query_scalar("SELECT COALESCE(SUM(refunded_amount), 0)::bigint FROM payments WHERE booking_id = $1::uuid")
        .bind(&id)
        .fetch_one(&pool)
        .await
        .expect("refunds");
    assert_eq!(refunded, 35_000);
}

#[sqlx::test(migrations = "../../migrations")]
async fn send_quote_ignores_card_fields_in_the_request(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0002").await;
    let visit = (Utc::now() + Duration::days(12)).date_naive();
    let (st, b) = call(
        &app,
        "POST",
        "/v1/bookings",
        Some(c.token.as_str()),
        Some(json!({
            "service_code": "move_in", "address_id": c.address, "visit_date": visit, "start_hour": 13,
            "answers": {
                "cleaning_type": "normal_move_in", "luggage": "empty", "building": "villa", "layout": "studio",
                "duplex": false, "bathrooms": 1, "balconies": 0, "elevator": false, "floor_3_or_higher": false
            },
            "visit_notes": {}
        })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "quote request: {b}");
    let id = b["id"].as_str().expect("booking id");
    let staff = consultant(&pool).await;
    let (st, msg) = call(
        &app,
        "POST",
        &format!("/v1/admin/bookings/{id}/send-quote"),
        Some(staff.as_str()),
        Some(json!({ "final_price": 120_049, "deposit": 1, "visit_date": "2000-01-01", "start_hour": 3, "estimate": 1 })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "send-quote: {msg}");
    let body = &msg["body"];
    assert_eq!(body["final_price"], 120_000, "rounded to 100 won");
    assert_eq!(body["deposit"], 12_000);
    assert_eq!(body["visit_date"], visit.to_string(), "from the booking, not the request");
    assert_eq!(body["start_hour"], 13);
    assert_eq!(body["estimate"], b["estimate"]);
}
