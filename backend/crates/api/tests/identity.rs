//! PASS identity flow over the real router (dev provider) and a migrated database: a verification id is
//! issued per customer, checked once, and burnt on use. Needs DATABASE_URL (sqlx::test).

mod common;

use axum::http::StatusCode;
use common::{call, login};
use serde_json::{Value, json};
use sqlx::PgPool;

async fn session(app: &axum::Router, token: &str) -> (StatusCode, Value) {
    call(app, "POST", "/v1/me/identity/session", Some(token), None).await
}

#[sqlx::test(migrations = "../../migrations")]
async fn session_is_issued_and_verifies_once(db: PgPool) {
    let app = common::app(db);
    let (token, _) = login(&app, "010-7100-0001", "customer").await;

    let (st, s) = session(&app, &token).await;
    assert_eq!(st, StatusCode::OK, "{s}");
    let id = s["identity_verification_id"].as_str().expect("id").to_string();
    assert!(id.starts_with("dev:"), "dev provider accepts dev ids: {id}");

    let body = json!({ "identity_verification_id": id });
    let (st, me) = call(&app, "POST", "/v1/me/identity", Some(token.as_str()), Some(body.clone())).await;
    assert_eq!(st, StatusCode::OK, "{me}");
    assert_eq!(me["identity_verified"], json!(true));

    let (st, _) = call(&app, "POST", "/v1/me/identity", Some(token.as_str()), Some(body)).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "a used id cannot verify again");
}

#[sqlx::test(migrations = "../../migrations")]
async fn unissued_id_is_refused(db: PgPool) {
    let app = common::app(db);
    let (token, _) = login(&app, "010-7100-0002", "customer").await;
    let (st, b) = call(&app, "POST", "/v1/me/identity", Some(token.as_str()), Some(json!({ "identity_verification_id": "dev:forged" }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{b}");
    assert_eq!(b["error"]["code"], json!("identity_not_found"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn id_issued_to_another_customer_is_refused(db: PgPool) {
    let app = common::app(db);
    let (alice, _) = login(&app, "010-7100-0003", "customer").await;
    let (bob, _) = login(&app, "010-7100-0004", "customer").await;
    let (_, s) = session(&app, &alice).await;
    let id = s["identity_verification_id"].as_str().expect("id").to_string();
    let (st, _) = call(&app, "POST", "/v1/me/identity", Some(bob.as_str()), Some(json!({ "identity_verification_id": id }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "bob cannot use alice's session");
}

#[sqlx::test(migrations = "../../migrations")]
async fn setup_reports_enabled_in_dev_mode(db: PgPool) {
    let app = common::app(db);
    let (token, _) = login(&app, "010-7100-0005", "customer").await;
    let (st, b) = call(&app, "GET", "/v1/me/identity/setup", Some(token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(b["enabled"], json!(true));
}
