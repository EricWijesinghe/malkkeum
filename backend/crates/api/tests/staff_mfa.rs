//! Staff second factor over the real router and a migrated database: admin enrolment, TOTP and recovery-code
//! sign-in, replay refusal, and that a password alone cannot replace an active second factor.
//! Needs DATABASE_URL (sqlx::test).

mod common;

use api::{auth, totp};
use axum::http::StatusCode;
use chrono::Utc;
use common::call;
use serde_json::{Value, json};
use sqlx::PgPool;

const PASSWORD: &str = "staff-password-123";

async fn insert_staff(db: &PgPool, email: &str, role: &str) {
    let hash = auth::hash_password(PASSWORD).expect("hash");
    sqlx::query("INSERT INTO staff (email, name, password_hash, role) VALUES ($1, 'Test', $2, $3)")
        .bind(email)
        .bind(hash)
        .bind(role)
        .execute(db)
        .await
        .expect("insert staff");
}

async fn password_step(app: &axum::Router, email: &str) -> Value {
    let (st, b) = call(app, "POST", "/v1/auth/staff/login", None, Some(json!({ "email": email, "password": PASSWORD }))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    b
}

fn code_now(secret: &[u8]) -> String {
    format!("{:06}", totp::code_at(secret, (Utc::now().timestamp() / totp::STEP_SECS) as u64))
}

/// Enrols the admin and returns (secret, recovery codes).
async fn enrol(app: &axum::Router, mfa: &str) -> (Vec<u8>, Vec<String>) {
    let (st, e) = call(app, "POST", "/v1/auth/staff/mfa/enrol", None, Some(json!({ "mfa_token": mfa }))).await;
    assert_eq!(st, StatusCode::OK, "{e}");
    let secret = totp::decode_secret(e["secret"].as_str().unwrap()).unwrap();
    let (st, c) = call(app, "POST", "/v1/auth/staff/mfa/enrol/confirm", None, Some(json!({ "mfa_token": mfa, "code": code_now(&secret) }))).await;
    assert_eq!(st, StatusCode::OK, "{c}");
    assert!(c["access_token"].is_string());
    let codes = c["recovery_codes"].as_array().unwrap().iter().map(|v| v.as_str().unwrap().to_string()).collect();
    (secret, codes)
}

#[sqlx::test(migrations = "../../migrations")]
async fn consultant_signs_in_with_password_only(db: PgPool) {
    insert_staff(&db, "consultant@test.local", "consultant").await;
    let b = password_step(&common::app(db), "consultant@test.local").await;
    assert!(b["access_token"].is_string(), "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn admin_must_enrol_before_tokens(db: PgPool) {
    insert_staff(&db, "admin@test.local", "admin").await;
    let app = common::app(db);
    let b = password_step(&app, "admin@test.local").await;
    assert_eq!(b["mfa_enrol_required"], json!(true));
    assert!(b.get("access_token").is_none(), "no tokens before enrolment");
}

#[sqlx::test(migrations = "../../migrations")]
async fn enrolled_admin_signs_in_with_totp_once_per_step(db: PgPool) {
    insert_staff(&db, "admin2@test.local", "admin").await;
    let app = common::app(db);
    let mfa = password_step(&app, "admin2@test.local").await["mfa_token"].as_str().unwrap().to_string();
    let (secret, codes) = enrol(&app, &mfa).await;
    assert_eq!(codes.len(), 10);

    let b = password_step(&app, "admin2@test.local").await;
    assert_eq!(b["mfa_required"], json!(true), "{b}");
    let mfa = b["mfa_token"].as_str().unwrap().to_string();
    // Enrolment used the current step; sign-in needs a later one (the next step is inside the window).
    let code = format!("{:06}", totp::code_at(&secret, (Utc::now().timestamp() / totp::STEP_SECS) as u64 + 1));
    let (st, ok) = call(&app, "POST", "/v1/auth/staff/mfa/verify", None, Some(json!({ "mfa_token": mfa, "code": code }))).await;
    assert_eq!(st, StatusCode::OK, "{ok}");
    assert!(ok["access_token"].is_string());

    // The same step again is a replay.
    let b = password_step(&app, "admin2@test.local").await;
    let mfa = b["mfa_token"].as_str().unwrap().to_string();
    let (st, _) = call(&app, "POST", "/v1/auth/staff/mfa/verify", None, Some(json!({ "mfa_token": mfa, "code": code }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "replayed code refused");
}

#[sqlx::test(migrations = "../../migrations")]
async fn recovery_code_works_once(db: PgPool) {
    insert_staff(&db, "admin3@test.local", "admin").await;
    let app = common::app(db);
    let mfa = password_step(&app, "admin3@test.local").await["mfa_token"].as_str().unwrap().to_string();
    let (_, codes) = enrol(&app, &mfa).await;
    let rc = codes[0].to_lowercase(); // input form does not matter

    let mfa = password_step(&app, "admin3@test.local").await["mfa_token"].as_str().unwrap().to_string();
    let (st, ok) = call(&app, "POST", "/v1/auth/staff/mfa/verify", None, Some(json!({ "mfa_token": mfa, "recovery_code": rc }))).await;
    assert_eq!(st, StatusCode::OK, "{ok}");

    let mfa = password_step(&app, "admin3@test.local").await["mfa_token"].as_str().unwrap().to_string();
    let (st, _) = call(&app, "POST", "/v1/auth/staff/mfa/verify", None, Some(json!({ "mfa_token": mfa, "recovery_code": rc }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "a recovery code is single use");
}

#[sqlx::test(migrations = "../../migrations")]
async fn password_alone_cannot_replace_an_active_second_factor(db: PgPool) {
    insert_staff(&db, "admin4@test.local", "admin").await;
    let app = common::app(db);
    let mfa = password_step(&app, "admin4@test.local").await["mfa_token"].as_str().unwrap().to_string();
    enrol(&app, &mfa).await;

    // Someone with only the password gets a challenge token and tries to re-enrol.
    let mfa = password_step(&app, "admin4@test.local").await["mfa_token"].as_str().unwrap().to_string();
    let (st, b) = call(&app, "POST", "/v1/auth/staff/mfa/enrol", None, Some(json!({ "mfa_token": mfa }))).await;
    assert_eq!(st, StatusCode::CONFLICT, "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn challenge_token_is_not_an_access_token(db: PgPool) {
    insert_staff(&db, "admin5@test.local", "admin").await;
    let app = common::app(db);
    let mfa = password_step(&app, "admin5@test.local").await["mfa_token"].as_str().unwrap().to_string();
    let (st, _) = call(&app, "GET", "/v1/admin/staff", Some(mfa.as_str()), None).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "MFA audience is refused on the API");
}

#[sqlx::test(migrations = "../../migrations")]
async fn wrong_codes_lock_the_account(db: PgPool) {
    insert_staff(&db, "admin6@test.local", "admin").await;
    let app = common::app(db);
    let mfa = password_step(&app, "admin6@test.local").await["mfa_token"].as_str().unwrap().to_string();
    enrol(&app, &mfa).await;
    for _ in 0..5 {
        let mfa = password_step(&app, "admin6@test.local").await["mfa_token"].as_str().unwrap().to_string();
        let (st, _) = call(&app, "POST", "/v1/auth/staff/mfa/verify", None, Some(json!({ "mfa_token": mfa, "code": "000000" }))).await;
        assert!(st == StatusCode::BAD_REQUEST || st == StatusCode::TOO_MANY_REQUESTS, "{st}");
    }
    let (st, _) = call(&app, "POST", "/v1/auth/staff/login", None, Some(json!({ "email": "admin6@test.local", "password": PASSWORD }))).await;
    assert_eq!(st, StatusCode::TOO_MANY_REQUESTS, "locked after repeated bad second factors");
}

#[sqlx::test(migrations = "../../migrations")]
async fn demo_kit_can_switch_off_admin_mfa_enrolment(db: PgPool) {
    insert_staff(&db, "owner@test.local", "admin").await;
    let mut cfg = common::test_config();
    cfg.staff_mfa_required = false;
    let app = api::routes::router(api::build_state(db, cfg).expect("state"));
    let b = password_step(&app, "owner@test.local").await;
    assert!(b["access_token"].is_string(), "tokens issued directly: {b}");
    assert!(b.get("mfa_enrol_required").is_none());
    let (st, _) = call(&app, "GET", "/v1/admin/staff", b["access_token"].as_str(), None).await;
    assert_eq!(st, StatusCode::OK, "the token carries the admin role");
}
