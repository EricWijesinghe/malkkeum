//! Sign-in hardening over the real router and a migrated database: refresh rotation with reuse detection,
//! logout and logout-all, and the OTP resend cooldown and lifetime. Needs DATABASE_URL (sqlx::test).

mod common;

use axum::http::StatusCode;
use common::call;
use serde_json::{Value, json};
use sqlx::PgPool;

/// Full sign-in through the OTP flow; returns the whole token payload.
async fn sign_in(app: &axum::Router, phone: &str) -> Value {
    let (st, sent) = call(app, "POST", "/v1/auth/otp", None, Some(json!({ "phone": phone }))).await;
    assert_eq!(st, StatusCode::OK, "{sent}");
    let code = sent["dev_code"].as_str().expect("dev code").to_string();
    let (st, tokens) = call(app, "POST", "/v1/auth/verify", None, Some(json!({ "phone": phone, "code": code, "audience": "customer" }))).await;
    assert_eq!(st, StatusCode::OK, "{tokens}");
    tokens
}

async fn refresh(app: &axum::Router, token: &str) -> (StatusCode, Value) {
    call(app, "POST", "/v1/auth/refresh", None, Some(json!({ "refresh_token": token }))).await
}

#[sqlx::test(migrations = "../../migrations")]
async fn rotation_issues_a_new_refresh_token_that_works(db: PgPool) {
    let app = common::app(db);
    let first = sign_in(&app, "010-7200-0001").await;
    let (st, second) = refresh(&app, first["refresh_token"].as_str().unwrap()).await;
    assert_eq!(st, StatusCode::OK, "{second}");
    let (st, _) = refresh(&app, second["refresh_token"].as_str().unwrap()).await;
    assert_eq!(st, StatusCode::OK, "the rotated-in token keeps the chain alive");
}

#[sqlx::test(migrations = "../../migrations")]
async fn reusing_a_rotated_token_revokes_the_whole_family(db: PgPool) {
    let app = common::app(db.clone());
    let first = sign_in(&app, "010-7200-0002").await;
    let old = first["refresh_token"].as_str().unwrap().to_string();
    let (_, legit) = refresh(&app, &old).await;
    let newest = legit["refresh_token"].as_str().unwrap().to_string();

    // A copy of the old token is replayed after rotation: the family dies, including the newest token.
    let (st, _) = refresh(&app, &old).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "replay refused");
    let (st, _) = refresh(&app, &newest).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "the whole family is revoked");

    let reused: i64 = sqlx::query_scalar("SELECT count(*) FROM audit_log WHERE action = 'auth.refresh_reuse'")
        .fetch_one(&db)
        .await
        .expect("count");
    assert_eq!(reused, 1, "reuse is audited");
}

#[sqlx::test(migrations = "../../migrations")]
async fn logout_revokes_only_this_device_family(db: PgPool) {
    let app = common::app(db);
    let phone_device_a = sign_in(&app, "010-7200-0003").await;
    let device_b = sign_in(&app, "010-7200-0003").await;
    let a = phone_device_a["refresh_token"].as_str().unwrap().to_string();
    let b = device_b["refresh_token"].as_str().unwrap().to_string();

    let (st, _) = call(&app, "POST", "/v1/auth/logout", None, Some(json!({ "refresh_token": a }))).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(refresh(&app, &a).await.0, StatusCode::UNAUTHORIZED, "device A is signed out");
    assert_eq!(refresh(&app, &b).await.0, StatusCode::OK, "device B keeps its session");
}

#[sqlx::test(migrations = "../../migrations")]
async fn logout_all_revokes_every_device(db: PgPool) {
    let app = common::app(db);
    let a = sign_in(&app, "010-7200-0004").await;
    let b = sign_in(&app, "010-7200-0004").await;
    let access = a["access_token"].as_str().unwrap().to_string();
    let (st, _) = call(&app, "POST", "/v1/auth/logout-all", Some(&access), None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(refresh(&app, a["refresh_token"].as_str().unwrap()).await.0, StatusCode::UNAUTHORIZED);
    assert_eq!(refresh(&app, b["refresh_token"].as_str().unwrap()).await.0, StatusCode::UNAUTHORIZED);
}

#[sqlx::test(migrations = "../../migrations")]
async fn logout_all_needs_a_session(db: PgPool) {
    let app = common::app(db);
    let (st, _) = call(&app, "POST", "/v1/auth/logout-all", None, None).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED);
}

#[sqlx::test(migrations = "../../migrations")]
async fn otp_resend_has_a_cooldown_and_three_minute_lifetime(db: PgPool) {
    let app = common::app(db);
    let (st, sent) = call(&app, "POST", "/v1/auth/otp", None, Some(json!({ "phone": "010-7200-0005" }))).await;
    assert_eq!(st, StatusCode::OK, "{sent}");
    assert_eq!(sent["expires_in"], json!(180));
    let (st, b) = call(&app, "POST", "/v1/auth/otp", None, Some(json!({ "phone": "010-7200-0005" }))).await;
    assert_eq!(st, StatusCode::TOO_MANY_REQUESTS, "resend inside the cooldown is refused: {b}");
}
