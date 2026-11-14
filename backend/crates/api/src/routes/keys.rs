//! Keys bundle for restores on a fresh server (`keys_bundle.rs`). Every request needs the caller's live admin
//! role and a TOTP code in `X-Owner-Totp`, burnt by step like the sign-in second factor.
//! shortcut: the owner gate is "live admin with a TOTP code", the is_owner flag and shared OwnerTotp extractor come with be/owner-account.

use crate::{
    auth::{self, Admin, Role},
    crypto,
    error::{ApiError, ApiResult},
    keys_bundle::{self, BundleError, Keys},
    lockout,
    state::AppState,
    totp,
};
use axum::{
    Json, Router,
    extract::{ConnectInfo, DefaultBodyLimit, State},
    http::{HeaderMap, header},
    response::IntoResponse,
    routing::{get, post},
};
use base64::{Engine, engine::general_purpose::STANDARD};
use chrono::{DateTime, Utc};
use serde::Deserialize;
use serde_json::{Value, json};
use std::net::SocketAddr;
use uuid::Uuid;

const OWNER_TOTP_HEADER: &str = "x-owner-totp";
/// Base64 of the largest bundle, plus the passphrase and JSON framing.
const VERIFY_BODY_LIMIT: usize = 8 * 1024;

pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/keys/status", get(status))
        .route("/keys/bundle", post(make_bundle))
        .route("/keys/verify", post(verify).layer(DefaultBodyLimit::max(VERIFY_BODY_LIMIT)))
}

fn bundle_failure(e: BundleError) -> ApiError {
    ApiError::Internal(format!("keys bundle: {e}"))
}

async fn status(State(s): State<AppState>, Admin(_): Admin) -> ApiResult<Json<Value>> {
    let verified_at: Option<DateTime<Utc>> = sqlx::query_scalar("SELECT verified_at FROM key_bundle_checks WHERE id = 1")
        .fetch_optional(&s.db)
        .await?
        .flatten();
    Ok(Json(json!({ "verified_at": verified_at })))
}

/// Live admin role plus this request's TOTP code. A wrong code counts against the account like a failed sign-in.
pub(crate) async fn owner_gate(s: &AppState, peer: SocketAddr, headers: &HeaderMap, id: Uuid) -> ApiResult<()> {
    if auth::live_staff_role(&s.db, id).await? != Role::StaffAdmin {
        return Err(ApiError::Forbidden);
    }
    let code = headers
        .get(OWNER_TOTP_HEADER)
        .and_then(|v| v.to_str().ok())
        .map(str::trim)
        .ok_or(ApiError::Unauthorized)?;
    let keys = lockout::keys("owner_totp", lockout::ip_of(s, peer, headers), &id.to_string());
    s.lockout.check(&keys).await?;
    if totp_step(s, id, code).await?.is_none() {
        return Err(if s.lockout.failure(&keys).await? {
            ApiError::RateLimited
        } else {
            ApiError::Unauthorized
        });
    }
    s.lockout.success(&keys).await
}

/// Matches `code` to a fresh TOTP step and burns that step in one UPDATE, so a code works once.
async fn totp_step(s: &AppState, id: Uuid, code: &str) -> ApiResult<Option<i64>> {
    let row: Option<(bool, Option<i64>, Option<String>)> =
        sqlx::query_as("SELECT totp_enabled_at IS NOT NULL, totp_last_step, totp_secret FROM staff WHERE id = $1 AND active")
            .bind(id)
            .fetch_optional(&s.db)
            .await?;
    let Some((true, last_step, Some(enc))) = row else {
        return Ok(None);
    };
    let Some(secret) = crypto::decrypt(&s.config.data_key, &enc).and_then(|b32| totp::decode_secret(&b32)) else {
        return Ok(None);
    };
    let Some(step) = totp::verify(&secret, code, Utc::now().timestamp(), last_step) else {
        return Ok(None);
    };
    let burnt = sqlx::query("UPDATE staff SET totp_last_step = $2 WHERE id = $1 AND (totp_last_step IS NULL OR totp_last_step < $2)")
        .bind(id)
        .bind(step)
        .execute(&s.db)
        .await?
        .rows_affected()
        == 1;
    Ok(burnt.then_some(step))
}

/// Seals the live keys under a new passphrase and returns both. The passphrase is never stored.
async fn make_bundle(
    State(s): State<AppState>,
    ConnectInfo(peer): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    Admin(a): Admin,
) -> ApiResult<impl IntoResponse> {
    owner_gate(&s, peer, &headers, a.id).await?;
    let keys = Keys::from_parts(s.config.data_key, &s.config.jwt_secret).map_err(bundle_failure)?;
    let passphrase = keys_bundle::new_passphrase();
    let sealed = keys_bundle::seal(&keys, &passphrase).map_err(bundle_failure)?;
    // The passphrase is shown only after the bundle has opened and matched the live keys.
    let opened = keys_bundle::open(&sealed, &passphrase).map_err(bundle_failure)?;
    if !opened.matches(&s.config.data_key, &s.config.jwt_secret) {
        return Err(ApiError::Internal("keys bundle self-test failed".into()));
    }
    let body = json!({
        "file_name": format!("dahae-keys-{}.mkk", Utc::now().format("%Y%m%d")),
        "bundle": STANDARD.encode(&sealed),
        "passphrase": passphrase,
    });
    Ok(([(header::CACHE_CONTROL, "no-store")], Json(body)))
}

#[derive(Deserialize)]
struct VerifyInput {
    bundle: String,
    passphrase: String,
}

/// Upload test: a bundle that opens with the passphrase and matches the live keys sets `verified_at`.
async fn verify(
    State(s): State<AppState>,
    ConnectInfo(peer): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    Admin(a): Admin,
    Json(req): Json<VerifyInput>,
) -> ApiResult<Json<Value>> {
    owner_gate(&s, peer, &headers, a.id).await?;
    let raw = STANDARD.decode(req.bundle.trim()).map_err(|_| ApiError::BadRequest("keys_not_opened"))?;
    let opened = keys_bundle::open(&raw, &req.passphrase).map_err(|_| ApiError::BadRequest("keys_not_opened"))?;
    if !opened.matches(&s.config.data_key, &s.config.jwt_secret) {
        return Err(ApiError::BadRequest("keys_mismatch"));
    }
    let verified_at: DateTime<Utc> = sqlx::query_scalar(
        "INSERT INTO key_bundle_checks (id, verified_at) VALUES (1, now())
         ON CONFLICT (id) DO UPDATE SET verified_at = excluded.verified_at
         RETURNING verified_at",
    )
    .fetch_one(&s.db)
    .await?;
    Ok(Json(json!({ "verified_at": verified_at })))
}
