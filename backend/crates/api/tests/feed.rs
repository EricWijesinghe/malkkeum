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
