use crate::{
    auth::{self, Auth, Role},
    crypto,
    error::{ApiError, ApiResult},
    lockout,
    providers::{
        apple,
        social::{self, SocialUser},
    },
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{ConnectInfo, Path, State},
    http::HeaderMap,
    routing::{delete, get, post},
};
use chrono::{Duration, Utc};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use std::net::SocketAddr;
use subtle::ConstantTimeEq;
use uuid::Uuid;

const OTP_TTL_SECS: i64 = 180;
/// Minimum gap between code requests for one number (resend cooldown).
const OTP_RESEND_COOLDOWN_SECS: i64 = 60;
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
        .route("/auth/logout-all", post(logout_all))
        .route("/auth/sessions", get(sessions))
        .route("/auth/sessions/{family}", delete(revoke_session))
        .route("/auth/staff/login", post(staff_login))
        .route("/auth/social", post(social_login))
        .route("/auth/apple/notifications", post(apple_notifications))
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
    /// App language, so the code SMS is readable before any account exists.
    #[serde(default)]
    locale: Option<String>,
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
    let cooling: bool =
        sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM otp_codes WHERE phone = $1 AND created_at > now() - ($2::float8 * interval '1 second'))")
            .bind(&phone)
            .bind(OTP_RESEND_COOLDOWN_SECS)
            .fetch_one(&s.db)
            .await?;
    if recent >= OTP_MAX_PER_HOUR || global >= OTP_GLOBAL_PER_HOUR || cooling {
        return Err(ApiError::RateLimited);
    }
    // Store-review demo number: the owner's fixed code, no SMS (reviewers are abroad).
    let review = super::setup::review_code_hash(&s.db, &phone).await?;
    let code = auth::otp_code();
    let code_hash = review.clone().unwrap_or_else(|| auth::otp_hash(s.config.otp_key(), &phone, &code));
    sqlx::query("INSERT INTO otp_codes (phone, code_hash, expires_at) VALUES ($1, $2, $3)")
        .bind(&phone)
        .bind(code_hash)
        .bind(Utc::now() + Duration::seconds(OTP_TTL_SECS))
        .execute(&s.db)
        .await?;
    if review.is_none() {
        // Inline, not queued: the user is waiting on this code. One quick retry covers a blip (see sms_outbox).
        let text = format!("[{}] {code}", crate::i18n::tr(req.locale.as_deref().unwrap_or("ko"), "인증번호"));
        crate::sms_outbox::retry_once(|| s.providers.send_sms(&phone, &text))
            .await
            .map_err(|e| ApiError::Internal(e.to_string()))?;
    }
    Ok(Json(OtpSent {
        expires_in: OTP_TTL_SECS,
        dev_code: (s.config.dev_mode && review.is_none()).then_some(code),
    }))
}

#[derive(Deserialize)]
struct VerifyRequest {
    phone: String,
    code: String,
    audience: Audience,
    /// First-touch UTM / referral the app captured; only used when the account is created.
    #[serde(default)]
    attribution: Option<Value>,
}

#[derive(Serialize)]
pub struct Tokens {
    access_token: String,
    refresh_token: String,
    role: Role,
    subject: Uuid,
    is_new: bool,
}

/// Issues a token pair. A rotation passes its existing `family`; a fresh sign-in starts a new one.
pub(super) async fn issue_tokens(s: &AppState, id: Uuid, role: Role, is_new: bool, family: Option<Uuid>) -> ApiResult<Tokens> {
    let (refresh_token, hash) = auth::new_refresh_token();
    sqlx::query("INSERT INTO refresh_tokens (token_hash, subject, role, expires_at, family_id) VALUES ($1, $2, $3, $4, $5)")
        .bind(hash)
        .bind(id)
        .bind(role.as_str())
        .bind(Utc::now() + Duration::days(auth::REFRESH_TTL_DAYS))
        .bind(family.unwrap_or_else(Uuid::now_v7))
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

async fn verify_otp(
    State(s): State<AppState>,
    ConnectInfo(peer): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    Json(req): Json<VerifyRequest>,
) -> ApiResult<Json<Tokens>> {
    let phone = auth::normalize_phone(&req.phone).ok_or(ApiError::BadRequest("invalid_phone"))?;
    // Guessing across fresh codes for one number is stopped here, not only by the per-code attempt cap.
    let keys = lockout::keys("otp", lockout::ip_of(&s, peer, &headers), &phone);
    s.lockout.delay(&keys).await?;
    s.lockout.check(&keys).await?;
    match consume_otp(&s, &phone, &req.code).await {
        Ok(()) => s.lockout.success(&keys).await?,
        Err(e @ ApiError::BadRequest(_)) => {
            if s.lockout.failure(&keys).await? {
                crate::ops::auth_abuse(&s.db, "otp_lockout").await;
            }
            return Err(e);
        }
        Err(e) => return Err(e),
    }

    // Partner app: a phone that owns a team logs in as owner; otherwise an invited team member logs in as member.
    let member = if req.audience == Audience::Partner && !owner_phone_exists(&s, &phone).await? {
        member_for_phone(&s, &phone).await?
    } else {
        None
    };
    if let Some(member) = member {
        return Ok(Json(member_login(&s, member).await?));
    }

    let (table, role) = match req.audience {
        Audience::Customer => ("users", Role::Customer),
        Audience::Partner => ("pros", Role::Pro),
    };
    // Upsert keeps sign-up and login a single step; xmax = 0 means the row was inserted.
    let (id, is_new): (Uuid, bool) = match role {
        Role::Customer => {
            sqlx::query_as(
                "INSERT INTO users (phone, acquisition) VALUES ($1, $2) ON CONFLICT (phone) DO UPDATE SET phone = EXCLUDED.phone RETURNING id, (xmax = 0)",
            )
            .bind(&phone)
            .bind(crate::acquisition::clean(req.attribution.as_ref()).map(sqlx::types::Json))
            .fetch_one(&s.db)
            .await?
        }
        _ => {
            sqlx::query_as(&format!(
                "INSERT INTO {table} (phone) VALUES ($1) ON CONFLICT (phone) DO UPDATE SET phone = EXCLUDED.phone RETURNING id, (xmax = 0)"
            ))
            .bind(&phone)
            .fetch_one(&s.db)
            .await?
        }
    };
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
    Ok(Json(issue_tokens(&s, id, role, is_new, None).await?))
}

/// Owner login wins: a phone that already owns a pro account is never treated as a member login.
async fn owner_phone_exists(s: &AppState, phone: &str) -> ApiResult<bool> {
    Ok(sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM pros WHERE phone = $1)")
        .bind(phone)
        .fetch_one(&s.db)
        .await?)
}

/// Newest non-removed member invite for the phone. A phone invited to several teams signs in to the
/// team it used most recently (one session = one team).
async fn member_for_phone(s: &AppState, phone: &str) -> ApiResult<Option<Uuid>> {
    Ok(sqlx::query_scalar(
        "SELECT id FROM team_members WHERE phone = $1 AND role = 'member' AND invite_status <> 'removed'
         ORDER BY last_login_at DESC NULLS LAST, created_at DESC LIMIT 1",
    )
    .bind(phone)
    .fetch_optional(&s.db)
    .await?)
}

/// Member sign-in: the invite becomes active and the session subject is the team_members row.
async fn member_login(s: &AppState, member: Uuid) -> ApiResult<Tokens> {
    let r = sqlx::query("UPDATE team_members SET invite_status = 'active', last_login_at = now() WHERE id = $1 AND invite_status <> 'removed'")
        .bind(member)
        .execute(&s.db)
        .await?;
    // Removed between lookup and update: no session.
    if r.rows_affected() == 0 {
        return Err(ApiError::Unauthorized);
    }
    issue_tokens(s, member, Role::Member, false, None).await
}

/// A phone number proven by a login code, used for sign-in and for binding a phone to an account.
#[derive(Deserialize)]
pub struct PhoneBind {
    pub phone: String,
    pub code: String,
}

/// Checks a login code and burns it: attempts are counted before comparing, and a code works once.
pub async fn consume_otp(s: &AppState, phone: &str, code: &str) -> ApiResult<()> {
    // Count the attempt *before* comparing, atomically: parallel guesses can't share one budget.
    let row: Option<String> = sqlx::query_scalar(
        "UPDATE otp_codes SET attempts = attempts + 1
         WHERE id = (SELECT id FROM otp_codes WHERE phone = $1 AND expires_at > now() ORDER BY created_at DESC LIMIT 1)
           AND attempts < $2
         RETURNING code_hash",
    )
    .bind(phone)
    .bind(OTP_MAX_ATTEMPTS)
    .fetch_optional(&s.db)
    .await?;
    let stored = row.ok_or(ApiError::BadRequest("otp_expired"))?;
    let matches = s
        .config
        .otp_keys()
        .into_iter()
        .any(|key| bool::from(auth::otp_hash(key, phone, code.trim()).as_bytes().ct_eq(stored.as_bytes())));
    if !matches {
        return Err(ApiError::BadRequest("otp_invalid"));
    }
    // Single use: only the request that deletes the code proceeds.
    let consumed = sqlx::query("DELETE FROM otp_codes WHERE phone = $1 AND code_hash = $2")
        .bind(phone)
        .bind(&stored)
        .execute(&s.db)
        .await?;
    if consumed.rows_affected() == 0 {
        return Err(ApiError::BadRequest("otp_expired"));
    }

    Ok(())
}

#[derive(Deserialize)]
struct RefreshRequest {
    refresh_token: String,
}

async fn refresh(State(s): State<AppState>, Json(req): Json<RefreshRequest>) -> ApiResult<Json<Tokens>> {
    let hash = auth::sha256_hex(req.refresh_token.as_bytes());
    // Rotation: the presented token is revoked as it is used, atomically.
    let row: Option<(Uuid, String, Uuid)> = sqlx::query_as(
        "UPDATE refresh_tokens SET revoked_at = now(), rotated_at = now()
         WHERE token_hash = $1 AND revoked_at IS NULL AND expires_at > now() RETURNING subject, role, family_id",
    )
    .bind(&hash)
    .fetch_optional(&s.db)
    .await?;
    let Some((id, role, family)) = row else {
        reject_reuse(&s, &hash).await?;
        return Err(ApiError::Unauthorized);
    };
    let role = Role::parse(&role).ok_or(ApiError::Unauthorized)?;
    ensure_active(&s, id, role).await?;
    Ok(Json(issue_tokens(&s, id, role, false, Some(family)).await?))
}

/// A rotated token presented again means a copy was used: the whole family is revoked, which signs out
/// the thief and the legitimate holder alike.
async fn reject_reuse(s: &AppState, hash: &str) -> ApiResult<()> {
    let reused: Option<(Uuid, Uuid, String)> =
        sqlx::query_as("SELECT subject, family_id, role FROM refresh_tokens WHERE token_hash = $1 AND rotated_at IS NOT NULL")
            .bind(hash)
            .fetch_optional(&s.db)
            .await?;
    if let Some((subject, family, role)) = reused {
        sqlx::query("UPDATE refresh_tokens SET revoked_at = now() WHERE family_id = $1 AND revoked_at IS NULL")
            .bind(family)
            .execute(&s.db)
            .await?;
        super::audit(&s.db, &role, Some(subject), "auth.refresh_reuse", &family.to_string(), json!({})).await?;
        crate::ops::auth_abuse(&s.db, "refresh_reuse").await;
    }
    Ok(())
}

/// Deleted customers and deactivated staff can't keep a session alive.
/// (Suspended pros may sign in: the app shows them why they can't work.)
async fn ensure_active(s: &AppState, id: Uuid, role: Role) -> ApiResult<()> {
    let ok: bool = match role {
        Role::Customer => sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM users WHERE id = $1 AND deleted_at IS NULL)"),
        Role::Pro => sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM pros WHERE id = $1 AND deleted_at IS NULL)"),
        Role::Member => sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM team_members WHERE id = $1 AND role = 'member' AND invite_status <> 'removed')"),
        Role::StaffAdmin | Role::StaffConsultant => sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM staff WHERE id = $1 AND active)"),
    }
    .bind(id)
    .fetch_one(&s.db)
    .await?;
    if ok { Ok(()) } else { Err(ApiError::Unauthorized) }
}

/// Signs out this device: its whole rotation family is revoked.
async fn logout(State(s): State<AppState>, Json(req): Json<RefreshRequest>) -> ApiResult<Json<serde_json::Value>> {
    sqlx::query(
        "UPDATE refresh_tokens SET revoked_at = now() WHERE family_id = (SELECT family_id FROM refresh_tokens WHERE token_hash = $1) AND revoked_at IS NULL",
    )
    .bind(auth::sha256_hex(req.refresh_token.as_bytes()))
    .execute(&s.db)
    .await?;
    Ok(Json(serde_json::json!({ "ok": true })))
}

/// Signs out every device of the caller. Access tokens already issued last at most ACCESS_TTL_MIN.
async fn logout_all(State(s): State<AppState>, a: Auth) -> ApiResult<Json<serde_json::Value>> {
    sqlx::query("UPDATE refresh_tokens SET revoked_at = now() WHERE subject = $1 AND revoked_at IS NULL")
        .bind(a.id)
        .execute(&s.db)
        .await?;
    Ok(Json(serde_json::json!({ "ok": true })))
}

/// One signed-in device: a refresh family that still holds a live token.
#[derive(Serialize)]
struct SessionView {
    session_id: Uuid,
    signed_in_at: chrono::DateTime<Utc>,
    last_refreshed_at: chrono::DateTime<Utc>,
}

/// Signed-in devices of the caller, most recently refreshed first.
async fn sessions(State(s): State<AppState>, a: Auth) -> ApiResult<Json<Value>> {
    let rows: Vec<(Uuid, chrono::DateTime<Utc>, chrono::DateTime<Utc>)> = sqlx::query_as(
        "SELECT family_id, min(created_at), max(created_at) FROM refresh_tokens
         WHERE subject = $1 AND revoked_at IS NULL AND rotated_at IS NULL AND expires_at > now()
         GROUP BY family_id ORDER BY max(created_at) DESC",
    )
    .bind(a.id)
    .fetch_all(&s.db)
    .await?;
    let items: Vec<SessionView> = rows
        .into_iter()
        .map(|(session_id, signed_in_at, last_refreshed_at)| SessionView {
            session_id,
            signed_in_at,
            last_refreshed_at,
        })
        .collect();
    Ok(Json(json!({ "sessions": items })))
}

/// Signs one device out: its whole family is revoked. Another account's family looks like no family.
async fn revoke_session(State(s): State<AppState>, a: Auth, Path(family): Path<Uuid>) -> ApiResult<Json<Value>> {
    let revoked = sqlx::query("UPDATE refresh_tokens SET revoked_at = now() WHERE subject = $1 AND family_id = $2 AND revoked_at IS NULL")
        .bind(a.id)
        .bind(family)
        .execute(&s.db)
        .await?
        .rows_affected();
    if revoked == 0 {
        return Err(ApiError::NotFound);
    }
    Ok(Json(json!({ "ok": true })))
}

#[derive(Deserialize)]
struct StaffLogin {
    email: String,
    password: String,
}

/// Password step. Consultants get tokens; a second factor is required before tokens for enrolled staff and
/// for admins, who must enrol first. Those steps run on a short-lived challenge token (routes/staff_mfa).
async fn staff_login(
    State(s): State<AppState>,
    ConnectInfo(peer): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    Json(req): Json<StaffLogin>,
) -> ApiResult<Json<Value>> {
    if req.password.len() > MAX_PASSWORD_BYTES {
        return Err(ApiError::Unauthorized);
    }
    let keys = lockout::keys("staff", lockout::ip_of(&s, peer, &headers), &req.email);
    s.lockout.delay(&keys).await?;
    s.lockout.check(&keys).await?;
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
    if !ok && s.lockout.failure(&keys).await? {
        crate::ops::auth_abuse(&s.db, "staff_lockout").await;
    }
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
        super::audit(&s.db, "staff", Some(r.0), "staff.login_failed", "staff", json!({})).await?;
    }
    let (id, _, role, _) = row.filter(|_| ok).ok_or(ApiError::Unauthorized)?;
    // Reset the lockout only when tokens are issued here. A password step that leads to a second
    // factor must not reset it, or a password holder could retry codes forever (see staff_mfa).
    let enrolled: bool = sqlx::query_scalar("SELECT totp_enabled_at IS NOT NULL FROM staff WHERE id = $1")
        .bind(id)
        .fetch_one(&s.db)
        .await?;
    if enrolled {
        return Ok(Json(json!({ "mfa_required": true, "mfa_token": auth::issue_mfa(&s.config.jwt_secret, id)? })));
    }
    if role == "admin" && s.config.staff_mfa_required {
        return Ok(Json(
            json!({ "mfa_enrol_required": true, "mfa_token": auth::issue_mfa(&s.config.jwt_secret, id)? }),
        ));
    }
    sqlx::query("UPDATE staff SET failed_logins = 0, locked_until = NULL WHERE id = $1")
        .bind(id)
        .execute(&s.db)
        .await?;
    s.lockout.success(&keys).await?;
    let staff_role = if role == "admin" { Role::StaffAdmin } else { Role::StaffConsultant };
    let tokens = issue_tokens(&s, id, staff_role, false, None).await?;
    Ok(Json(serde_json::to_value(tokens).map_err(|e| ApiError::Internal(e.to_string()))?))
}

/// Maps a unique violation to a 409 with a specific code; any other database error stays internal.
pub fn conflict_on_unique(e: sqlx::Error, code: &'static str) -> ApiError {
    if matches!(&e, sqlx::Error::Database(d) if d.is_unique_violation()) {
        ApiError::Conflict(code)
    } else {
        ApiError::Db(e)
    }
}

const PROVIDERS: [&str; 4] = ["kakao", "naver", "google", "apple"];
const MAX_SOCIAL_TOKEN: usize = 4096;
const IDENTITY_SQL: &str = "SELECT subject_id FROM user_identities WHERE provider = $1 AND provider_user_id = $2 AND role = $3";

#[derive(Deserialize)]
struct SocialLogin {
    provider: String,
    token: String,
    /// Raw nonce the app generated for this sign-in; Apple and Google tokens must echo it when one was requested.
    #[serde(default)]
    nonce: Option<String>,
    /// Apple only: the credential's authorization code. Exchanged for a refresh token that is kept (encrypted)
    /// solely to revoke the sign-in when the account is deleted.
    #[serde(default)]
    authorization_code: Option<String>,
    audience: Audience,
    #[serde(default)]
    attribution: Option<Value>,
}

#[derive(Serialize)]
pub struct SocialTokens {
    #[serde(flatten)]
    tokens: Tokens,
    /// True until the account has a verified phone; the app asks for one before the main flow.
    needs_phone: bool,
}

async fn social_login(State(s): State<AppState>, Json(req): Json<SocialLogin>) -> ApiResult<Json<SocialTokens>> {
    if !PROVIDERS.contains(&req.provider.as_str()) {
        return Err(ApiError::BadRequest("invalid_provider"));
    }
    if req.token.is_empty() || req.token.len() > MAX_SOCIAL_TOKEN {
        return Err(ApiError::BadRequest("invalid_token"));
    }
    let nonce = req.nonce.as_deref().filter(|n| !n.is_empty());
    let social = social::verify(&s.providers, &req.provider, &req.token, nonce).await?;
    let role = match req.audience {
        Audience::Customer => Role::Customer,
        Audience::Partner => Role::Pro,
    };
    let attribution = crate::acquisition::clean(req.attribution.as_ref());
    let (id, is_new) = find_or_create_identity(&s, &req.provider, &social, role, attribution).await?;
    ensure_active(&s, id, role).await?;
    let code = req.authorization_code.as_deref().filter(|c| !c.is_empty() && c.len() <= MAX_SOCIAL_TOKEN);
    let refresh = match (req.provider.as_str(), code) {
        ("apple", Some(code)) => apple::exchange_code(&s.providers, social.audience.as_deref(), code, &social.provider_user_id).await,
        _ => social.refresh_token.clone(),
    };
    if let Some(token) = refresh {
        store_social_token(&s, &req.provider, &social, role, &token).await?;
    }
    let needs_phone = phone_missing(&s, id, role).await?;
    let tokens = issue_tokens(&s, id, role, is_new, None).await?;
    Ok(Json(SocialTokens { tokens, needs_phone }))
}

/// Keeps the newest provider refresh token for the identity, encrypted with DATA_KEY.
async fn store_social_token(s: &AppState, provider: &str, social: &SocialUser, role: Role, token: &str) -> ApiResult<()> {
    sqlx::query(
        "INSERT INTO social_tokens (identity_id, client_id, refresh_token_enc)
         SELECT id, $4, $5 FROM user_identities WHERE provider = $1 AND provider_user_id = $2 AND role = $3
         ON CONFLICT (identity_id) DO UPDATE SET client_id = EXCLUDED.client_id, refresh_token_enc = EXCLUDED.refresh_token_enc, updated_at = now()",
    )
    .bind(provider)
    .bind(&social.provider_user_id)
    .bind(role.as_str())
    .bind(social.audience.as_deref().unwrap_or_default())
    .bind(crypto::encrypt(&s.config.data_key, crypto::aad::SOCIAL_TOKEN, token))
    .execute(&s.db)
    .await?;
    Ok(())
}

/// Largest notification body accepted; Apple's JWS is a few hundred bytes.
const MAX_APPLE_NOTIFICATION: usize = 16 * 1024;

/// The `payload` JWS from Apple's POST: a JSON object `{"payload": ...}`, or the same field form-encoded.
fn apple_payload(body: &[u8]) -> Option<String> {
    if let Ok(v) = serde_json::from_slice::<Value>(body) {
        return v["payload"].as_str().map(str::to_string);
    }
    let text = std::str::from_utf8(body).ok()?;
    let url = reqwest::Url::parse(&format!("http://form.invalid/?{text}")).ok()?;
    url.query_pairs().find(|(k, _)| k == "payload").map(|(_, v)| v.into_owned())
}

/// Sign in with Apple server-to-server notifications (register this URL in the Apple developer account).
/// Unsigned, forged or foreign notifications get 401; a replayed one is acknowledged without acting again.
async fn apple_notifications(State(s): State<AppState>, body: axum::body::Bytes) -> ApiResult<Json<Value>> {
    if body.len() > MAX_APPLE_NOTIFICATION {
        return Err(ApiError::BadRequest("invalid_payload"));
    }
    let jws = apple_payload(&body).filter(|p| !p.is_empty()).ok_or(ApiError::BadRequest("invalid_payload"))?;
    let n = apple::verify_notification(&s.providers, &jws).await?;
    crate::privacy::apple_notification(&s, &n).await?;
    Ok(Json(json!({ "ok": true })))
}

async fn find_identity(s: &AppState, provider: &str, social: &SocialUser, role: Role) -> ApiResult<Option<Uuid>> {
    Ok(sqlx::query_scalar(IDENTITY_SQL)
        .bind(provider)
        .bind(&social.provider_user_id)
        .bind(role.as_str())
        .fetch_optional(&s.db)
        .await?)
}

/// Finds the account behind a provider identity, or creates it with its identity row in one transaction.
async fn find_or_create_identity(s: &AppState, provider: &str, social: &SocialUser, role: Role, attribution: Option<Value>) -> ApiResult<(Uuid, bool)> {
    if let Some(id) = find_identity(s, provider, social, role).await? {
        return Ok((id, false));
    }
    let mut tx = s.db.begin().await?;
    let id: Uuid = if role == Role::Pro {
        sqlx::query_scalar("INSERT INTO pros DEFAULT VALUES RETURNING id").fetch_one(&mut *tx).await?
    } else {
        sqlx::query_scalar("INSERT INTO users (acquisition) VALUES ($1) RETURNING id")
            .bind(attribution.map(sqlx::types::Json))
            .fetch_one(&mut *tx)
            .await?
    };
    let linked =
        sqlx::query("INSERT INTO user_identities (provider, provider_user_id, role, subject_id, email) VALUES ($1,$2,$3,$4,$5) ON CONFLICT DO NOTHING")
            .bind(provider)
            .bind(&social.provider_user_id)
            .bind(role.as_str())
            .bind(id)
            .bind(&social.email)
            .execute(&mut *tx)
            .await?;
    if linked.rows_affected() == 0 {
        // A parallel first sign-in with the same identity won: use its account.
        tx.rollback().await?;
        let existing = find_identity(s, provider, social, role)
            .await?
            .ok_or(ApiError::Internal("identity vanished".into()))?;
        return Ok((existing, false));
    }
    if role == Role::Pro {
        sqlx::query("INSERT INTO partner_prefs (pro_id) VALUES ($1) ON CONFLICT DO NOTHING")
            .bind(id)
            .execute(&mut *tx)
            .await?;
        // Phone is unknown until verified; the owner row takes it when /partner/me/phone succeeds.
        sqlx::query("INSERT INTO team_members (pro_id, name, phone, role, invite_status) VALUES ($1, '', '', 'owner', 'active')")
            .bind(id)
            .execute(&mut *tx)
            .await?;
    }
    tx.commit().await?;
    Ok((id, true))
}

async fn phone_missing(s: &AppState, id: Uuid, role: Role) -> ApiResult<bool> {
    let table = if role == Role::Pro { "pros" } else { "users" };
    let missing: bool = sqlx::query_scalar(&format!("SELECT phone IS NULL FROM {table} WHERE id = $1"))
        .bind(id)
        .fetch_one(&s.db)
        .await?;
    Ok(missing)
}
