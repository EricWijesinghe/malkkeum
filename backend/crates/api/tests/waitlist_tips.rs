//! Waitlist offer flow and customer tips. Needs DATABASE_URL (sqlx::test).

mod common;

use axum::http::StatusCode;
use chrono::{Duration, Utc};
use common::{app, book, call, customer, seed_catalog, verified_pro};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

/// One seat at 09:00, so the first booking fills the slot.
async fn one_seat_at_nine(db: &PgPool) {
    sqlx::query("INSERT INTO slot_capacity (start_hour, capacity) VALUES (9, 1) ON CONFLICT (start_hour) DO UPDATE SET capacity = 1")
        .execute(db)
        .await
        .expect("capacity");
}

#[sqlx::test(migrations = "../../migrations")]
async fn join_is_refused_while_the_slot_has_room(pool: PgPool) {
    seed_catalog(&pool).await;
    one_seat_at_nine(&pool).await;
    let app = app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0001").await;
    let visit = (Utc::now() + Duration::days(20)).date_naive();
    let body = json!({ "service_code": "studio", "address_id": c.address, "visit_date": visit, "start_hour": 9, "visit_notes": {} });
    let (st, _) = call(&app, "POST", "/v1/waitlist", Some(c.token.as_str()), Some(body)).await;
    assert_eq!(st, StatusCode::CONFLICT, "an open seat is booked directly, not queued");
}

#[sqlx::test(migrations = "../../migrations")]
async fn cancelled_seat_is_offered_then_accepted_into_a_booking(pool: PgPool) {
    seed_catalog(&pool).await;
    one_seat_at_nine(&pool).await;
    let app = app(pool.clone());
    let first = customer(&app, &pool, "010-5400-0002").await;
    let (first_booking, _) = book(&app, &first, 20, None).await;

    let second = customer(&app, &pool, "010-5400-0003").await;
    let visit = (Utc::now() + Duration::days(20)).date_naive();
    let body = json!({ "service_code": "studio", "address_id": second.address, "visit_date": visit, "start_hour": 9, "visit_notes": {}, "payment_method_id": second.card });
    let (st, joined) = call(&app, "POST", "/v1/waitlist", Some(second.token.as_str()), Some(body)).await;
    assert_eq!(st, StatusCode::OK, "full slot takes a waitlist entry: {joined}");
    let entry = joined["id"].as_str().expect("entry id").to_string();

    let (st, _) = call(&app, "POST", &format!("/v1/bookings/{first_booking}/cancel"), Some(first.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "cancel frees the seat");

    let (st, mine) = call(&app, "GET", "/v1/waitlist", Some(second.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(mine[0]["status"], "offered", "next waiter gets the freed seat: {mine}");

    let (st, accepted) = call(&app, "POST", &format!("/v1/waitlist/{entry}/accept"), Some(second.token.as_str()), Some(json!({ "payment_method_id": second.card }))).await;
    assert_eq!(st, StatusCode::OK, "accept creates the booking: {accepted}");
    assert!(accepted["booking_id"].is_string());
}

#[sqlx::test(migrations = "../../migrations")]
async fn tip_is_refused_before_the_job_is_completed(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0004").await;
    let (booking, _) = book(&app, &c, 20, None).await;
    let (st, _) = call(&app, "POST", &format!("/v1/bookings/{booking}/tip"), Some(c.token.as_str()), Some(json!({ "amount": 5000, "payment_method_id": c.card }))).await;
    assert_ne!(st, StatusCode::OK, "tips need a completed job");
    let tips: i64 = sqlx::query_scalar("SELECT count(*) FROM booking_tips").fetch_one(&pool).await.expect("count");
    assert_eq!(tips, 0, "nothing charged or recorded");
}

#[sqlx::test(migrations = "../../migrations")]
async fn tip_is_refused_once_the_settlement_is_in_a_payout_batch(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0009").await;
    let (booking, _) = book(&app, &c, 20, None).await;
    let (_, pro) = verified_pro(&app, &pool, "010-5400-0109").await;
    // A completed job whose settlement already sits in a payout batch that may be at the provider.
    sqlx::query("UPDATE bookings SET status = 3, pro_id = $2, completed_at = now() WHERE id = $1")
        .bind(booking)
        .bind(pro)
        .execute(&pool)
        .await
        .expect("complete");
    let payout: Uuid = sqlx::query_scalar(
        "INSERT INTO payouts (pro_id, payout_date, amount, items, provider, state, bank, holder, account_enc, account_last4)
         VALUES ($1, '2026-03-10', 80000, 1, 'toss', 'requested', '국민은행', '홍길동', 'enc', '6789') RETURNING id",
    )
    .bind(pro)
    .fetch_one(&pool)
    .await
    .expect("payout");
    sqlx::query(
        "INSERT INTO settlements (pro_id, booking_id, gross, fee, net, payout_date, state, payout_id)
         VALUES ($1, $2, 100000, 20000, 80000, '2026-03-10', 'pending', $3)",
    )
    .bind(pro)
    .bind(booking)
    .bind(payout)
    .execute(&pool)
    .await
    .expect("settlement");
    let (st, _) = call(&app, "POST", &format!("/v1/bookings/{booking}/tip"), Some(c.token.as_str()), Some(json!({ "amount": 5000, "payment_method_id": c.card }))).await;
    assert_eq!(st, StatusCode::CONFLICT, "a settlement in a payout batch takes no tip");
    let tips: i64 = sqlx::query_scalar("SELECT count(*) FROM booking_tips").fetch_one(&pool).await.expect("count");
    assert_eq!(tips, 0, "nothing charged or recorded");
}
