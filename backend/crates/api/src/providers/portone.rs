//! PortOne V2 adapter: payments, identity verification, cancellations and
//! Standard Webhooks signatures. Dev fakes only answer `dev:` ids.

use super::{IdentityInfo, PaymentInfo, ProviderError, Providers};
use crate::config::PortOne;
use base64::{Engine, engine::general_purpose::STANDARD};
use hmac::{Hmac, Mac};
use reqwest::{StatusCode, header::AUTHORIZATION};
use serde_json::{Value, json};
use sha2::Sha256;
use subtle::ConstantTimeEq;
use uuid::Uuid;

const API: &str = "https://api.portone.io";
const WEBHOOK_TOLERANCE_SECS: i64 = 300;

fn auth(p: &Providers) -> Result<String, ProviderError> {
    let integ = p.integ();
    let secret = integ.portone.api_secret.as_deref().ok_or(ProviderError::NotConfigured("portone"))?;
    Ok(format!("PortOne {secret}"))
}

/// Setup-wizard check: looks up a payment that cannot exist. 404 means the secret was accepted.
pub async fn check(http: &reqwest::Client, secret: &str) -> Result<StatusCode, ProviderError> {
    http.get(format!("{API}/payments/malkkeum-setup-check"))
        .header(AUTHORIZATION, format!("PortOne {secret}"))
        .send()
        .await
        .map(|r| r.status())
        .map_err(upstream)
}

/// Ids are put into URL paths: only plain tokens, so no traversal or query injection.
fn check_id(id: &str) -> Result<(), ProviderError> {
    let ok = !id.is_empty() && id.len() <= 128 && id.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-' || b == b'_');
    if ok { Ok(()) } else { Err(ProviderError::NotFound) }
}

fn upstream(e: reqwest::Error) -> ProviderError {
    ProviderError::Upstream(e.to_string())
}

fn text(v: &Value) -> String {
    v.as_str().unwrap_or_default().to_string()
}

async fn read_json(resp: reqwest::Response) -> Result<Value, ProviderError> {
    let status = resp.status();
    if status == StatusCode::NOT_FOUND {
        return Err(ProviderError::NotFound);
    }
    if !status.is_success() {
        return Err(ProviderError::Upstream(format!("status {status}")));
    }
    resp.json().await.map_err(upstream)
}

async fn get_json(p: &Providers, path: &str) -> Result<Value, ProviderError> {
    let resp = p
        .http()
        .get(format!("{API}{path}"))
        .header(AUTHORIZATION, auth(p)?)
        .send()
        .await
        .map_err(upstream)?;
    read_json(resp).await
}

pub async fn payment(p: &Providers, id: &str) -> Result<PaymentInfo, ProviderError> {
    check_id(id)?;
    let v = get_json(p, &format!("/payments/{id}")).await?;
    Ok(PaymentInfo {
        status: text(&v["status"]),
        // Missing amount reads as -1, which never matches a checkout: the payment gets refunded.
        total: v["amount"]["total"].as_i64().unwrap_or(-1),
        currency: text(&v["currency"]),
        method: v["method"].clone(),
    })
}

/// Full or partial cancellation of a PAID payment (used for refunds).
pub async fn cancel(p: &Providers, id: &str, amount: i64) -> Result<(), ProviderError> {
    check_id(id)?;
    let resp = p
        .http()
        .post(format!("{API}/payments/{id}/cancel"))
        .header(AUTHORIZATION, auth(p)?)
        .json(&json!({ "amount": amount, "reason": "booking refund" }))
        .send()
        .await
        .map_err(upstream)?;
    read_json(resp).await.map(|_| ())
}

pub async fn identity(p: &Providers, id: &str) -> Result<IdentityInfo, ProviderError> {
    check_id(id)?;
    let v = get_json(p, &format!("/identity-verifications/{id}")).await?;
    let customer = &v["verifiedCustomer"];
    Ok(IdentityInfo {
        id: text(&v["id"]),
        status: text(&v["status"]),
        ci: customer["ci"].as_str().map(str::to_string),
        name: customer["name"].as_str().map(str::to_string),
    })
}

/// The checkout id a payment was created with, from its `customData` (object, or JSON text).
/// Dev mode has no provider to ask, so it answers `None`.
pub async fn custom_checkout_id(p: &Providers, id: &str) -> Result<Option<Uuid>, ProviderError> {
    if p.cfg().dev_mode {
        return Ok(None);
    }
    check_id(id)?;
    match get_json(p, &format!("/payments/{id}")).await {
        Ok(v) => Ok(custom_data_checkout_id(&v["customData"])),
        Err(ProviderError::NotFound) => Ok(None),
        Err(e) => Err(e),
    }
}

fn custom_data_checkout_id(custom: &Value) -> Option<Uuid> {
    let parsed_text: Value;
    let obj: &Value = match custom.as_str() {
        Some(raw) => {
            parsed_text = serde_json::from_str(raw).ok()?;
            &parsed_text
        }
        None => custom,
    };
    Uuid::parse_str(obj["checkoutId"].as_str()?).ok()
}

/// Billing (saved card) needs the API secret, the store and a card channel key.
pub fn billing_ready(p: &PortOne) -> bool {
    p.api_secret.is_some() && p.store_id.is_some() && p.channel_keys.contains_key("card")
}

/// Verifies a billing key the browser SDK issued before we store it. The key must be `ISSUED` and bound to
/// this customer and this issue ticket (see [`bound`]). The card details are not kept: we store the key only.
pub async fn verify_billing_key(p: &Providers, key: &str, customer: &str, issue: &str) -> Result<(), ProviderError> {
    let integ = p.integ();
    let secret = integ.portone.api_secret.as_deref().ok_or(ProviderError::NotConfigured("portone"))?;
    if check_id(key).is_err() {
        return Err(ProviderError::Declined("invalid_billing_key".into()));
    }
    let info = billing_key_at(p.http(), API, secret, key).await?;
    bound(&info, customer, issue)
}

/// Binds a key to the customer and ticket it was issued for. Missing fields fail closed.
/// shortcut: `customer.id` and `issueId` on GET /billing-keys/{key} are not on the reference pages we could
/// reach (only `status` and `billingKey` are confirmed). Verify both in a PortOne test store before enabling billing.
pub fn bound(info: &Value, customer: &str, issue: &str) -> Result<(), ProviderError> {
    issued(info)?;
    if info["customer"]["id"].as_str() == Some(customer) && info["issueId"].as_str() == Some(issue) {
        Ok(())
    } else {
        Err(ProviderError::Declined("billing_key_not_bound".into()))
    }
}

/// `GET {base}/billing-keys/{key}` with the API secret. `base` is `API` in production, a fake in tests.
/// Source: https://developers.portone.io/api/rest-v2/payment.billingKey (BillingKeyStatus: ISSUED | DELETED).
pub async fn billing_key_at(http: &reqwest::Client, base: &str, secret: &str, key: &str) -> Result<Value, ProviderError> {
    let resp = http
        .get(format!("{base}/billing-keys/{key}"))
        .header(AUTHORIZATION, format!("PortOne {secret}"))
        .send()
        .await
        .map_err(upstream)?;
    read_json(resp).await
}

/// `DELETE /billing-keys/{key}`: stops the saved card at the gateway. A key already gone (404) counts as deleted.
/// Source: https://developers.portone.io/api/rest-v2/payment.billingKey (verify the delete path against the live docs).
pub async fn delete_billing_key(p: &Providers, key: &str) -> Result<(), ProviderError> {
    check_id(key)?;
    let resp = p
        .http()
        .delete(format!("{API}/billing-keys/{key}"))
        .header(AUTHORIZATION, auth(p)?)
        .send()
        .await
        .map_err(upstream)?;
    match resp.status() {
        StatusCode::NOT_FOUND => Ok(()),
        s if s.is_success() => Ok(()),
        s => Err(ProviderError::Upstream(format!("status {s}"))),
    }
}

fn issued(info: &Value) -> Result<(), ProviderError> {
    match info["status"].as_str() {
        Some("ISSUED") => Ok(()),
        _ => Err(ProviderError::Declined("billing_key_not_issued".into())),
    }
}

/// Dev fakes: `dev:paid` settles at the expected total, `dev:va` issues a virtual account,
/// and a checkout id pays as a card payment (the dev gateway has no real payer).
pub fn dev_payment(id: &str, total: i64) -> Option<PaymentInfo> {
    let (status, method) = match id {
        "dev:paid" => ("PAID", json!({ "type": "PaymentMethodEasyPay" })),
        "dev:va" => (
            "VIRTUAL_ACCOUNT_ISSUED",
            json!({ "type": "PaymentMethodVirtualAccount", "bank": "KB", "accountNumber": "123-456-789012" }),
        ),
        "dev:failed" => ("FAILED", json!({})),
        _ if Uuid::parse_str(id).is_ok() => ("PAID", json!({ "type": "PaymentMethodCard" })),
        _ => return None,
    };
    Some(PaymentInfo {
        status: status.into(),
        total,
        currency: "KRW".into(),
        method,
    })
}

pub fn dev_identity(id: &str) -> Option<IdentityInfo> {
    let rest = id.strip_prefix("dev:").filter(|r| !r.is_empty())?;
    Some(IdentityInfo {
        id: id.to_string(),
        status: "VERIFIED".into(),
        ci: Some(format!("dev-ci:{rest}")),
        name: None,
    })
}

#[derive(Debug, PartialEq, Eq)]
pub enum WebhookError {
    Malformed,
    Stale,
    BadSignature,
}

/// Standard Webhooks check: HMAC-SHA256 over `<id>.<timestamp>.<body>` keyed with the
/// base64 part of `whsec_...`. The header may carry several `v1,` signatures during rotation.
pub fn verify_webhook(secret: &str, msg_id: &str, timestamp: &str, signatures: &str, body: &[u8], now: i64) -> Result<(), WebhookError> {
    let ts: i64 = timestamp.parse().map_err(|_| WebhookError::Malformed)?;
    if (now - ts).abs() > WEBHOOK_TOLERANCE_SECS {
        return Err(WebhookError::Stale);
    }
    let raw = secret.strip_prefix("whsec_").ok_or(WebhookError::Malformed)?;
    let key = STANDARD.decode(raw).map_err(|_| WebhookError::Malformed)?;
    let mut mac = Hmac::<Sha256>::new_from_slice(&key).map_err(|_| WebhookError::Malformed)?;
    mac.update(format!("{msg_id}.{timestamp}.").as_bytes());
    mac.update(body);
    let expected = STANDARD.encode(mac.finalize().into_bytes());
    let valid = signatures
        .split(' ')
        .filter_map(|s| s.strip_prefix("v1,"))
        .any(|s| bool::from(s.as_bytes().ct_eq(expected.as_bytes())));
    if valid { Ok(()) } else { Err(WebhookError::BadSignature) }
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{Json, Router, extract::Path, http::{HeaderMap, StatusCode}, routing::get};

    const NOW: i64 = 1_800_000_000;

    fn secret() -> String {
        format!("whsec_{}", STANDARD.encode(b"0123456789abcdef0123456789abcdef"))
    }

    fn sign(secret: &str, id: &str, ts: i64, body: &[u8]) -> String {
        let key = STANDARD.decode(secret.trim_start_matches("whsec_")).expect("test key");
        let mut mac = Hmac::<Sha256>::new_from_slice(&key).expect("test key length");
        mac.update(format!("{id}.{ts}.").as_bytes());
        mac.update(body);
        format!("v1,{}", STANDARD.encode(mac.finalize().into_bytes()))
    }

    #[test]
    fn valid_signature_passes() {
        let body = br#"{"type":"Transaction.Paid"}"#;
        let sig = sign(&secret(), "msg_1", NOW, body);
        assert_eq!(verify_webhook(&secret(), "msg_1", &NOW.to_string(), &sig, body, NOW), Ok(()));
    }

    #[test]
    fn tampered_body_is_rejected() {
        let sig = sign(&secret(), "msg_1", NOW, b"{\"amount\":1}");
        let r = verify_webhook(&secret(), "msg_1", &NOW.to_string(), &sig, b"{\"amount\":9}", NOW);
        assert_eq!(r, Err(WebhookError::BadSignature));
    }

    #[test]
    fn stale_timestamp_is_rejected_both_ways() {
        let body = b"{}";
        let old = sign(&secret(), "m", NOW - 301, body);
        assert_eq!(
            verify_webhook(&secret(), "m", &(NOW - 301).to_string(), &old, body, NOW),
            Err(WebhookError::Stale)
        );
        let future = sign(&secret(), "m", NOW + 301, body);
        assert_eq!(
            verify_webhook(&secret(), "m", &(NOW + 301).to_string(), &future, body, NOW),
            Err(WebhookError::Stale)
        );
        let edge = sign(&secret(), "m", NOW - 300, body);
        assert_eq!(verify_webhook(&secret(), "m", &(NOW - 300).to_string(), &edge, body, NOW), Ok(()));
    }

    #[test]
    fn wrong_key_and_malformed_inputs_are_rejected() {
        let body = b"{}";
        let other = format!("whsec_{}", STANDARD.encode(b"another-key-another-key-another!"));
        let sig = sign(&other, "m", NOW, body);
        assert_eq!(
            verify_webhook(&secret(), "m", &NOW.to_string(), &sig, body, NOW),
            Err(WebhookError::BadSignature)
        );
        assert_eq!(verify_webhook(&secret(), "m", "soon", &sig, body, NOW), Err(WebhookError::Malformed));
        assert_eq!(verify_webhook("nope", "m", &NOW.to_string(), &sig, body, NOW), Err(WebhookError::Malformed));
    }

    #[test]
    fn rotated_signature_list_accepts_any_valid_entry() {
        let body = b"{}";
        let good = sign(&secret(), "m", NOW, body);
        let header = format!("v1,bogusbogus {good}");
        assert_eq!(verify_webhook(&secret(), "m", &NOW.to_string(), &header, body, NOW), Ok(()));
    }

    #[test]
    fn provider_ids_cannot_escape_the_url_path() {
        assert!(check_id("payment-abc_123").is_ok());
        assert!(check_id("../identity").is_err());
        assert!(check_id("x?y=1").is_err());
        assert!(check_id("").is_err());
    }

    #[test]
    fn custom_data_checkout_id_reads_object_and_json_text() {
        let id = Uuid::now_v7();
        let object = json!({ "checkoutId": id.to_string() });
        assert_eq!(custom_data_checkout_id(&object), Some(id));
        let text = Value::String(object.to_string());
        assert_eq!(custom_data_checkout_id(&text), Some(id));
        assert_eq!(custom_data_checkout_id(&json!({ "checkoutId": "not-a-uuid" })), None);
        assert_eq!(custom_data_checkout_id(&Value::String("{broken".into())), None);
        assert_eq!(custom_data_checkout_id(&Value::Null), None);
    }

    #[test]
    fn billing_needs_secret_store_and_card_channel() {
        let mut p = PortOne { api_secret: Some("s".into()), store_id: Some("st".into()), ..Default::default() };
        assert!(!billing_ready(&p));
        p.channel_keys.insert("card".into(), "ch".into());
        assert!(billing_ready(&p));
        p.api_secret = None;
        assert!(!billing_ready(&p));
    }

    /// Fake PortOne: checks the secret header and answers per billing key.
    async fn fake_billing(Path(key): Path<String>, headers: HeaderMap) -> (StatusCode, Json<Value>) {
        if headers.get(AUTHORIZATION).and_then(|v| v.to_str().ok()) != Some("PortOne test-secret") {
            return (StatusCode::UNAUTHORIZED, Json(json!({"type": "UnauthorizedError"})));
        }
        match key.as_str() {
            "bk_ok" => (StatusCode::OK, Json(json!({"status": "ISSUED", "billingKey": "bk_ok"}))),
            "bk_gone" => (StatusCode::OK, Json(json!({"status": "DELETED", "billingKey": "bk_gone"}))),
            _ => (StatusCode::NOT_FOUND, Json(json!({"type": "BillingKeyNotFoundError"}))),
        }
    }

    async fn billing_fake() -> String {
        let app = Router::new().route("/billing-keys/{key}", get(fake_billing));
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.expect("bind fake");
        let addr = listener.local_addr().expect("fake addr");
        tokio::spawn(async move { axum::serve(listener, app).await.expect("fake serves") });
        format!("http://{addr}")
    }

    #[tokio::test]
    async fn only_issued_billing_keys_pass_verification() {
        let base = billing_fake().await;
        let http = reqwest::Client::new();
        let ok = billing_key_at(&http, &base, "test-secret", "bk_ok").await.expect("issued");
        assert!(issued(&ok).is_ok());
        let gone = billing_key_at(&http, &base, "test-secret", "bk_gone").await.expect("deleted body");
        assert!(matches!(issued(&gone), Err(ProviderError::Declined(ref m)) if m == "billing_key_not_issued"));
        assert!(matches!(billing_key_at(&http, &base, "test-secret", "bk_none").await, Err(ProviderError::NotFound)));
        assert!(matches!(billing_key_at(&http, &base, "wrong", "bk_ok").await, Err(ProviderError::Upstream(_))));
    }

    #[test]
    fn billing_key_must_be_bound_to_customer_and_ticket() {
        let info = json!({"status": "ISSUED", "billingKey": "bk", "issueId": "t1", "customer": {"id": "u1"}});
        assert!(bound(&info, "u1", "t1").is_ok());
        assert!(matches!(bound(&info, "u2", "t1"), Err(ProviderError::Declined(m)) if m == "billing_key_not_bound"));
        assert!(matches!(bound(&info, "u1", "t2"), Err(ProviderError::Declined(m)) if m == "billing_key_not_bound"));
        let no_fields = json!({"status": "ISSUED", "billingKey": "bk"});
        assert!(bound(&no_fields, "u1", "t1").is_err());
        let deleted = json!({"status": "DELETED", "issueId": "t1", "customer": {"id": "u1"}});
        assert!(matches!(bound(&deleted, "u1", "t1"), Err(ProviderError::Declined(m)) if m == "billing_key_not_issued"));
    }

    #[test]
    fn dev_gateway_pays_checkout_ids_and_keeps_fakes() {
        let id = Uuid::now_v7().to_string();
        assert_eq!(dev_payment(&id, 52_000).map(|p| (p.status, p.total)), Some(("PAID".into(), 52_000)));
        assert_eq!(dev_payment("dev:paid", 1).map(|p| p.status), Some("PAID".into()));
        assert_eq!(dev_payment("dev:va", 1).map(|p| p.status), Some("VIRTUAL_ACCOUNT_ISSUED".into()));
        assert!(dev_payment("random-string", 1).is_none());
    }
}
