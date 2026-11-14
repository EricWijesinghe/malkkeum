//! Catalogue gaps over the real router and a migrated database: a created service is listed only while
//! active, archiving hides it from the public list, demo load refuses over real bookings, and demo clear
//! needs the owner's TOTP code. Needs DATABASE_URL (sqlx::test).

mod common;

use api::{auth::Role, crypto, totp};
use axum::{
    Router,
    body::Body,
    extract::ConnectInfo,
    http::{Request, StatusCode, header},
};
use common::{app, book, call, customer, seed_catalog, staff_token, test_config};
use serde_json::{Value, json};
use sqlx::PgPool;
use std::net::SocketAddr;
use tower::ServiceExt;

const TOTP_SEED: &[u8] = b"12345678901234567890";

fn window_service(active: bool) -> Value {
    json!({
        "code": "window",
        "pricing": { "type": "fixed", "price": 50000, "minutes": 120 },
        "needs_preparation": false,
        "max_pyeong": null,
        "content": { "name": "창문 청소" },
        "active": active,
        "sort_order": 90,
    })
}

async fn public_codes(app: &Router) -> Vec<String> {
    let (st, body) = call(app, "GET", "/v1/services", None, None).await;
    assert_eq!(st, StatusCode::OK);
    body.as_array()
        .expect("service list")
        .iter()
        .map(|s| s["code"].as_str().expect("code").to_string())
        .collect()
}

/// Admin with an enrolled TOTP secret, so the owner gate accepts codes made from `TOTP_SEED`.
async fn enrolled_admin(db: &PgPool) -> String {
    let (token, id) = staff_token(db, Role::StaffAdmin).await;
    let enc = crypto::encrypt(&test_config().data_key, &totp::encode_secret(TOTP_SEED));
    sqlx::query("UPDATE staff SET totp_secret = $2, totp_enabled_at = now() WHERE id = $1")
        .bind(id)
        .bind(enc)
        .execute(db)
        .await
        .expect("enrol totp");
    token
}

fn code_now() -> String {
    let step = chrono::Utc::now().timestamp().div_euclid(totp::STEP_SECS);
    format!("{:06}", totp::code_at(TOTP_SEED, step as u64))
}

async fn clear_with_totp(app: &Router, token: &str, totp: Option<&str>) -> StatusCode {
    let mut req = Request::builder()
        .method("POST")
        .uri("/v1/admin/demo/clear")
        .header(header::AUTHORIZATION, format!("Bearer {token}"));
    if let Some(code) = totp {
        req = req.header("x-owner-totp", code);
    }
    let mut request = req.body(Body::empty()).expect("valid request");
    request.extensions_mut().insert(ConnectInfo(SocketAddr::from(([127, 0, 0, 1], 40_000))));
    app.clone().oneshot(request).await.expect("router is infallible").status()
}

#[sqlx::test(migrations = "../../migrations")]
async fn archived_service_leaves_the_public_list(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let (token, _) = staff_token(&pool, Role::StaffAdmin).await;

    let (st, _) = call(&app, "POST", "/v1/admin/services", Some(token.as_str()), Some(window_service(true))).await;
    assert_eq!(st, StatusCode::OK);
    assert!(public_codes(&app).await.contains(&"window".to_string()), "new active service is listed");

    let (st, _) = call(&app, "PUT", "/v1/admin/services/window", Some(token.as_str()), Some(window_service(false))).await;
    assert_eq!(st, StatusCode::OK);
    assert!(!public_codes(&app).await.contains(&"window".to_string()), "archived service is hidden");

    let (st, body) = call(&app, "POST", "/v1/admin/services", Some(token.as_str()), Some(window_service(true))).await;
    assert_eq!(st, StatusCode::CONFLICT);
    assert_eq!(body["error"]["code"], "service_exists", "an existing code is never overwritten");
}

#[sqlx::test(migrations = "../../migrations")]
async fn service_code_must_be_a_plain_key(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let (token, _) = staff_token(&pool, Role::StaffAdmin).await;
    for code in ["Window", "1window", "win dow", "x"] {
        let mut body = window_service(true);
        body["code"] = json!(code);
        let (st, _) = call(&app, "POST", "/v1/admin/services", Some(token.as_str()), Some(body)).await;
        assert_eq!(st, StatusCode::BAD_REQUEST, "code `{code}` refused");
    }
}

#[sqlx::test(migrations = "../../migrations")]
async fn demo_load_refuses_over_real_bookings(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let (token, _) = staff_token(&pool, Role::StaffAdmin).await;
    let c = customer(&app, &pool, "010-5550-0101").await;
    book(&app, &c, 3, None).await;

    let (st, body) = call(&app, "POST", "/v1/admin/demo/load", Some(token.as_str()), None).await;
    assert_eq!(st, StatusCode::CONFLICT);
    assert_eq!(body["error"]["code"], "demo_real_data");
}

#[sqlx::test(migrations = "../../migrations")]
async fn demo_clear_needs_the_owner_totp(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let token = enrolled_admin(&pool).await;

    assert_eq!(clear_with_totp(&app, &token, None).await, StatusCode::UNAUTHORIZED, "no code");
    assert_eq!(clear_with_totp(&app, &token, Some("000000")).await, StatusCode::UNAUTHORIZED, "wrong code");
    assert_eq!(clear_with_totp(&app, &token, Some(&code_now())).await, StatusCode::OK, "owner code");
    assert_eq!(
        clear_with_totp(&app, &token, Some(&code_now())).await,
        StatusCode::UNAUTHORIZED,
        "code is single-use"
    );
}
