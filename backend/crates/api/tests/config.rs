//! Maintenance mode: the owner can still sign in and switch it off; the public API is refused meanwhile.

mod common;

use api::routes::setup::ensure_setup_code;
use axum::http::StatusCode;
use common::call;
use serde_json::{Value, json};
use sqlx::PgPool;

const CODE: &str = "ABCD2345EFGH";
const PASSWORD: &str = "owner-password-123";

async fn owner_login(app: &axum::Router) -> (StatusCode, Value) {
    call(
        app,
        "POST",
        "/v1/auth/staff/login",
        None,
        Some(json!({"email": "owner@test.local", "password": PASSWORD})),
    )
    .await
}

#[sqlx::test(migrations = "../../migrations")]
async fn owner_signs_in_during_maintenance_and_switches_it_off(pool: PgPool) {
    ensure_setup_code(&pool, Some(CODE)).await.expect("code");
    let app = common::app(pool.clone());
    let (st, b) = call(
        &app,
        "POST",
        "/v1/setup/admin",
        None,
        Some(json!({"code": CODE, "email": "owner@test.local", "name": "사장님", "password": PASSWORD})),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{b}");

    let (st, b) = owner_login(&app).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let token = b["access_token"].as_str().expect("token").to_string();

    let (st, _) = call(
        &app,
        "PUT",
        "/v1/admin/config",
        Some(&token),
        Some(json!({"maintenance": {"on": true, "message": "점검"}})),
    )
    .await;
    assert_eq!(st, StatusCode::OK);

    // Public booking traffic is refused with the stable code, before any auth check.
    let (st, b) = call(&app, "GET", "/v1/bookings", None, None).await;
    assert_eq!(st, StatusCode::SERVICE_UNAVAILABLE);
    assert_eq!(b["error"]["code"], "maintenance");

    // The owner can still sign in, refresh and reach the admin config during maintenance.
    let (st, b) = owner_login(&app).await;
    assert_eq!(st, StatusCode::OK, "staff login must stay open in maintenance: {b}");
    let token = b["access_token"].as_str().expect("token").to_string();
    let (st, _) = call(&app, "GET", "/v1/admin/config", Some(&token), None).await;
    assert_eq!(st, StatusCode::OK);

    let (st, b) = call(&app, "PUT", "/v1/admin/config", Some(&token), Some(json!({"maintenance": {"on": false}}))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert_eq!(b["maintenance"]["on"], json!(false));

    // Switched off: the public API answers again (here 401, since no token is sent).
    let (st, _) = call(&app, "GET", "/v1/bookings", None, None).await;
    assert_ne!(st, StatusCode::SERVICE_UNAVAILABLE);
}

#[sqlx::test(migrations = "../../migrations")]
async fn config_endpoint_is_public_and_hides_business_fields(pool: PgPool) {
    let app = common::app(pool.clone());
    let (st, b) = call(&app, "GET", "/v1/config", None, None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(b["maintenance"]["on"], json!(false));
    assert_eq!(b["flags"]["booking"], json!(true));
    assert!(b.get("name").is_none());
}
