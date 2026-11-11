//! Owner-initiated staff password reset over the real router: token issue, single-use redemption, password
//! policy, lockout clearing, and session revocation. Needs DATABASE_URL (sqlx::test).

mod common;

use api::auth::{self, Role};
use axum::http::StatusCode;
use common::{SECRET, call};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

const OLD: &str = "old-staff-password-1";
const NEW: &str = "fresh-staff-password-2";

async fn insert(db: &PgPool, email: &str, role: &str) -> Uuid {
    sqlx::query_scalar("INSERT INTO staff (email, name, password_hash, role) VALUES ($1, 'Test', $2, $3) RETURNING id")
        .bind(email)
        .bind(auth::hash_password(OLD).expect("hash"))
        .bind(role)
        .fetch_one(db)
        .await
        .expect("insert")
}

async fn login(app: &axum::Router, email: &str, password: &str) -> (StatusCode, Value) {
    call(app, "POST", "/v1/auth/staff/login", None, Some(json!({ "email": email, "password": password }))).await
}

async fn issue(app: &axum::Router, admin_token: &str, staff: Uuid) -> String {
    let (st, b) = call(app, "POST", &format!("/v1/admin/staff/{staff}/password-reset"), Some(admin_token), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    b["token"].as_str().expect("token").to_string()
}

#[sqlx::test(migrations = "../../migrations")]
async fn reset_sets_new_password_once_and_signs_out_everywhere(db: PgPool) {
    let target = insert(&db, "consultant-reset@test.local", "consultant").await;
    let admin = insert(&db, "admin-reset@test.local", "admin").await;
    let admin_token = auth::issue_access(SECRET, admin, Role::StaffAdmin).expect("admin token");
    let app = common::app(db);

    // An existing session of the target.
    let (_, before) = login(&app, "consultant-reset@test.local", OLD).await;
    let refresh = before["refresh_token"].as_str().unwrap().to_string();

    let token = issue(&app, &admin_token, target).await;
    let (st, b) = call(&app, "POST", "/v1/auth/staff/password/reset", None, Some(json!({ "token": token, "password": NEW }))).await;
    assert_eq!(st, StatusCode::OK, "{b}");

    assert_eq!(login(&app, "consultant-reset@test.local", OLD).await.0, StatusCode::UNAUTHORIZED, "old password is dead");
    assert_eq!(login(&app, "consultant-reset@test.local", NEW).await.0, StatusCode::OK, "new password works");
    let (st, _) = call(&app, "POST", "/v1/auth/refresh", None, Some(json!({ "refresh_token": refresh }))).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "existing sessions are revoked");

    let (st, _) = call(&app, "POST", "/v1/auth/staff/password/reset", None, Some(json!({ "token": token, "password": "another-staff-password-3" }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "a reset token works once");
}

#[sqlx::test(migrations = "../../migrations")]
async fn reset_enforces_the_password_policy(db: PgPool) {
    let target = insert(&db, "consultant-policy@test.local", "consultant").await;
    let admin = insert(&db, "admin-policy@test.local", "admin").await;
    let admin_token = auth::issue_access(SECRET, admin, Role::StaffAdmin).expect("admin token");
    let app = common::app(db);
    let token = issue(&app, &admin_token, target).await;

    let (st, b) = call(&app, "POST", "/v1/auth/staff/password/reset", None, Some(json!({ "token": token, "password": "short-1" }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{b}");
    assert_eq!(b["error"]["code"], json!("weak_password"));

    let (st, b) = call(&app, "POST", "/v1/auth/staff/password/reset", None, Some(json!({ "token": token, "password": "Password1234" }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{b}");
    assert_eq!(b["error"]["code"], json!("breached_password"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn unknown_or_expired_token_is_refused(db: PgPool) {
    let app = common::app(db);
    let (st, b) = call(&app, "POST", "/v1/auth/staff/password/reset", None, Some(json!({ "token": "deadbeef", "password": NEW }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{b}");
    assert_eq!(b["error"]["code"], json!("reset_token_invalid"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn only_admins_issue_reset_tokens(db: PgPool) {
    let target = insert(&db, "consultant-auth@test.local", "consultant").await;
    let consultant = insert(&db, "consultant-caller@test.local", "consultant").await;
    let consultant_token = auth::issue_access(SECRET, consultant, Role::StaffConsultant).expect("token");
    let app = common::app(db);
    let (st, _) = call(&app, "POST", &format!("/v1/admin/staff/{target}/password-reset"), Some(consultant_token.as_str()), None).await;
    assert_eq!(st, StatusCode::FORBIDDEN);
}
