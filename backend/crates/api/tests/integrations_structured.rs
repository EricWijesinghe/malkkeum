//! Console integration sections over the real router: a Toss payout change needs the owner's TOTP in the request,
//! while a manual payout save does not. Needs DATABASE_URL (sqlx::test).

mod common;

use api::{auth::Role, crypto, totp};
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

/// Admin with an enrolled TOTP secret. Returns the access token.
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
    format!("{:06}", totp::code_at(TOTP_SEED, (Utc::now().timestamp() / totp::STEP_SECS) as u64))
}

#[sqlx::test(migrations = "../../migrations")]
async fn toss_payout_change_needs_owner_totp_and_manual_does_not(db: PgPool) {
    let app = common::app(db.clone());
    let token = enrolled_admin(&db).await;
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
