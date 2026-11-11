//! PortOne V2 현금영수증 calls. Shapes follow `@portone/server-sdk` 0.19.0 (`IssueCashReceiptBody`,
//! `IssueCashReceiptCustomerInput`, `CashReceiptClient.cancelCashReceiptByPaymentId`).
//! SANDBOX-VERIFY: the success envelope (`cashReceipt.status == "ISSUED"`) and the error bodies are taken from
//! the typings, not from a live store. Gated by `PORTONE_CASH_RECEIPTS` (off by default).

use super::ProviderError;
use reqwest::{StatusCode, header::AUTHORIZATION};
use serde::Serialize;
use serde_json::Value;

const API: &str = "https://api.portone.io";
/// PortOne `Currency` value for won (SDK `Currency`; SANDBOX-VERIFY).
const CURRENCY_KRW: &str = "KRW";

/// `IssueCashReceiptBody`. `type` is `PERSONAL` (소득공제용) or `CORPORATE` (지출증빙용).
#[derive(Debug, Clone, Serialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct IssueBody {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub store_id: Option<String>,
    pub payment_id: String,
    pub channel_key: String,
    #[serde(rename = "type")]
    pub kind: &'static str,
    pub order_name: String,
    pub currency: &'static str,
    pub amount: Amount,
    pub customer: Customer,
}

/// `PaymentAmountInput`. Only `total` is sent: PortOne derives VAT as 1/11 of the taxable amount.
/// ACCOUNTANT: confirm the derived VAT matches the invoiced service (no tax-free portion).
#[derive(Debug, Clone, Serialize, PartialEq, Eq)]
pub struct Amount {
    pub total: i64,
}

/// `IssueCashReceiptCustomerInput`. `identityNumberType` is `PHONE` or `BUSINESS`.
#[derive(Debug, Clone, Serialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct Customer {
    pub identity_number: String,
    pub identity_number_type: &'static str,
}

/// An issued receipt: the number shown on the customer's receipt and its viewing link.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Issued {
    pub issue_number: String,
    pub url: Option<String>,
}

/// Builds the issue request from domain-level choices. Pure.
pub fn issue_body(store_id: Option<String>, payment_id: &str, channel_key: &str, business: bool, identity: &str, total: i64) -> IssueBody {
    IssueBody {
        store_id,
        payment_id: payment_id.to_string(),
        channel_key: channel_key.to_string(),
        kind: if business { "CORPORATE" } else { "PERSONAL" },
        order_name: "청소 서비스".to_string(),
        currency: CURRENCY_KRW,
        amount: Amount { total },
        customer: Customer {
            identity_number: identity.to_string(),
            identity_number_type: if business { "BUSINESS" } else { "PHONE" },
        },
    }
}

/// Reads `cashReceipt` from an issue response. Anything but `ISSUED` is a decline. Pure.
pub fn parse_issue(body: &Value) -> Result<Issued, ProviderError> {
    let receipt = body.get("cashReceipt").ok_or_else(|| ProviderError::Upstream("cash receipt response without cashReceipt".into()))?;
    match receipt.get("status").and_then(Value::as_str) {
        Some("ISSUED") => {
            let issue_number = receipt
                .get("issueNumber")
                .and_then(Value::as_str)
                .ok_or_else(|| ProviderError::Upstream("issued cash receipt without issueNumber".into()))?;
            Ok(Issued {
                issue_number: issue_number.to_string(),
                url: receipt.get("url").and_then(Value::as_str).map(str::to_string),
            })
        }
        other => Err(ProviderError::Declined(format!("cash receipt status {}", other.unwrap_or("unknown")))),
    }
}

/// Payment ids go into URL paths: plain tokens only.
fn check_id(id: &str) -> Result<(), ProviderError> {
    let ok = !id.is_empty() && id.len() <= 128 && id.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-' || b == b'_');
    if ok { Ok(()) } else { Err(ProviderError::NotFound) }
}

fn upstream(e: reqwest::Error) -> ProviderError {
    ProviderError::Upstream(e.to_string())
}

async fn read(resp: reqwest::Response) -> Result<Value, ProviderError> {
    let status = resp.status();
    if status == StatusCode::NOT_FOUND {
        return Err(ProviderError::NotFound);
    }
    if !status.is_success() {
        return Err(ProviderError::Upstream(format!("status {status}")));
    }
    resp.json().await.map_err(upstream)
}

/// `POST {base}/cash-receipts`. `base` is `https://api.portone.io` in production; tests pass a loopback mock.
pub async fn issue(http: &reqwest::Client, base: &str, secret: &str, body: &IssueBody) -> Result<Issued, ProviderError> {
    let resp = http
        .post(format!("{base}/cash-receipts"))
        .header(AUTHORIZATION, format!("PortOne {secret}"))
        .json(body)
        .send()
        .await
        .map_err(upstream)?;
    parse_issue(&read(resp).await?)
}

/// `POST {base}/payments/{paymentId}/cash-receipt/cancel`. Cancels the whole receipt; no request body.
pub async fn cancel(http: &reqwest::Client, base: &str, secret: &str, payment_id: &str) -> Result<(), ProviderError> {
    check_id(payment_id)?;
    let resp = http
        .post(format!("{base}/payments/{payment_id}/cash-receipt/cancel"))
        .header(AUTHORIZATION, format!("PortOne {secret}"))
        .send()
        .await
        .map_err(upstream)?;
    read(resp).await.map(|_| ())
}

/// Production base URL for the default helpers in the routes layer.
pub fn api_base() -> &'static str {
    API
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{Router, body::Bytes, extract::State, http::Uri};
    use serde_json::json;
    use std::sync::{Arc, Mutex};

    /// Loopback stand-in for PortOne: records each request (path, JSON body) and replies with `reply`.
    struct Mock {
        seen: Mutex<Vec<(String, Value)>>,
        reply: Value,
    }

    async fn capture(State(m): State<Arc<Mock>>, uri: Uri, body: Bytes) -> axum::Json<Value> {
        let json = serde_json::from_slice(&body).unwrap_or(Value::Null);
        m.seen.lock().unwrap().push((uri.path().to_string(), json));
        axum::Json(m.reply.clone())
    }

    async fn serve(reply: Value) -> (String, Arc<Mock>) {
        let mock = Arc::new(Mock { seen: Mutex::new(Vec::new()), reply });
        let app = Router::new().fallback(capture).with_state(mock.clone());
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        tokio::spawn(async move { axum::serve(listener, app).await.unwrap() });
        (format!("http://{addr}"), mock)
    }

    #[tokio::test]
    async fn issue_sends_typed_body_and_parses_issued_receipt() {
        let reply = json!({ "cashReceipt": { "status": "ISSUED", "issueNumber": "1234567890", "url": "https://example.test/r" } });
        let (base, mock) = serve(reply).await;
        let body = issue_body(None, "pay_1", "ch-1", false, "01012345678", 110_000);
        let issued = issue(&reqwest::Client::new(), &base, "secret", &body).await.unwrap();
        assert_eq!(issued, Issued { issue_number: "1234567890".into(), url: Some("https://example.test/r".into()) });
        let seen = mock.seen.lock().unwrap();
        assert_eq!(seen[0].0, "/cash-receipts");
        assert_eq!(seen[0].1["paymentId"], "pay_1");
        assert_eq!(seen[0].1["channelKey"], "ch-1");
        assert_eq!(seen[0].1["type"], "PERSONAL");
        assert_eq!(seen[0].1["currency"], "KRW");
        assert_eq!(seen[0].1["amount"]["total"], 110_000);
        assert_eq!(seen[0].1["customer"]["identityNumber"], "01012345678");
        assert_eq!(seen[0].1["customer"]["identityNumberType"], "PHONE");
        assert!(seen[0].1.get("storeId").is_none(), "storeId omitted when unset");
    }

    #[tokio::test]
    async fn corporate_request_uses_business_number_and_store_id() {
        let reply = json!({ "cashReceipt": { "status": "ISSUED", "issueNumber": "9" } });
        let (base, mock) = serve(reply).await;
        let body = issue_body(Some("store-1".into()), "pay_2", "ch-2", true, "2208162517", 50_000);
        issue(&reqwest::Client::new(), &base, "s", &body).await.unwrap();
        let seen = mock.seen.lock().unwrap();
        assert_eq!(seen[0].1["type"], "CORPORATE");
        assert_eq!(seen[0].1["storeId"], "store-1");
        assert_eq!(seen[0].1["customer"]["identityNumberType"], "BUSINESS");
    }

    #[tokio::test]
    async fn cancel_posts_to_the_cancel_path() {
        let (base, mock) = serve(json!({ "cancelledAmount": 110000, "cancelledAt": "2026-11-11T00:00:00Z" })).await;
        cancel(&reqwest::Client::new(), &base, "s", "pay_3").await.unwrap();
        assert_eq!(mock.seen.lock().unwrap()[0].0, "/payments/pay_3/cash-receipt/cancel");
    }

    #[test]
    fn non_issued_status_is_a_decline() {
        let err = parse_issue(&json!({ "cashReceipt": { "status": "FAILED" } })).unwrap_err();
        assert!(matches!(err, ProviderError::Declined(_)));
        assert!(parse_issue(&json!({})).is_err());
    }

    #[test]
    fn payment_ids_with_path_characters_are_refused() {
        assert!(check_id("../etc").is_err());
        assert!(check_id("pay_ok-1").is_ok());
    }
}
