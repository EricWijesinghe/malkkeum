//! Keys bundle over the real router and a migrated database: owner TOTP and admin role on every request,
//! the bundle opens with its passphrase and matches the live keys, and only a matching upload sets verified_at.
//! Needs DATABASE_URL (sqlx::test).

mod common;

use api::{
    auth::Role,
    crypto,
    keys_bundle::{self, Keys},
    totp,
};
use axum::{
    Router,
    body::Body,
    extract::ConnectInfo,
    http::{Request, StatusCode, header},
};
use base64::{Engine, engine::general_purpose::STANDARD};
use chrono::Utc;
use common::{call, staff_token, test_config};
use serde_json::{Value, json};
use sqlx::PgPool;
use std::net::SocketAddr;
use tower::ServiceExt;

const TOTP_SEED: &[u8] = b"12345678901234567890";
/// The JWT secret of `test_config()`, so the live keys are the ones the bundle must hold.
const JWT: &[u8] = common::SECRET;

/// One request with an `X-Owner-Totp` header, through the router.
async fn owner_call(app: &Router, method: &str, uri: &str, token: &str, totp: Option<&str>, body: Option<Value>) -> (StatusCode, Value) {
    let mut req = Request::builder()
        .method(method)
        .uri(uri)
        .header(header::AUTHORIZATION, format!("Bearer {token}"));
    if let Some(code) = totp {
        req = req.header("x-owner-totp", code);
    }
    let payload = match body {
        Some(v) => {
            req = req.header(header::CONTENT_TYPE, "application/json");
            Body::from(v.to_string())
        }
        None => Body::empty(),
    };
    let mut request = req.body(payload).expect("valid request");
    request.extensions_mut().insert(ConnectInfo(SocketAddr::from(([127, 0, 0, 1], 40_000))));
    let resp = app.clone().oneshot(request).await.expect("router is infallible");
    let status = resp.status();
    let bytes = axum::body::to_bytes(resp.into_body(), usize::MAX).await.expect("response body");
    (status, serde_json::from_slice(&bytes).unwrap_or(Value::Null))
}

/// Admin with an enrolled TOTP secret. Returns the access token.
async fn enrolled_admin(db: &PgPool) -> String {
    let (token, id) = staff_token(db, Role::StaffAdmin).await;
    let enc = crypto::encrypt(&test_config().data_key, crypto::aad::STAFF_TOTP, &totp::encode_secret(TOTP_SEED));
    sqlx::query("UPDATE staff SET totp_secret = $2, totp_enabled_at = now() WHERE id = $1")
        .bind(id)
        .bind(enc)
        .execute(db)
        .await
        .expect("enrol totp");
    token
}

/// The code for the current step plus `offset` (the window accepts -1..+1).
fn code_at_step(offset: i64) -> String {
    let step = Utc::now().timestamp().div_euclid(totp::STEP_SECS) + offset;
    format!("{:06}", totp::code_at(TOTP_SEED, step as u64))
}

fn live_keys() -> Keys {
    Keys::from_parts(test_config().data_key, JWT).expect("live keys")
}

fn sealed_b64(keys: &Keys, passphrase: &str) -> String {
    STANDARD.encode(keys_bundle::seal(keys, passphrase).expect("seal"))
}

#[sqlx::test(migrations = "../../migrations")]
async fn every_request_needs_an_admin_and_a_totp_code(db: PgPool) {
    let app = common::app(db.clone());
    let admin = enrolled_admin(&db).await;
    let (consultant, _) = staff_token(&db, Role::StaffConsultant).await;

    let (st, _) = owner_call(&app, "POST", "/v1/admin/keys/bundle", &consultant, Some(&code_at_step(0)), None).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "consultant");
    let (st, _) = owner_call(&app, "POST", "/v1/admin/keys/bundle", &admin, None, None).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "no TOTP header");
    let (st, _) = owner_call(&app, "POST", "/v1/admin/keys/bundle", &admin, Some("not-a-code"), None).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "malformed TOTP");
}

#[sqlx::test(migrations = "../../migrations")]
async fn bundle_opens_and_a_matching_upload_sets_the_check(db: PgPool) {
    let app = common::app(db.clone());
    let admin = enrolled_admin(&db).await;

    let (st, made) = owner_call(&app, "POST", "/v1/admin/keys/bundle", &admin, Some(&code_at_step(0)), None).await;
    assert_eq!(st, StatusCode::OK, "{made}");
    let passphrase = made["passphrase"].as_str().expect("passphrase").to_string();
    let bundle = made["bundle"].as_str().expect("bundle").to_string();
    let opened = keys_bundle::open(&STANDARD.decode(&bundle).expect("base64"), &passphrase).expect("opens");
    assert!(opened.matches(&test_config().data_key, JWT), "bundle holds the live keys");

    let (st, status) = call(&app, "GET", "/v1/admin/keys/status", Some(admin.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    assert!(status["verified_at"].is_null(), "no check before the upload test");

    let upload = json!({ "bundle": bundle, "passphrase": passphrase });
    let (st, ok) = owner_call(&app, "POST", "/v1/admin/keys/verify", &admin, Some(&code_at_step(1)), Some(upload.clone())).await;
    assert_eq!(st, StatusCode::OK, "{ok}");
    let (st, status) = call(&app, "GET", "/v1/admin/keys/status", Some(admin.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    assert!(status["verified_at"].is_string(), "{status}");

    let (st, _) = owner_call(&app, "POST", "/v1/admin/keys/verify", &admin, Some(&code_at_step(1)), Some(upload)).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "the same TOTP step cannot be used twice");
}

#[sqlx::test(migrations = "../../migrations")]
async fn upload_of_other_keys_leaves_the_check_unset(db: PgPool) {
    let app = common::app(db.clone());
    let admin = enrolled_admin(&db).await;
    let other = Keys::from_parts([9u8; 32], JWT).expect("other keys");
    let upload = json!({ "bundle": sealed_b64(&other, "ABCD-EFGH-JKLM-NPQR-STUV"), "passphrase": "ABCD-EFGH-JKLM-NPQR-STUV" });

    let (st, _) = owner_call(&app, "POST", "/v1/admin/keys/verify", &admin, Some(&code_at_step(0)), Some(upload)).await;
    assert_eq!(st, StatusCode::BAD_REQUEST);
    let (_, status) = call(&app, "GET", "/v1/admin/keys/status", Some(admin.as_str()), None).await;
    assert!(status["verified_at"].is_null(), "{status}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn upload_with_the_wrong_passphrase_is_refused(db: PgPool) {
    let app = common::app(db.clone());
    let admin = enrolled_admin(&db).await;
    let upload = json!({ "bundle": sealed_b64(&live_keys(), "ABCD-EFGH-JKLM-NPQR-STUV"), "passphrase": "ZZZZ-ZZZZ-ZZZZ-ZZZZ-ZZZZ" });

    let (st, _) = owner_call(&app, "POST", "/v1/admin/keys/verify", &admin, Some(&code_at_step(0)), Some(upload)).await;
    assert_eq!(st, StatusCode::BAD_REQUEST);
}
