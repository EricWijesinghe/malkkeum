//! Staff second factor: TOTP enrolment, sign-in verification, and one-time recovery codes.
//! Every step after the password runs on a short-lived MFA challenge token, never on an access token.

use super::auth::issue_tokens;
use crate::{
    auth::{self, Role, Staff},
    crypto,
    error::{ApiError, ApiResult},
    lockout,
    state::AppState,
    totp,
};
use axum::{
    Json, Router,
    extract::{ConnectInfo, State},
    http::HeaderMap,
    routing::post,
};
use chrono::Utc;
use data_encoding::BASE32_NOPAD;
use rand::{RngCore, rngs::OsRng};
use serde::Deserialize;
use serde_json::{Value, json};
use std::net::SocketAddr;
use uuid::Uuid;

const RECOVERY_CODE_COUNT: usize = 10;
const RECOVERY_CODE_BYTES: usize = 10;
const MAX_MFA_FAILURES: i32 = 5;
const LOCK_MINUTES: i32 = 15;
/// How long a step-up proves a second factor for sensitive actions.
pub const STEP_UP_MINUTES: i32 = 5;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/auth/staff/mfa/enrol", post(enrol_start))
        .route("/auth/staff/mfa/enrol/confirm", post(enrol_confirm))
        .route("/auth/staff/mfa/verify", post(verify))
        .route("/auth/staff/mfa/step-up", post(step_up))
}

#[derive(Deserialize)]
struct MfaInput {
    mfa_token: String,
    code: Option<String>,
    recovery_code: Option<String>,
}

/// Staff row as the MFA steps read it: (email, role, totp enabled, totp_last_step, locked, active, encrypted secret).
type StaffRow = (String, String, bool, Option<i64>, bool, bool, Option<String>);

async fn load(s: &AppState, id: Uuid) -> ApiResult<StaffRow> {
    let row: Option<StaffRow> = sqlx::query_as(
        "SELECT email, role, totp_enabled_at IS NOT NULL, totp_last_step, COALESCE(locked_until > now(), FALSE), active, totp_secret
         FROM staff WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(&s.db)
    .await?;
    let row = row.ok_or(ApiError::Unauthorized)?;
    if !row.5 {
        return Err(ApiError::Unauthorized);
    }
    if row.4 {
        return Err(ApiError::RateLimited);
    }
    Ok(row)
}

fn subject(s: &AppState, token: &str) -> ApiResult<Uuid> {
    auth::verify_mfa(&s.config.jwt_keys(), token)
}

/// Starts (or restarts, before confirmation) enrolment. Refused once TOTP is active, so a password alone
/// can never replace the second factor.
async fn enrol_start(State(s): State<AppState>, Json(req): Json<MfaInput>) -> ApiResult<Json<Value>> {
    let id = subject(&s, &req.mfa_token)?;
    let (email, _, enabled, _, _, _, _) = load(&s, id).await?;
    if enabled {
        return Err(ApiError::Conflict("mfa_already_enabled"));
    }
    let secret = totp::new_secret();
    sqlx::query("UPDATE staff SET totp_secret = $2 WHERE id = $1 AND totp_enabled_at IS NULL")
        .bind(id)
        .bind(crypto::encrypt(&s.config.data_key, crypto::aad::STAFF_TOTP, &totp::encode_secret(&secret)))
        .execute(&s.db)
        .await?;
    Ok(Json(json!({
        "secret": totp::encode_secret(&secret),
        "otpauth_uri": totp::otpauth_uri("Dahae staff", &email, &secret),
    })))
}

/// Confirms the first code, turns TOTP on, and returns the recovery codes once (only hashes are stored).
async fn enrol_confirm(State(s): State<AppState>, Json(req): Json<MfaInput>) -> ApiResult<Json<Value>> {
    let id = subject(&s, &req.mfa_token)?;
    let (_, role, enabled, _, _, _, secret) = load(&s, id).await?;
    if enabled {
        return Err(ApiError::Conflict("mfa_already_enabled"));
    }
    let secret = secret
        .and_then(|enc| crypto::decrypt(&s.config.data_key, crypto::aad::STAFF_TOTP, &enc))
        .and_then(|b32| totp::decode_secret(&b32))
        .ok_or(ApiError::BadRequest("mfa_not_started"))?;
    let step = totp::verify(&secret, req.code.unwrap_or_default().trim(), Utc::now().timestamp(), None).ok_or(ApiError::BadRequest("mfa_invalid_code"))?;

    let codes: Vec<String> = (0..RECOVERY_CODE_COUNT).map(|_| recovery_code()).collect();
    let mut tx = s.db.begin().await?;
    // Only the request that flips the flag proceeds.
    let flipped = sqlx::query("UPDATE staff SET totp_enabled_at = now(), totp_last_step = $2 WHERE id = $1 AND totp_enabled_at IS NULL")
        .bind(id)
        .bind(step)
        .execute(&mut *tx)
        .await?;
    if flipped.rows_affected() == 0 {
        return Err(ApiError::Conflict("mfa_already_enabled"));
    }
    sqlx::query("DELETE FROM staff_recovery_codes WHERE staff_id = $1")
        .bind(id)
        .execute(&mut *tx)
        .await?;
    for c in &codes {
        sqlx::query("INSERT INTO staff_recovery_codes (staff_id, code_hash) VALUES ($1, $2)")
            .bind(id)
            .bind(auth::sha256_hex(normalize(c).as_bytes()))
            .execute(&mut *tx)
            .await?;
    }
    tx.commit().await?;
    let mut tokens = session_tokens(&s, id, &role).await?;
    tokens["recovery_codes"] = json!(codes);
    Ok(Json(tokens))
}

/// Second factor at sign-in: a TOTP code (each step accepted once) or one unused recovery code.
async fn verify(
    State(s): State<AppState>,
    ConnectInfo(peer): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    Json(req): Json<MfaInput>,
) -> ApiResult<Json<Value>> {
    let id = subject(&s, &req.mfa_token)?;
    let role = prove(&s, peer, &headers, id, req.code, req.recovery_code).await?;
    Ok(Json(session_tokens(&s, id, &role).await?))
}

#[derive(Deserialize)]
struct StepUpInput {
    code: Option<String>,
    recovery_code: Option<String>,
}

/// Signed-in staff proves a second factor for one sensitive action. Sign-in does not count.
async fn step_up(
    State(s): State<AppState>,
    ConnectInfo(peer): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    Staff(st): Staff,
    Json(req): Json<StepUpInput>,
) -> ApiResult<Json<Value>> {
    prove(&s, peer, &headers, st.id, req.code, req.recovery_code).await?;
    sqlx::query("UPDATE staff SET stepup_at = now() WHERE id = $1")
        .bind(st.id)
        .execute(&s.db)
        .await?;
    super::audit(&s.db, "staff", Some(st.id), "staff.stepup", "staff", json!({})).await?;
    Ok(Json(json!({ "ok": true, "valid_minutes": STEP_UP_MINUTES })))
}

/// Sensitive staff actions (customer export and deletion, payouts) need a step-up within STEP_UP_MINUTES.
/// Skipped only when second factors are off, which config allows solely in DEV_MODE (local demo kits).
pub async fn require_recent_stepup(s: &AppState, id: Uuid) -> ApiResult<()> {
    if !s.config.staff_mfa_required {
        return Ok(());
    }
    let fresh: bool = sqlx::query_scalar(
        "SELECT COALESCE(stepup_at > now() - make_interval(mins => $2), FALSE) FROM staff WHERE id = $1 AND active",
    )
    .bind(id)
    .bind(STEP_UP_MINUTES)
    .fetch_optional(&s.db)
    .await?
    .unwrap_or(false);
    if fresh { Ok(()) } else { Err(ApiError::StepUpRequired) }
}

/// Checks a TOTP or recovery code for the staff member, with lockout and replay protection. Returns the stored role.
async fn prove(s: &AppState, peer: SocketAddr, headers: &HeaderMap, id: Uuid, code: Option<String>, recovery_code: Option<String>) -> ApiResult<String> {
    let (email, role, enabled, last_step, locked, _, secret) = load(s, id).await?;
    // A challenge issued before the lock must not finish sign-in while the account is locked.
    if locked {
        return Err(ApiError::RateLimited);
    }
    if !enabled {
        return Err(ApiError::Unauthorized);
    }
    let keys = lockout::keys("staff", lockout::ip_of(s, peer, headers), &email);
    s.lockout.delay(&keys).await?;
    s.lockout.check(&keys).await?;
    let accepted = factor_accepted(s, id, secret, last_step, code, recovery_code).await?;
    if !accepted {
        if s.lockout.failure(&keys).await? {
            crate::ops::auth_abuse(&s.db, "mfa_lockout").await;
        }
        record_failure(s, id).await?;
        return Err(ApiError::BadRequest("mfa_invalid_code"));
    }
    sqlx::query("UPDATE staff SET failed_logins = 0, locked_until = NULL WHERE id = $1")
        .bind(id)
        .execute(&s.db)
        .await?;
    s.lockout.success(&keys).await?;
    Ok(role)
}

async fn factor_accepted(
    s: &AppState,
    id: Uuid,
    secret: Option<String>,
    last_step: Option<i64>,
    code: Option<String>,
    recovery_code: Option<String>,
) -> ApiResult<bool> {
    Ok(match (code, recovery_code) {
        (Some(code), _) => {
            let secret = secret
                .and_then(|enc| crypto::decrypt(&s.config.data_key, crypto::aad::STAFF_TOTP, &enc))
                .and_then(|b32| totp::decode_secret(&b32));
            match secret.and_then(|k| totp::verify(&k, code.trim(), Utc::now().timestamp(), last_step)) {
                // The step is burnt atomically: parallel submissions of one code cannot both pass.
                Some(step) => {
                    sqlx::query("UPDATE staff SET totp_last_step = $2 WHERE id = $1 AND (totp_last_step IS NULL OR totp_last_step < $2)")
                        .bind(id)
                        .bind(step)
                        .execute(&s.db)
                        .await?
                        .rows_affected()
                        == 1
                }
                None => false,
            }
        }
        (None, Some(rc)) => {
            sqlx::query("UPDATE staff_recovery_codes SET used_at = now() WHERE staff_id = $1 AND code_hash = $2 AND used_at IS NULL")
                .bind(id)
                .bind(auth::sha256_hex(normalize(&rc).as_bytes()))
                .execute(&s.db)
                .await?
                .rows_affected()
                == 1
        }
        (None, None) => return Err(ApiError::BadRequest("mfa_invalid_code")),
    })
}

/// Failed second factors count against the same lockout as passwords.
async fn record_failure(s: &AppState, id: Uuid) -> ApiResult<()> {
    sqlx::query(
        "UPDATE staff SET failed_logins = CASE WHEN failed_logins + 1 >= $2 THEN 0 ELSE failed_logins + 1 END,
           locked_until = CASE WHEN failed_logins + 1 >= $2 THEN now() + make_interval(mins => $3) ELSE locked_until END
         WHERE id = $1",
    )
    .bind(id)
    .bind(MAX_MFA_FAILURES)
    .bind(LOCK_MINUTES)
    .execute(&s.db)
    .await?;
    super::audit(&s.db, "staff", Some(id), "staff.mfa_failed", "staff", json!({})).await?;
    Ok(())
}

async fn session_tokens(s: &AppState, id: Uuid, role: &str) -> ApiResult<Value> {
    let role = if role == "admin" { Role::StaffAdmin } else { Role::StaffConsultant };
    let tokens = issue_tokens(s, id, role, false, None).await?;
    serde_json::to_value(tokens).map_err(|e| ApiError::Internal(e.to_string()))
}

/// Random recovery code shown once, grouped for reading: XXXX-XXXX-XXXX-XXXX.
fn recovery_code() -> String {
    let mut bytes = [0u8; RECOVERY_CODE_BYTES];
    OsRng.fill_bytes(&mut bytes);
    let raw = BASE32_NOPAD.encode(&bytes);
    raw.as_bytes()
        .chunks(4)
        .map(|c| std::str::from_utf8(c).unwrap_or_default())
        .collect::<Vec<_>>()
        .join("-")
}

/// Input form does not matter: case, spaces and dashes are ignored.
fn normalize(code: &str) -> String {
    code.chars().filter(|c| c.is_ascii_alphanumeric()).map(|c| c.to_ascii_uppercase()).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn recovery_codes_are_grouped_and_normalise_back() {
        let code = recovery_code();
        assert_eq!(code.len(), 19, "{code}");
        assert_eq!(code.matches('-').count(), 3);
        assert_eq!(normalize(&code.to_lowercase()), normalize(&code));
        assert!(normalize(&code).chars().all(|c| c.is_ascii_uppercase() || c.is_ascii_digit()));
    }

    #[test]
    fn codes_differ() {
        assert_ne!(recovery_code(), recovery_code());
    }
}
