//! Staff password reset, owner-initiated: an admin issues a single-use token; the staff member redeems it
//! with a new password. Redeeming ends every session the staff member has.

use super::audit;
use crate::{
    auth::{self, Admin},
    error::{ApiError, ApiResult},
    owner,
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{ConnectInfo, Path, State},
    http::HeaderMap,
    routing::post,
};
use rand::{RngCore, rngs::OsRng};
use serde::Deserialize;
use serde_json::{Value, json};
use std::net::SocketAddr;
use uuid::Uuid;

const RESET_TTL_MIN: i64 = 30;

pub fn public_routes() -> Router<AppState> {
    Router::new().route("/auth/staff/password/reset", post(redeem))
}

pub fn admin_routes() -> Router<AppState> {
    Router::new().route("/staff/{id}/password-reset", post(issue))
}

/// Admin issues a reset token for an active staff member. The token is shown once; only its hash is kept.
/// The owner's own password is reset only with the owner's code: a reset token would otherwise be a way in.
async fn issue(
    State(s): State<AppState>,
    ConnectInfo(peer): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    Admin(me): Admin,
    Path(id): Path<Uuid>,
) -> ApiResult<Json<Value>> {
    let target: Option<bool> = sqlx::query_scalar("SELECT is_owner FROM staff WHERE id = $1 AND active")
        .bind(id)
        .fetch_optional(&s.db)
        .await?;
    let Some(target_is_owner) = target else {
        return Err(ApiError::NotFound);
    };
    if target_is_owner {
        owner::verify_owner(&s, me, &headers, Some(peer.ip()), true).await?;
    }
    let mut bytes = [0u8; 32];
    OsRng.fill_bytes(&mut bytes);
    let token = hex::encode(bytes);
    sqlx::query("INSERT INTO staff_password_resets (token_hash, staff_id, expires_at) VALUES ($1, $2, now() + make_interval(mins => $3))")
        .bind(auth::sha256_hex(token.as_bytes()))
        .bind(id)
        .bind(RESET_TTL_MIN as i32)
        .execute(&s.db)
        .await?;
    audit(&s.db, "staff", Some(me.id), "staff.password_reset_issued", &id.to_string(), json!({})).await?;
    Ok(Json(json!({ "token": token, "expires_in": RESET_TTL_MIN * 60 })))
}

#[derive(Deserialize)]
struct RedeemInput {
    token: String,
    password: String,
}

/// Sets the new password (length and breach policy), burns the token, clears lockout, and signs the staff
/// member out everywhere.
async fn redeem(State(s): State<AppState>, Json(req): Json<RedeemInput>) -> ApiResult<Json<Value>> {
    auth::check_password_policy(&req.password).map_err(ApiError::BadRequest)?;
    let hash = auth::hash_password(&req.password)?;
    let mut tx = s.db.begin().await?;
    // Only one request can burn the token.
    let staff: Option<Uuid> = sqlx::query_scalar(
        "UPDATE staff_password_resets SET used_at = now()
         WHERE token_hash = $1 AND used_at IS NULL AND expires_at > now()
         RETURNING staff_id",
    )
    .bind(auth::sha256_hex(req.token.as_bytes()))
    .fetch_optional(&mut *tx)
    .await?;
    let Some(staff) = staff else {
        return Err(ApiError::BadRequest("reset_token_invalid"));
    };
    sqlx::query("UPDATE staff SET password_hash = $2, failed_logins = 0, locked_until = NULL WHERE id = $1")
        .bind(staff)
        .bind(hash)
        .execute(&mut *tx)
        .await?;
    sqlx::query("UPDATE refresh_tokens SET revoked_at = now() WHERE subject = $1 AND revoked_at IS NULL")
        .bind(staff)
        .execute(&mut *tx)
        .await?;
    audit(&s.db, "staff", Some(staff), "staff.password_reset_redeemed", &staff.to_string(), json!({})).await?;
    tx.commit().await?;
    Ok(Json(json!({ "ok": true })))
}
