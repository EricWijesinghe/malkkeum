//! Maintenance mode: the owner can still sign in and switch it off; new bookings are refused meanwhile.

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

fn code_now(secret: &[u8]) -> String {
    let counter = (chrono::Utc::now().timestamp() / api::totp::STEP_SECS) as u64;
    format!("{:06}", api::totp::code_at(secret, counter))
}

/// First sign-in: admins must enrol a TOTP factor before tokens. Returns the token and one recovery
/// code (a TOTP step can be used only once, and later sign-ins in this test happen within one step).
async fn owner_enrol(app: &axum::Router) -> (String, String) {
    let (st, b) = owner_login(app).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let mfa = b["mfa_token"].as_str().expect("mfa_token");
    let (st, e) = call(app, "POST", "/v1/auth/staff/mfa/enrol", None, Some(json!({ "mfa_token": mfa }))).await;
    assert_eq!(st, StatusCode::OK, "{e}");
    let secret = api::totp::decode_secret(e["secret"].as_str().expect("secret")).expect("base32 secret");
    let (st, c) = call(
        app,
        "POST",
        "/v1/auth/staff/mfa/enrol/confirm",
        None,
        Some(json!({ "mfa_token": mfa, "code": code_now(&secret) })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{c}");
    let recovery = c["recovery_codes"][0].as_str().expect("recovery code").to_string();
    (c["access_token"].as_str().expect("token").to_string(), recovery)
}

/// Later sign-in: password, then one recovery code.
async fn owner_verify(app: &axum::Router, recovery: &str) -> String {
    let (st, b) = owner_login(app).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let mfa = b["mfa_token"].as_str().expect("mfa_token");
    let (st, c) = call(
        app,
        "POST",
        "/v1/auth/staff/mfa/verify",
        None,
        Some(json!({ "mfa_token": mfa, "recovery_code": recovery })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{c}");
    c["access_token"].as_str().expect("token").to_string()
}

#[sqlx::test(migrations = "../../migrations")]
async fn owner_signs_in_during_maintenance_and_switches_it_off(pool: PgPool) {
    ensure_setup_code(&pool, Some(CODE), None).await.expect("code");
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

    let (token, recovery) = owner_enrol(&app).await;

    let (st, _) = call(
        &app,
        "PUT",
        "/v1/admin/config",
        Some(&token),
        Some(json!({"maintenance": {"on": true, "message": "점검"}})),
    )
    .await;
    assert_eq!(st, StatusCode::OK);

    // The switch lives in the settings registry, so the public document reports it at once.
    let (st, b) = call(&app, "GET", "/v1/config", None, None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(b["maintenance"], json!({"on": true, "message": "점검"}));

    // New bookings are refused with the stable code, before any auth check; reads stay open.
    let (st, b) = call(&app, "POST", "/v1/bookings", None, None).await;
    assert_eq!(st, StatusCode::SERVICE_UNAVAILABLE);
    assert_eq!(b["error"]["code"], "maintenance");
    let (st, _) = call(&app, "GET", "/v1/bookings", None, None).await;
    assert_ne!(st, StatusCode::SERVICE_UNAVAILABLE);

    // The owner can still sign in, refresh and reach the admin config during maintenance.
    let token = owner_verify(&app, &recovery).await;
    let (st, _) = call(&app, "GET", "/v1/admin/config", Some(&token), None).await;
    assert_eq!(st, StatusCode::OK);

    let (st, b) = call(&app, "PUT", "/v1/admin/config", Some(&token), Some(json!({"maintenance": {"on": false}}))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert_eq!(b["maintenance"]["on"], json!(false));

    // Switched off: new bookings pass the gate again (here 401, since no token is sent).
    let (st, _) = call(&app, "POST", "/v1/bookings", None, None).await;
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
