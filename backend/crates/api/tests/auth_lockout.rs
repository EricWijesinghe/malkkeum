//! Lockout, owner alert and signed-in device rules over the real router and a migrated database.
//! Needs DATABASE_URL (sqlx::test).

mod common;

use api::{auth, lockout::PAIR_FREE_FAILURES};
use axum::http::StatusCode;
use common::{call, login};
use serde_json::{Value, json};
use sqlx::PgPool;

const PASSWORD: &str = "staff-password-123";

async fn insert_consultant(db: &PgPool, email: &str) {
    let hash = auth::hash_password(PASSWORD).expect("hash");
    sqlx::query("INSERT INTO staff (email, name, password_hash, role) VALUES ($1, 'Test', $2, 'consultant')")
        .bind(email)
        .bind(hash)
        .execute(db)
        .await
        .expect("insert staff");
}

async fn staff_login(app: &axum::Router, email: &str, password: &str) -> (StatusCode, Value) {
    call(app, "POST", "/v1/auth/staff/login", None, Some(json!({ "email": email, "password": password }))).await
}

#[sqlx::test(migrations = "../../migrations")]
async fn wrong_passwords_lock_the_pair_even_for_the_right_password(db: PgPool) {
    insert_consultant(&db, "lock@test.local").await;
    let app = common::app(db);
    for _ in 0..PAIR_FREE_FAILURES {
        let (st, _) = staff_login(&app, "lock@test.local", "wrong-password-123").await;
        assert_eq!(st, StatusCode::UNAUTHORIZED);
    }
    // Locked: even the correct password is refused until the backoff ends.
    let (st, b) = staff_login(&app, "lock@test.local", PASSWORD).await;
    assert_eq!(st, StatusCode::TOO_MANY_REQUESTS, "{b}");
    assert_eq!(b["error"]["code"], "rate_limited");
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_success_before_the_lock_returns_the_free_budget(db: PgPool) {
    insert_consultant(&db, "reset@test.local").await;
    let app = common::app(db);
    for _ in 0..PAIR_FREE_FAILURES - 1 {
        staff_login(&app, "reset@test.local", "wrong-password-123").await;
    }
    let (st, b) = staff_login(&app, "reset@test.local", PASSWORD).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    for _ in 0..PAIR_FREE_FAILURES - 1 {
        staff_login(&app, "reset@test.local", "wrong-password-123").await;
    }
    let (st, _) = staff_login(&app, "reset@test.local", PASSWORD).await;
    assert_eq!(st, StatusCode::OK, "budget came back after the success");
}

#[sqlx::test(migrations = "../../migrations")]
async fn repeated_otp_guesses_across_codes_lock_the_number(db: PgPool) {
    let app = common::app(db);
    let phone = "010-5400-0001";
    // One code per cooldown window; wrong guesses burn it, then the number's lock takes over.
    let (st, sent) = call(&app, "POST", "/v1/auth/otp", None, Some(json!({ "phone": phone }))).await;
    assert_eq!(st, StatusCode::OK, "{sent}");
    let code = sent["dev_code"].as_str().expect("dev_code").to_string();
    for _ in 0..PAIR_FREE_FAILURES {
        let (st, _) = call(&app, "POST", "/v1/auth/verify", None, Some(json!({ "phone": phone, "code": "000000", "audience": "customer" }))).await;
        assert_eq!(st, StatusCode::BAD_REQUEST);
    }
    let (st, b) = call(&app, "POST", "/v1/auth/verify", None, Some(json!({ "phone": phone, "code": code, "audience": "customer" }))).await;
    assert_eq!(st, StatusCode::TOO_MANY_REQUESTS, "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn lockouts_feed_the_owner_suspicious_activity_alert(db: PgPool) {
    insert_consultant(&db, "alert@test.local").await;
    let app = common::app(db.clone());
    for _ in 0..PAIR_FREE_FAILURES {
        staff_login(&app, "alert@test.local", "wrong-password-123").await;
    }
    let n: i64 = sqlx::query_scalar("SELECT count(*) FROM ops_failures WHERE integration = 'auth_abuse' AND code = 'staff_lockout'")
        .fetch_one(&db)
        .await
        .expect("count");
    assert_eq!(n, 1, "one event per lock, not per refused request");
    for _ in 0..3 {
        staff_login(&app, "alert@test.local", PASSWORD).await;
    }
    let n_after: i64 = sqlx::query_scalar("SELECT count(*) FROM ops_failures WHERE integration = 'auth_abuse'")
        .fetch_one(&db)
        .await
        .expect("count");
    assert_eq!(n_after, 1, "refused requests during a lock are not new events");
}

#[sqlx::test(migrations = "../../migrations")]
async fn signed_in_devices_list_and_revoke_one_family(db: PgPool) {
    insert_consultant(&db, "devices@test.local").await;
    let app = common::app(db.clone());
    let (_, a) = staff_login(&app, "devices@test.local", PASSWORD).await;
    let (_, b) = staff_login(&app, "devices@test.local", PASSWORD).await;
    let access = a["access_token"].as_str().expect("access").to_string();
    let (st, list) = call(&app, "GET", "/v1/auth/sessions", Some(&access), None).await;
    assert_eq!(st, StatusCode::OK, "{list}");
    let sessions = list["sessions"].as_array().expect("sessions");
    assert_eq!(sessions.len(), 2, "one row per device");

    // Find the second device's family by its refresh token, then sign it out.
    let family: String = sqlx::query_scalar("SELECT family_id::text FROM refresh_tokens WHERE token_hash = $1")
        .bind(auth::sha256_hex(b["refresh_token"].as_str().expect("refresh").as_bytes()))
        .fetch_one(&db)
        .await
        .expect("family");
    let (st, _) = call(&app, "DELETE", &format!("/v1/auth/sessions/{family}"), Some(&access), None).await;
    assert_eq!(st, StatusCode::OK);
    let (st, _) = call(&app, "POST", "/v1/auth/refresh", None, Some(json!({ "refresh_token": b["refresh_token"] }))).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "revoked device cannot refresh");
    let (st, _) = call(&app, "POST", "/v1/auth/refresh", None, Some(json!({ "refresh_token": a["refresh_token"] }))).await;
    assert_eq!(st, StatusCode::OK, "other device still signed in");
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_device_of_another_account_cannot_be_revoked(db: PgPool) {
    let app = common::app(db.clone());
    let (customer, _) = login(&app, "010-5400-0002", "customer").await;
    insert_consultant(&db, "other@test.local").await;
    let (_, other) = staff_login(&app, "other@test.local", PASSWORD).await;
    let family: String = sqlx::query_scalar("SELECT family_id::text FROM refresh_tokens WHERE token_hash = $1")
        .bind(auth::sha256_hex(other["refresh_token"].as_str().expect("refresh").as_bytes()))
        .fetch_one(&db)
        .await
        .expect("family");
    let (st, _) = call(&app, "DELETE", &format!("/v1/auth/sessions/{family}"), Some(&customer), None).await;
    assert_eq!(st, StatusCode::NOT_FOUND, "no cross-account revoke");
}
