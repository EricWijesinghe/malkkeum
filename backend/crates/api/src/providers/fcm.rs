//! Firebase Cloud Messaging HTTP v1. Service-account JWT (RS256) -> OAuth access token (cached
//! until 60 s before expiry) -> `projects/{id}/messages:send` once per device token.
//! Docs: https://firebase.google.com/docs/cloud-messaging/send-message

use super::ProviderError;
use chrono::Utc;
use jsonwebtoken::{Algorithm, EncodingKey, Header, encode};
use reqwest::{StatusCode, header};
use serde::{Deserialize, Serialize};
use serde_json::{Map, Value, json};
use std::{
    fmt,
    sync::Arc,
    time::{Duration, Instant},
};
use tokio::sync::Mutex;

const SCOPE: &str = "https://www.googleapis.com/auth/firebase.messaging";
const TOKEN_URL: &str = "https://oauth2.googleapis.com/token";
const SEND_BASE: &str = "https://fcm.googleapis.com/v1/projects";
/// `urn:ietf:params:oauth:grant-type:jwt-bearer`, percent-encoded for the form body.
const GRANT_TYPE: &str = "urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer";
const ASSERTION_TTL_SECS: i64 = 3600;
/// Refresh the access token once less than this much lifetime is left.
const REFRESH_MARGIN: Duration = Duration::from_secs(60);

/// The fields of a Google service-account key file that push needs.
#[derive(Clone, Deserialize)]
pub struct ServiceAccount {
    pub project_id: String,
    pub client_email: String,
    pub private_key: String,
}

/// Never print the private key.
impl fmt::Debug for ServiceAccount {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("ServiceAccount")
            .field("project_id", &self.project_id)
            .field("client_email", &self.client_email)
            .finish_non_exhaustive()
    }
}

#[derive(Debug, PartialEq, Eq, Serialize)]
pub struct AssertionClaims {
    pub iss: String,
    pub scope: &'static str,
    pub aud: &'static str,
    pub iat: i64,
    pub exp: i64,
}

/// Claims of the JWT assertion sent to the token endpoint (one hour, Google's maximum).
pub fn assertion_claims(client_email: &str, now: i64) -> AssertionClaims {
    AssertionClaims {
        iss: client_email.to_string(),
        scope: SCOPE,
        aud: TOKEN_URL,
        iat: now,
        exp: now + ASSERTION_TTL_SECS,
    }
}

#[derive(Clone)]
struct CachedToken {
    token: String,
    expires_at: Instant,
}

/// True while the cached token still has more than the refresh margin left at `now`.
fn usable(expires_at: Instant, now: Instant) -> bool {
    expires_at.saturating_duration_since(now) > REFRESH_MARGIN
}

#[derive(Deserialize)]
struct TokenResponse {
    access_token: String,
    expires_in: u64,
}

#[derive(Clone)]
pub struct Fcm {
    account: ServiceAccount,
    /// Held across the refresh so concurrent sends trigger one token exchange, not many.
    cache: Arc<Mutex<Option<CachedToken>>>,
}

impl Fcm {
    pub fn new(account: ServiceAccount) -> Self {
        Self {
            account,
            cache: Arc::new(Mutex::new(None)),
        }
    }

    async fn access_token(&self, http: &reqwest::Client) -> Result<String, ProviderError> {
        let mut cache = self.cache.lock().await;
        let now = Instant::now();
        if let Some(c) = (*cache).as_ref().filter(|c| usable(c.expires_at, now)) {
            return Ok(c.token.clone());
        }
        let (token, expires_in) = exchange(http, &self.account, Utc::now().timestamp()).await?;
        *cache = Some(CachedToken {
            token: token.clone(),
            expires_at: now + Duration::from_secs(expires_in),
        });
        Ok(token)
    }

    /// Sends one message per token. Returns the tokens FCM reports as dead (UNREGISTERED / 404) so the caller can prune them.
    pub async fn send(&self, http: &reqwest::Client, tokens: &[String], title: &str, body: &str, data: &Value) -> Result<Vec<String>, ProviderError> {
        let access = self.access_token(http).await?;
        let url = format!("{SEND_BASE}/{}/messages:send", self.account.project_id);
        let mut dead = Vec::new();
        for token in tokens {
            let msg = message(token, title, body, data);
            let resp = match http.post(url.as_str()).bearer_auth(&access).json(&msg).send().await {
                Ok(r) => r,
                Err(e) => {
                    tracing::warn!(error = %e, "fcm send failed");
                    continue;
                }
            };
            let status = resp.status();
            if status.is_success() {
                continue;
            }
            let text = resp.text().await.unwrap_or_default();
            if status == StatusCode::NOT_FOUND || text.contains("UNREGISTERED") {
                dead.push(token.clone());
            } else {
                tracing::warn!(%status, "fcm rejected message");
            }
        }
        Ok(dead)
    }
}

fn sign_assertion(account: &ServiceAccount, now: i64) -> Result<String, ProviderError> {
    let key = EncodingKey::from_rsa_pem(account.private_key.as_bytes()).map_err(|_| ProviderError::NotConfigured("fcm"))?;
    encode(&Header::new(Algorithm::RS256), &assertion_claims(&account.client_email, now), &key).map_err(|_| ProviderError::NotConfigured("fcm"))
}

/// Trades a signed assertion for an access token. Returns (token, lifetime in seconds).
pub(crate) async fn exchange(http: &reqwest::Client, account: &ServiceAccount, now: i64) -> Result<(String, u64), ProviderError> {
    let jwt = sign_assertion(account, now)?;
    // JWTs are base64url, so the assertion needs no further escaping.
    let form = format!("grant_type={GRANT_TYPE}&assertion={jwt}");
    let resp = http
        .post(TOKEN_URL)
        .header(header::CONTENT_TYPE, "application/x-www-form-urlencoded")
        .body(form)
        .send()
        .await
        .map_err(|e| ProviderError::Upstream(e.to_string()))?;
    if !resp.status().is_success() {
        return Err(ProviderError::Upstream(format!("fcm token exchange: {}", resp.status())));
    }
    let t: TokenResponse = resp.json().await.map_err(|e| ProviderError::Upstream(e.to_string()))?;
    Ok((t.access_token, t.expires_in))
}

/// FCM v1 message: `notification` shows in the OS tray, `data` reaches the app (values must be strings).
pub fn message(token: &str, title: &str, body: &str, data: &Value) -> Value {
    json!({
        "message": {
            "token": token,
            "notification": { "title": title, "body": body },
            "data": string_data(data),
            "android": { "priority": "HIGH" },
            "apns": { "payload": { "aps": { "sound": "default" } } }
        }
    })
}

/// FCM data values must be strings: non-string JSON values are serialized.
pub fn string_data(data: &Value) -> Value {
    let map: Map<String, Value> = match data {
        Value::Object(o) => o
            .iter()
            .map(|(k, v)| {
                let s = match v {
                    Value::String(s) => s.clone(),
                    other => other.to_string(),
                };
                (k.clone(), Value::String(s))
            })
            .collect(),
        _ => Map::new(),
    };
    Value::Object(map)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn assertion_claims_carry_scope_audience_and_one_hour_ttl() {
        let c = assertion_claims("svc@proj.iam.gserviceaccount.com", 1_000);
        assert_eq!(c.iss, "svc@proj.iam.gserviceaccount.com");
        assert_eq!(c.scope, SCOPE);
        assert_eq!(c.aud, TOKEN_URL);
        assert_eq!((c.iat, c.exp), (1_000, 4_600));
    }

    #[test]
    fn cached_token_is_reused_until_the_refresh_margin() {
        let t0 = Instant::now();
        let expires = t0 + Duration::from_secs(3600);
        assert!(usable(expires, t0));
        assert!(usable(expires, t0 + Duration::from_secs(3539)));
        // Exactly 60 s left: refresh now.
        assert!(!usable(expires, t0 + Duration::from_secs(3540)));
        assert!(!usable(expires, t0 + Duration::from_secs(4000)));
    }

    #[test]
    fn data_values_are_stringified() {
        let v = string_data(&json!({ "booking_id": "abc", "status": 2, "flag": true }));
        assert_eq!(v, json!({ "booking_id": "abc", "status": "2", "flag": "true" }));
    }

    #[test]
    fn message_sets_android_priority_and_apns_sound() {
        let m = message("tok", "t", "b", &json!({}));
        assert_eq!(m["message"]["token"], "tok");
        assert_eq!(m["message"]["android"]["priority"], "HIGH");
        assert_eq!(m["message"]["apns"]["payload"]["aps"]["sound"], "default");
    }
}
