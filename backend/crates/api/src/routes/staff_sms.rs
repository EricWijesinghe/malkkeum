//! Staff invites and password resets by one-time SMS code. A code is 6 digits, works once, lives 24 hours,
//! and is burned after too many wrong guesses. The admin can copy the code instead of sending it by SMS.

use super::audit;
use crate::{
    auth::{self, Admin, Role, Staff, live_staff_role},
    contract,
    error::{ApiError, ApiResult},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Path, State},
    routing::post,
};
use chrono::{Duration, Utc};
use serde::Deserialize;
use serde_json::{Value, json};
use sqlx::{PgConnection, Postgres, Transaction};
use subtle::ConstantTimeEq;
use uuid::Uuid;

const CODE_TTL_SECS: i64 = 24 * 60 * 60;
const CODE_MAX_ATTEMPTS: i32 = 5;
const CODE_RESEND_COOLDOWN_SECS: f64 = 60.0;
const CODE_MAX_PER_DAY: i64 = 5;

pub fn public_routes() -> Router<AppState> {
    Router::new().route("/auth/staff/code/redeem", post(redeem))
}

pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/staff/invite", post(invite))
        .route("/staff/{id}/password-reset", post(issue_reset))
}

/// How the code reaches the staff member: an SMS, or shown once so the admin can copy it.
#[derive(Deserialize, Default, Clone, Copy, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
enum Channel {
    #[default]
    Sms,
    Copy,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct InviteInput {
    email: String,
    name: String,
    phone: String,
    role: String,
    #[serde(default)]
    channel: Channel,
}

/// Checks the invite fields and who may grant the role. Returns the stored role name.
fn validate_invite(n: &InviteInput, actor: Role) -> ApiResult<&'static str> {
    let too_long = n.email.len() > contract::MAX_EMAIL_BYTES || n.name.chars().count() > contract::MAX_TEXT_CHARS;
    if too_long || !n.email.contains('@') || n.name.trim().is_empty() {
        return Err(ApiError::BadRequest("invalid_staff"));
    }
    let role = match n.role.as_str() {
        "admin" => "admin",
        "consultant" => "consultant",
        _ => return Err(ApiError::BadRequest("invalid_staff")),
    };
    if role == "admin" && actor == Role::StaffConsultant {
        return Err(ApiError::Forbidden);
    }
    Ok(role)
}

/// Maps a duplicate-key failure on the staff row to a readable conflict.
fn staff_conflict(e: sqlx::Error) -> ApiError {
    match &e {
        sqlx::Error::Database(d) if d.is_unique_violation() && d.constraint() == Some("staff_phone_unique") => ApiError::Conflict("phone_taken"),
        sqlx::Error::Database(d) if d.is_unique_violation() => ApiError::Conflict("email_taken"),
        _ => e.into(),
    }
}

/// Creates an inactive staff row with no usable password (an empty hash never verifies) and sends its first
/// code. The row and the code commit together; a failed SMS rolls the whole invite back.
async fn invite(State(s): State<AppState>, Staff(actor): Staff, Json(n): Json<InviteInput>) -> ApiResult<Json<Value>> {
    let actor_role = live_staff_role(&s.db, actor.id).await?;
    let role = validate_invite(&n, actor_role)?;
    let phone = auth::normalize_phone(&n.phone).ok_or(ApiError::BadRequest("invalid_phone"))?;
    let mut tx = s.db.begin().await?;
    let id: Uuid = sqlx::query_scalar("INSERT INTO staff (email, name, role, phone, password_hash, active) VALUES ($1, $2, $3, $4, '', FALSE) RETURNING id")
        .bind(n.email.trim().to_lowercase())
        .bind(n.name.trim())
        .bind(role)
        .bind(&phone)
        .fetch_one(&mut *tx)
        .await
        .map_err(staff_conflict)?;
    let shown = issue_and_deliver(&s, &mut tx, id, &phone, "invite", n.channel).await?;
    tx.commit().await?;
    audit(
        &s.db,
        "staff",
        Some(actor.id),
        "staff.invite",
        &id.to_string(),
        json!({ "role": role, "channel": channel_name(n.channel) }),
    )
    .await?;
    Ok(Json(json!({ "id": id, "expires_in": CODE_TTL_SECS, "code": shown })))
}

#[derive(Deserialize, Default)]
struct ResetInput {
    #[serde(default)]
    channel: Channel,
    /// Needed once, for a staff member who has no phone number on file yet.
    #[serde(default)]
    phone: Option<String>,
}

/// Admin sends a reset code to an active staff member. Revokes nothing until the code is redeemed.
async fn issue_reset(State(s): State<AppState>, Admin(me): Admin, Path(id): Path<Uuid>, Json(req): Json<ResetInput>) -> ApiResult<Json<Value>> {
    let mut tx = s.db.begin().await?;
    let stored: Option<Option<String>> = sqlx::query_scalar("SELECT phone FROM staff WHERE id = $1 AND active FOR UPDATE")
        .bind(id)
        .fetch_optional(&mut *tx)
        .await?;
    let stored = stored.ok_or(ApiError::NotFound)?;
    let phone = resolve_phone(&mut tx, id, stored, req.phone.as_deref()).await?;
    let shown = issue_and_deliver(&s, &mut tx, id, &phone, "reset", req.channel).await?;
    tx.commit().await?;
    audit(
        &s.db,
        "staff",
        Some(me.id),
        "staff.password_reset_issued",
        &id.to_string(),
        json!({ "channel": channel_name(req.channel) }),
    )
    .await?;
    Ok(Json(json!({ "expires_in": CODE_TTL_SECS, "code": shown })))
}

/// The phone on file, or the one the admin supplies when the staff member has none yet (then it is saved).
async fn resolve_phone(tx: &mut Transaction<'_, Postgres>, id: Uuid, stored: Option<String>, given: Option<&str>) -> ApiResult<String> {
    if let Some(phone) = stored {
        return Ok(phone);
    }
    let phone = auth::normalize_phone(given.ok_or(ApiError::BadRequest("no_phone"))?).ok_or(ApiError::BadRequest("invalid_phone"))?;
    sqlx::query("UPDATE staff SET phone = $2 WHERE id = $1")
        .bind(id)
        .bind(&phone)
        .execute(&mut **tx)
        .await
        .map_err(staff_conflict)?;
    Ok(phone)
}

/// Refuses a resend inside the cooldown or past the daily cap, stores the new code (replacing older codes for
/// the purpose), and sends it. Returns the code only for the copy channel.
async fn issue_and_deliver(
    s: &AppState,
    tx: &mut Transaction<'_, Postgres>,
    staff: Uuid,
    phone: &str,
    purpose: &str,
    channel: Channel,
) -> ApiResult<Option<String>> {
    check_cooldown(&mut **tx, staff).await?;
    let code = auth::otp_code();
    sqlx::query("DELETE FROM staff_sms_codes WHERE staff_id = $1 AND purpose = $2")
        .bind(staff)
        .bind(purpose)
        .execute(&mut **tx)
        .await?;
    sqlx::query("INSERT INTO staff_sms_codes (staff_id, purpose, code_hash, expires_at) VALUES ($1, $2, $3, $4)")
        .bind(staff)
        .bind(purpose)
        .bind(code_hash(s, phone, &code))
        .bind(Utc::now() + Duration::seconds(CODE_TTL_SECS))
        .execute(&mut **tx)
        .await?;
    match channel {
        Channel::Copy => Ok(Some(code)),
        Channel::Sms => {
            let text = if purpose == "invite" {
                format!("[다해] 직원 초대 인증번호는 {code}예요. 24시간 안에 입력해 주세요.")
            } else {
                format!("[다해] 비밀번호 재설정 인증번호는 {code}예요. 24시간 안에 입력해 주세요.")
            };
            s.providers.send_sms(phone, &text).await.map_err(|_| ApiError::Unavailable("sms"))?;
            Ok(None)
        }
    }
}

async fn check_cooldown(conn: &mut PgConnection, staff: Uuid) -> ApiResult<()> {
    let (cooling, today): (bool, i64) = sqlx::query_as(
        "SELECT EXISTS (SELECT 1 FROM staff_sms_codes WHERE staff_id = $1 AND created_at > now() - make_interval(secs => $2)),
                (SELECT count(*) FROM staff_sms_codes WHERE staff_id = $1 AND created_at > now() - interval '1 day')",
    )
    .bind(staff)
    .bind(CODE_RESEND_COOLDOWN_SECS)
    .fetch_one(conn)
    .await?;
    if cooling || today >= CODE_MAX_PER_DAY {
        return Err(ApiError::RateLimited);
    }
    Ok(())
}

/// Keyed on the phone so a code cannot be checked for a different number. The staff row is found by phone.
fn code_hash(s: &AppState, phone: &str, code: &str) -> String {
    auth::otp_hash(&s.config.jwt_secret, &format!("staff:{phone}"), code.trim())
}

#[derive(Deserialize)]
struct RedeemInput {
    phone: String,
    code: String,
    password: String,
}

/// Sets the password, burns the code, activates an invited account, clears lockout and signs the staff member
/// out everywhere. Every wrong guess counts, and a code is burned after `CODE_MAX_ATTEMPTS`.
async fn redeem(State(s): State<AppState>, Json(req): Json<RedeemInput>) -> ApiResult<Json<Value>> {
    auth::check_password_policy(&req.password).map_err(ApiError::BadRequest)?;
    let (code_id, staff, purpose) = consume_attempt(&s, &req.phone, &req.code).await?;
    let hash = auth::hash_password(&req.password)?;
    let invite = purpose == "invite";
    let mut tx = s.db.begin().await?;
    let burned = sqlx::query("DELETE FROM staff_sms_codes WHERE id = $1").bind(code_id).execute(&mut *tx).await?;
    // A reset cannot revive a deactivated account; an invite activates it.
    let updated: Option<Uuid> = sqlx::query_scalar(
        "UPDATE staff SET password_hash = $2, failed_logins = 0, locked_until = NULL, active = (active OR $3)
         WHERE id = $1 AND (active OR $3) RETURNING id",
    )
    .bind(staff)
    .bind(hash)
    .bind(invite)
    .fetch_optional(&mut *tx)
    .await?;
    if burned.rows_affected() == 0 || updated.is_none() {
        return Err(ApiError::BadRequest("code_invalid"));
    }
    sqlx::query("UPDATE refresh_tokens SET revoked_at = now() WHERE subject = $1 AND revoked_at IS NULL")
        .bind(staff)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    audit(
        &s.db,
        "staff",
        Some(staff),
        "staff.code_redeemed",
        &staff.to_string(),
        json!({ "purpose": purpose }),
    )
    .await?;
    Ok(Json(json!({ "ok": true })))
}

/// Counts one guess against the newest live code for the phone (atomically, before comparing), then checks it.
/// Returns (code id, staff id, purpose). Every failure is the same error, so the phone cannot be probed.
async fn consume_attempt(s: &AppState, phone: &str, code: &str) -> ApiResult<(Uuid, Uuid, String)> {
    let phone = auth::normalize_phone(phone).ok_or(ApiError::BadRequest("code_invalid"))?;
    let row: Option<(Uuid, Uuid, String, String)> = sqlx::query_as(
        "UPDATE staff_sms_codes SET attempts = attempts + 1
         WHERE id = (SELECT c.id FROM staff_sms_codes c JOIN staff st ON st.id = c.staff_id
                     WHERE st.phone = $1 AND c.expires_at > now() ORDER BY c.created_at DESC LIMIT 1)
           AND attempts < $2
         RETURNING id, staff_id, purpose, code_hash",
    )
    .bind(&phone)
    .bind(CODE_MAX_ATTEMPTS)
    .fetch_optional(&s.db)
    .await?;
    let (id, staff, purpose, stored) = row.ok_or(ApiError::BadRequest("code_invalid"))?;
    let given = code_hash(s, &phone, code);
    if !bool::from(given.as_bytes().ct_eq(stored.as_bytes())) {
        return Err(ApiError::BadRequest("code_invalid"));
    }
    Ok((id, staff, purpose))
}

fn channel_name(c: Channel) -> &'static str {
    match c {
        Channel::Sms => "sms",
        Channel::Copy => "copy",
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn invite(role: &str) -> InviteInput {
        InviteInput {
            email: "new@test.local".into(),
            name: "Kim".into(),
            phone: "010-1234-5678".into(),
            role: role.into(),
            channel: Channel::Sms,
        }
    }

    #[test]
    fn consultant_cannot_grant_admin() {
        assert!(matches!(validate_invite(&invite("admin"), Role::StaffConsultant), Err(ApiError::Forbidden)));
        assert_eq!(validate_invite(&invite("consultant"), Role::StaffConsultant).ok(), Some("consultant"));
    }

    #[test]
    fn admin_can_grant_either_role_and_unknown_roles_are_refused() {
        assert_eq!(validate_invite(&invite("admin"), Role::StaffAdmin).ok(), Some("admin"));
        assert!(matches!(
            validate_invite(&invite("owner"), Role::StaffAdmin),
            Err(ApiError::BadRequest("invalid_staff"))
        ));
    }
}
