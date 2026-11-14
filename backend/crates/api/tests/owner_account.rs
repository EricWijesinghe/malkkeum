//! Owner account over the real router and a migrated database: the owner gate (live flag, per-request TOTP,
//! single-use steps), claim and transfer, recovery codes, alert number, password, sign-out-everywhere,
//! and the server-issued reset after a lost second factor. Needs DATABASE_URL (sqlx::test).

mod common;

use api::{auth, owner, totp};
use axum::{
    Router,
    body::Body,
    extract::ConnectInfo,
    http::{Request, StatusCode, header},
};
use chrono::Utc;
use common::call;
use serde_json::{Value, json};
use sqlx::PgPool;
use std::net::SocketAddr;
use tower::ServiceExt;
use uuid::Uuid;

const PASSWORD: &str = "owner-password-123";
const NEW_PASSWORD: &str = "owner-password-456-new";

/// An enrolled, confirmed staff member: id, access token, TOTP secret, refresh token, the recovery codes shown at enrolment.
struct Staff {
    id: Uuid,
    token: String,
    secret: Vec<u8>,
    refresh: String,
    recovery: Vec<String>,
}

async fn insert_staff(db: &PgPool, email: &str, role: &str, is_owner: bool) -> Uuid {
    let hash = auth::hash_password(PASSWORD).expect("hash");
    sqlx::query_scalar("INSERT INTO staff (email, name, password_hash, role, is_owner) VALUES ($1, 'Test', $2, $3, $4) RETURNING id")
        .bind(email)
        .bind(hash)
        .bind(role)
        .bind(is_owner)
        .fetch_one(db)
        .await
        .expect("insert staff")
}

async fn password_step(app: &Router, email: &str, password: &str) -> (StatusCode, Value) {
    call(app, "POST", "/v1/auth/staff/login", None, Some(json!({ "email": email, "password": password }))).await
}

/// Enrols TOTP and confirms the recovery codes, so the owner gates open. Returns the signed-in staff member.
async fn enrolled(db: &PgPool, app: &Router, email: &str, is_owner: bool) -> Staff {
    let id = insert_staff(db, email, "admin", is_owner).await;
    let (_, b) = password_step(app, email, PASSWORD).await;
    assert_eq!(b["mfa_enrol_required"], json!(true), "{b}");
    let mfa = b["mfa_token"].as_str().unwrap().to_string();
    let (st, e) = call(app, "POST", "/v1/auth/staff/mfa/enrol", None, Some(json!({ "mfa_token": mfa }))).await;
    assert_eq!(st, StatusCode::OK, "{e}");
    let secret = totp::decode_secret(e["secret"].as_str().unwrap()).unwrap();
    let (st, c) = call(
        app,
        "POST",
        "/v1/auth/staff/mfa/enrol/confirm",
        None,
        Some(json!({ "mfa_token": mfa, "code": now_code(&secret) })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{c}");
    let token = c["access_token"].as_str().unwrap().to_string();
    let refresh = c["refresh_token"].as_str().unwrap().to_string();
    let recovery = recovery_codes(&c);
    let (st, _) = confirm_codes(app, &token, &recovery[0]).await;
    assert_eq!(st, StatusCode::OK);
    // Enrolment burnt the current step; the tests reset it when they need a fresh code.
    Staff {
        id,
        token,
        secret,
        refresh,
        recovery,
    }
}

fn recovery_codes(body: &Value) -> Vec<String> {
    body["recovery_codes"]
        .as_array()
        .expect("recovery codes")
        .iter()
        .map(|c| c.as_str().unwrap().to_string())
        .collect()
}

/// Owner confirms the recovery codes by typing one of them back.
async fn confirm_codes(app: &Router, token: &str, code: &str) -> (StatusCode, Value) {
    call(app, "POST", "/v1/admin/me/recovery-codes/confirm", Some(token), Some(json!({ "code": code }))).await
}

fn now_code(secret: &[u8]) -> String {
    format!("{:06}", totp::code_at(secret, (Utc::now().timestamp() / totp::STEP_SECS) as u64))
}

/// A code for the current step, with the replay mark cleared so the request can use it.
async fn fresh(db: &PgPool, staff: &Staff) -> String {
    sqlx::query("UPDATE staff SET totp_last_step = NULL WHERE id = $1")
        .bind(staff.id)
        .execute(db)
        .await
        .expect("reset step");
    now_code(&staff.secret)
}

/// One request with the owner's TOTP in `X-Owner-Totp` (or none when `totp` is None).
async fn owner_call(app: &Router, method: &str, uri: &str, token: &str, totp: Option<&str>, body: Option<Value>) -> (StatusCode, Value) {
    let mut req = Request::builder()
        .method(method)
        .uri(uri)
        .header(header::AUTHORIZATION, format!("Bearer {token}"));
    if let Some(code) = totp {
        req = req.header(owner::OWNER_TOTP_HEADER, code);
    }
    let payload = match body {
        Some(v) => {
            req = req.header(header::CONTENT_TYPE, "application/json");
            Body::from(v.to_string())
        }
        None => Body::empty(),
    };
    let mut request = req.body(payload).expect("request");
    request.extensions_mut().insert(ConnectInfo(SocketAddr::from(([127, 0, 0, 1], 40_000))));
    let resp = app.clone().oneshot(request).await.expect("router is infallible");
    let status = resp.status();
    let bytes = axum::body::to_bytes(resp.into_body(), usize::MAX).await.expect("body");
    (status, serde_json::from_slice(&bytes).unwrap_or(Value::Null))
}

async fn is_owner(db: &PgPool, id: Uuid) -> bool {
    sqlx::query_scalar("SELECT is_owner FROM staff WHERE id = $1")
        .bind(id)
        .fetch_one(db)
        .await
        .expect("row")
}

const PHONE_CALL: (&str, &str) = ("PUT", "/v1/admin/me/alert-phone");

#[sqlx::test(migrations = "../../migrations")]
async fn non_owner_admin_is_refused_on_owner_routes(db: PgPool) {
    let app = common::app(db.clone());
    let staff = enrolled(&db, &app, "plain@test.local", false).await;
    let code = fresh(&db, &staff).await;
    let (st, b) = owner_call(
        &app,
        PHONE_CALL.0,
        PHONE_CALL.1,
        &staff.token,
        Some(code.as_str()),
        Some(json!({ "phone": "010-1234-5678" })),
    )
    .await;
    assert_eq!(st, StatusCode::FORBIDDEN, "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn consultant_cannot_read_owner_account(db: PgPool) {
    let id = insert_staff(&db, "consult@test.local", "consultant", false).await;
    let token = auth::issue_access(common::SECRET, id, auth::Role::StaffConsultant).expect("token");
    let (st, _) = call(&common::app(db), "GET", "/v1/admin/me/account", Some(token.as_str()), None).await;
    assert_eq!(st, StatusCode::FORBIDDEN);
}

#[sqlx::test(migrations = "../../migrations")]
async fn owner_request_needs_a_totp_each_time(db: PgPool) {
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "owner1@test.local", true).await;
    let body = Some(json!({ "phone": "010-1234-5678" }));
    let (st, b) = owner_call(&app, PHONE_CALL.0, PHONE_CALL.1, &owner.token, None, body.clone()).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::BAD_REQUEST, Some("totp_required")), "missing TOTP: {b}");
    let (st, b) = owner_call(&app, PHONE_CALL.0, PHONE_CALL.1, &owner.token, Some("000000"), body.clone()).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::BAD_REQUEST, Some("totp_invalid")), "wrong TOTP: {b}");
    let code = fresh(&db, &owner).await;
    let (st, b) = owner_call(&app, PHONE_CALL.0, PHONE_CALL.1, &owner.token, Some(code.as_str()), body).await;
    assert_eq!(st, StatusCode::OK, "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn owner_totp_step_is_single_use(db: PgPool) {
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "owner2@test.local", true).await;
    let code = fresh(&db, &owner).await;
    let body = Some(json!({ "phone": "010-1234-5678" }));
    let (st, _) = owner_call(&app, PHONE_CALL.0, PHONE_CALL.1, &owner.token, Some(code.as_str()), body.clone()).await;
    assert_eq!(st, StatusCode::OK);
    let (st, b) = owner_call(&app, PHONE_CALL.0, PHONE_CALL.1, &owner.token, Some(code.as_str()), body).await;
    assert_eq!(st, StatusCode::CONFLICT, "a spent code is told apart from a wrong one: {b}");
    assert_eq!(b["error"]["code"], json!("totp_reused"), "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn owner_gates_stay_shut_until_recovery_codes_are_confirmed(db: PgPool) {
    let app = common::app(db.clone());
    let id = insert_staff(&db, "owner3@test.local", "admin", true).await;
    let (_, b) = password_step(&app, "owner3@test.local", PASSWORD).await;
    let mfa = b["mfa_token"].as_str().unwrap().to_string();
    let (_, e) = call(&app, "POST", "/v1/auth/staff/mfa/enrol", None, Some(json!({ "mfa_token": mfa }))).await;
    let secret = totp::decode_secret(e["secret"].as_str().unwrap()).unwrap();
    let (_, c) = call(
        &app,
        "POST",
        "/v1/auth/staff/mfa/enrol/confirm",
        None,
        Some(json!({ "mfa_token": mfa, "code": now_code(&secret) })),
    )
    .await;
    let token = c["access_token"].as_str().unwrap().to_string();
    let recovery = recovery_codes(&c);
    let staff = Staff {
        id,
        token: token.clone(),
        secret,
        refresh: String::new(),
        recovery: recovery.clone(),
    };
    let code = fresh(&db, &staff).await;
    let body = Some(json!({ "phone": "010-1234-5678" }));
    let (st, b) = owner_call(&app, PHONE_CALL.0, PHONE_CALL.1, &token, Some(code.as_str()), body.clone()).await;
    assert_eq!(st, StatusCode::CONFLICT, "codes not confirmed yet: {b}");
    let (st, _) = confirm_codes(&app, &token, &recovery[0]).await;
    assert_eq!(st, StatusCode::OK);
    let code = fresh(&db, &staff).await;
    let (st, _) = owner_call(&app, PHONE_CALL.0, PHONE_CALL.1, &token, Some(code.as_str()), body).await;
    assert_eq!(st, StatusCode::OK);
}

#[sqlx::test(migrations = "../../migrations")]
async fn demoted_owner_is_refused_on_the_live_flag(db: PgPool) {
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "owner4@test.local", true).await;
    sqlx::query("UPDATE staff SET is_owner = FALSE WHERE id = $1")
        .bind(owner.id)
        .execute(&db)
        .await
        .expect("demote");
    let code = fresh(&db, &owner).await;
    let (st, _) = owner_call(
        &app,
        PHONE_CALL.0,
        PHONE_CALL.1,
        &owner.token,
        Some(code.as_str()),
        Some(json!({ "phone": "010-1234-5678" })),
    )
    .await;
    assert_eq!(st, StatusCode::FORBIDDEN, "token still says admin, the row says no");
}

#[sqlx::test(migrations = "../../migrations")]
async fn sign_out_everywhere_kills_tokens_and_refresh(db: PgPool) {
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "owner5@test.local", true).await;
    let code = fresh(&db, &owner).await;
    let (st, _) = owner_call(&app, "POST", "/v1/admin/me/sign-out-all", &owner.token, Some(code.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    let (st, _) = call(&app, "GET", "/v1/admin/me/account", Some(owner.token.as_str()), None).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "access token from before the epoch bump");
    let (st, _) = call(&app, "POST", "/v1/auth/refresh", None, Some(json!({ "refresh_token": owner.refresh }))).await;
    assert_ne!(st, StatusCode::OK, "refresh token is revoked");
}

#[sqlx::test(migrations = "../../migrations")]
async fn claim_is_allowed_only_while_no_owner_exists(db: PgPool) {
    let app = common::app(db.clone());
    let first = enrolled(&db, &app, "claim1@test.local", false).await;
    let second = enrolled(&db, &app, "claim2@test.local", false).await;

    let code = fresh(&db, &first).await;
    let (st, b) = owner_call(&app, "POST", "/v1/admin/owner/claim", &first.token, Some(code.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert!(is_owner(&db, first.id).await);

    let code = fresh(&db, &second).await;
    let (st, b) = owner_call(&app, "POST", "/v1/admin/owner/claim", &second.token, Some(code.as_str()), None).await;
    assert_eq!(st, StatusCode::CONFLICT, "{b}");
    assert!(!is_owner(&db, second.id).await);
}

#[sqlx::test(migrations = "../../migrations")]
async fn claim_needs_an_enrolled_factor(db: PgPool) {
    let app = common::app(db.clone());
    let id = insert_staff(&db, "noclaim@test.local", "admin", false).await;
    let token = auth::issue_access(common::SECRET, id, auth::Role::StaffAdmin).expect("token");
    let (st, b) = owner_call(&app, "POST", "/v1/admin/owner/claim", &token, Some("123456"), None).await;
    assert_eq!(st, StatusCode::CONFLICT, "{b}");
    assert!(!is_owner(&db, id).await);
}

#[sqlx::test(migrations = "../../migrations")]
async fn transfer_needs_both_factors_and_an_active_admin(db: PgPool) {
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "from@test.local", true).await;
    let target = enrolled(&db, &app, "to@test.local", false).await;

    let code = fresh(&db, &owner).await;
    let (st, _) = owner_call(
        &app,
        "POST",
        "/v1/admin/owner/transfer",
        &owner.token,
        Some(code.as_str()),
        Some(json!({ "to": owner.id, "code": "000000" })),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "cannot transfer to self");

    let code = fresh(&db, &owner).await;
    let (st, _) = owner_call(
        &app,
        "POST",
        "/v1/admin/owner/transfer",
        &owner.token,
        Some(code.as_str()),
        Some(json!({ "to": target.id, "code": "000000" })),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "the new owner's factor is wrong");
    assert!(is_owner(&db, owner.id).await, "nothing changed");

    let code = fresh(&db, &owner).await;
    let target_code = fresh(&db, &target).await;
    let (st, b) = owner_call(
        &app,
        "POST",
        "/v1/admin/owner/transfer",
        &owner.token,
        Some(code.as_str()),
        Some(json!({ "to": target.id, "code": target_code })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert!(!is_owner(&db, owner.id).await);
    assert!(is_owner(&db, target.id).await);

    let code = fresh(&db, &owner).await;
    let (st, _) = owner_call(
        &app,
        PHONE_CALL.0,
        PHONE_CALL.1,
        &owner.token,
        Some(code.as_str()),
        Some(json!({ "phone": "010-1234-5678" })),
    )
    .await;
    assert_eq!(st, StatusCode::FORBIDDEN, "the old owner is out");
}

#[sqlx::test(migrations = "../../migrations")]
async fn reissued_recovery_codes_replace_the_old_ones(db: PgPool) {
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "codes@test.local", true).await;
    let old: Vec<String> = sqlx::query_scalar("SELECT code_hash FROM staff_recovery_codes WHERE staff_id = $1")
        .bind(owner.id)
        .fetch_all(&db)
        .await
        .unwrap();
    assert_eq!(old.len(), 10);

    let code = fresh(&db, &owner).await;
    let (st, b) = owner_call(&app, "POST", "/v1/admin/me/recovery-codes", &owner.token, Some(code.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let codes = b["recovery_codes"].as_array().unwrap();
    assert_eq!(codes.len(), 10);
    let fresh_hashes: Vec<String> = sqlx::query_scalar("SELECT code_hash FROM staff_recovery_codes WHERE staff_id = $1")
        .bind(owner.id)
        .fetch_all(&db)
        .await
        .unwrap();
    assert!(old.iter().all(|h| !fresh_hashes.contains(h)), "old codes are gone");
    assert!(fresh_hashes.contains(&owner::code_hash(codes[0].as_str().unwrap())));

    // Until the new codes are confirmed the owner gates stay shut.
    let code = fresh(&db, &owner).await;
    let (st, _) = owner_call(
        &app,
        PHONE_CALL.0,
        PHONE_CALL.1,
        &owner.token,
        Some(code.as_str()),
        Some(json!({ "phone": "010-1234-5678" })),
    )
    .await;
    assert_eq!(st, StatusCode::CONFLICT);
}

#[sqlx::test(migrations = "../../migrations")]
async fn alert_phone_is_validated_masked_and_told_to_the_old_number(db: PgPool) {
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "phone@test.local", true).await;
    let code = fresh(&db, &owner).await;
    let (st, _) = owner_call(
        &app,
        PHONE_CALL.0,
        PHONE_CALL.1,
        &owner.token,
        Some(code.as_str()),
        Some(json!({ "phone": "123" })),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST);

    let code = fresh(&db, &owner).await;
    let (st, b) = owner_call(
        &app,
        PHONE_CALL.0,
        PHONE_CALL.1,
        &owner.token,
        Some(code.as_str()),
        Some(json!({ "phone": "010-1234-5678" })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert_eq!(b["alert_phone_masked"], json!("010-****-5678"));

    // Second change: the number being replaced gets the SMS (dev mode only logs it, so this passes).
    let code = fresh(&db, &owner).await;
    let (st, _) = owner_call(
        &app,
        PHONE_CALL.0,
        PHONE_CALL.1,
        &owner.token,
        Some(code.as_str()),
        Some(json!({ "phone": "010-9999-0000" })),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    let (st, account) = call(&app, "GET", "/v1/admin/me/account", Some(owner.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(account["alert_phone_masked"], json!("010-****-0000"));
    assert_eq!(account["is_owner"], json!(true));
    assert_eq!(account["two_factor_enrolled"], json!(true));
}

#[sqlx::test(migrations = "../../migrations")]
async fn password_change_needs_the_current_password_and_ends_sessions(db: PgPool) {
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "pw@test.local", true).await;
    let code = fresh(&db, &owner).await;
    let (st, _) = owner_call(
        &app,
        "POST",
        "/v1/admin/me/password",
        &owner.token,
        Some(code.as_str()),
        Some(json!({ "current_password": "not-the-one-123", "new_password": NEW_PASSWORD })),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST);

    let code = fresh(&db, &owner).await;
    let (st, b) = owner_call(
        &app,
        "POST",
        "/v1/admin/me/password",
        &owner.token,
        Some(code.as_str()),
        Some(json!({ "current_password": PASSWORD, "new_password": NEW_PASSWORD })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (st, _) = call(&app, "GET", "/v1/admin/me/account", Some(owner.token.as_str()), None).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "the session that changed the password ends too");
    let (st, _) = password_step(&app, "pw@test.local", PASSWORD).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "old password is dead");
    let (st, _) = password_step(&app, "pw@test.local", NEW_PASSWORD).await;
    assert_eq!(st, StatusCode::OK, "new password reaches the second factor");
}

#[sqlx::test(migrations = "../../migrations")]
async fn reset_code_is_single_use_and_clears_the_second_factor(db: PgPool) {
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "lost@test.local", true).await;
    let code = owner::issue_reset_code(&db, owner.id).await.expect("reset code");
    let ttl: f64 = sqlx::query_scalar("SELECT extract(epoch FROM expires_at - created_at)::float8 FROM owner_reset_codes WHERE staff_id = $1")
        .bind(owner.id)
        .fetch_one(&db)
        .await
        .expect("ttl");
    assert!((ttl - 3600.0).abs() < 5.0, "one hour, got {ttl}");

    let reset = json!({ "email": "lost@test.local", "password": PASSWORD, "code": code });
    let (st, b) = call(&app, "POST", "/v1/auth/staff/owner-reset", None, Some(reset.clone())).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let enrolled_now: bool = sqlx::query_scalar("SELECT totp_enabled_at IS NOT NULL FROM staff WHERE id = $1")
        .bind(owner.id)
        .fetch_one(&db)
        .await
        .unwrap();
    assert!(!enrolled_now, "second factor cleared");
    assert!(is_owner(&db, owner.id).await, "owner keeps the role");

    let (st, _) = call(&app, "POST", "/v1/auth/staff/owner-reset", None, Some(reset)).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "the code is single use");

    // Sign-in now asks for enrolment again.
    let (st, b) = password_step(&app, "lost@test.local", PASSWORD).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(b["mfa_enrol_required"], json!(true), "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn reset_code_expires_after_its_hour_and_needs_the_password(db: PgPool) {
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "late@test.local", true).await;
    let code = owner::issue_reset_code(&db, owner.id).await.expect("reset code");
    sqlx::query("UPDATE owner_reset_codes SET expires_at = now() - interval '1 second' WHERE staff_id = $1")
        .bind(owner.id)
        .execute(&db)
        .await
        .unwrap();
    let (st, _) = call(
        &app,
        "POST",
        "/v1/auth/staff/owner-reset",
        None,
        Some(json!({ "email": "late@test.local", "password": PASSWORD, "code": code })),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "expired");

    let code = owner::issue_reset_code(&db, owner.id).await.expect("reset code");
    let (st, _) = call(
        &app,
        "POST",
        "/v1/auth/staff/owner-reset",
        None,
        Some(json!({ "email": "late@test.local", "password": "wrong-password-1", "code": code.clone() })),
    )
    .await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "password is still required");
    let enrolled_now: bool = sqlx::query_scalar("SELECT totp_enabled_at IS NOT NULL FROM staff WHERE id = $1")
        .bind(owner.id)
        .fetch_one(&db)
        .await
        .unwrap();
    assert!(enrolled_now, "a failed attempt changes nothing");
}

#[sqlx::test(migrations = "../../migrations")]
async fn reset_code_is_refused_for_a_non_owner(db: PgPool) {
    let app = common::app(db.clone());
    let plain = enrolled(&db, &app, "notowner@test.local", false).await;
    let code = owner::issue_reset_code(&db, plain.id).await.expect("reset code");
    let (st, _) = call(
        &app,
        "POST",
        "/v1/auth/staff/owner-reset",
        None,
        Some(json!({ "email": "notowner@test.local", "password": PASSWORD, "code": code })),
    )
    .await;
    assert_eq!(st, StatusCode::UNAUTHORIZED);
}

#[sqlx::test(migrations = "../../migrations")]
async fn setup_marks_the_first_admin_as_owner(db: PgPool) {
    api::routes::setup::ensure_setup_code(&db, Some("OWNERSET2026")).await.expect("setup code");
    let app = common::app(db.clone());
    let (st, b) = call(
        &app,
        "POST",
        "/v1/setup/admin",
        None,
        Some(json!({ "code": "OWNERSET2026", "email": "first@test.local", "name": "First", "password": "Dahae-first-owner-2026" })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let flag: bool = sqlx::query_scalar("SELECT is_owner FROM staff WHERE email = 'first@test.local'")
        .fetch_one(&db)
        .await
        .unwrap();
    assert!(flag);
}

#[sqlx::test(migrations = "../../migrations")]
async fn owner_cannot_be_deactivated_by_another_admin(db: PgPool) {
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "keep-owner@test.local", true).await;
    let other = enrolled(&db, &app, "other-admin@test.local", false).await;
    let (st, b) = call(
        &app,
        "POST",
        &format!("/v1/admin/staff/{}/active", owner.id),
        Some(other.token.as_str()),
        Some(json!({ "active": false })),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{b}");
    assert_eq!(b["error"]["code"], json!("owner_cannot_deactivate"));
    let active: bool = sqlx::query_scalar("SELECT active FROM staff WHERE id = $1")
        .bind(owner.id)
        .fetch_one(&db)
        .await
        .expect("row");
    assert!(active, "the owner stays active");
    assert!(is_owner(&db, owner.id).await);
}

#[sqlx::test(migrations = "../../migrations")]
async fn making_an_admin_needs_the_owner_code(db: PgPool) {
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "make-owner@test.local", true).await;
    let plain = enrolled(&db, &app, "make-plain@test.local", false).await;
    let new_admin = json!({ "email": "new-admin@test.local", "name": "New Admin", "role": "admin", "password": "Dahae-new-admin-2026" });
    let (st, b) = call(&app, "POST", "/v1/admin/staff", Some(plain.token.as_str()), Some(new_admin.clone())).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "{b}");
    let (st, b) = owner_call(&app, "POST", "/v1/admin/staff", &owner.token, None, Some(new_admin.clone())).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "no owner code: {b}");
    let code = fresh(&db, &owner).await;
    let (st, b) = owner_call(&app, "POST", "/v1/admin/staff", &owner.token, Some(code.as_str()), Some(new_admin)).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let consultant = json!({ "email": "consult-new@test.local", "name": "Consult", "role": "consultant", "password": "Dahae-consult-2026" });
    let (st, b) = call(&app, "POST", "/v1/admin/staff", Some(plain.token.as_str()), Some(consultant)).await;
    assert_eq!(st, StatusCode::OK, "consultants need no owner code: {b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn owner_password_reset_is_refused_to_others_and_needs_the_owner_code(db: PgPool) {
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "reset-owner@test.local", true).await;
    let other = enrolled(&db, &app, "reset-other@test.local", false).await;
    let uri = format!("/v1/admin/staff/{}/password-reset", owner.id);
    let (st, b) = call(&app, "POST", &uri, Some(other.token.as_str()), None).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "{b}");
    let (st, b) = owner_call(&app, "POST", &uri, &owner.token, None, None).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "no owner code: {b}");
    let code = fresh(&db, &owner).await;
    let (st, b) = owner_call(&app, "POST", &uri, &owner.token, Some(code.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn claim_releases_an_inactive_owner_slot(db: PgPool) {
    let app = common::app(db.clone());
    let old = enrolled(&db, &app, "old-owner@test.local", true).await;
    let heir = enrolled(&db, &app, "heir@test.local", false).await;
    sqlx::query("UPDATE staff SET active = FALSE WHERE id = $1")
        .bind(old.id)
        .execute(&db)
        .await
        .expect("deactivate");
    let code = fresh(&db, &heir).await;
    let (st, b) = owner_call(&app, "POST", "/v1/admin/owner/claim", &heir.token, Some(code.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert!(is_owner(&db, heir.id).await);
    assert!(!is_owner(&db, old.id).await, "the inactive row no longer holds the flag");
}

#[sqlx::test(migrations = "../../migrations")]
async fn live_check_refuses_a_staff_token_from_before_sign_out(db: PgPool) {
    // The websocket upgrade and the extractors share this check: a socket must not outlive a sign-out.
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "ws-owner@test.local", true).await;
    let keys = [common::SECRET];
    assert!(auth::verify_access_live(&db, &keys, &owner.token).await.is_ok(), "a live session passes");
    let code = fresh(&db, &owner).await;
    let (st, _) = owner_call(&app, "POST", "/v1/admin/me/sign-out-all", &owner.token, Some(code.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    assert!(auth::verify_access_live(&db, &keys, &owner.token).await.is_err(), "the old token is refused");
}

#[sqlx::test(migrations = "../../migrations")]
async fn lost_reissue_reply_can_be_retried(db: PgPool) {
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "retry-owner@test.local", true).await;
    let code = fresh(&db, &owner).await;
    let (st, first) = owner_call(&app, "POST", "/v1/admin/me/recovery-codes", &owner.token, Some(code.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{first}");
    // The reply never arrived: the owner asks again with a fresh code and gets a working set.
    let code = fresh(&db, &owner).await;
    let (st, second) = owner_call(&app, "POST", "/v1/admin/me/recovery-codes", &owner.token, Some(code.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{second}");
    let new_codes = recovery_codes(&second);
    assert_ne!(recovery_codes(&first), new_codes);
    let (st, _) = confirm_codes(&app, &owner.token, &new_codes[0]).await;
    assert_eq!(st, StatusCode::OK);
    let code = fresh(&db, &owner).await;
    let (st, b) = owner_call(
        &app,
        PHONE_CALL.0,
        PHONE_CALL.1,
        &owner.token,
        Some(code.as_str()),
        Some(json!({ "phone": "010-1234-5678" })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "gates open once the new set is confirmed: {b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn confirming_needs_a_current_recovery_code(db: PgPool) {
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "confirm-owner@test.local", true).await;
    let old = owner.recovery.clone();
    let code = fresh(&db, &owner).await;
    let (st, b) = owner_call(&app, "POST", "/v1/admin/me/recovery-codes", &owner.token, Some(code.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let new_codes = recovery_codes(&b);
    let (st, b) = confirm_codes(&app, &owner.token, "AAAA-AAAA-AAAA-AAAA").await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "a made-up code is refused: {b}");
    assert_eq!(b["error"]["code"], json!("recovery_code_invalid"));
    let (st, b) = confirm_codes(&app, &owner.token, &old[0]).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "codes from before the reissue are gone: {b}");
    let (st, b) = confirm_codes(&app, &owner.token, &new_codes[0]).await;
    assert_eq!(st, StatusCode::OK, "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn wrong_current_password_does_not_spend_the_code(db: PgPool) {
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "typo-owner@test.local", true).await;
    let code = fresh(&db, &owner).await;
    let body = |current: &str| Some(json!({ "current_password": current, "new_password": NEW_PASSWORD }));
    let (st, _) = owner_call(
        &app,
        "POST",
        "/v1/admin/me/password",
        &owner.token,
        Some(code.as_str()),
        body("not-the-one-123"),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST);
    let (st, b) = owner_call(&app, "POST", "/v1/admin/me/password", &owner.token, Some(code.as_str()), body(PASSWORD)).await;
    assert_eq!(st, StatusCode::OK, "the same code still works after a typo: {b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn transfer_to_a_non_admin_spends_no_code(db: PgPool) {
    let app = common::app(db.clone());
    let owner = enrolled(&db, &app, "keep-code-owner@test.local", true).await;
    let consultant = insert_staff(&db, "consultant-target@test.local", "consultant", false).await;
    let code = fresh(&db, &owner).await;
    let (st, b) = owner_call(
        &app,
        "POST",
        "/v1/admin/owner/transfer",
        &owner.token,
        Some(code.as_str()),
        Some(json!({ "to": consultant, "code": "000000" })),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{b}");
    assert_eq!(b["error"]["code"], json!("owner_target_invalid"));
    let (st, b) = owner_call(
        &app,
        PHONE_CALL.0,
        PHONE_CALL.1,
        &owner.token,
        Some(code.as_str()),
        Some(json!({ "phone": "010-1234-5678" })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "the refused transfer left the code unspent: {b}");
}
