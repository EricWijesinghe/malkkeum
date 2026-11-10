//! Social sign-in: verifies a provider token server-side and returns the provider's stable user id.
//! Dev mode accepts `dev:<id>` for any provider without network.

use super::Providers;
use crate::error::{ApiError, ApiResult};
use jsonwebtoken::{Algorithm, DecodingKey, Validation, decode, decode_header};
use serde::{Deserialize, Deserializer};
use serde_json::Value;
use std::{
    sync::Mutex,
    time::{Duration, Instant},
};

const APPLE_ISS: &str = "https://appleid.apple.com";
const APPLE_KEYS_URL: &str = "https://appleid.apple.com/auth/keys";
const APPLE_KEYS_TTL: Duration = Duration::from_secs(6 * 60 * 60);
const GOOGLE_ISSUERS: [&str; 2] = ["accounts.google.com", "https://accounts.google.com"];
const DEV_ID_MAX: usize = 128;

pub struct SocialUser {
    pub provider_user_id: String,
    pub email: Option<String>,
}

pub async fn verify(p: &Providers, provider: &str, token: &str) -> ApiResult<SocialUser> {
    if p.cfg().dev_mode
        && let Some(id) = token.strip_prefix("dev:")
    {
        if id.is_empty() || id.len() > DEV_ID_MAX {
            return Err(ApiError::BadRequest("invalid_token"));
        }
        return Ok(SocialUser {
            provider_user_id: id.into(),
            email: None,
        });
    }
    match provider {
        "kakao" => kakao(p, token).await,
        "naver" => naver(p, token).await,
        "google" => google(p, token).await,
        "apple" => apple(p, token).await,
        _ => Err(ApiError::BadRequest("invalid_provider")),
    }
}

/// Shared by the id-token providers: issuer, audience (our client id), and expiry all must hold.
pub fn id_claims_ok(issuer_ok: bool, audience: &str, client_ids: &[String], exp: i64, now: i64) -> bool {
    issuer_ok && exp > now && client_ids.iter().any(|c| c == audience)
}

fn json_text(v: &Value) -> String {
    match v {
        Value::String(s) => s.clone(),
        Value::Number(n) => n.to_string(),
        _ => String::new(),
    }
}

fn unreachable_provider(_: reqwest::Error) -> ApiError {
    ApiError::Unavailable("provider_unreachable")
}

/// Access-token lookup: 4xx means the token is bad, 5xx means the provider is down.
async fn bearer_json(p: &Providers, url: &str, token: &str) -> ApiResult<Value> {
    let resp = p.http().get(url).bearer_auth(token).send().await.map_err(unreachable_provider)?;
    let status = resp.status();
    if status.is_server_error() {
        return Err(ApiError::Unavailable("provider_unreachable"));
    }
    if !status.is_success() {
        return Err(ApiError::Unauthorized);
    }
    resp.json().await.map_err(unreachable_provider)
}

async fn kakao(p: &Providers, token: &str) -> ApiResult<SocialUser> {
    let integ = p.integ();
    let app_id = integ.kakao_app_id.as_deref().ok_or(ApiError::Unavailable("provider_not_configured"))?;
    let info = bearer_json(p, "https://kapi.kakao.com/v1/user/access_token_info", token).await?;
    if json_text(&info["app_id"]) != app_id {
        return Err(ApiError::Unauthorized);
    }
    let me = bearer_json(p, "https://kapi.kakao.com/v2/user/me", token).await?;
    let id = json_text(&me["id"]);
    if id.is_empty() {
        return Err(ApiError::Unauthorized);
    }
    Ok(SocialUser {
        provider_user_id: id,
        email: me["kakao_account"]["email"].as_str().map(str::to_string),
    })
}

async fn naver(p: &Providers, token: &str) -> ApiResult<SocialUser> {
    // shortcut: Naver's profile call does not name the issuing app, so a Naver token from another app
    // would pass; add a client-id check once NAVER_CLIENT_ID is available to compare against.
    let v = bearer_json(p, "https://openapi.naver.com/v1/nid/me", token).await?;
    let id = json_text(&v["response"]["id"]);
    if id.is_empty() {
        return Err(ApiError::Unauthorized);
    }
    Ok(SocialUser {
        provider_user_id: id,
        email: v["response"]["email"].as_str().map(str::to_string),
    })
}

#[derive(Deserialize)]
struct TokenInfo {
    iss: String,
    aud: String,
    sub: String,
    #[serde(deserialize_with = "flex_i64")]
    exp: i64,
    email: Option<String>,
}

/// Google's tokeninfo returns some numeric claims as strings.
fn flex_i64<'de, D: Deserializer<'de>>(d: D) -> Result<i64, D::Error> {
    #[derive(Deserialize)]
    #[serde(untagged)]
    enum Num {
        Int(i64),
        Text(String),
    }
    match Num::deserialize(d)? {
        Num::Int(n) => Ok(n),
        Num::Text(s) => s.parse().map_err(serde::de::Error::custom),
    }
}

async fn google(p: &Providers, token: &str) -> ApiResult<SocialUser> {
    let integ = p.integ();
    let ids = &integ.google_client_ids;
    if ids.is_empty() {
        return Err(ApiError::Unavailable("provider_not_configured"));
    }
    // Google checks the signature for us; we check who it was issued to and when it expires.
    let resp = p
        .http()
        .get("https://oauth2.googleapis.com/tokeninfo")
        .query(&[("id_token", token)])
        .send()
        .await
        .map_err(unreachable_provider)?;
    if resp.status().is_server_error() {
        return Err(ApiError::Unavailable("provider_unreachable"));
    }
    if !resp.status().is_success() {
        return Err(ApiError::Unauthorized);
    }
    let info: TokenInfo = resp.json().await.map_err(unreachable_provider)?;
    let issuer_ok = GOOGLE_ISSUERS.contains(&info.iss.as_str());
    if !id_claims_ok(issuer_ok, &info.aud, ids, info.exp, chrono::Utc::now().timestamp()) {
        return Err(ApiError::Unauthorized);
    }
    Ok(SocialUser {
        provider_user_id: info.sub,
        email: info.email,
    })
}

#[derive(Deserialize, Clone)]
struct Jwk {
    kid: String,
    n: String,
    e: String,
}

#[derive(Deserialize)]
struct Jwks {
    keys: Vec<Jwk>,
}

#[derive(Deserialize)]
struct AppleClaims {
    iss: String,
    aud: String,
    sub: String,
    exp: i64,
    email: Option<String>,
}

/// Apple's signing keys, cached for a few hours (process-wide).
static APPLE_KEYS: Mutex<Option<(Instant, Vec<Jwk>)>> = Mutex::new(None);

fn cached_apple_keys() -> Option<Vec<Jwk>> {
    let guard = APPLE_KEYS.lock().ok()?;
    let (at, keys) = guard.as_ref()?;
    (at.elapsed() < APPLE_KEYS_TTL).then(|| keys.clone())
}

async fn apple_keys(p: &Providers, force: bool) -> ApiResult<Vec<Jwk>> {
    if !force && let Some(keys) = cached_apple_keys() {
        return Ok(keys);
    }
    let jwks: Jwks = p
        .http()
        .get(APPLE_KEYS_URL)
        .send()
        .await
        .map_err(unreachable_provider)?
        .json()
        .await
        .map_err(unreachable_provider)?;
    if let Ok(mut guard) = APPLE_KEYS.lock() {
        *guard = Some((Instant::now(), jwks.keys.clone()));
    }
    Ok(jwks.keys)
}

async fn apple(p: &Providers, token: &str) -> ApiResult<SocialUser> {
    let integ = p.integ();
    let ids = &integ.apple_client_ids;
    if ids.is_empty() {
        return Err(ApiError::Unavailable("provider_not_configured"));
    }
    let header = decode_header(token).map_err(|_| ApiError::Unauthorized)?;
    let kid = header.kid.ok_or(ApiError::Unauthorized)?;
    let mut keys = apple_keys(p, false).await?;
    if !keys.iter().any(|k| k.kid == kid) {
        // Apple rotated its keys since we cached them.
        keys = apple_keys(p, true).await?;
    }
    let jwk = keys.iter().find(|k| k.kid == kid).ok_or(ApiError::Unauthorized)?;
    let key = DecodingKey::from_rsa_components(&jwk.n, &jwk.e).map_err(|_| ApiError::Unauthorized)?;
    // Signature and algorithm (RS256 only) are checked by jsonwebtoken; claims are checked below.
    let mut v = Validation::new(Algorithm::RS256);
    v.validate_exp = false;
    v.validate_aud = false;
    v.required_spec_claims.clear();
    let c = decode::<AppleClaims>(token, &key, &v).map_err(|_| ApiError::Unauthorized)?.claims;
    let issuer_ok = c.iss == APPLE_ISS;
    if !id_claims_ok(issuer_ok, &c.aud, ids, c.exp, chrono::Utc::now().timestamp()) {
        return Err(ApiError::Unauthorized);
    }
    Ok(SocialUser {
        provider_user_id: c.sub,
        email: c.email,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    const NOW: i64 = 1_800_000_000;

    fn ids() -> Vec<String> {
        vec!["com.example.app".into(), "com.example.web".into()]
    }

    #[test]
    fn valid_claims_pass() {
        assert!(id_claims_ok(true, "com.example.web", &ids(), NOW + 60, NOW));
    }

    #[test]
    fn wrong_issuer_audience_or_expiry_fail() {
        assert!(!id_claims_ok(false, "com.example.app", &ids(), NOW + 60, NOW));
        assert!(!id_claims_ok(true, "com.evil.app", &ids(), NOW + 60, NOW));
        assert!(!id_claims_ok(true, "com.example.app", &ids(), NOW, NOW));
        assert!(!id_claims_ok(true, "com.example.app", &[], NOW + 60, NOW));
    }

    #[test]
    fn google_numeric_claims_accept_strings() {
        let json = r#"{"iss":"accounts.google.com","aud":"x","sub":"1","exp":"1800000060"}"#;
        let info: TokenInfo = serde_json::from_str(json).expect("tokeninfo shape");
        assert_eq!(info.exp, NOW + 60);
    }

    #[test]
    fn provider_ids_accept_numbers_and_strings() {
        assert_eq!(json_text(&serde_json::json!(42)), "42");
        assert_eq!(json_text(&serde_json::json!("abc")), "abc");
        assert_eq!(json_text(&serde_json::json!(null)), "");
    }
}
