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
    format!("HMAC-SHA256 apiKey={api_key}, date={date}, salt={salt}, signature={}", signature(api_secret, date, salt))
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

/// AlimTalk with the plain text as its SMS fallback: Solapi sends the SMS itself when KakaoTalk can't deliver.
pub async fn send_alimtalk(
    http: &reqwest::Client,
    cfg: &SolapiConfig,
    pf_id: &str,
    template_id: &str,
    to: &str,
    fallback_text: &str,
    variables: Value,
) -> Result<(), ProviderError> {
    post(
        http,
        cfg,
        json!({
            "to": to,
            "from": cfg.sender,
            "text": fallback_text,
            "type": "ATA",
            "kakaoOptions": { "pfId": pf_id, "templateId": template_id, "variables": variables, "disableSms": false }
        }),
    )
    .await
}

async fn post(http: &reqwest::Client, cfg: &SolapiConfig, message: Value) -> Result<(), ProviderError> {
    let date = Utc::now().to_rfc3339_opts(SecondsFormat::Secs, true);
    let auth = auth_header(&cfg.api_key, &cfg.api_secret, &date, &random_salt());
    let resp = http
        .post(SEND_URL)
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
    fn auth_header_has_documented_fields_in_order() {
        let h = auth_header("key", "Jefe", "2026-11-10T00:00:00Z", "salt");
        assert!(h.starts_with("HMAC-SHA256 apiKey=key, date=2026-11-10T00:00:00Z, salt=salt, signature="));
        assert!(h.ends_with(&signature("Jefe", "2026-11-10T00:00:00Z", "salt")));
    }
}
