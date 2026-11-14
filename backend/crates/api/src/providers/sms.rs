//! Solapi (SMS + KakaoTalk AlimTalk) via REST API v4, HMAC-SHA256 header auth.
//! Docs: https://docs.solapi.com (Authentication, messages/v4/send).

use super::ProviderError;
use crate::config::SolapiConfig;
use chrono::{SecondsFormat, Utc};
use hmac::{Hmac, Mac};
use rand::{RngCore, rngs::OsRng};
use serde_json::{Value, json};
use sha2::Sha256;

const SEND_URL: &str = "https://api.solapi.com/messages/v4/send";
const BALANCE_URL: &str = "https://api.solapi.com/cash/v1/balance";
/// Korean text fits 90 bytes (EUC-KR) in 45 characters; longer text goes out as LMS.
const SMS_MAX_CHARS: usize = 45;

/// `HMAC-SHA256(apiSecret, date + salt)` as lowercase hex.
pub fn signature(api_secret: &str, date: &str, salt: &str) -> String {
    // HMAC accepts keys of any length, so this cannot fail.
    let mut mac = Hmac::<Sha256>::new_from_slice(api_secret.as_bytes()).expect("HMAC accepts any key length");
    mac.update(date.as_bytes());
    mac.update(salt.as_bytes());
    hex::encode(mac.finalize().into_bytes())
}

/// Value of the `Authorization` header.
pub fn auth_header(api_key: &str, api_secret: &str, date: &str, salt: &str) -> String {
    format!(
        "HMAC-SHA256 apiKey={api_key}, date={date}, salt={salt}, signature={}",
        signature(api_secret, date, salt)
    )
}

fn random_salt() -> String {
    let mut bytes = [0u8; 16];
    OsRng.fill_bytes(&mut bytes);
    hex::encode(bytes)
}

pub async fn send_sms(http: &reqwest::Client, cfg: &SolapiConfig, to: &str, text: &str) -> Result<(), ProviderError> {
    let kind = if text.chars().count() <= SMS_MAX_CHARS { "SMS" } else { "LMS" };
    post(http, cfg, json!({ "to": to, "from": cfg.sender, "text": text, "type": kind })).await
}

/// AlimTalk body. `disableSms: false` lets Solapi send `text` as an SMS when KakaoTalk can't deliver
/// (https://solapi.com/developers/api/messages-ata, https://solapi.com/developers/api/messages-disablesms).
/// `variables` keys carry the `#{..}` wrapper and must match the approved template exactly.
pub fn alimtalk_message(pf_id: &str, template_id: &str, to: &str, from: &str, fallback_text: &str, variables: Value) -> Value {
    json!({
        "to": to,
        "from": from,
        "text": fallback_text,
        "type": "ATA",
        "kakaoOptions": { "pfId": pf_id, "templateId": template_id, "variables": variables, "disableSms": false }
    })
}

/// AlimTalk with the plain text as its SMS fallback.
pub async fn send_alimtalk(
    http: &reqwest::Client,
    cfg: &SolapiConfig,
    pf_id: &str,
    template_id: &str,
    to: &str,
    fallback_text: &str,
    variables: Value,
) -> Result<(), ProviderError> {
    send_alimtalk_at(http, SEND_URL, cfg, pf_id, template_id, to, fallback_text, variables).await
}

/// `send_alimtalk` against an explicit endpoint, so tests can point it at a mock server.
#[allow(clippy::too_many_arguments)]
pub async fn send_alimtalk_at(
    http: &reqwest::Client,
    url: &str,
    cfg: &SolapiConfig,
    pf_id: &str,
    template_id: &str,
    to: &str,
    fallback_text: &str,
    variables: Value,
) -> Result<(), ProviderError> {
    let msg = alimtalk_message(pf_id, template_id, to, &cfg.sender, fallback_text, variables);
    post_to(http, url, cfg, msg).await
}

/// Template keys (the `templates` map in the setup wizard). Event sources are noted in `alert_key`.
pub const TPL_CONFIRMED: &str = "booking.confirmed";
pub const TPL_ASSIGNED: &str = "partner.assigned";
pub const TPL_REMINDER: &str = "booking.reminder";
pub const TPL_ARRIVAL: &str = "booking.arrival";
pub const TPL_COMPLETED: &str = "booking.completed";
pub const TPL_RECEIPT: &str = "payment.receipt";
pub const TPL_CANCELLED: &str = "booking.cancelled";
/// Every key the setup wizard accepts in the solapi `templates` map.
pub const TEMPLATE_KEYS: [&str; 7] = [
    TPL_CONFIRMED,
    TPL_ASSIGNED,
    TPL_REMINDER,
    TPL_ARRIVAL,
    TPL_COMPLETED,
    TPL_RECEIPT,
    TPL_CANCELLED,
];

/// Notify kind + data -> transactional alert template key. None means in-app and push only.
/// Status codes follow `domain::booking::BookingStatus` (1 confirmed, 2 team assigned).
pub fn alert_key(kind: &str, data: &Value) -> Option<&'static str> {
    match kind {
        "booking.status" => match data.get("status").and_then(Value::as_i64) {
            Some(1) => Some(TPL_CONFIRMED),
            Some(2) => Some(TPL_ASSIGNED),
            _ => None,
        },
        "booking.completed" => Some(TPL_COMPLETED),
        "booking.arrival" => Some(TPL_ARRIVAL),
        "payment.receipt" => Some(TPL_RECEIPT),
        "booking.cancelled" => Some(TPL_CANCELLED),
        _ => None,
    }
}

async fn post(http: &reqwest::Client, cfg: &SolapiConfig, message: Value) -> Result<(), ProviderError> {
    post_to(http, SEND_URL, cfg, message).await
}

async fn post_to(http: &reqwest::Client, url: &str, cfg: &SolapiConfig, message: Value) -> Result<(), ProviderError> {
    let date = Utc::now().to_rfc3339_opts(SecondsFormat::Secs, true);
    let auth = auth_header(&cfg.api_key, &cfg.api_secret, &date, &random_salt());
    let resp = http
        .post(url)
        .header(reqwest::header::AUTHORIZATION, auth)
        .json(&json!({ "message": message }))
        .send()
        .await
        .map_err(|e| ProviderError::Upstream(e.to_string()))?;
    if resp.status().is_success() {
        Ok(())
    } else {
        Err(ProviderError::Upstream(format!("solapi status {}", resp.status())))
    }
}

/// Setup-wizard check: reads the account balance, which needs valid keys and sends nothing.
pub async fn check(http: &reqwest::Client, cfg: &SolapiConfig) -> Result<reqwest::StatusCode, ProviderError> {
    let date = Utc::now().to_rfc3339_opts(SecondsFormat::Secs, true);
    let auth = auth_header(&cfg.api_key, &cfg.api_secret, &date, &random_salt());
    http.get(BALANCE_URL)
        .header(reqwest::header::AUTHORIZATION, auth)
        .send()
        .await
        .map(|r| r.status())
        .map_err(|e| ProviderError::Upstream(e.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn signature_matches_hmac_sha256_known_vector() {
        // RFC 4231 test case 2 (key "Jefe", data "what do ya want for nothing?"), split as date + salt
        // to pin the concatenation order that Solapi requires: HMAC(secret, date || salt).
        let sig = signature("Jefe", "what do ya want ", "for nothing?");
        assert_eq!(sig, "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843");
    }

    #[test]
    fn alert_kinds_map_to_templates_and_everything_else_is_not_an_alert() {
        assert_eq!(alert_key("booking.status", &json!({ "status": 1 })), Some(TPL_CONFIRMED));
        assert_eq!(alert_key("booking.status", &json!({ "status": 2 })), Some(TPL_ASSIGNED));
        assert_eq!(alert_key("booking.status", &json!({ "status": 3 })), None);
        assert_eq!(alert_key("booking.arrival", &json!({})), Some(TPL_ARRIVAL));
        assert_eq!(alert_key("payment.receipt", &json!({})), Some(TPL_RECEIPT));
        assert_eq!(alert_key("booking.completed", &json!({})), Some(TPL_COMPLETED));
        assert_eq!(alert_key("booking.cancelled", &json!({})), Some(TPL_CANCELLED));
        assert_eq!(alert_key("marketing.rebook", &json!({})), None);
        assert_eq!(alert_key("chat.message", &json!({})), None);
    }

    #[test]
    fn alimtalk_body_is_ata_with_sms_fallback_enabled() {
        let m = alimtalk_message("PF1", "TPL1", "01012345678", "0212345678", "t\nb", json!({ "#{title}": "t" }));
        assert_eq!(m["type"], "ATA");
        assert_eq!(m["from"], "0212345678");
        assert_eq!(m["text"], "t\nb");
        assert_eq!(m["kakaoOptions"]["pfId"], "PF1");
        assert_eq!(m["kakaoOptions"]["templateId"], "TPL1");
        assert_eq!(m["kakaoOptions"]["disableSms"], false);
        assert_eq!(m["kakaoOptions"]["variables"]["#{title}"], "t");
    }

    /// Reads one HTTP/1.1 request (headers, then Content-Length bytes) and returns (request line, auth, body).
    async fn read_request(sock: &mut tokio::net::TcpStream) -> (String, String, String) {
        use tokio::io::AsyncReadExt;
        let mut buf = Vec::new();
        let head_end = loop {
            if let Some(pos) = buf.windows(4).position(|w| w == b"\r\n\r\n") {
                break pos + 4;
            }
            let mut chunk = [0u8; 1024];
            let n = sock.read(&mut chunk).await.expect("read");
            assert!(n > 0, "connection closed before headers");
            buf.extend_from_slice(&chunk[..n]);
        };
        let head = String::from_utf8_lossy(&buf[..head_end]).to_string();
        let len: usize = head
            .lines()
            .find_map(|l| l.to_ascii_lowercase().strip_prefix("content-length:").map(|v| v.trim().parse().unwrap()))
            .unwrap_or(0);
        while buf.len() < head_end + len {
            let mut chunk = [0u8; 1024];
            let n = sock.read(&mut chunk).await.expect("read body");
            assert!(n > 0, "connection closed mid-body");
            buf.extend_from_slice(&chunk[..n]);
        }
        let body = String::from_utf8_lossy(&buf[head_end..head_end + len]).to_string();
        let line = head.lines().next().unwrap_or_default().to_string();
        let auth = head
            .lines()
            .find(|l| l.to_ascii_lowercase().starts_with("authorization:"))
            .unwrap_or_default()
            .to_string();
        (line, auth, body)
    }

    #[tokio::test]
    async fn alimtalk_request_hits_send_endpoint_with_hmac_auth_and_template_body() {
        use tokio::io::AsyncWriteExt;
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.expect("bind");
        let url = format!("http://{}/messages/v4/send", listener.local_addr().expect("addr"));
        let server = tokio::spawn(async move {
            let (mut sock, _) = listener.accept().await.expect("accept");
            let req = read_request(&mut sock).await;
            sock.write_all(b"HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}")
                .await
                .expect("write");
            req
        });
        let cfg = SolapiConfig {
            api_key: "KEY".into(),
            api_secret: "SECRET".into(),
            sender: "0212345678".into(),
            pf_id: Some("PF1".into()),
            templates: Default::default(),
        };
        let http = reqwest::Client::new();
        send_alimtalk_at(
            &http,
            &url,
            &cfg,
            "PF1",
            "TPL1",
            "01012345678",
            "t\nb",
            json!({ "#{title}": "t", "#{body}": "b" }),
        )
        .await
        .expect("send ok");
        let (line, auth, body) = server.await.expect("server");
        assert_eq!(line, "POST /messages/v4/send HTTP/1.1");
        assert!(auth.to_ascii_lowercase().starts_with("authorization: hmac-sha256 apikey=key, date="), "{auth}");
        let json: Value = serde_json::from_str(&body).expect("json body");
        assert_eq!(json["message"]["type"], "ATA");
        assert_eq!(json["message"]["kakaoOptions"]["templateId"], "TPL1");
        assert_eq!(json["message"]["kakaoOptions"]["variables"]["#{body}"], "b");
    }

    #[test]
    fn auth_header_has_documented_fields_in_order() {
        let h = auth_header("key", "Jefe", "2026-11-10T00:00:00Z", "salt");
        assert!(h.starts_with("HMAC-SHA256 apiKey=key, date=2026-11-10T00:00:00Z, salt=salt, signature="));
        assert!(h.ends_with(&signature("Jefe", "2026-11-10T00:00:00Z", "salt")));
    }
}
