//! Owner (소유자) gates. The owner is the one staff admin who changes accounts, staff roles and host settings.
//! Every owner-only request carries a fresh TOTP in `X-Owner-Totp`; that step is burnt like a sign-in code,
//! so one code authorises one request. The owner flag is read live, never from the token.

use crate::{
    auth::{self, Auth, Role},
    crypto,
    error::{ApiError, ApiResult},
    lockout,
    state::AppState,
    totp,
};
use axum::{
    extract::{ConnectInfo, FromRequestParts},
    http::{HeaderMap, request::Parts},
};
use chrono::Utc;
use data_encoding::BASE32_NOPAD;
use rand::{RngCore, rngs::OsRng};
use sqlx::{PgPool, Postgres, Transaction};
use std::net::{IpAddr, SocketAddr};
use uuid::Uuid;

pub const OWNER_TOTP_HEADER: &str = "x-owner-totp";
pub const RECOVERY_CODE_COUNT: usize = 10;
/// One-time reset codes live one hour (`api owner-reset`).
pub const RESET_CODE_TTL_MIN: i32 = 60;
const RECOVERY_CODE_BYTES: usize = 10;

/// Owner-only request: an admin token, the live owner flag, and a TOTP for this request.
#[derive(Debug, Clone, Copy)]
pub struct OwnerTotp(pub Auth);

impl FromRequestParts<AppState> for OwnerTotp {
    type Rejection = ApiError;
    async fn from_request_parts(parts: &mut Parts, state: &AppState) -> Result<Self, Self::Rejection> {
        let auth = Auth::from_request_parts(parts, state).await?;
        let peer = parts.extensions.get::<ConnectInfo<SocketAddr>>().map(|c| c.0.ip());
        verify_owner(state, auth, &parts.headers, peer, true).await?;
        Ok(Self(auth))
    }
}

/// Owner request that needs only an enrolled authenticator, not confirmed codes. Used to replace the recovery
/// codes, so an owner who lost the set (or whose reply was lost) can always get a new one.
#[derive(Debug, Clone, Copy)]
pub struct OwnerEnrolledTotp(pub Auth);

impl FromRequestParts<AppState> for OwnerEnrolledTotp {
    type Rejection = ApiError;
    async fn from_request_parts(parts: &mut Parts, state: &AppState) -> Result<Self, Self::Rejection> {
        let auth = Auth::from_request_parts(parts, state).await?;
        let peer = parts.extensions.get::<ConnectInfo<SocketAddr>>().map(|c| c.0.ip());
        verify_owner(state, auth, &parts.headers, peer, false).await?;
        Ok(Self(auth))
    }
}

/// Live owner flag of an active staff row.
pub async fn is_owner(db: &PgPool, staff: Uuid) -> ApiResult<bool> {
    Ok(sqlx::query_scalar("SELECT is_owner FROM staff WHERE id = $1 AND active")
        .bind(staff)
        .fetch_optional(db)
        .await?
        .unwrap_or(false))
}

/// The TOTP sent with an owner request. Missing is 400 `totp_required`; a 401 would read as an expired session.
pub fn owner_code(headers: &HeaderMap) -> ApiResult<String> {
    headers
        .get(OWNER_TOTP_HEADER)
        .and_then(|v| v.to_str().ok())
        .map(|v| v.trim().to_string())
        .filter(|v| !v.is_empty())
        .ok_or(ApiError::BadRequest("totp_required"))
}

/// Client address for lockout keys (forwarded headers count only behind a trusted proxy).
pub fn client_ip(s: &AppState, peer: Option<IpAddr>, headers: &HeaderMap) -> IpAddr {
    let fwd = headers.get("x-forwarded-for").and_then(|v| v.to_str().ok());
    lockout::request_ip(s.config.trusted_proxy, peer, fwd)
}

/// Owner gate for a handler that must validate its input first: checks the live flag and the request's TOTP
/// without spending the step. The handler calls `burn_totp` once its own checks pass, so a typo does not cost a code.
pub async fn check_owner(s: &AppState, auth: Auth, headers: &HeaderMap, peer: Option<IpAddr>, require_confirmed: bool) -> ApiResult<i64> {
    if auth.role != Role::StaffAdmin || !is_owner(&s.db, auth.id).await? {
        return Err(ApiError::Forbidden);
    }
    let code = owner_code(headers)?;
    check_totp(s, auth.id, &code, client_ip(s, peer, headers), require_confirmed).await
}

/// Owner gate that spends the request's TOTP at once. Handlers with nothing to validate use it.
pub async fn verify_owner(s: &AppState, auth: Auth, headers: &HeaderMap, peer: Option<IpAddr>, require_confirmed: bool) -> ApiResult<()> {
    let step = check_owner(s, auth, headers, peer, require_confirmed).await?;
    burn_totp(s, auth.id, client_ip(s, peer, headers), step).await
}

/// Checks a TOTP for `staff` without spending it. Refused until the factor is enrolled (and, when
/// `require_confirmed`, the recovery codes are confirmed). A valid code whose step was already spent is 409.
pub async fn check_totp(s: &AppState, staff: Uuid, code: &str, ip: IpAddr, require_confirmed: bool) -> ApiResult<i64> {
    let keys = lockout::keys("owner", ip, &staff.to_string());
    s.lockout.delay(&keys).await?;
    s.lockout.check(&keys).await?;
    let row: Option<(Option<String>, Option<i64>, bool, bool)> = sqlx::query_as(
        "SELECT totp_secret, totp_last_step, totp_enabled_at IS NOT NULL, recovery_confirmed_at IS NOT NULL
         FROM staff WHERE id = $1 AND active",
    )
    .bind(staff)
    .fetch_optional(&s.db)
    .await?;
    let (secret, last_step, enrolled, confirmed) = row.ok_or(ApiError::Unauthorized)?;
    if !enrolled || (require_confirmed && !confirmed) {
        return Err(ApiError::Conflict("second_factor_required"));
    }
    let secret = secret
        .and_then(|enc| crypto::decrypt(&s.config.data_key, &enc))
        .and_then(|b32| totp::decode_secret(&b32))
        .ok_or(ApiError::Unauthorized)?;
    let Some(step) = totp::verify(&secret, code.trim(), Utc::now().timestamp(), None) else {
        s.lockout.failure(&keys).await?;
        return Err(ApiError::BadRequest("totp_invalid"));
    };
    if last_step.is_some_and(|last| step <= last) {
        return Err(ApiError::Conflict("totp_reused"));
    }
    Ok(step)
}

/// Spends a step checked by `check_totp`. Atomic: two parallel requests with one code cannot both pass.
pub async fn burn_totp(s: &AppState, staff: Uuid, ip: IpAddr, step: i64) -> ApiResult<()> {
    let burnt = sqlx::query("UPDATE staff SET totp_last_step = $2 WHERE id = $1 AND (totp_last_step IS NULL OR totp_last_step < $2)")
        .bind(staff)
        .bind(step)
        .execute(&s.db)
        .await?
        .rows_affected();
    if burnt != 1 {
        return Err(ApiError::Conflict("totp_reused"));
    }
    s.lockout.success(&lockout::keys("owner", ip, &staff.to_string())).await
}

/// Counts a failed owner action (for example a wrong current password) against the owner lockout. The code
/// is not spent by such a failure, so this is what stops guessing within one code's life.
pub async fn record_failure(s: &AppState, staff: Uuid, ip: IpAddr) -> ApiResult<()> {
    s.lockout.failure(&lockout::keys("owner", ip, &staff.to_string())).await.map(|_| ())
}

/// Checks and spends a TOTP for `staff` in one step (claim). Handlers that validate first use the split form.
pub async fn verify_totp(s: &AppState, staff: Uuid, code: &str, ip: IpAddr, require_confirmed: bool) -> ApiResult<()> {
    let step = check_totp(s, staff, code, ip, require_confirmed).await?;
    burn_totp(s, staff, ip, step).await
}

/// Ends every session of a staff member inside `tx`: the epoch moves on (access tokens stop at the next
/// request) and every refresh token is revoked.
pub async fn end_sessions_tx(tx: &mut Transaction<'_, Postgres>, staff: Uuid) -> Result<(), sqlx::Error> {
    sqlx::query("UPDATE staff SET session_epoch = session_epoch + 1 WHERE id = $1")
        .bind(staff)
        .execute(&mut **tx)
        .await?;
    sqlx::query("UPDATE refresh_tokens SET revoked_at = now() WHERE subject = $1 AND revoked_at IS NULL")
        .bind(staff)
        .execute(&mut **tx)
        .await?;
    Ok(())
}

/// Inserts a fresh set of recovery codes (only hashes are stored) and returns them once.
pub async fn insert_recovery_codes(tx: &mut Transaction<'_, Postgres>, staff: Uuid) -> ApiResult<Vec<String>> {
    let codes: Vec<String> = (0..RECOVERY_CODE_COUNT).map(|_| new_code()).collect();
    for code in &codes {
        sqlx::query("INSERT INTO staff_recovery_codes (staff_id, code_hash) VALUES ($1, $2)")
            .bind(staff)
            .bind(code_hash(code))
            .execute(&mut **tx)
            .await?;
    }
    Ok(codes)
}

/// Random code shown once, grouped for reading: XXXX-XXXX-XXXX-XXXX.
pub fn new_code() -> String {
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
pub fn normalize_code(code: &str) -> String {
    code.chars().filter(|c| c.is_ascii_alphanumeric()).map(|c| c.to_ascii_uppercase()).collect()
}

/// Stored form of a code: SHA-256 of its normalised text.
pub fn code_hash(code: &str) -> String {
    auth::sha256_hex(normalize_code(code).as_bytes())
}

/// Masks a Korean mobile number for display: 010-****-5678.
pub fn mask_phone(digits: &str) -> String {
    if digits.len() < 10 || !digits.is_ascii() {
        return "***".into();
    }
    format!("{}-****-{}", &digits[..3], &digits[digits.len() - 4..])
}

/// Issues the one-time reset code for the owner. Earlier unused codes are voided. Only the hash is stored.
pub async fn issue_reset_code(db: &PgPool, staff: Uuid) -> Result<String, sqlx::Error> {
    let code = new_code();
    let mut tx = db.begin().await?;
    sqlx::query("UPDATE owner_reset_codes SET used_at = now() WHERE staff_id = $1 AND used_at IS NULL")
        .bind(staff)
        .execute(&mut *tx)
        .await?;
    sqlx::query("INSERT INTO owner_reset_codes (staff_id, code_hash, expires_at) VALUES ($1, $2, now() + make_interval(mins => $3))")
        .bind(staff)
        .bind(code_hash(&code))
        .bind(RESET_CODE_TTL_MIN)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    Ok(code)
}

/// `api owner-reset`: prints a one-time code for the current owner. Run on the server (SSH or the desktop helper).
pub async fn reset_cli() -> i32 {
    let config = match crate::config::Config::from_env() {
        Ok(c) => c,
        Err(e) => return fail(&format!("config: {e}")),
    };
    let db = match sqlx::postgres::PgPoolOptions::new().max_connections(2).connect(&config.database_url).await {
        Ok(db) => db,
        Err(e) => return fail(&format!("database: {e}")),
    };
    if let Err(e) = crate::migrate(&db).await {
        return fail(&format!("migrate: {e}"));
    }
    let owner: Option<(Uuid, String, bool)> = match sqlx::query_as("SELECT id, email, active FROM staff WHERE is_owner").fetch_optional(&db).await {
        Ok(row) => row,
        Err(e) => return fail(&format!("database: {e}")),
    };
    let Some((id, email, active)) = owner else {
        return fail("no owner is set; the owner claims it from the console while no owner exists");
    };
    // The reset sign-in only accepts an active account. Reactivating here is the server operator's call, not an API route.
    if !active && let Err(e) = sqlx::query("UPDATE staff SET active = TRUE WHERE id = $1").bind(id).execute(&db).await {
        return fail(&format!("database: {e}"));
    }
    match issue_reset_code(&db, id).await {
        Ok(code) => {
            if !active {
                println!("the owner account was inactive and has been reactivated");
            }
            println!("owner: {email}");
            println!("reset code: {code}");
            println!("Valid for one hour, one use. Enter it with the owner's password on the sign-in screen.");
            0
        }
        Err(e) => fail(&format!("database: {e}")),
    }
}

fn fail(msg: &str) -> i32 {
    eprintln!("error: {msg}");
    1
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn codes_are_grouped_and_hash_ignores_form() {
        let code = new_code();
        assert_eq!(code.len(), 19, "{code}");
        assert_eq!(code.matches('-').count(), 3);
        assert_eq!(code_hash(&code.to_lowercase()), code_hash(&code.replace('-', " ")));
        assert_ne!(new_code(), new_code());
    }

    #[test]
    fn reset_code_lives_one_hour() {
        assert_eq!(RESET_CODE_TTL_MIN, 60);
    }

    #[test]
    fn phone_is_masked_to_first_three_and_last_four() {
        assert_eq!(mask_phone("01012345678"), "010-****-5678");
        assert_eq!(mask_phone("0101"), "***");
    }

    #[test]
    fn owner_code_header_must_be_present_and_non_empty() {
        let mut h = HeaderMap::new();
        assert!(owner_code(&h).is_err());
        h.insert(OWNER_TOTP_HEADER, "  ".parse().unwrap());
        assert!(owner_code(&h).is_err());
        h.insert(OWNER_TOTP_HEADER, " 123456 ".parse().unwrap());
        assert_eq!(owner_code(&h).unwrap(), "123456");
    }
}
