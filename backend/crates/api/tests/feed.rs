//! Personalized feed over the real router: guests read it with no session, members only with one,
//! and a half-finished quote on the device comes first.

mod common;

use axum::http::StatusCode;
use common::{call, customer, seed_catalog};
use sqlx::PgPool;

#[sqlx::test(migrations = "../../migrations")]
async fn guest_feed_is_public_and_resumes_a_draft_first(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());

    let (st, b) = call(&app, "GET", "/v1/feed?draft=move_in", None, None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert_eq!(b["cards"][0]["kind"], "resume_quote", "{b}");
    assert_eq!(b["cards"][0]["service"], "move_in");
}

#[sqlx::test(migrations = "../../migrations")]
async fn member_feed_needs_a_session(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());

    let (st, _) = call(&app, "GET", "/v1/me/feed", None, None).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED);

    let c = customer(&app, &pool, "010-5300-0001").await;
    let (st, b) = call(&app, "GET", "/v1/me/feed?draft=move_out", Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert_eq!(b["cards"][0]["kind"], "resume_quote");
    assert_eq!(b["cards"][0]["service"], "move_out");
}

#[sqlx::test(migrations = "../../migrations")]
async fn garbage_codes_from_the_device_are_ignored(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());

    let (st, b) = call(&app, "GET", "/v1/feed?draft=x'%20OR%201%3D1&district=%27%20--", None, None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert!(b["cards"].as_array().unwrap().iter().all(|c| c["kind"] != "resume_quote"));
}

async fn move_to_district_last_week(pool: &PgPool, booking: uuid::Uuid, code: &str) {
    // Exactly seven days back always lands in the previous complete KST week.
    sqlx::query("UPDATE bookings SET district_code = $2, created_at = now() - interval '7 days' WHERE id = $1")
        .bind(booking)
        .bind(code)
        .execute(pool)
        .await
        .expect("move booking");
}

fn has_district_card(b: &serde_json::Value) -> bool {
    b["cards"].as_array().expect("cards").iter().any(|c| c["kind"] == "district_proof")
}

#[sqlx::test(migrations = "../../migrations")]
async fn district_proof_counts_distinct_homes_not_bookings(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    // Codes unique to this test: the district count is cached per process.
    let one = customer(&app, &pool, "010-5300-0100").await;
    for days in 3..8 {
        let (id, _) = common::book(&app, &one, days, None).await;
        move_to_district_last_week(&pool, id, "T_ONE_HOME").await;
    }
    for i in 0..5 {
        let c = customer(&app, &pool, &format!("010-5300-011{i}")).await;
        let (id, _) = common::book(&app, &c, 3 + i, None).await;
        move_to_district_last_week(&pool, id, "T_FIVE_HOMES").await;
    }

    let (st, b) = call(&app, "GET", "/v1/feed?district=T_ONE_HOME", None, None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert!(!has_district_card(&b), "five bookings from one home stay hidden: {b}");
    let (st, b) = call(&app, "GET", "/v1/feed?district=T_FIVE_HOMES", None, None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert!(has_district_card(&b), "five distinct homes show the proof: {b}");
}
