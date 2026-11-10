//! Provider callbacks. Unauthenticated by design: the Standard Webhooks signature is the gate.

use super::checkouts::{find_awaiting, settle};
use crate::{
    error::{ApiError, ApiResult},
    providers::portone::{WebhookError, verify_webhook},
    state::AppState,
};
use axum::{Json, Router, body::Bytes, extract::State, http::HeaderMap, routing::post};
use chrono::Utc;
use serde::Deserialize;
use serde_json::{Value, json};

pub fn routes() -> Router<AppState> {
    Router::new().route("/webhooks/portone", post(portone))
}

fn header<'a>(h: &'a HeaderMap, name: &str) -> &'a str {
    h.get(name).and_then(|v| v.to_str().ok()).unwrap_or("")
}

#[derive(Deserialize)]
struct Event {
    #[serde(rename = "type")]
    kind: String,
    #[serde(default)]
    data: EventData,
}

#[derive(Deserialize, Default)]
#[serde(rename_all = "camelCase")]
struct EventData {
    payment_id: Option<String>,
}

async fn portone(State(s): State<AppState>, headers: HeaderMap, body: Bytes) -> ApiResult<Json<Value>> {
    let secret = s
        .config
        .portone
        .webhook_secret
        .as_deref()
        .ok_or(ApiError::Unavailable("provider_not_configured"))?;
    verify_webhook(
        secret,
        header(&headers, "webhook-id"),
        header(&headers, "webhook-timestamp"),
        header(&headers, "webhook-signature"),
        &body,
        Utc::now().timestamp(),
    )
    .map_err(|e: WebhookError| {
        tracing::warn!(error = ?e, "portone webhook rejected");
        ApiError::Unauthorized
    })?;
    let event: Event = serde_json::from_slice(&body).map_err(|_| ApiError::BadRequest("invalid_event"))?;
    // Only virtual-account deposits are recovered here; card payments without a confirm call are not (see checkouts.rs).
    if event.kind == "Transaction.Paid"
        && let Some(payment_id) = event.data.payment_id
        && let Some(ck) = find_awaiting(&s.db, &payment_id).await?
    {
        match settle(&s, &ck, &payment_id).await {
            Ok(_) => {}
            // Retry later: PortOne re-sends on a 5xx.
            Err(e @ (ApiError::Db(_) | ApiError::Internal(_))) => return Err(e),
            // Business refusals (slot full, amount mismatch) are handled and refunded inside settle.
            Err(e) => tracing::warn!(error = %e, checkout = %ck.id, "portone deposit not fulfilled"),
        }
    }
    Ok(Json(json!({ "ok": true })))
}
