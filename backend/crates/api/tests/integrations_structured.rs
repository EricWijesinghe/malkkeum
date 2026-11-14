//! Console integration sections over the real router: a Toss payout change needs the owner's TOTP in the request,
//! while a manual payout save does not. Needs DATABASE_URL (sqlx::test).

mod common;

use api::{
    auth::Role,
    crypto,
    integrations::{self, Section},
    totp,
};
use axum::{
    Router,
    body::Body,
    extract::ConnectInfo,
    http::{Request, StatusCode, header},
};
use chrono::Utc;
use common::{staff_token, test_config};
use serde_json::{Value, json};
use sqlx::PgPool;
use std::net::SocketAddr;
use tower::ServiceExt;
use uuid::Uuid;

const TOTP_SEED: &[u8] = b"12345678901234567890";

/// One request with an optional `X-Owner-Totp` header, through the router.
async fn call_with_totp(app: &Router, method: &str, uri: &str, token: &str, totp: Option<&str>, body: Value) -> (StatusCode, Value) {
    let mut req = Request::builder()
        .method(method)
        .uri(uri)
        .header(header::AUTHORIZATION, format!("Bearer {token}"))
        .header(header::CONTENT_TYPE, "application/json");
    if let Some(code) = totp {
        req = req.header("x-owner-totp", code);
    }
    let mut request = req.body(Body::from(body.to_string())).expect("valid request");
    request.extensions_mut().insert(ConnectInfo(SocketAddr::from(([127, 0, 0, 1], 40_000))));
    let resp = app.clone().oneshot(request).await.expect("router is infallible");
    let status = resp.status();
    let bytes = axum::body::to_bytes(resp.into_body(), usize::MAX).await.expect("response body");
    (status, serde_json::from_slice(&bytes).unwrap_or(Value::Null))
}

/// Admin with an enrolled TOTP secret. Returns the access token and the staff id.
async fn enrolled_admin(db: &PgPool) -> (String, Uuid) {
    let (token, id) = staff_token(db, Role::StaffAdmin).await;
    let enc = crypto::encrypt(&test_config().data_key, &totp::encode_secret(TOTP_SEED));
    sqlx::query("UPDATE staff SET totp_secret = $2, totp_enabled_at = now() WHERE id = $1")
        .bind(id)
        .bind(enc)
        .execute(db)
        .await
        .expect("enrol totp");
    (token, id)
}

fn code_now() -> String {
    format!("{:06}", totp::code_at(TOTP_SEED, (Utc::now().timestamp() / totp::STEP_SECS) as u64))
}

#[sqlx::test(migrations = "../../migrations")]
async fn toss_payout_change_needs_owner_totp_and_manual_does_not(db: PgPool) {
    let app = common::app(db.clone());
    let (token, _) = enrolled_admin(&db).await;
    let toss = json!({ "mode": "toss", "secret_key": "test_sk_x", "security_key": "x" });

    let (st, _) = call_with_totp(&app, "PUT", "/v1/admin/setup/payout", &token, None, toss.clone()).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "toss without a code must be refused");

    let (st, _) = call_with_totp(&app, "PUT", "/v1/admin/setup/payout", &token, Some("000000"), toss.clone()).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "a wrong code must be refused");

    let manual = json!({ "mode": "manual" });
    let (st, body) = call_with_totp(&app, "PUT", "/v1/admin/setup/payout", &token, None, manual).await;
    assert_eq!(st, StatusCode::OK, "manual save needs no owner code: {body}");

    // A valid code passes the gate; the toss values are then checked on their own (bad security key here).
    let (st, body) = call_with_totp(&app, "PUT", "/v1/admin/setup/payout", &token, Some(&code_now()), toss).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "gate passed, values refused: {body}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn clearing_a_saved_toss_payout_needs_owner_totp_and_manual_does_not(db: PgPool) {
    let app = common::app(db.clone());
    let (token, id) = enrolled_admin(&db).await;

    let manual = json!({ "mode": "manual" });
    let (st, body) = call_with_totp(&app, "PUT", "/v1/admin/setup/payout", &token, None, manual).await;
    assert_eq!(st, StatusCode::OK, "manual save: {body}");
    let (st, body) = call_with_totp(&app, "DELETE", "/v1/admin/setup/payout", &token, None, Value::Null).await;
    assert_eq!(st, StatusCode::OK, "clearing a manual payout needs no owner code: {body}");

    // Seeded directly: the route itself refuses to write a Toss config without the owner's code.
    let toss = json!({ "mode": "toss", "secret_key": "test_sk_x", "security_key": "x" });
    integrations::save_section(&db, &test_config().data_key, Section::Payout, toss.as_object().expect("object"), id)
        .await
        .expect("seed toss payout");
    let (st, _) = call_with_totp(&app, "DELETE", "/v1/admin/setup/payout", &token, None, Value::Null).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "clearing a Toss payout without a code must be refused");
    let kept = integrations::load_section(&db, &test_config().data_key, Section::Payout).await.expect("load");
    assert_eq!(kept.get("mode"), Some(&json!("toss")), "a refused clear keeps the saved config");

    let (st, body) = call_with_totp(&app, "DELETE", "/v1/admin/setup/payout", &token, Some(&code_now()), Value::Null).await;
    assert_eq!(st, StatusCode::OK, "a valid code clears it: {body}");
    let gone = integrations::load_section(&db, &test_config().data_key, Section::Payout).await.expect("load");
    assert!(gone.is_empty(), "the Toss config is removed");
}

#[sqlx::test(migrations = "../../migrations")]
async fn push_with_malformed_service_account_json_is_a_400(db: PgPool) {
    let app = common::app(db.clone());
    let (token, _) = staff_token(&db, Role::StaffAdmin).await;
    let (st, body) = call_with_totp(&app, "PUT", "/v1/admin/setup/push", &token, None, json!({ "service_account": "{not json" })).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{body}");
    assert_eq!(body["error"]["code"], "invalid_service_account");
}

#[sqlx::test(migrations = "../../migrations")]
async fn apple_with_a_bad_private_key_pem_is_a_400(db: PgPool) {
    let app = common::app(db.clone());
    let (token, _) = staff_token(&db, Role::StaffAdmin).await;
    let bad = json!({
        "client_ids": "com.x",
        "team_id": "TEAM123456",
        "key_id": "KEY1234567",
        "private_key": "-----BEGIN PRIVATE KEY-----\nnot a key\n-----END PRIVATE KEY-----"
    });
    let (st, body) = call_with_totp(&app, "PUT", "/v1/admin/setup/apple", &token, None, bad).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{body}");
    assert_eq!(body["error"]["code"], "invalid_private_key");
}

#[sqlx::test(migrations = "../../migrations")]
async fn saved_console_value_beats_the_env_key_after_load(db: PgPool) {
    let (_, id) = staff_token(&db, Role::StaffAdmin).await;
    let mut config = test_config();
    config.kakao_app_id = Some("env-app".to_string());
    let saved = json!({ "app_id": "console-app" });
    integrations::save_section(&db, &config.data_key, Section::Kakao, saved.as_object().expect("object"), id)
        .await
        .expect("save kakao");
    let integ = integrations::load(&db, &config).await.expect("load integrations");
    assert_eq!(integ.kakao_app_id.as_deref(), Some("console-app"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn backup_test_against_an_unreachable_endpoint_reports_unreachable(db: PgPool) {
    let app = common::app(db.clone());
    let (token, _) = staff_token(&db, Role::StaffAdmin).await;
    let cfg = json!({
        "endpoint": "https://backup.invalid",
        "region": "ap-northeast-2",
        "bucket": "malkkeum-backup",
        "access_key": "AKIAEXAMPLE",
        "secret_key": "examplesecret"
    });
    let (st, body) = call_with_totp(&app, "PUT", "/v1/admin/setup/backup", &token, None, cfg).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    let (st, body) = call_with_totp(&app, "POST", "/v1/admin/setup/backup/test", &token, None, Value::Null).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    assert_eq!(body["ok"], false);
    assert_eq!(body["code"], "unreachable", "setup_guides.dart maps this code to plain Korean text");
}
