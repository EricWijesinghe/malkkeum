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
    if recent >= OTP_MAX_PER_HOUR {
        return Err(ApiError::RateLimited);
    }
    let code = auth::otp_code();
    sqlx::query("INSERT INTO otp_codes (phone, code_hash, expires_at) VALUES ($1, $2, $3)")
        .bind(&phone)
        .bind(auth::otp_hash(&s.config.jwt_secret, &phone, &code))
        .bind(Utc::now() + Duration::minutes(OTP_TTL_MIN))
        .execute(&s.db)
        .await?;
    s.providers.send_sms(&phone, &format!("[인증번호] {code}")).await.map_err(|e| ApiError::Internal(e.to_string()))?;
    Ok(Json(OtpSent { expires_in: OTP_TTL_MIN * 60, dev_code: s.config.dev_mode.then_some(code) }))
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
    Ok(Tokens { access_token: auth::issue_access(&s.config.jwt_secret, id, role)?, refresh_token, role, subject: id, is_new })
}

async fn verify_otp(State(s): State<AppState>, Json(req): Json<VerifyRequest>) -> ApiResult<Json<Tokens>> {
    let phone = auth::normalize_phone(&req.phone).ok_or(ApiError::BadRequest("invalid_phone"))?;
    let row: Option<(Uuid, String, i32)> = sqlx::query_as(
        "SELECT id, code_hash, attempts FROM otp_codes WHERE phone = $1 AND expires_at > now() ORDER BY created_at DESC LIMIT 1",
    )
    .bind(&phone)
    .fetch_optional(&s.db)
    .await?;
    let (otp_id, stored, attempts) = row.ok_or(ApiError::BadRequest("otp_expired"))?;
    if attempts >= OTP_MAX_ATTEMPTS {
        return Err(ApiError::RateLimited);
    }
    let given = auth::otp_hash(&s.config.jwt_secret, &phone, req.code.trim());
    if !bool::from(given.as_bytes().ct_eq(stored.as_bytes())) {
        sqlx::query("UPDATE otp_codes SET attempts = attempts + 1 WHERE id = $1").bind(otp_id).execute(&s.db).await?;
        return Err(ApiError::BadRequest("otp_invalid"));
    }
    sqlx::query("DELETE FROM otp_codes WHERE phone = $1").bind(&phone).execute(&s.db).await?;

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
        sqlx::query("INSERT INTO partner_prefs (pro_id) VALUES ($1) ON CONFLICT DO NOTHING").bind(id).execute(&s.db).await?;
        sqlx::query("INSERT INTO team_members (pro_id, name, phone, role, invite_status) VALUES ($1, '', $2, 'owner', 'active')").bind(id).bind(&phone).execute(&s.db).await?;
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
    Ok(Json(issue_tokens(&s, id, role, false).await?))
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
    let row: Option<(Uuid, String, String)> = sqlx::query_as("SELECT id, password_hash, role FROM staff WHERE lower(email) = lower($1) AND active")
        .bind(req.email.trim())
        .fetch_optional(&s.db)
        .await?;
    // Verify against a dummy hash when the account is missing to keep timing uniform.
    let hash = row.as_ref().map(|r| r.1.as_str()).unwrap_or(STAFF_DUMMY_HASH);
    let ok = auth::verify_password(&req.password, hash);
    let (id, _, role) = row.filter(|_| ok).ok_or(ApiError::Unauthorized)?;
    let role = if role == "admin" { Role::StaffAdmin } else { Role::StaffConsultant };
    Ok(Json(issue_tokens(&s, id, role, false).await?))
}
