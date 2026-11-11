//! Address search: signed-in customers and partners only, with a per-user minute bucket. The feature
//! flags stay public. Dev mode has no Juso key, so an allowed search answers 503 without network.
//! Needs DATABASE_URL (sqlx::test).

mod common;

use axum::http::StatusCode;
use common::{app, call, login, seed_catalog};
use serde_json::json;
use sqlx::PgPool;

const SEARCH: &str = "/v1/address/search?q=테헤란로";

#[sqlx::test(migrations = "../../migrations")]
async fn search_needs_a_signed_in_customer_or_partner(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let (st, _) = call(&app, "GET", SEARCH, None, None).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "anonymous callers are refused");

    let (customer, _) = login(&app, "010-5300-0001", "customer").await;
    let (st, _) = call(&app, "GET", SEARCH, Some(&customer), None).await;
    assert_eq!(st, StatusCode::SERVICE_UNAVAILABLE, "customers pass auth; no Juso key in dev");

    let (partner, _) = login(&app, "010-5300-0002", "partner").await;
    let (st, _) = call(&app, "GET", SEARCH, Some(&partner), None).await;
    assert_eq!(st, StatusCode::SERVICE_UNAVAILABLE, "partners pass auth too");
}

#[sqlx::test(migrations = "../../migrations")]
async fn staff_tokens_cannot_search(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let token = api::auth::issue_access(common::SECRET, uuid::Uuid::now_v7(), api::auth::Role::StaffAdmin).expect("token");
    let (st, _) = call(&app, "GET", SEARCH, Some(&token), None).await;
    assert_eq!(st, StatusCode::FORBIDDEN);
}

#[sqlx::test(migrations = "../../migrations")]
async fn each_user_gets_thirty_searches_a_minute(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let (token, _) = login(&app, "010-5300-0003", "customer").await;
    for _ in 0..30 {
        let (st, _) = call(&app, "GET", SEARCH, Some(&token), None).await;
        assert_eq!(st, StatusCode::SERVICE_UNAVAILABLE);
    }
    let (st, body) = call(&app, "GET", SEARCH, Some(&token), None).await;
    assert_eq!(st, StatusCode::TOO_MANY_REQUESTS, "31st search in the window: {body}");

    let (other, _) = login(&app, "010-5300-0004", "customer").await;
    let (st, _) = call(&app, "GET", SEARCH, Some(&other), None).await;
    assert_eq!(st, StatusCode::SERVICE_UNAVAILABLE, "the bucket is per user");
}

#[sqlx::test(migrations = "../../migrations")]
async fn feature_flags_stay_public(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let (st, body) = call(&app, "GET", "/v1/features", None, None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(body["address_search"], json!(false), "no key in dev, and the flag says so without auth");
}
