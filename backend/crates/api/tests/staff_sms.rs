//! Staff invites and SMS-code password resets over the real router: single use, expiry, guess limit, resend
//! cooldown and daily cap, role limits, and session revocation. Needs DATABASE_URL (sqlx::test).

mod common;

use api::auth::{self, Role};
use axum::{Router, http::StatusCode};
use common::{SECRET, call};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

const OLD: &str = "old-staff-password-1";
const NEW: &str = "fresh-staff-password-2";
const PHONE: &str = "010-1234-5678";

async fn insert(db: &PgPool, email: &str, role: &str, phone: Option<&str>) -> Uuid {
    sqlx::query_scalar("INSERT INTO staff (email, name, password_hash, role, phone) VALUES ($1, 'Test', $2, $3, $4) RETURNING id")
        .bind(email)
        .bind(auth::hash_password(OLD).expect("hash"))
        .bind(role)
        .bind(phone)
        .fetch_one(db)
        .await
        .expect("insert")
}

fn admin_token(id: Uuid) -> String {
    auth::issue_access(SECRET, id, Role::StaffAdmin).expect("admin token")
}

async fn login(app: &Router, email: &str, password: &str) -> (StatusCode, Value) {
    call(app, "POST", "/v1/auth/staff/login", None, Some(json!({ "email": email, "password": password }))).await
}

/// Issues a reset with the copy channel so the test can read the code.
async fn reset_code(app: &Router, admin: &str, staff: Uuid) -> (StatusCode, Value) {
    call(
        app,
        "POST",
        &format!("/v1/admin/staff/{staff}/password-reset"),
        Some(admin),
        Some(json!({ "channel": "copy" })),
    )
    .await
}

async fn redeem(app: &Router, phone: &str, code: &str, password: &str) -> (StatusCode, Value) {
    call(
        app,
        "POST",
        "/v1/auth/staff/code/redeem",
        None,
        Some(json!({ "phone": phone, "code": code, "password": password })),
    )
    .await
}

fn code_of(body: &Value) -> String {
    body["code"].as_str().expect("code in copy-channel response").to_string()
}

#[sqlx::test(migrations = "../../migrations")]
async fn reset_code_sets_new_password_once_and_signs_out_everywhere(db: PgPool) {
    let target = insert(&db, "consultant-reset@test.local", "consultant", Some(PHONE)).await;
    let admin = insert(&db, "admin-reset@test.local", "admin", None).await;
    let app = common::app(db);
    let admin_tok = admin_token(admin);

    let (_, before) = login(&app, "consultant-reset@test.local", OLD).await;
    let refresh = before["refresh_token"].as_str().unwrap().to_string();

    let (st, b) = reset_code(&app, &admin_tok, target).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let code = code_of(&b);
    let (st, b) = redeem(&app, PHONE, &code, NEW).await;
    assert_eq!(st, StatusCode::OK, "{b}");

    assert_eq!(
        login(&app, "consultant-reset@test.local", OLD).await.0,
        StatusCode::UNAUTHORIZED,
        "old password is dead"
    );
    assert_eq!(login(&app, "consultant-reset@test.local", NEW).await.0, StatusCode::OK, "new password works");
    let (st, _) = call(&app, "POST", "/v1/auth/refresh", None, Some(json!({ "refresh_token": refresh }))).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "existing sessions are revoked");

    let (st, b) = redeem(&app, PHONE, &code, "another-staff-password-3").await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "a code works once: {b}");
    assert_eq!(b["error"]["code"], json!("code_invalid"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn invite_creates_an_inactive_staff_who_activates_by_redeeming(db: PgPool) {
    let admin = insert(&db, "admin-invite@test.local", "admin", None).await;
    let app = common::app(db.clone());
    let admin_tok = admin_token(admin);

    let (st, b) = call(
        &app,
        "POST",
        "/v1/admin/staff/invite",
        Some(&admin_tok),
        Some(json!({
            "email": "New.Hire@Test.local", "name": "김지은", "phone": PHONE, "role": "consultant", "channel": "copy"
        })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert_eq!(b["expires_in"], json!(24 * 60 * 60));
    let code = code_of(&b);
    assert_eq!(
        login(&app, "new.hire@test.local", "").await.0,
        StatusCode::UNAUTHORIZED,
        "no password before redeem"
    );

    let (st, b) = call(
        &app,
        "POST",
        &format!("/v1/admin/staff/{}/active", b["id"].as_str().unwrap()),
        Some(&admin_tok),
        Some(json!({ "active": true })),
    )
    .await;
    assert_eq!(st, StatusCode::CONFLICT, "an unredeemed invite cannot be switched on by hand: {b}");
    assert_eq!(b["error"]["code"], json!("invite_pending"));

    let (st, b) = redeem(&app, PHONE, &code, NEW).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert_eq!(
        login(&app, "new.hire@test.local", NEW).await.0,
        StatusCode::OK,
        "invited account signs in after redeem"
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn consultant_can_invite_a_consultant_but_not_an_admin(db: PgPool) {
    let consultant = insert(&db, "consultant-caller@test.local", "consultant", None).await;
    let token = auth::issue_access(SECRET, consultant, Role::StaffConsultant).expect("token");
    let app = common::app(db);

    let (st, _) = call(
        &app,
        "POST",
        "/v1/admin/staff/invite",
        Some(&token),
        Some(json!({
            "email": "a@test.local", "name": "박", "phone": "01011112222", "role": "admin", "channel": "copy"
        })),
    )
    .await;
    assert_eq!(st, StatusCode::FORBIDDEN);

    let (st, b) = call(
        &app,
        "POST",
        "/v1/admin/staff/invite",
        Some(&token),
        Some(json!({
            "email": "b@test.local", "name": "박", "phone": "01033334444", "role": "consultant", "channel": "copy"
        })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn wrong_guesses_burn_the_code(db: PgPool) {
    let target = insert(&db, "consultant-guess@test.local", "consultant", Some(PHONE)).await;
    let admin = insert(&db, "admin-guess@test.local", "admin", None).await;
    let app = common::app(db);
    let (_, b) = reset_code(&app, &admin_token(admin), target).await;
    let code = code_of(&b);
    let wrong = if code == "000000" { "111111" } else { "000000" };

    for _ in 0..5 {
        let (st, _) = redeem(&app, PHONE, wrong, NEW).await;
        assert_eq!(st, StatusCode::BAD_REQUEST);
    }
    let (st, b) = redeem(&app, PHONE, &code, NEW).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "the right code is refused after five misses: {b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn expired_code_is_refused(db: PgPool) {
    let target = insert(&db, "consultant-expired@test.local", "consultant", Some(PHONE)).await;
    let admin = insert(&db, "admin-expired@test.local", "admin", None).await;
    let app = common::app(db.clone());
    let (_, b) = reset_code(&app, &admin_token(admin), target).await;
    let code = code_of(&b);
    sqlx::query("UPDATE staff_sms_codes SET expires_at = now() - interval '1 minute' WHERE staff_id = $1")
        .bind(target)
        .execute(&db)
        .await
        .expect("expire");

    let (st, b) = redeem(&app, PHONE, &code, NEW).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{b}");
    assert_eq!(b["error"]["code"], json!("code_invalid"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn resend_is_cooled_down_and_capped_per_day(db: PgPool) {
    let target = insert(&db, "consultant-resend@test.local", "consultant", Some(PHONE)).await;
    let admin = insert(&db, "admin-resend@test.local", "admin", None).await;
    let app = common::app(db.clone());
    let tok = admin_token(admin);

    assert_eq!(reset_code(&app, &tok, target).await.0, StatusCode::OK);
    let (st, b) = reset_code(&app, &tok, target).await;
    assert_eq!(st, StatusCode::TOO_MANY_REQUESTS, "{b}");

    sqlx::query("UPDATE staff_sms_codes SET created_at = now() - interval '2 hours' WHERE staff_id = $1")
        .bind(target)
        .execute(&db)
        .await
        .expect("age codes");
    sqlx::query("INSERT INTO staff_sms_codes (staff_id, purpose, code_hash, expires_at, created_at) SELECT $1, 'reset', 'x', now() + interval '1 day', now() - interval '3 hours' FROM generate_series(1, 4)")
        .bind(target)
        .execute(&db)
        .await
        .expect("fill daily cap");
    let (st, b) = reset_code(&app, &tok, target).await;
    assert_eq!(st, StatusCode::TOO_MANY_REQUESTS, "daily cap of five codes: {b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn reset_needs_a_phone_and_saves_the_one_given(db: PgPool) {
    let target = insert(&db, "consultant-nophone@test.local", "consultant", None).await;
    let admin = insert(&db, "admin-nophone@test.local", "admin", None).await;
    let app = common::app(db);
    let tok = admin_token(admin);
    let uri = format!("/v1/admin/staff/{target}/password-reset");

    let (st, b) = call(&app, "POST", &uri, Some(&tok), Some(json!({ "channel": "copy" }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST);
    assert_eq!(b["error"]["code"], json!("no_phone"));

    let (st, b) = call(&app, "POST", &uri, Some(&tok), Some(json!({ "channel": "copy", "phone": PHONE }))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (st, b) = redeem(&app, PHONE, &code_of(&b), NEW).await;
    assert_eq!(st, StatusCode::OK, "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn duplicate_phone_is_refused(db: PgPool) {
    insert(&db, "holder@test.local", "consultant", Some(PHONE)).await;
    let admin = insert(&db, "admin-dup@test.local", "admin", None).await;
    let app = common::app(db);
    let (st, b) = call(
        &app,
        "POST",
        "/v1/admin/staff/invite",
        Some(&admin_token(admin)),
        Some(json!({
            "email": "dup@test.local", "name": "중복", "phone": PHONE, "role": "consultant", "channel": "copy"
        })),
    )
    .await;
    assert_eq!(st, StatusCode::CONFLICT, "{b}");
    assert_eq!(b["error"]["code"], json!("phone_taken"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn only_staff_issue_codes_and_consultants_cannot_reset(db: PgPool) {
    let target = insert(&db, "target-auth@test.local", "consultant", Some(PHONE)).await;
    let consultant = insert(&db, "consultant-caller@test.local", "consultant", None).await;
    let token = auth::issue_access(SECRET, consultant, Role::StaffConsultant).expect("token");
    let app = common::app(db);
    let (st, _) = call(&app, "POST", &format!("/v1/admin/staff/{target}/password-reset"), Some(&token), Some(json!({}))).await;
    assert_eq!(st, StatusCode::FORBIDDEN);
}
