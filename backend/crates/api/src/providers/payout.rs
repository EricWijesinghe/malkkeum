//! Partner payout transfers. Two adapters behind one interface:
//! - `manual` (default): nothing is sent. The owner transfers from the bank app and confirms.
//! - `toss`: Toss Payments 지급대행 (payouts API). Status is polled; there is no webhook here.
//!
//! shortcut: Toss payouts are NOT enabled end to end. Verified against docs.tosspayments.com (see
//! constants): endpoint paths, status enum, lookup by Toss payout id, bank codes. Still missing:
//! (1) seller registration (`POST /v2/sellers`) so each payout carries a `destination` seller id,
//! (2) JWE body encryption (`TossPayments-api-security-mode: ENCRYPTION`, A256GCM, secret key) for
//! requests and responses, (3) the create-payout body schema, `amount` shape not on any reachable
//! page, (4) payout.changed webhook signature scheme. Until those land, keep payout mode `manual`
//! (see docs/DEPLOY.md). Upgrade when a sandbox payout succeeds end to end.

use super::ProviderError;
use base64::{Engine, engine::general_purpose::STANDARD};
use reqwest::{Client, Request, StatusCode, header::AUTHORIZATION};
use serde_json::{Value, json};

// Source: https://docs.tosspayments.com/guides/v2/payouts and https://docs.tosspayments.com/reference/additional
// (endpoint table: POST /v2/payouts, GET /v2/payouts/{id}; "Payout" object fields: id, refPayoutId, status, error).
const TOSS_API: &str = "https://api.tosspayments.com";
const TOSS_PAYOUTS: &str = "/v2/payouts";
/// Toss caps `transactionDescription` at 7 characters (reference/additional, request parameters).
const TOSS_DESCRIPTION_MAX: usize = 7;

/// One transfer to a pro's bank account. `amount` is whole won.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Transfer {
    pub amount: i64,
    pub bank_code: &'static str,
    pub account: String,
    pub holder: String,
    pub memo: String,
}

/// Provider's answer about a transfer we already sent.
#[derive(Debug, PartialEq, Eq)]
pub enum TransferStatus {
    Pending,
    Paid,
    Failed(String),
}

/// Korean bank name (as the pro typed it) -> the bank code the payout API wants.
pub fn bank_code(name: &str) -> Option<&'static str> {
    const BANKS: &[(&str, &[&str])] = &[
        ("002", &["산업", "KDB"]),
        ("003", &["기업", "IBK"]),
        ("004", &["국민", "KB"]),
        ("007", &["수협"]),
        ("011", &["농협", "NH"]),
        ("020", &["우리"]),
        ("023", &["SC", "제일"]),
        ("031", &["대구"]),
        ("032", &["부산"]),
        ("034", &["광주"]),
        ("035", &["제주"]),
        ("037", &["전북"]),
        ("039", &["경남"]),
        ("071", &["우체국"]),
        ("081", &["하나"]),
        ("088", &["신한"]),
        ("089", &["케이뱅크", "K뱅크"]),
        ("090", &["카카오뱅크", "카카오"]),
        ("092", &["토스뱅크"]),
    ];
    let name = name.replace(' ', "");
    BANKS.iter().find(|(_, aliases)| aliases.iter().any(|a| name.contains(a))).map(|(code, _)| *code)
}

/// Body fields Toss documents for a payout: refPayoutId, amount, transactionDescription (plus
/// destination, scheduleType, payoutDate, still missing: see the module shortcut). Bank fields
/// are kept only so the existing `Transfer` shape stays in use; they belong to seller registration.
fn body(ref_id: &str, t: &Transfer) -> Value {
    let description: String = t.memo.chars().take(TOSS_DESCRIPTION_MAX).collect();
    json!({
        "refPayoutId": ref_id,
        "amount": t.amount,
        "bankCode": t.bank_code,
        "accountNumber": t.account,
        "holderName": t.holder,
        "transactionDescription": description,
    })
}

/// Builds the create-transfer request. Pure, so tests inspect headers and body without a network call.
pub fn send_request(http: &Client, secret: &str, idempotency_key: &str, ref_id: &str, t: &Transfer) -> Result<Request, ProviderError> {
    http.post(format!("{TOSS_API}{TOSS_PAYOUTS}"))
        .header(AUTHORIZATION, basic(secret))
        .header("Idempotency-Key", idempotency_key)
        .json(&body(ref_id, t))
        .build()
        .map_err(|e| ProviderError::Upstream(e.to_string()))
}

/// Builds the status lookup. `GET /v2/payouts/{id}` takes Toss's payout id (the `id` returned on create),
/// not our refPayoutId.
pub fn status_request(http: &Client, secret: &str, provider_id: &str) -> Result<Request, ProviderError> {
    http.get(format!("{TOSS_API}{TOSS_PAYOUTS}/{provider_id}"))
        .header(AUTHORIZATION, basic(secret))
        .build()
        .map_err(|e| ProviderError::Upstream(e.to_string()))
}

fn basic(secret: &str) -> String {
    format!("Basic {}", STANDARD.encode(format!("{secret}:")))
}

/// Maps a provider error response. Only explicit business rejections count as declines (the
/// transfer definitely did not happen). Anything ambiguous (5xx, timeouts, 409 idempotency
/// conflicts, 429) stays an upstream error so the caller never rotates the idempotency key.
pub fn classify(status: StatusCode, body: &Value) -> ProviderError {
    let message = body["message"].as_str().unwrap_or("transfer rejected").to_string();
    let definite = status.is_client_error() && !matches!(status, StatusCode::CONFLICT | StatusCode::TOO_MANY_REQUESTS | StatusCode::REQUEST_TIMEOUT);
    if definite { ProviderError::Declined(message) } else { ProviderError::Upstream(format!("status {status}")) }
}

/// Reads Toss's payout id (`id` on the Payout object) of an accepted transfer.
pub fn parse_sent(body: &Value) -> Result<String, ProviderError> {
    body["id"].as_str().filter(|s| !s.is_empty()).map(String::from).ok_or_else(|| ProviderError::Upstream("missing payout id".into()))
}

/// Payout `status` enum from the guide: REQUESTED, IN_PROGRESS, COMPLETED, FAILED, CANCELED, DELETED, REJECTED.
/// REJECTED is delivered as FAILED on webhooks, so both count as failed. `error` holds the reason.
pub fn parse_status(body: &Value) -> TransferStatus {
    let reason = || body["error"]["message"].as_str().or_else(|| body["error"].as_str()).unwrap_or("transfer failed").to_string();
    match body["status"].as_str() {
        Some("COMPLETED") => TransferStatus::Paid,
        Some("FAILED" | "REJECTED") => TransferStatus::Failed(reason()),
        Some("CANCELED" | "DELETED") => TransferStatus::Failed("canceled".into()),
        _ => TransferStatus::Pending,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn transfer() -> Transfer {
        Transfer { amount: 120_000, bank_code: "004", account: "12345678901".into(), holder: "홍길동".into(), memo: "말끔 정산".into() }
    }

    #[test]
    fn send_request_carries_key_auth_and_integer_won() {
        let http = Client::new();
        let req = send_request(&http, "test_sk_abc", "idem-1", "payout-1", &transfer()).unwrap();
        assert_eq!(req.method().as_str(), "POST");
        assert_eq!(req.url().as_str(), "https://api.tosspayments.com/v2/payouts");
        assert_eq!(req.headers()["Idempotency-Key"], "idem-1");
        assert_eq!(req.headers()[AUTHORIZATION], format!("Basic {}", STANDARD.encode("test_sk_abc:")));
        let sent: Value = serde_json::from_slice(req.body().and_then(|b| b.as_bytes()).unwrap()).unwrap();
        assert_eq!(sent["amount"], json!(120_000));
        assert_eq!(sent["refPayoutId"], "payout-1");
        assert_eq!(sent["bankCode"], "004");
    }

    #[test]
    fn status_request_is_a_get_on_the_reference_id() {
        let req = status_request(&Client::new(), "k", "payout-9").unwrap();
        assert_eq!(req.method().as_str(), "GET");
        assert_eq!(req.url().path(), "/v2/payouts/payout-9");
    }

    #[test]
    fn bank_names_map_to_codes() {
        assert_eq!(bank_code("국민은행"), Some("004"));
        assert_eq!(bank_code("카카오뱅크"), Some("090"));
        assert_eq!(bank_code("신 한 은행"), Some("088"));
        assert_eq!(bank_code("없는은행"), None);
    }

    #[test]
    fn only_definite_rejections_are_declines() {
        assert!(matches!(classify(StatusCode::BAD_REQUEST, &json!({"message": "계좌 오류"})), ProviderError::Declined(m) if m == "계좌 오류"));
        assert!(matches!(classify(StatusCode::CONFLICT, &json!({})), ProviderError::Upstream(_)));
        assert!(matches!(classify(StatusCode::TOO_MANY_REQUESTS, &json!({})), ProviderError::Upstream(_)));
        assert!(matches!(classify(StatusCode::INTERNAL_SERVER_ERROR, &json!({})), ProviderError::Upstream(_)));
    }

    #[test]
    fn parses_sent_and_status_responses() {
        assert_eq!(parse_sent(&json!({"id": "tp_1"})).unwrap(), "tp_1");
        assert!(parse_sent(&json!({"payoutId": "tp_1"})).is_err());
        assert_eq!(parse_status(&json!({"status": "COMPLETED"})), TransferStatus::Paid);
        assert_eq!(parse_status(&json!({"status": "FAILED", "error": {"message": "잔액 부족"}})), TransferStatus::Failed("잔액 부족".into()));
        assert_eq!(parse_status(&json!({"status": "REJECTED", "error": "계좌 오류"})), TransferStatus::Failed("계좌 오류".into()));
        assert_eq!(parse_status(&json!({"status": "CANCELED"})), TransferStatus::Failed("canceled".into()));
        assert_eq!(parse_status(&json!({"status": "IN_PROGRESS"})), TransferStatus::Pending);
        assert_eq!(parse_status(&json!({"status": "REQUESTED"})), TransferStatus::Pending);
    }

    #[test]
    fn status_lookup_uses_provider_id_and_description_is_seven_chars() {
        let req = status_request(&Client::new(), "k", "tp-payout-9").unwrap();
        assert_eq!(req.url().path(), "/v2/payouts/tp-payout-9");
        let mut t = transfer();
        t.memo = "말끔청소정산서비스".into();
        let sent = body("payout-1", &t);
        assert_eq!(sent["transactionDescription"], "말끔청소정산서");
    }
}
