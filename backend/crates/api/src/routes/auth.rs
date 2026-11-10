use crate::{
    auth::{self, Role},
    error::{ApiError, ApiResult},
    state::AppState,
};
use axum::{Json, Router, extract::State, routing::post};
use chrono::{Duration, Utc};
use serde::{Deserialize, Serialize};
use subtle::ConstantTimeEq;
use uuid::Uuid;

const OTP_TTL_MIN: i64 = 5;
const OTP_MAX_ATTEMPTS: i32 = 5;
const OTP_MAX_PER_HOUR: i64 = 5;
const OTP_GLOBAL_PER_HOUR: i64 = 3_000;
const STAFF_MAX_FAILURES: i32 = 5;
const MAX_PASSWORD_BYTES: usize = 256;
const STAFF_DUMMY_HASH: &str = "$argon2id$v=19$m=19456,t=2,p=1$c2FsdHNhbHRzYWx0$0000000000000000000000000000000000000000000";

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/auth/otp", post(request_otp))
        .route("/auth/verify", post(verify_otp))
        .route("/auth/refresh", post(refresh))
        .route("/auth/logout", post(logout))
        .route("/auth/staff/login", post(staff_login))
}

#[derive(Deserialize, Clone, Copy, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
enum Audience {
    Customer,
    Partner,
}

#[derive(Deserialize)]
struct OtpRequest {
    phone: String,
}

#[derive(Serialize)]
struct OtpSent {
    expires_in: i64,
    /// Only in dev mode, so the apps can auto-fill during local testing.
    #[serde(skip_serializing_if = "Option::is_none")]
    dev_code: Option<String>,
}

async fn request_otp(State(s): State<AppState>, Json(req): Json<OtpRequest>) -> ApiResult<Json<OtpSent>> {
    let phone = auth::normalize_phone(&req.phone).ok_or(ApiError::BadRequest("invalid_phone"))?;
    let recent: i64 = sqlx::query_scalar("SELECT count(*) FROM otp_codes WHERE phone = $1 AND created_at > now() - interval '1 hour'")
        .bind(&phone)
        .fetch_one(&s.db)
        .await?;
    // Global ceiling too: stops SMS-pumping across many numbers (cost + table growth).
    let global: i64 = sqlx::query_scalar("SELECT count(*) FROM otp_codes WHERE created_at > now() - interval '1 hour'")
        .fetch_one(&s.db)
        .await?;
    if recent >= OTP_MAX_PER_HOUR || global >= OTP_GLOBAL_PER_HOUR {
        return Err(ApiError::RateLimited);
    }
    let code = auth::otp_code();
    sqlx::query("INSERT INTO otp_codes (phone, code_hash, expires_at) VALUES ($1, $2, $3)")
        .bind(&phone)
        .bind(auth::otp_hash(&s.config.jwt_secret, &phone, &code))
        .bind(Utc::now() + Duration::minutes(OTP_TTL_MIN))
        .execute(&s.db)
        .await?;
    s.providers
        .send_sms(&phone, &format!("[인증번호] {code}"))
        .await
        .map_err(|e| ApiError::Internal(e.to_string()))?;
    Ok(Json(OtpSent {
        expires_in: OTP_TTL_MIN * 60,
        dev_code: s.config.dev_mode.then_some(code),
    }))
}

#[derive(Deserialize)]
struct VerifyRequest {
    phone: String,
    code: String,
    audience: Audience,
}

#[derive(Serialize)]
pub struct Tokens {
    access_token: String,
    refresh_token: String,
    role: Role,
    subject: Uuid,
    is_new: bool,
}

async fn issue_tokens(s: &AppState, id: Uuid, role: Role, is_new: bool) -> ApiResult<Tokens> {
    let (refresh_token, hash) = auth::new_refresh_token();
    sqlx::query("INSERT INTO refresh_tokens (token_hash, subject, role, expires_at) VALUES ($1, $2, $3, $4)")
        .bind(hash)
        .bind(id)
        .bind(role.as_str())
        .bind(Utc::now() + Duration::days(auth::REFRESH_TTL_DAYS))
        .execute(&s.db)
        .await?;
    Ok(Tokens {
        access_token: auth::issue_access(&s.config.jwt_secret, id, role)?,
        refresh_token,
        role,
        subject: id,
        is_new,
    })
}

async fn verify_otp(State(s): State<AppState>, Json(req): Json<VerifyRequest>) -> ApiResult<Json<Tokens>> {
    let phone = auth::normalize_phone(&req.phone).ok_or(ApiError::BadRequest("invalid_phone"))?;
    // Count the attempt *before* comparing, atomically: parallel guesses can't share one budget.
    let row: Option<String> = sqlx::query_scalar(
        "UPDATE otp_codes SET attempts = attempts + 1
         WHERE id = (SELECT id FROM otp_codes WHERE phone = $1 AND expires_at > now() ORDER BY created_at DESC LIMIT 1)
           AND attempts < $2
         RETURNING code_hash",
    )
    .bind(&phone)
    .bind(OTP_MAX_ATTEMPTS)
    .fetch_optional(&s.db)
    .await?;
    let stored = row.ok_or(ApiError::BadRequest("otp_expired"))?;
    let given = auth::otp_hash(&s.config.jwt_secret, &phone, req.code.trim());
    if !bool::from(given.as_bytes().ct_eq(stored.as_bytes())) {
        return Err(ApiError::BadRequest("otp_invalid"));
    }
    // Single use: only the request that deletes the code proceeds.
    let consumed = sqlx::query("DELETE FROM otp_codes WHERE phone = $1 AND code_hash = $2")
        .bind(&phone)
        .bind(&stored)
        .execute(&s.db)
        .await?;
    if consumed.rows_affected() == 0 {
        return Err(ApiError::BadRequest("otp_expired"));
    }

    let (table, role) = match req.audience {
        Audience::Customer => ("users", Role::Customer),
        Audience::Partner => ("pros", Role::Pro),
    };
    // Upsert keeps sign-up and login a single step; xmax = 0 means the row was inserted.
    let (id, is_new): (Uuid, bool) = sqlx::query_as(&format!(
        "INSERT INTO {table} (phone) VALUES ($1) ON CONFLICT (phone) DO UPDATE SET phone = EXCLUDED.phone RETURNING id, (xmax = 0)"
    ))
    .bind(&phone)
    .fetch_one(&s.db)
    .await?;
    if role == Role::Pro && is_new {
        sqlx::query("INSERT INTO partner_prefs (pro_id) VALUES ($1) ON CONFLICT DO NOTHING")
            .bind(id)
            .execute(&s.db)
            .await?;
        sqlx::query("INSERT INTO team_members (pro_id, name, phone, role, invite_status) VALUES ($1, '', $2, 'owner', 'active')")
            .bind(id)
            .bind(&phone)
            .execute(&s.db)
            .await?;
    }
    Ok(Json(issue_tokens(&s, id, role, is_new).await?))
}

#[derive(Deserialize)]
struct RefreshRequest {
    refresh_token: String,
}

async fn refresh(State(s): State<AppState>, Json(req): Json<RefreshRequest>) -> ApiResult<Json<Tokens>> {
    let hash = auth::sha256_hex(req.refresh_token.as_bytes());
    // Rotation: the old token is revoked atomically as it is used.
    let row: Option<(Uuid, String)> = sqlx::query_as(
        "UPDATE refresh_tokens SET revoked_at = now() WHERE token_hash = $1 AND revoked_at IS NULL AND expires_at > now() RETURNING subject, role",
    )
    .bind(hash)
    .fetch_optional(&s.db)
    .await?;
    let (id, role) = row.ok_or(ApiError::Unauthorized)?;
    let role = Role::parse(&role).ok_or(ApiError::Unauthorized)?;
    ensure_active(&s, id, role).await?;
    Ok(Json(issue_tokens(&s, id, role, false).await?))
}

/// Deleted customers and deactivated staff can't keep a session alive.
/// (Suspended pros may sign in: the app shows them why they can't work.)
async fn ensure_active(s: &AppState, id: Uuid, role: Role) -> ApiResult<()> {
    let ok: bool = match role {
        Role::Customer => sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM users WHERE id = $1 AND deleted_at IS NULL)"),
        Role::Pro => sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM pros WHERE id = $1)"),
        Role::StaffAdmin | Role::StaffConsultant => sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM staff WHERE id = $1 AND active)"),
    }
    .bind(id)
    .fetch_one(&s.db)
    .await?;
    if ok { Ok(()) } else { Err(ApiError::Unauthorized) }
}

async fn logout(State(s): State<AppState>, Json(req): Json<RefreshRequest>) -> ApiResult<Json<serde_json::Value>> {
    sqlx::query("UPDATE refresh_tokens SET revoked_at = now() WHERE token_hash = $1")
        .bind(auth::sha256_hex(req.refresh_token.as_bytes()))
        .execute(&s.db)
        .await?;
    Ok(Json(serde_json::json!({ "ok": true })))
}

#[derive(Deserialize)]
struct StaffLogin {
    email: String,
    password: String,
}

async fn staff_login(State(s): State<AppState>, Json(req): Json<StaffLogin>) -> ApiResult<Json<Tokens>> {
    if req.password.len() > MAX_PASSWORD_BYTES {
        return Err(ApiError::Unauthorized);
    }
    let row: Option<(Uuid, String, String, bool)> =
        sqlx::query_as("SELECT id, password_hash, role, COALESCE(locked_until > now(), FALSE) FROM staff WHERE lower(email) = lower($1) AND active")
            .bind(req.email.trim())
            .fetch_optional(&s.db)
            .await?;
    if row.as_ref().is_some_and(|r| r.3) {
        return Err(ApiError::RateLimited);
    }
    // Verify against a dummy hash when the account is missing to keep timing uniform.
    let hash = row.as_ref().map(|r| r.1.clone()).unwrap_or_else(|| STAFF_DUMMY_HASH.to_string());
    let ok = auth::verify_password_blocking(req.password, hash).await?;
    if let (Some(r), false) = (&row, ok) {
        // Lock the account for a while after repeated failures (online guessing).
        sqlx::query(
            "UPDATE staff SET failed_logins = CASE WHEN failed_logins + 1 >= $2 THEN 0 ELSE failed_logins + 1 END,
               locked_until = CASE WHEN failed_logins + 1 >= $2 THEN now() + interval '15 minutes' ELSE locked_until END
             WHERE id = $1",
        )
        .bind(r.0)
        .bind(STAFF_MAX_FAILURES)
        .execute(&s.db)
        .await?;
    }
    let (id, _, role, _) = row.filter(|_| ok).ok_or(ApiError::Unauthorized)?;
    sqlx::query("UPDATE staff SET failed_logins = 0, locked_until = NULL WHERE id = $1")
        .bind(id)
        .execute(&s.db)
        .await?;
    let role = if role == "admin" { Role::StaffAdmin } else { Role::StaffConsultant };
    Ok(Json(issue_tokens(&s, id, role, false).await?))
}
