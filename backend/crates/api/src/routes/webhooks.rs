//! Provider callbacks. The Standard Webhooks signature is the gate. Without a configured
//! secret only dev mode accepts unsigned events (smoke tests); production refuses them.
//! Events never move money on their own: the payment is re-read from the provider.

use super::checkouts::{CheckoutRow, find_by_id, find_by_payment, settle};
use crate::{
    error::{ApiError, ApiResult},
    providers::portone::{self, WebhookError, verify_webhook},
    state::AppState,
};
use axum::{Json, Router, body::Bytes, extract::State, http::HeaderMap, routing::post};
use chrono::Utc;
use serde::Deserialize;
use serde_json::{Value, json};

const PAYMENT_EVENTS: [&str; 3] = ["Transaction.Paid", "Transaction.VirtualAccountIssued", "Transaction.Cancelled"];

pub fn routes() -> Router<AppState> {
    Router::new().route("/webhooks/portone", post(portone))
}

fn header<'a>(h: &'a HeaderMap, name: &str) -> &'a str {
    h.get(name).and_then(|v| v.to_str().ok()).unwrap_or("")
}

#[derive(Debug, PartialEq, Eq)]
pub enum WebhookAuth {
    /// A secret is configured: the signature must verify.
    Verify,
    /// No secret, dev mode: accept unsigned events.
    UnsignedDev,
    /// No secret, not dev mode: refuse everything.
    Unavailable,
}

/// The signature rule, as a pure decision. A configured secret always wins, so dev mode
/// never bypasses a real secret.
pub fn webhook_auth(dev_mode: bool, secret: Option<&str>) -> WebhookAuth {
    match (secret, dev_mode) {
        (Some(_), _) => WebhookAuth::Verify,
        (None, true) => WebhookAuth::UnsignedDev,
        (None, false) => WebhookAuth::Unavailable,
    }
}

/// Events that can change a checkout's payment state.
pub fn is_payment_event(kind: &str) -> bool {
    PAYMENT_EVENTS.contains(&kind)
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
    let secret = s.config.portone.webhook_secret.as_deref();
    match (webhook_auth(s.config.dev_mode, secret), secret) {
        (WebhookAuth::Verify, Some(secret)) => {
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
        }
        (WebhookAuth::UnsignedDev, _) => {
            tracing::warn!("unsigned portone webhook accepted: DEV_MODE without PORTONE_WEBHOOK_SECRET");
        }
        _ => return Err(ApiError::Unavailable("provider_not_configured")),
    }
    let event: Event = serde_json::from_slice(&body).map_err(|_| ApiError::BadRequest("invalid_event"))?;
    if is_payment_event(&event.kind)
        && let Some(payment_id) = event.data.payment_id
    {
        handle_payment(&s, &payment_id).await?;
    }
    Ok(Json(json!({ "ok": true })))
}

/// Settles the checkout a payment event is about. Unknown payments are acknowledged and ignored.
async fn handle_payment(s: &AppState, payment_id: &str) -> ApiResult<()> {
    let Some(ck) = locate(s, payment_id).await? else {
        tracing::info!(payment_id, "portone event for an unknown checkout");
        return Ok(());
    };
    match settle(s, &ck, payment_id).await {
        Ok(_) => Ok(()),
        // Retry later: PortOne re-sends on a 5xx.
        Err(e @ (ApiError::Db(_) | ApiError::Internal(_) | ApiError::Unavailable(_))) => Err(e),
        // Business refusals (slot full, amount mismatch, not paid yet) are handled inside settle.
        Err(e) => {
            tracing::warn!(error = %e, checkout = %ck.id, "portone payment not fulfilled");
            Ok(())
        }
    }
}

/// By checkout id or stored payment id first; then by the `checkoutId` the payment was created with.
async fn locate(s: &AppState, payment_id: &str) -> ApiResult<Option<CheckoutRow>> {
    if let Some(ck) = find_by_payment(&s.db, payment_id).await? {
        return Ok(Some(ck));
    }
    match portone::custom_checkout_id(&s.providers, payment_id).await? {
        Some(checkout) => find_by_id(&s.db, checkout).await,
        None => Ok(None),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn signature_gate_truth_table() {
        assert_eq!(webhook_auth(true, Some("whsec_x")), WebhookAuth::Verify);
        assert_eq!(webhook_auth(false, Some("whsec_x")), WebhookAuth::Verify);
        assert_eq!(webhook_auth(true, None), WebhookAuth::UnsignedDev);
        assert_eq!(webhook_auth(false, None), WebhookAuth::Unavailable);
    }

    #[test]
    fn only_payment_state_events_are_handled() {
        assert!(is_payment_event("Transaction.Paid"));
        assert!(is_payment_event("Transaction.VirtualAccountIssued"));
        assert!(is_payment_event("Transaction.Cancelled"));
        assert!(!is_payment_event("Transaction.Ready"));
        assert!(!is_payment_event("BillingKey.Issued"));
        assert!(!is_payment_event(""));
    }
}
