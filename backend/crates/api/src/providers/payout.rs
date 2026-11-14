//! Partner payout transfers. Two adapters behind one interface:
//! - `manual` (default): nothing is sent. The owner transfers from the bank app and confirms.
//! - `toss`: Toss Payments 지급대행 (payouts API). Each pro is registered as a seller first; a payout's
//!   `destination` is that seller id. Request bodies are JWE-encrypted (see `toss_jwe`). Status is polled.
//!
//! Source: https://docs.tosspayments.com/guides/v2/payouts and https://docs.tosspayments.com/reference/additional
//! (seller create `POST /v2/sellers`, payout create `POST /v2/payouts`, lookups `GET /v2/payouts/{id}` and
//! `GET /v2/sellers/{id}`, balance `GET /v2/balances`, cancel `POST /v2/payouts/{id}/cancel`).
//!
//! shortcut: not verified against a live sandbox. Unverified in the docs: the `amount` sub-fields on the
//! request (sent as `{currency, value}`, the shape of the Payout object), the idempotency header name
//! (`Idempotency-Key`), the content type of an encrypted body (`text/plain`), the seller response's
//! `status` field, and the webhook signature scheme (none documented, so webhooks only trigger a poll).
//! Upgrade when a sandbox seller registration and payout round-trip succeed (see docs/DEPLOY.md section 7).

use super::{ProviderError, toss_jwe};
use base64::{Engine, engine::general_purpose::STANDARD};
use reqwest::{Client, Request, StatusCode, header::AUTHORIZATION};
use serde_json::{Value, json};

const TOSS_API: &str = "https://api.tosspayments.com";
const TOSS_PAYOUTS: &str = "/v2/payouts";
const TOSS_SELLERS: &str = "/v2/sellers";
const TOSS_BALANCES: &str = "/v2/balances";
/// Request header that switches a body to JWE (guides/v2/payouts).
pub const SECURITY_MODE: &str = "TossPayments-api-security-mode";
/// Toss caps `transactionDescription` at 7 characters (reference/additional, request parameters).
const TOSS_DESCRIPTION_MAX: usize = 7;
/// Toss requires `refSellerId` to be 7 to 20 characters (reference/additional, seller create).
pub const REF_SELLER_ID_RANGE: std::ops::RangeInclusive<usize> = 7..=20;

/// One transfer to a pro's bank account. `amount` is whole won.
#[derive(Clone, PartialEq, Eq)]
pub struct Transfer {
    pub amount: i64,
    pub bank_code: &'static str,
    pub account: String,
    pub holder: String,
    pub memo: String,
}

/// The account number is redacted: a transfer must never reach logs through `{:?}`.
impl std::fmt::Debug for Transfer {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Transfer")
            .field("amount", &self.amount)
            .field("bank_code", &self.bank_code)
            .field("account", &"<redacted>")
            .field("holder", &"<redacted>")
            .field("memo", &self.memo)
            .finish()
    }
}

/// A pro's registration with Toss. The bank account lives on the seller, not on each transfer.
#[derive(Clone, PartialEq, Eq)]
pub struct SellerDraft {
    pub ref_id: String,
    pub business: Business,
    pub bank_code: &'static str,
    pub account: String,
    pub holder: String,
}

/// Business info Toss needs: a sole individual, or a business (individual or corporate) with a registration number.
#[derive(Clone, PartialEq, Eq)]
pub enum Business {
    Individual {
        name: String,
        email: String,
        phone: String,
    },
    Company {
        name: Option<String>,
        representative: String,
        registration_no: String,
        email: String,
        phone: String,
    },
}

impl std::fmt::Debug for SellerDraft {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("SellerDraft")
            .field("ref_id", &self.ref_id)
            .field("account", &"<redacted>")
            .finish()
    }
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
    BANKS
        .iter()
        .find(|(_, aliases)| aliases.iter().any(|a| name.contains(a)))
        .map(|(code, _)| *code)
}

/// Seller body for `POST /v2/sellers`. Field names follow the reference; required fields per business type.
pub fn seller_body(d: &SellerDraft) -> Value {
    let account = json!({ "bankCode": d.bank_code, "accountNumber": d.account, "holderName": d.holder });
    let mut body = json!({ "refSellerId": d.ref_id, "account": account });
    match &d.business {
        Business::Individual { name, email, phone } => {
            body["businessType"] = json!("INDIVIDUAL");
            body["individual"] = json!({ "name": name, "email": email, "phone": phone });
        }
        Business::Company {
            name,
            representative,
            registration_no,
            email,
            phone,
        } => {
            body["businessType"] = json!("CORPORATE");
            let mut company = json!({
                "representativeName": representative,
                "businessRegistrationNumber": registration_no,
                "email": email,
                "phone": phone,
            });
            if let Some(n) = name {
                company["name"] = json!(n);
            }
            body["company"] = company;
        }
    }
    body
}

/// Body fields Toss documents for a payout (reference/additional). `scheduleType` is EXPRESS (same-day, business
/// hours); SCHEDULED would also need `payoutDate`.
fn payout_body(ref_id: &str, seller_id: &str, t: &Transfer) -> Value {
    let description: String = t.memo.chars().take(TOSS_DESCRIPTION_MAX).collect();
    json!({
        "refPayoutId": ref_id,
        "destination": seller_id,
        "scheduleType": "EXPRESS",
        "amount": { "currency": "KRW", "value": t.amount },
        "transactionDescription": description,
    })
}

/// `POST` with a JWE body, the encryption header, and optional idempotency key.
fn encrypted_post(http: &Client, secret: &str, key: &[u8; 32], path: &str, idempotency: Option<&str>, body: &Value) -> Result<Request, ProviderError> {
    let mut b = http
        .post(format!("{TOSS_API}{path}"))
        .header(AUTHORIZATION, basic(secret))
        .header(SECURITY_MODE, "ENCRYPTION")
        .header(reqwest::header::CONTENT_TYPE, "text/plain")
        .body(toss_jwe::seal(key, body));
    if let Some(k) = idempotency {
        b = b.header("Idempotency-Key", k);
    }
    b.build().map_err(|e| ProviderError::Upstream(e.to_string()))
}

fn plain_get(http: &Client, secret: &str, path: &str) -> Result<Request, ProviderError> {
    http.get(format!("{TOSS_API}{path}"))
        .header(AUTHORIZATION, basic(secret))
        .build()
        .map_err(|e| ProviderError::Upstream(e.to_string()))
}

/// Builds the seller registration request (encrypted).
pub fn seller_request(http: &Client, secret: &str, key: &[u8; 32], d: &SellerDraft) -> Result<Request, ProviderError> {
    encrypted_post(http, secret, key, TOSS_SELLERS, None, &seller_body(d))
}

/// Builds the seller lookup (plain GET, no body to encrypt).
pub fn seller_status_request(http: &Client, secret: &str, seller_id: &str) -> Result<Request, ProviderError> {
    plain_get(http, secret, &format!("{TOSS_SELLERS}/{seller_id}"))
}

/// Builds the payout create request (encrypted). `seller_id` is the Toss seller `id` (the destination).
pub fn send_request(
    http: &Client,
    secret: &str,
    key: &[u8; 32],
    idempotency_key: &str,
    ref_id: &str,
    seller_id: &str,
    t: &Transfer,
) -> Result<Request, ProviderError> {
    encrypted_post(http, secret, key, TOSS_PAYOUTS, Some(idempotency_key), &payout_body(ref_id, seller_id, t))
}

/// Builds the status lookup. `GET /v2/payouts/{id}` takes Toss's payout id (the `id` returned on create),
/// not our refPayoutId.
pub fn status_request(http: &Client, secret: &str, provider_id: &str) -> Result<Request, ProviderError> {
    plain_get(http, secret, &format!("{TOSS_PAYOUTS}/{provider_id}"))
}

/// Builds the balance call used by the console's sandbox connection test. Harmless: reads only.
pub fn balance_request(http: &Client, secret: &str) -> Result<Request, ProviderError> {
    plain_get(http, secret, TOSS_BALANCES)
}

fn basic(secret: &str) -> String {
    format!("Basic {}", STANDARD.encode(format!("{secret}:")))
}

/// Reads a response body. Responses to encrypted requests are JWE; plain ones are JSON.
pub fn read_body(text: &str, key: Option<&[u8; 32]>) -> Result<Value, ProviderError> {
    let trimmed = text.trim();
    if trimmed.is_empty() {
        return Ok(Value::Null);
    }
    if trimmed.starts_with('{') {
        return serde_json::from_str(trimmed).map_err(|_| ProviderError::Upstream("unreadable response".into()));
    }
    let key = key.ok_or_else(|| ProviderError::Upstream("encrypted response without key".into()))?;
    toss_jwe::open(key, trimmed).map_err(|reason| ProviderError::Upstream(format!("response {reason}")))
}

/// Maps a provider error response. Only explicit business rejections count as declines (the
/// transfer definitely did not happen). Anything ambiguous (5xx, timeouts, 409 idempotency
/// conflicts, 429) stays an upstream error so the caller never rotates the idempotency key.
pub fn classify(status: StatusCode, body: &Value) -> ProviderError {
    let message = body["message"].as_str().unwrap_or("transfer rejected").to_string();
    let definite = status.is_client_error() && !matches!(status, StatusCode::CONFLICT | StatusCode::TOO_MANY_REQUESTS | StatusCode::REQUEST_TIMEOUT);
    if definite {
        ProviderError::Declined(message)
    } else {
        ProviderError::Upstream(format!("status {status}"))
    }
}

/// Fingerprint of the account a seller is registered with. Equal fingerprints mean the same bank account.
pub fn account_fingerprint(bank_code: &str, account: &str, holder: &str) -> String {
    use sha2::{Digest, Sha256};
    Sha256::digest(format!("{bank_code}|{account}|{holder}").as_bytes())
        .iter()
        .map(|b| format!("{b:02x}"))
        .collect()
}

/// Reads Toss's payout id (`id` on the Payout object) of an accepted transfer.
pub fn parse_sent(body: &Value) -> Result<String, ProviderError> {
    body["id"]
        .as_str()
        .filter(|s| !s.is_empty())
        .map(String::from)
        .ok_or_else(|| ProviderError::Upstream("missing payout id".into()))
}

/// Reads a seller's Toss id and status (`APPROVAL_REQUIRED`, `PARTIALLY_APPROVED`, `KYC_REQUIRED`, `APPROVED`).
pub fn parse_seller(body: &Value) -> Result<(String, String), ProviderError> {
    let id = body["id"]
        .as_str()
        .filter(|s| !s.is_empty())
        .ok_or_else(|| ProviderError::Upstream("missing seller id".into()))?;
    let status = body["status"].as_str().unwrap_or("UNKNOWN");
    Ok((id.to_string(), status.to_string()))
}

/// Payout `status` enum from the guide: REQUESTED, IN_PROGRESS, COMPLETED, FAILED, CANCELED, DELETED, REJECTED.
/// REJECTED is delivered as FAILED on webhooks, so both count as failed. `error` holds the reason.
pub fn parse_status(body: &Value) -> TransferStatus {
    let reason = || {
        body["error"]["message"]
            .as_str()
            .or_else(|| body["error"].as_str())
            .unwrap_or("transfer failed")
            .to_string()
    };
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
    use crate::providers::toss_jwe::{key_bytes, open, seal};

    const KEY_HEX: &str = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

    fn key() -> [u8; 32] {
        key_bytes(KEY_HEX).unwrap()
    }

    fn transfer() -> Transfer {
        Transfer {
            amount: 120_000,
            bank_code: "004",
            account: "12345678901".into(),
            holder: "홍길동".into(),
            memo: "다해 정산".into(),
        }
    }

    fn body_text(req: &Request) -> String {
        String::from_utf8(req.body().and_then(|b| b.as_bytes()).unwrap().to_vec()).unwrap()
    }

    #[test]
    fn payout_request_is_encrypted_with_destination_seller() {
        let req = send_request(&Client::new(), "test_sk_abc", &key(), "idem-1", "payout-1", "seller-7", &transfer()).unwrap();
        assert_eq!(req.method().as_str(), "POST");
        assert_eq!(req.url().as_str(), "https://api.tosspayments.com/v2/payouts");
        assert_eq!(req.headers()[SECURITY_MODE], "ENCRYPTION");
        assert_eq!(req.headers()["Idempotency-Key"], "idem-1");
        assert_eq!(req.headers()[AUTHORIZATION], format!("Basic {}", STANDARD.encode("test_sk_abc:")));
        let sent = open(&key(), &body_text(&req)).unwrap();
        assert_eq!(sent["refPayoutId"], "payout-1");
        assert_eq!(sent["destination"], "seller-7");
        assert_eq!(sent["scheduleType"], "EXPRESS");
        assert_eq!(sent["amount"], json!({"currency": "KRW", "value": 120_000}));
        assert_eq!(sent["transactionDescription"], "다해 정산");
        assert!(sent.get("accountNumber").is_none(), "account data belongs to the seller, not the transfer");
    }

    #[test]
    fn request_body_is_never_plaintext() {
        let req = send_request(&Client::new(), "k", &key(), "i", "r", "s", &transfer()).unwrap();
        let text = body_text(&req);
        assert!(!text.contains("seller") && !text.contains("refPayoutId"));
        assert_eq!(text.split('.').count(), 5);
    }

    #[test]
    fn seller_request_encodes_business_registration() {
        let d = SellerDraft {
            ref_id: "pro0123456789abcdef".into(),
            business: Business::Company {
                name: None,
                representative: "홍길동".into(),
                registration_no: "1234567890".into(),
                email: "pro@example.com".into(),
                phone: "01012345678".into(),
            },
            bank_code: "004",
            account: "12345678901".into(),
            holder: "홍길동".into(),
        };
        let req = seller_request(&Client::new(), "test_sk_abc", &key(), &d).unwrap();
        assert_eq!(req.url().path(), "/v2/sellers");
        assert_eq!(req.headers()[SECURITY_MODE], "ENCRYPTION");
        let sent = open(&key(), &body_text(&req)).unwrap();
        assert_eq!(sent["businessType"], "CORPORATE");
        assert_eq!(sent["refSellerId"], "pro0123456789abcdef");
        assert_eq!(
            sent["account"],
            json!({"bankCode": "004", "accountNumber": "12345678901", "holderName": "홍길동"})
        );
        assert_eq!(sent["company"]["businessRegistrationNumber"], "1234567890");
        assert!(sent.get("individual").is_none());
    }

    #[test]
    fn individual_seller_uses_individual_block() {
        let d = SellerDraft {
            ref_id: "pro-individual-1".into(),
            business: Business::Individual {
                name: "홍길동".into(),
                email: "a@b.kr".into(),
                phone: "01000000000".into(),
            },
            bank_code: "090",
            account: "3333000000000".into(),
            holder: "홍길동".into(),
        };
        let body = seller_body(&d);
        assert_eq!(body["businessType"], "INDIVIDUAL");
        assert_eq!(body["individual"]["name"], "홍길동");
        assert!(body.get("company").is_none());
    }

    #[test]
    fn seller_draft_debug_hides_account() {
        let d = SellerDraft {
            ref_id: "pro-1234567".into(),
            business: Business::Individual {
                name: "x".into(),
                email: "x".into(),
                phone: "x".into(),
            },
            bank_code: "004",
            account: "12345678901".into(),
            holder: "홍길동".into(),
        };
        assert!(!format!("{d:?}").contains("12345678901"));
    }

    #[test]
    fn plain_lookups_are_gets_without_bodies() {
        let http = Client::new();
        let seller = seller_status_request(&http, "k", "seller-9").unwrap();
        assert_eq!(seller.method().as_str(), "GET");
        assert_eq!(seller.url().path(), "/v2/sellers/seller-9");
        assert!(seller.body().is_none());
        let status = status_request(&http, "k", "tp-payout-9").unwrap();
        assert_eq!(status.url().path(), "/v2/payouts/tp-payout-9");
        let bal = balance_request(&http, "k").unwrap();
        assert_eq!(bal.url().path(), "/v2/balances");
        assert!(bal.headers().get(SECURITY_MODE).is_none());
    }

    #[test]
    fn debug_output_never_shows_the_account() {
        let shown = format!("{:?}", transfer());
        assert!(!shown.contains("12345678901") && !shown.contains("홍길동"), "{shown}");
        assert!(shown.contains("120000"));
    }

    #[test]
    fn read_body_decrypts_jwe_and_parses_json() {
        let k = key();
        let jwe = seal(&k, &json!({"id": "tp_1", "status": "REQUESTED"}));
        assert_eq!(read_body(&jwe, Some(&k)).unwrap()["id"], "tp_1");
        assert_eq!(read_body(r#"{"id":"plain"}"#, None).unwrap()["id"], "plain");
        assert_eq!(read_body("", None).unwrap(), Value::Null);
        assert!(read_body(&jwe, None).is_err());
        assert!(read_body(&jwe, Some(&[1u8; 32])).is_err());
    }

    #[test]
    fn ref_seller_id_length_matches_docs() {
        assert!(REF_SELLER_ID_RANGE.contains(&"pro0123456789abcdef".len()));
        assert!(!REF_SELLER_ID_RANGE.contains(&"short".len()));
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
    fn parses_sent_seller_and_status_responses() {
        assert_eq!(parse_sent(&json!({"id": "tp_1"})).unwrap(), "tp_1");
        assert!(parse_sent(&json!({"payoutId": "tp_1"})).is_err());
        assert_eq!(
            parse_seller(&json!({"id": "s_1", "status": "KYC_REQUIRED"})).unwrap(),
            ("s_1".into(), "KYC_REQUIRED".into())
        );
        assert!(parse_seller(&json!({"status": "APPROVED"})).is_err());
        assert_eq!(parse_status(&json!({"status": "COMPLETED"})), TransferStatus::Paid);
        assert_eq!(
            parse_status(&json!({"status": "FAILED", "error": {"message": "잔액 부족"}})),
            TransferStatus::Failed("잔액 부족".into())
        );
        assert_eq!(
            parse_status(&json!({"status": "REJECTED", "error": "계좌 오류"})),
            TransferStatus::Failed("계좌 오류".into())
        );
        assert_eq!(parse_status(&json!({"status": "CANCELED"})), TransferStatus::Failed("canceled".into()));
        assert_eq!(parse_status(&json!({"status": "IN_PROGRESS"})), TransferStatus::Pending);
        assert_eq!(parse_status(&json!({"status": "REQUESTED"})), TransferStatus::Pending);
    }

    #[test]
    fn description_is_seven_chars() {
        let mut t = transfer();
        t.memo = "다해청소정산서비스".into();
        assert_eq!(payout_body("payout-1", "s", &t)["transactionDescription"], "다해청소정산서");
    }
}
