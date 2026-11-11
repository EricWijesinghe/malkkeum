//! Payment method catalogue: the methods customers can pay with, and the admin switch for each.

use super::audit;
use crate::{
    auth::Admin,
    error::{ApiError, ApiResult},
    state::AppState,
};
use axum::{Json, Router, extract::State, routing::get};
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::PgPool;

const SETTING: &str = "payment_methods";

/// (code, flow). `billing` methods can be saved for one-tap payment; `checkout` ones are one-off via the SDK.
pub const METHODS: [(&str, &str); 10] = [
    ("card", "billing"),
    ("kakaopay", "billing"),
    ("naverpay", "billing"),
    ("tosspay", "billing"),
    ("payco", "billing"),
    ("samsungpay", "checkout"),
    ("applepay", "checkout"),
    ("transfer", "checkout"),
    ("virtual_account", "checkout"),
    ("phone", "checkout"),
];

pub fn routes() -> Router<AppState> {
    Router::new().route("/payments/methods", get(enabled))
}

pub fn admin_routes() -> Router<AppState> {
    Router::new().route("/payment-methods", get(admin_list).put(admin_update))
}

/// Enabled codes from settings; every method is enabled until an admin changes the list.
pub async fn enabled_codes(db: &PgPool) -> ApiResult<Vec<String>> {
    let stored: Option<sqlx::types::Json<Vec<String>>> = sqlx::query_scalar("SELECT value FROM settings WHERE key = $1")
        .bind(SETTING)
        .fetch_optional(db)
        .await?;
    Ok(stored.map(|j| j.0).unwrap_or_else(|| METHODS.iter().map(|m| m.0.to_string()).collect()))
}

/// Rejects unknown or switched-off methods before any intent is created.
pub async fn ensure_enabled(db: &PgPool, code: &str) -> ApiResult<()> {
    if !METHODS.iter().any(|m| m.0 == code) {
        return Err(ApiError::BadRequest("invalid_payment_method"));
    }
    if !enabled_codes(db).await?.iter().any(|c| c == code) {
        return Err(ApiError::BadRequest("payment_method_disabled"));
    }
    Ok(())
}

#[derive(Serialize)]
struct Method {
    code: &'static str,
    flow: &'static str,
}

async fn enabled(State(s): State<AppState>) -> ApiResult<Json<Vec<Method>>> {
    let on = enabled_codes(&s.db).await?;
    Ok(Json(
        METHODS
            .iter()
            .filter(|(code, _)| on.iter().any(|c| c == code))
            .map(|&(code, flow)| Method { code, flow })
            .collect(),
    ))
}

#[derive(Serialize)]
struct AdminMethod {
    code: &'static str,
    flow: &'static str,
    enabled: bool,
}

async fn admin_view(db: &PgPool) -> ApiResult<Vec<AdminMethod>> {
    let on = enabled_codes(db).await?;
    Ok(METHODS
        .iter()
        .map(|&(code, flow)| AdminMethod {
            code,
            flow,
            enabled: on.iter().any(|c| c == code),
        })
        .collect())
}

async fn admin_list(State(s): State<AppState>, Admin(_): Admin) -> ApiResult<Json<Vec<AdminMethod>>> {
    Ok(Json(admin_view(&s.db).await?))
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct Update {
    enabled: Vec<String>,
}

async fn admin_update(State(s): State<AppState>, Admin(a): Admin, Json(u): Json<Update>) -> ApiResult<Json<Vec<AdminMethod>>> {
    if u.enabled.iter().any(|c| !METHODS.iter().any(|m| m.0 == c)) {
        return Err(ApiError::BadRequest("invalid_payment_method"));
    }
    // Keep catalogue order and drop duplicates so the stored list is canonical.
    let codes: Vec<&str> = METHODS.iter().map(|m| m.0).filter(|c| u.enabled.iter().any(|e| e == c)).collect();
    sqlx::query("INSERT INTO settings (key, value) VALUES ($1, $2) ON CONFLICT (key) DO UPDATE SET value = $2, updated_at = now()")
        .bind(SETTING)
        .bind(sqlx::types::Json(&codes))
        .execute(&s.db)
        .await?;
    audit(&s.db, "staff", Some(a.id), "payment_methods.update", SETTING, json!(codes)).await?;
    Ok(Json(admin_view(&s.db).await?))
}
