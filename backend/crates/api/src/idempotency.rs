//! `Idempotency-Key` replay for money-moving and duplicate-prone POSTs. A key is scoped to the caller
//! (the verified user, not one access token) and path, bound to the request body hash, and replays the stored response for 24h.
//! Only final answers are stored: a 5xx or an auth/rate refusal releases the key so the client can retry.

use crate::{
    auth::verify_access,
    config::Config,
    contract::JSON_BODY_LIMIT,
    error::{ApiError, ApiResult},
    state::AppState,
};
use axum::{
    body::{Body, to_bytes},
    extract::{Extension, Request},
    http::{HeaderName, HeaderValue, Method, StatusCode, header},
    middleware::Next,
    response::{IntoResponse, Response},
    routing::MethodRouter,
};
use sha2::{Digest, Sha256};
use sqlx::PgPool;
use std::sync::Arc;

const IDEMPOTENCY_KEY: HeaderName = HeaderName::from_static("idempotency-key");
const KEY_MAX_CHARS: usize = 128;
const RESPONSE_LIMIT: usize = 1024 * 1024;
/// A key still in flight this long is assumed to belong to a crashed request and may be retried.
const STALE_IN_FLIGHT: &str = "5 minutes";

/// Wraps a route's method router so its POST calls honour `Idempotency-Key`.
pub fn replayable(m: MethodRouter<AppState>) -> MethodRouter<AppState> {
    m.route_layer(axum::middleware::from_fn(replay))
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

fn valid_key(raw: &axum::http::HeaderValue) -> ApiResult<String> {
    let s = raw.to_str().map_err(|_| ApiError::BadRequest("invalid_idempotency_key"))?;
    let ok = !s.is_empty() && s.chars().count() <= KEY_MAX_CHARS && s.bytes().all(|b| b.is_ascii_graphic());
    if ok {
        Ok(s.to_owned())
    } else {
        Err(ApiError::BadRequest("invalid_idempotency_key"))
    }
}

/// What the key slot says about this request.
enum Slot {
    /// Newly claimed: run the handler and store its answer.
    Fresh,
    /// Already answered: replay this status and JSON body.
    Done(StatusCode, String),
}

/// Who owns a key: the user a valid bearer names, so a retry after the app refreshed its access token
/// (15 min TTL) still replays instead of booking or charging again. Any other header falls back to its
/// hash; such a request is refused as 401 by the handler, which releases the key.
fn caller(config: &Config, auth: Option<&HeaderValue>) -> String {
    let Some(v) = auth else { return "anon".to_owned() };
    let user = v
        .to_str()
        .ok()
        .and_then(|s| s.strip_prefix("Bearer "))
        .and_then(|t| verify_access(&config.jwt_keys(), t).ok());
    user.map_or_else(|| hex(&Sha256::digest(v.as_bytes())), |a| format!("user:{}", a.id))
}

pub async fn replay(Extension(db): Extension<PgPool>, Extension(config): Extension<Arc<Config>>, req: Request, next: Next) -> ApiResult<Response> {
    if req.method() != Method::POST {
        return Ok(next.run(req).await);
    }
    let Some(raw) = req.headers().get(IDEMPOTENCY_KEY) else {
        return Ok(next.run(req).await);
    };
    let key = valid_key(raw)?;
    let (parts, body) = req.into_parts();
    let bytes = match to_bytes(body, JSON_BODY_LIMIT).await {
        Ok(b) => b,
        Err(_) => return Ok(StatusCode::PAYLOAD_TOO_LARGE.into_response()),
    };
    let scope = format!("{}:{}", caller(&config, parts.headers.get(header::AUTHORIZATION)), parts.uri.path());
    let body_hash = hex(&Sha256::digest(&bytes));
    match claim(&db, &scope, &key, &body_hash).await? {
        Slot::Done(status, text) => Ok(replayed(status, text)),
        Slot::Fresh => {
            let res = next.run(Request::from_parts(parts, Body::from(bytes))).await;
            finish(&db, &scope, &key, res).await
        }
    }
}

/// Deletes expired keys (24h) and stale in-flight claims, then claims the key or reads its answer.
async fn claim(db: &PgPool, scope: &str, key: &str, body_hash: &str) -> ApiResult<Slot> {
    sqlx::query(
        "DELETE FROM idempotency_keys WHERE scope = $1 AND key = $2
         AND (created_at < now() - interval '24 hours' OR (status IS NULL AND created_at < now() - $3::interval))",
    )
    .bind(scope)
    .bind(key)
    .bind(STALE_IN_FLIGHT)
    .execute(db)
    .await?;
    let claimed = sqlx::query("INSERT INTO idempotency_keys (scope, key, request_hash) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING")
        .bind(scope)
        .bind(key)
        .bind(body_hash)
        .execute(db)
        .await?
        .rows_affected();
    if claimed == 1 {
        return Ok(Slot::Fresh);
    }
    let row: Option<(String, Option<i16>, Option<String>)> =
        sqlx::query_as("SELECT request_hash, status, body FROM idempotency_keys WHERE scope = $1 AND key = $2")
            .bind(scope)
            .bind(key)
            .fetch_optional(db)
            .await?;
    match row {
        Some((hash, _, _)) if hash != body_hash => Err(ApiError::BadRequest("idempotency_key_reused")),
        Some((_, Some(status), Some(body))) => {
            let code = u16::try_from(status)
                .ok()
                .and_then(|c| StatusCode::from_u16(c).ok())
                .unwrap_or(StatusCode::INTERNAL_SERVER_ERROR);
            Ok(Slot::Done(code, body))
        }
        // Still running (or released mid-read): the client should retry shortly.
        _ => Err(ApiError::Conflict("idempotency_in_progress")),
    }
}

/// Stores a final answer, or releases the key when the outcome is not safe to replay.
async fn finish(db: &PgPool, scope: &str, key: &str, res: Response) -> ApiResult<Response> {
    let status = res.status();
    let replayable = status.is_success()
        || (status.is_client_error() && ![StatusCode::UNAUTHORIZED, StatusCode::FORBIDDEN, StatusCode::TOO_MANY_REQUESTS].contains(&status));
    let (parts, body) = res.into_parts();
    let bytes = match to_bytes(body, RESPONSE_LIMIT).await {
        Ok(b) if replayable => b,
        _ => {
            release(db, scope, key).await?;
            return Ok(Response::from_parts(parts, Body::empty()));
        }
    };
    sqlx::query("UPDATE idempotency_keys SET status = $3, body = $4 WHERE scope = $1 AND key = $2")
        .bind(scope)
        .bind(key)
        .bind(i16::try_from(status.as_u16()).unwrap_or(500))
        .bind(String::from_utf8_lossy(&bytes).into_owned())
        .execute(db)
        .await?;
    Ok(Response::from_parts(parts, Body::from(bytes)))
}

async fn release(db: &PgPool, scope: &str, key: &str) -> ApiResult<()> {
    sqlx::query("DELETE FROM idempotency_keys WHERE scope = $1 AND key = $2")
        .bind(scope)
        .bind(key)
        .execute(db)
        .await?;
    Ok(())
}

fn replayed(status: StatusCode, text: String) -> Response {
    let mut res = text.into_response();
    *res.status_mut() = status;
    res.headers_mut()
        .insert(header::CONTENT_TYPE, axum::http::HeaderValue::from_static("application/json"));
    res.headers_mut()
        .insert(HeaderName::from_static("idempotent-replayed"), axum::http::HeaderValue::from_static("true"));
    res
}

/// Retention: keys older than 24h can never be replayed.
pub async fn purge(db: &PgPool) -> Result<u64, sqlx::Error> {
    Ok(sqlx::query("DELETE FROM idempotency_keys WHERE created_at < now() - interval '24 hours'")
        .execute(db)
        .await?
        .rows_affected())
}
