//! Owner account: claim and transfer of the owner role, recovery codes, alert number, password,
//! sign out everywhere, and the one-time reset after a lost second factor.
//! Owner-only routes take a TOTP per request (`owner::OwnerTotp`); the claim and transfer take the TOTP directly.

use super::audit;
use crate::{
    auth::{self, Admin, Role, live_staff_role},
    error::{ApiError, ApiResult},
    lockout,
    owner::{self, OwnerEnrolledTotp, OwnerTotp},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{ConnectInfo, State},
    http::HeaderMap,
    routing::{get, post, put},
};
use serde::Deserialize;
use serde_json::{Value, json};
use std::net::SocketAddr;
use uuid::Uuid;

const MAX_PASSWORD_BYTES: usize = 256;
const MAX_CODE_BYTES: usize = 64;

pub fn public_routes() -> Router<AppState> {
    Router::new().route("/auth/staff/owner-reset", post(reset_with_code))
}

pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/owner/claim", post(claim))
        .route("/owner/transfer", post(transfer))
        .route("/me/account", get(account))
        .route("/me/recovery-codes", post(reissue_recovery_codes))
        .route("/me/recovery-codes/confirm", post(confirm_recovery_codes))
        .route("/me/alert-phone", put(set_alert_phone))
        .route("/me/password", post(change_password))
        .route("/me/sign-out-all", post(sign_out_all))
}

/// Owner-facing status for the 내 계정 screen. Never includes a full phone number or any code.
async fn account(State(s): State<AppState>, Admin(a): Admin) -> ApiResult<Json<Value>> {
    let row: Option<(bool, bool, bool, Option<String>, bool)> = sqlx::query_as(
        "SELECT is_owner, totp_enabled_at IS NOT NULL, recovery_confirmed_at IS NOT NULL, alert_phone,
                EXISTS (SELECT 1 FROM staff WHERE is_owner)
         FROM staff WHERE id = $1 AND active",
    )
    .bind(a.id)
    .fetch_optional(&s.db)
    .await?;
    let (is_owner, enrolled, confirmed, phone, owner_exists) = row.ok_or(ApiError::Unauthorized)?;
    let sessions: i64 =
        sqlx::query_scalar("SELECT count(DISTINCT family_id) FROM refresh_tokens WHERE subject = $1 AND revoked_at IS NULL AND expires_at > now()")
            .bind(a.id)
            .fetch_one(&s.db)
            .await?;
    Ok(Json(json!({
        "id": a.id,
        "is_owner": is_owner,
        "owner_exists": owner_exists,
        "two_factor_enrolled": enrolled,
        "recovery_confirmed": confirmed,
        "alert_phone_masked": phone.as_deref().map(owner::mask_phone),
        "active_sessions": sessions,
    })))
}

/// Claims the owner role. Allowed only while no owner exists, and only with the claimant's own TOTP.
async fn claim(State(s): State<AppState>, ConnectInfo(peer): ConnectInfo<SocketAddr>, headers: HeaderMap, Admin(a): Admin) -> ApiResult<Json<Value>> {
    if live_staff_role(&s.db, a.id).await? != Role::StaffAdmin {
        return Err(ApiError::Forbidden);
    }
    let code = owner::owner_code(&headers)?;
    owner::verify_totp(&s, a.id, &code, owner::client_ip(&s, Some(peer.ip()), &headers), true).await?;
    let mut tx = s.db.begin().await?;
    // An owner row left inactive still holds the single-owner slot; release it so the claim can go through.
    sqlx::query("UPDATE staff SET is_owner = FALSE WHERE is_owner AND NOT active")
        .execute(&mut *tx)
        .await?;
    // The partial unique index is the real guard: a racing claim gets 409 from the database.
    let claimed = sqlx::query("UPDATE staff SET is_owner = TRUE WHERE id = $1 AND active AND NOT EXISTS (SELECT 1 FROM staff WHERE is_owner)")
        .bind(a.id)
        .execute(&mut *tx)
        .await
        .map_err(|e| super::auth::conflict_on_unique(e, "owner_exists"))?;
    if claimed.rows_affected() == 0 {
        return Err(ApiError::Conflict("owner_exists"));
    }
    tx.commit().await?;
    audit(&s.db, "staff", Some(a.id), "owner.claimed", &a.id.to_string(), json!({})).await?;
    Ok(Json(json!({ "ok": true })))
}

#[derive(Deserialize)]
struct TransferInput {
    to: Uuid,
    /// The new owner's own TOTP. Both factors are needed: the current owner's in the header, this one here.
    code: String,
}

/// Hands the owner role to another active admin. Both TOTPs are checked, and spent only once the target is
/// known to be valid; the change is one transaction.
async fn transfer(
    State(s): State<AppState>,
    ConnectInfo(peer): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    Admin(a): Admin,
    Json(req): Json<TransferInput>,
) -> ApiResult<Json<Value>> {
    if req.to == a.id {
        return Err(ApiError::BadRequest("owner_transfer_self"));
    }
    let ip = owner::client_ip(&s, Some(peer.ip()), &headers);
    let owner_step = owner::check_owner(&s, a, &headers, Some(peer.ip()), true).await?;
    let target_ok: bool = sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM staff WHERE id = $1 AND role = 'admin' AND active AND NOT is_owner)")
        .bind(req.to)
        .fetch_one(&s.db)
        .await?;
    if !target_ok {
        return Err(ApiError::BadRequest("owner_target_invalid"));
    }
    let target_step = owner::check_totp(&s, req.to, req.code.trim(), ip, true).await?;
    owner::burn_totp(&s, a.id, ip, owner_step).await?;
    owner::burn_totp(&s, req.to, ip, target_step).await?;
    let mut tx = s.db.begin().await?;
    let released = sqlx::query("UPDATE staff SET is_owner = FALSE WHERE id = $1 AND is_owner")
        .bind(a.id)
        .execute(&mut *tx)
        .await?;
    let moved = sqlx::query("UPDATE staff SET is_owner = TRUE WHERE id = $1 AND role = 'admin' AND active")
        .bind(req.to)
        .execute(&mut *tx)
        .await?;
    // Returning early drops the transaction, which rolls back the release as well.
    if released.rows_affected() != 1 || moved.rows_affected() != 1 {
        return Err(ApiError::BadRequest("owner_target_invalid"));
    }
    tx.commit().await?;
    audit(&s.db, "staff", Some(a.id), "owner.transferred", &req.to.to_string(), json!({})).await?;
    Ok(Json(json!({ "ok": true })))
}

/// Replaces every recovery code. Owner gates stay shut until the owner confirms the new codes are saved.
/// Needs only the enrolled authenticator, so a lost reply can be retried.
async fn reissue_recovery_codes(State(s): State<AppState>, OwnerEnrolledTotp(a): OwnerEnrolledTotp) -> ApiResult<Json<Value>> {
    let mut tx = s.db.begin().await?;
    sqlx::query("DELETE FROM staff_recovery_codes WHERE staff_id = $1")
        .bind(a.id)
        .execute(&mut *tx)
        .await?;
    let codes = owner::insert_recovery_codes(&mut tx, a.id).await?;
    sqlx::query("UPDATE staff SET recovery_confirmed_at = NULL WHERE id = $1")
        .bind(a.id)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    audit(&s.db, "staff", Some(a.id), "owner.recovery_codes_reissued", &a.id.to_string(), json!({})).await?;
    Ok(Json(json!({ "recovery_codes": codes })))
}

#[derive(Deserialize)]
struct ConfirmInput {
    /// One of the codes just shown. Typing it back proves the owner saw the new set.
    code: String,
}

/// The owner says the codes shown on screen were saved. Refused before a second factor is enrolled, and
/// refused unless one of the current, unused codes is typed back.
async fn confirm_recovery_codes(State(s): State<AppState>, Admin(a): Admin, Json(req): Json<ConfirmInput>) -> ApiResult<Json<Value>> {
    if req.code.len() > MAX_CODE_BYTES {
        return Err(ApiError::BadRequest("recovery_code_invalid"));
    }
    let known: bool = sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM staff_recovery_codes WHERE staff_id = $1 AND code_hash = $2 AND used_at IS NULL)")
        .bind(a.id)
        .bind(owner::code_hash(&req.code))
        .fetch_one(&s.db)
        .await?;
    if !known {
        return Err(ApiError::BadRequest("recovery_code_invalid"));
    }
    let done = sqlx::query(
        "UPDATE staff SET recovery_confirmed_at = COALESCE(recovery_confirmed_at, now())
         WHERE id = $1 AND active AND totp_enabled_at IS NOT NULL",
    )
    .bind(a.id)
    .execute(&s.db)
    .await?;
    if done.rows_affected() == 0 {
        return Err(ApiError::BadRequest("mfa_not_enabled"));
    }
    Ok(Json(json!({ "ok": true })))
}

#[derive(Deserialize)]
struct PhoneInput {
    phone: String,
}

/// Sets the SMS number for owner alerts. The number it replaces is told by SMS when possible. A dead phone
/// must not lock the owner out, so a failed notice is logged and audited, and the change still happens.
async fn set_alert_phone(
    State(s): State<AppState>,
    ConnectInfo(peer): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    Admin(a): Admin,
    Json(req): Json<PhoneInput>,
) -> ApiResult<Json<Value>> {
    let step = owner::check_owner(&s, a, &headers, Some(peer.ip()), true).await?;
    let phone = auth::normalize_phone(&req.phone).ok_or(ApiError::BadRequest("invalid_phone"))?;
    let ip = owner::client_ip(&s, Some(peer.ip()), &headers);
    owner::burn_totp(&s, a.id, ip, step).await?;
    let old: Option<String> = sqlx::query_scalar("SELECT alert_phone FROM staff WHERE id = $1")
        .bind(a.id)
        .fetch_optional(&s.db)
        .await?
        .flatten();
    let old_notified = match &old {
        Some(old) => notify_old_number(&s, old, &phone).await,
        None => false,
    };
    sqlx::query("UPDATE staff SET alert_phone = $2 WHERE id = $1")
        .bind(a.id)
        .bind(&phone)
        .execute(&s.db)
        .await?;
    let detail = json!({ "had_previous": old.is_some(), "old_notified": old_notified });
    audit(&s.db, "staff", Some(a.id), "owner.alert_phone_changed", &a.id.to_string(), detail).await?;
    Ok(Json(json!({ "ok": true, "alert_phone_masked": owner::mask_phone(&phone) })))
}

/// Best-effort SMS to the number being replaced. `false` when it could not be sent (logged, never fatal).
async fn notify_old_number(s: &AppState, old: &str, new_phone: &str) -> bool {
    let text = format!(
        "[다해] 소유자 알림 번호가 {}(으)로 바뀌었어요. 본인이 아니라면 바로 알려 주세요.",
        owner::mask_phone(new_phone)
    );
    match s.providers.send_sms(old, &text).await {
        Ok(()) => true,
        Err(_) => {
            tracing::warn!("owner alert phone: the previous number could not be notified");
            false
        }
    }
}

#[derive(Deserialize)]
struct PasswordInput {
    current_password: String,
    new_password: String,
}

/// Changes the owner's password. Every session ends, including this one: sign in again with the new password.
/// A wrong current password counts against the owner lockout but does not spend the code.
async fn change_password(
    State(s): State<AppState>,
    ConnectInfo(peer): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    Admin(a): Admin,
    Json(req): Json<PasswordInput>,
) -> ApiResult<Json<Value>> {
    if req.current_password.len() > MAX_PASSWORD_BYTES {
        return Err(ApiError::BadRequest("wrong_password"));
    }
    auth::check_password_policy(&req.new_password).map_err(ApiError::BadRequest)?;
    let step = owner::check_owner(&s, a, &headers, Some(peer.ip()), true).await?;
    let ip = owner::client_ip(&s, Some(peer.ip()), &headers);
    let hash: String = sqlx::query_scalar("SELECT password_hash FROM staff WHERE id = $1")
        .bind(a.id)
        .fetch_one(&s.db)
        .await?;
    if !auth::verify_password_blocking(req.current_password, hash).await? {
        owner::record_failure(&s, a.id, ip).await?;
        return Err(ApiError::BadRequest("wrong_password"));
    }
    owner::burn_totp(&s, a.id, ip, step).await?;
    let new_hash = auth::hash_password(&req.new_password)?;
    let mut tx = s.db.begin().await?;
    sqlx::query("UPDATE staff SET password_hash = $2 WHERE id = $1")
        .bind(a.id)
        .bind(new_hash)
        .execute(&mut *tx)
        .await?;
    owner::end_sessions_tx(&mut tx, a.id).await?;
    tx.commit().await?;
    audit(&s.db, "staff", Some(a.id), "owner.password_changed", &a.id.to_string(), json!({})).await?;
    Ok(Json(json!({ "ok": true })))
}

/// Ends every session of the owner, this one included.
async fn sign_out_all(State(s): State<AppState>, OwnerTotp(a): OwnerTotp) -> ApiResult<Json<Value>> {
    let mut tx = s.db.begin().await?;
    owner::end_sessions_tx(&mut tx, a.id).await?;
    tx.commit().await?;
    audit(&s.db, "staff", Some(a.id), "owner.sessions_ended", &a.id.to_string(), json!({})).await?;
    Ok(Json(json!({ "ok": true })))
}

#[derive(Deserialize)]
struct ResetInput {
    email: String,
    password: String,
    /// One-time code from `api owner-reset`, run on the server.
    code: String,
}

/// Lost second factor: the owner signs in with the password plus a server-issued code. The TOTP and the
/// recovery codes are cleared and every session ends; sign-in then asks the owner to enrol again.
async fn reset_with_code(
    State(s): State<AppState>,
    ConnectInfo(peer): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    Json(req): Json<ResetInput>,
) -> ApiResult<Json<Value>> {
    if req.password.len() > MAX_PASSWORD_BYTES {
        return Err(ApiError::Unauthorized);
    }
    let keys = lockout::keys("owner_reset", owner::client_ip(&s, Some(peer.ip()), &headers), &req.email);
    s.lockout.delay(&keys).await?;
    s.lockout.check(&keys).await?;
    let row: Option<(Uuid, String, bool)> = sqlx::query_as("SELECT id, password_hash, is_owner FROM staff WHERE lower(email) = lower($1) AND active")
        .bind(req.email.trim())
        .fetch_optional(&s.db)
        .await?;
    let hash = row.as_ref().map(|r| r.1.clone()).unwrap_or_else(|| super::auth::STAFF_DUMMY_HASH.to_string());
    let password_ok = auth::verify_password_blocking(req.password, hash).await?;
    let Some((id, _, true)) = row.filter(|_| password_ok) else {
        s.lockout.failure(&keys).await?;
        return Err(ApiError::Unauthorized);
    };
    if !reset_second_factor(&s, id, &req.code).await? {
        s.lockout.failure(&keys).await?;
        return Err(ApiError::BadRequest("reset_code_invalid"));
    }
    s.lockout.success(&keys).await?;
    Ok(Json(json!({ "ok": true })))
}

/// Burns the reset code and clears the second factor in one transaction. `false` when the code is not valid.
async fn reset_second_factor(s: &AppState, staff: Uuid, code: &str) -> ApiResult<bool> {
    let mut tx = s.db.begin().await?;
    let used = sqlx::query("UPDATE owner_reset_codes SET used_at = now() WHERE staff_id = $1 AND code_hash = $2 AND used_at IS NULL AND expires_at > now()")
        .bind(staff)
        .bind(owner::code_hash(code))
        .execute(&mut *tx)
        .await?
        .rows_affected();
    if used != 1 {
        return Ok(false);
    }
    sqlx::query(
        "UPDATE staff SET totp_enabled_at = NULL, totp_secret = NULL, totp_last_step = NULL, recovery_confirmed_at = NULL,
           failed_logins = 0, locked_until = NULL
         WHERE id = $1",
    )
    .bind(staff)
    .execute(&mut *tx)
    .await?;
    sqlx::query("DELETE FROM staff_recovery_codes WHERE staff_id = $1")
        .bind(staff)
        .execute(&mut *tx)
        .await?;
    owner::end_sessions_tx(&mut tx, staff).await?;
    tx.commit().await?;
    audit(&s.db, "staff", Some(staff), "owner.second_factor_reset", &staff.to_string(), json!({})).await?;
    Ok(true)
}
