//! Socket tickets: the WebSocket is opened with a 30-second, single-use ticket instead of the access token,
//! so the long-lived credential never appears in a URL (proxies and access logs record those).

use crate::{
    auth::{Auth, Role, new_refresh_token, sha256_hex, verify_access},
    error::{ApiError, ApiResult},
    state::AppState,
};
use axum::{Json, extract::State};
use serde::Deserialize;
use serde_json::{Value, json};
use sqlx::PgPool;
use std::time::Duration;
use uuid::Uuid;

pub const TICKET_TTL: Duration = Duration::from_secs(30);

/// Query of `GET /v1/ws`. A socket authenticates with `ticket`; `token` is the old form.
#[derive(Deserialize)]
pub struct WsQuery {
    ticket: Option<String>,
    /// shortcut: the access token in the URL is kept one release for apps installed before tickets; remove this field and its branch in `authenticate_socket` then.
    token: Option<String>,
}

/// `POST /v1/realtime/ticket`: a fresh ticket bound to the caller's id and role.
pub async fn issue_ticket(State(state): State<AppState>, auth: Auth) -> ApiResult<Json<Value>> {
    // The same 256-bit opaque form as refresh tokens; only the hash is kept.
    let (ticket, hash) = new_refresh_token();
    sqlx::query("INSERT INTO realtime_tickets (token_hash, subject, role, expires_at) VALUES ($1, $2, $3, now() + make_interval(secs => $4))")
        .bind(hash)
        .bind(auth.id)
        .bind(auth.role.as_str())
        .bind(TICKET_TTL.as_secs_f64())
        .execute(&state.db)
        .await?;
    Ok(Json(json!({ "ticket": ticket, "expires_in": TICKET_TTL.as_secs() })))
}

/// Spends a ticket. The row is deleted in the same statement that reads it, so a second use finds nothing.
pub async fn consume_ticket(db: &PgPool, ticket: &str) -> ApiResult<Auth> {
    let row: Option<(Uuid, String)> = sqlx::query_as("DELETE FROM realtime_tickets WHERE token_hash = $1 AND expires_at > now() RETURNING subject, role")
        .bind(sha256_hex(ticket.as_bytes()))
        .fetch_optional(db)
        .await?;
    let (id, role) = row.ok_or(ApiError::Unauthorized)?;
    let role = Role::parse(&role).ok_or(ApiError::Unauthorized)?;
    Ok(Auth { id, role })
}

/// Identity of a socket opening, from its ticket (or, deprecated, its access token).
pub async fn authenticate_socket(state: &AppState, q: &WsQuery) -> ApiResult<Auth> {
    if let Some(ticket) = q.ticket.as_deref() {
        return consume_ticket(&state.db, ticket).await;
    }
    let token = q.token.as_deref().ok_or(ApiError::Unauthorized)?;
    tracing::warn!("realtime socket opened with the deprecated ?token= form; clients should send ?ticket=");
    verify_access(&state.config.jwt_keys(), token)
}
