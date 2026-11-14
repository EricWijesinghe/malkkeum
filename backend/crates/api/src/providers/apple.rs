//! Sign in with Apple server calls: the client secret, the authorization-code exchange (its refresh token is kept
//! only for revocation), token revocation on account deletion (App Store Review 5.1.1(v)), and verification of
//! Apple's server-to-server notifications.
//! Sources: developer.apple.com/documentation/sign_in_with_apple (generate_and_validate_tokens, revoke_tokens,
//! "Processing changes for Sign in with Apple accounts") and TN3194.

use super::{
    Providers,
    social::{APPLE_ISS, APPLE_KEYS, Jwk, UnlinkResult, form_body, signing_key},
};
use crate::{
    config::AppleSignInKey,
    error::{ApiError, ApiResult},
};
use base64::{Engine, engine::general_purpose::URL_SAFE_NO_PAD};
use jsonwebtoken::{Algorithm, DecodingKey, EncodingKey, Header, Validation, decode, decode_header, encode};
use serde::{Deserialize, Serialize};
use serde_json::Value;

/// Each client secret lives 5 minutes (Apple allows 6 months); a fresh one per call is never stored.
const CLIENT_SECRET_TTL: i64 = 300;
/// Clock skew allowed on a notification's `iat`.
const MAX_SKEW: i64 = 300;
/// Oldest notification accepted. Seen ids are kept for good (`apple_notifications` is never purged), so this
/// only bounds how far back a captured payload can be replayed against a fresh database.
const MAX_AGE: i64 = 7 * 24 * 60 * 60;

#[derive(Serialize)]
struct SecretClaims<'a> {
    iss: &'a str,
    iat: i64,
    exp: i64,
    aud: &'a str,
    sub: &'a str,
}

/// ES256 JWT signed with the .p8 key: `iss` team id, `sub` the app's bundle id, header `kid` the key id.
pub fn client_secret(key: &AppleSignInKey, client_id: &str, now: i64) -> Result<String, &'static str> {
    let mut header = Header::new(Algorithm::ES256);
    header.kid = Some(key.key_id.clone());
    let signing = EncodingKey::from_ec_pem(key.private_key.as_bytes()).map_err(|_| "invalid_key")?;
    let claims = SecretClaims {
        iss: &key.team_id,
        iat: now,
        exp: now + CLIENT_SECRET_TTL,
        aud: APPLE_ISS,
        sub: client_id,
    };
    encode(&header, &claims, &signing).map_err(|_| "invalid_key")
}

async fn post_apple(http: &reqwest::Client, url: String, form: String) -> Result<reqwest::Response, &'static str> {
    let resp = http
        .post(url)
        .header(reqwest::header::CONTENT_TYPE, "application/x-www-form-urlencoded")
        .body(form)
        .send()
        .await
        .map_err(|_| "provider_unreachable")?;
    if resp.status().is_success() { Ok(resp) } else { Err("provider_error") }
}

/// `sub` of an id token Apple's token endpoint returned to us over TLS (no signature check needed for that).
fn id_token_sub(id_token: &str) -> Option<String> {
    let payload = id_token.split('.').nth(1)?;
    let claims: Value = serde_json::from_slice(&URL_SAFE_NO_PAD.decode(payload).ok()?).ok()?;
    claims["sub"].as_str().map(str::to_string)
}

/// `POST {base}/auth/token` with the code. The refresh token is returned only when Apple's id token names the
/// same user the app's identity token did, so a code from another account is never stored.
pub async fn exchange_at(http: &reqwest::Client, base: &str, key: &AppleSignInKey, client_id: &str, code: &str, sub: &str) -> Result<String, &'static str> {
    let secret = client_secret(key, client_id, chrono::Utc::now().timestamp())?;
    let form = form_body(&[
        ("client_id", client_id),
        ("client_secret", &secret),
        ("code", code),
        ("grant_type", "authorization_code"),
    ]);
    let reply: Value = post_apple(http, format!("{base}/auth/token"), form)
        .await?
        .json()
        .await
        .map_err(|_| "provider_error")?;
    if reply["id_token"].as_str().and_then(id_token_sub).as_deref() != Some(sub) {
        return Err("user_mismatch");
    }
    reply["refresh_token"]
        .as_str()
        .filter(|t| !t.is_empty())
        .map(str::to_string)
        .ok_or("no_refresh_token")
}

/// `POST {base}/auth/revoke` for a refresh token. Revoking it ends the app's authorization for that Apple ID.
pub async fn revoke_at(http: &reqwest::Client, base: &str, key: &AppleSignInKey, client_id: &str, token: &str) -> UnlinkResult {
    let secret = client_secret(key, client_id, chrono::Utc::now().timestamp())?;
    let form = form_body(&[
        ("client_id", client_id),
        ("client_secret", &secret),
        ("token", token),
        ("token_type_hint", "refresh_token"),
    ]);
    post_apple(http, format!("{base}/auth/revoke"), form).await.map(|_| ())
}

/// Refresh token for a sign-in, or None (logged) when the key is not set up or Apple refuses the code.
/// Sign-in itself never fails here: the identity token was already verified.
pub async fn exchange_code(p: &Providers, client_id: Option<&str>, code: &str, sub: &str) -> Option<String> {
    if p.cfg().dev_mode {
        return Some(format!("dev-refresh-{}", crate::auth::sha256_hex(code.as_bytes())));
    }
    let integ = p.integ();
    let result = match (integ.apple_signin.as_ref(), client_id) {
        (Some(key), Some(client)) => exchange_at(p.http(), APPLE_ISS, key, client, code, sub).await,
        _ => Err("not_configured"),
    };
    match result {
        Ok(token) => Some(token),
        Err(reason) => {
            tracing::warn!(reason, "apple code not exchanged; this sign-in cannot be revoked on deletion");
            None
        }
    }
}

pub async fn revoke(p: &Providers, client_id: Option<&str>, token: Option<&str>) -> UnlinkResult {
    let integ = p.integ();
    let key = integ.apple_signin.as_ref().ok_or("not_configured")?;
    let (Some(client), Some(token)) = (client_id, token) else {
        return Err("no_token");
    };
    revoke_at(p.http(), APPLE_ISS, key, client, token).await
}

/// A verified server-to-server notification.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Notification {
    /// The JWS id; a second delivery with the same id is a replay.
    pub jti: String,
    /// `email-disabled`, `email-enabled`, `consent-revoked` or `account-delete` (Apple also writes `account-deleted`).
    pub kind: String,
    /// The Apple user id (`sub` of the sign-in identity token).
    pub sub: String,
}

#[derive(Deserialize)]
struct NotificationClaims {
    iss: String,
    aud: String,
    iat: i64,
    #[serde(default)]
    exp: Option<i64>,
    jti: String,
    /// An object, or the same object JSON-encoded as a string (Apple has sent both).
    events: Value,
}

/// Signature (RS256 only, Apple's key for `kid`), issuer, audience (one of our bundle ids), `iat` not in the
/// future or over a week old, `exp` when present, and a typed event with a user.
fn decode_notification(jws: &str, jwk: &Jwk, client_ids: &[String], now: i64) -> ApiResult<Notification> {
    let key = DecodingKey::from_rsa_components(&jwk.n, &jwk.e).map_err(|_| ApiError::Unauthorized)?;
    let mut v = Validation::new(Algorithm::RS256);
    v.validate_exp = false;
    v.validate_aud = false;
    v.required_spec_claims.clear();
    let c = decode::<NotificationClaims>(jws, &key, &v).map_err(|_| ApiError::Unauthorized)?.claims;
    let fresh = c.iat <= now + MAX_SKEW && c.iat >= now - MAX_AGE && c.exp.is_none_or(|e| e > now);
    if c.iss != APPLE_ISS || !client_ids.contains(&c.aud) || !fresh || c.jti.is_empty() {
        return Err(ApiError::Unauthorized);
    }
    let events = match c.events {
        Value::String(s) => serde_json::from_str(&s).map_err(|_| ApiError::Unauthorized)?,
        other => other,
    };
    let (Some(kind), Some(sub)) = (events["type"].as_str(), events["sub"].as_str()) else {
        return Err(ApiError::Unauthorized);
    };
    if sub.is_empty() {
        return Err(ApiError::Unauthorized);
    }
    let kind = if kind == "account-deleted" { "account-delete" } else { kind };
    Ok(Notification {
        jti: c.jti,
        kind: kind.into(),
        sub: sub.into(),
    })
}

/// Verifies a notification JWS against Apple's published keys (cached, see `social::KeyCache`).
pub async fn verify_notification(p: &Providers, jws: &str) -> ApiResult<Notification> {
    let kid = decode_header(jws).map_err(|_| ApiError::Unauthorized)?.kid.ok_or(ApiError::Unauthorized)?;
    let integ = p.integ();
    if integ.apple_client_ids.is_empty() {
        return Err(ApiError::Unavailable("provider_not_configured"));
    }
    let jwk = signing_key(p, &APPLE_KEYS, &kid).await?;
    decode_notification(jws, &jwk, &integ.apple_client_ids, chrono::Utc::now().timestamp())
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{Form, Router, extract::State, http::StatusCode, routing::post};
    use serde_json::json;
    use std::{
        collections::HashMap,
        sync::{Arc, Mutex},
    };

    // Test-only keys generated for these fixtures; they sign nothing outside this module.
    const RSA_PEM: &str = include_str!("testdata/test_only_rsa.pem");
    const RSA_OTHER_PEM: &str = include_str!("testdata/test_only_rsa_other.pem");
    const RSA_N: &str = include_str!("testdata/test_only_rsa.n");
    const EC_P8: &str = include_str!("testdata/test_only_ec.p8");
    const EC_PUB: &str = include_str!("testdata/test_only_ec.pub.pem");
    const EC_OTHER_PUB: &str = include_str!("testdata/test_only_ec_other.pub.pem");
    const NOW: i64 = 1_800_000_000;
    const APP: &str = "com.example.customer";

    fn jwk() -> Jwk {
        Jwk {
            kid: "k1".into(),
            n: RSA_N.trim().into(),
            e: "AQAB".into(),
        }
    }

    fn ids() -> Vec<String> {
        vec![APP.into(), "com.example.partner".into()]
    }

    fn sign(pem: &str, claims: &Value) -> String {
        let mut h = Header::new(Algorithm::RS256);
        h.kid = Some("k1".into());
        encode(&h, claims, &EncodingKey::from_rsa_pem(pem.as_bytes()).expect("rsa pem")).expect("sign")
    }

    fn claims(events: Value) -> Value {
        json!({"iss": APPLE_ISS, "aud": APP, "iat": NOW - 10, "jti": "j-1", "events": events})
    }

    fn event(kind: &str) -> Value {
        json!({"type": kind, "sub": "001234.abcd", "event_time": NOW * 1000})
    }

    fn key() -> AppleSignInKey {
        AppleSignInKey::new("TEAM123456", "KEY1234567", EC_P8).expect("test key")
    }

    #[test]
    fn valid_notification_decodes_with_string_or_object_events() {
        let n = decode_notification(&sign(RSA_PEM, &claims(event("consent-revoked"))), &jwk(), &ids(), NOW).expect("valid");
        assert_eq!(
            n,
            Notification {
                jti: "j-1".into(),
                kind: "consent-revoked".into(),
                sub: "001234.abcd".into()
            }
        );
        let as_string = claims(json!(event("account-deleted").to_string()));
        let n = decode_notification(&sign(RSA_PEM, &as_string), &jwk(), &ids(), NOW).expect("string events");
        assert_eq!(n.kind, "account-delete", "both spellings map to one kind");
    }

    #[test]
    fn forged_or_mismatched_notifications_are_rejected() {
        let reject = |token: String| matches!(decode_notification(&token, &jwk(), &ids(), NOW), Err(ApiError::Unauthorized));
        assert!(reject(sign(RSA_OTHER_PEM, &claims(event("account-delete")))), "signed by another key");
        let mut c = claims(event("account-delete"));
        c["aud"] = json!("com.evil.app");
        assert!(reject(sign(RSA_PEM, &c)), "audience not ours");
        let mut c = claims(event("account-delete"));
        c["iss"] = json!("https://evil.example");
        assert!(reject(sign(RSA_PEM, &c)), "issuer not Apple");
        let mut c = claims(event("account-delete"));
        c["exp"] = json!(NOW - 1);
        assert!(reject(sign(RSA_PEM, &c)), "expired");
        let mut c = claims(event("account-delete"));
        c["iat"] = json!(NOW + MAX_SKEW + 60);
        assert!(reject(sign(RSA_PEM, &c)), "issued in the future");
        let mut c = claims(event("account-delete"));
        c["iat"] = json!(NOW - MAX_AGE - 1);
        assert!(reject(sign(RSA_PEM, &c)), "older than a week");
        assert!(reject(sign(RSA_PEM, &claims(json!({"type": "account-delete"})))), "no user");
        assert!(reject(sign(RSA_PEM, &claims(json!("not json")))), "events unreadable");
        let mut c = claims(event("account-delete"));
        c["jti"] = json!("");
        assert!(reject(sign(RSA_PEM, &c)), "no id to dedupe on");
    }

    #[test]
    fn tampered_payload_and_algorithm_swaps_are_rejected() {
        let reject = |token: &str| matches!(decode_notification(token, &jwk(), &ids(), NOW), Err(ApiError::Unauthorized));
        let good = sign(RSA_PEM, &claims(event("email-disabled")));
        let parts: Vec<&str> = good.split('.').collect();
        let forged_body = URL_SAFE_NO_PAD.encode(claims(event("account-delete")).to_string());
        assert!(
            reject(&format!("{}.{forged_body}.{}", parts[0], parts[2])),
            "payload swapped under a valid signature"
        );
        // HS256 keyed with the public modulus: the classic RS/HS confusion.
        let mut h = Header::new(Algorithm::HS256);
        h.kid = Some("k1".into());
        let hs = encode(&h, &claims(event("account-delete")), &EncodingKey::from_secret(RSA_N.trim().as_bytes())).expect("hs");
        assert!(reject(&hs));
        let none = format!("{}.{}.", URL_SAFE_NO_PAD.encode(r#"{"alg":"none","kid":"k1"}"#), parts[1]);
        assert!(reject(&none), "unsigned");
        assert!(reject("garbage"));
    }

    #[test]
    fn client_secret_names_team_key_and_app() {
        let secret = client_secret(&key(), APP, NOW).expect("sign");
        let header = decode_header(&secret).expect("header");
        assert_eq!(header.alg, Algorithm::ES256);
        assert_eq!(header.kid.as_deref(), Some("KEY1234567"));
        let payload: Value = serde_json::from_slice(&URL_SAFE_NO_PAD.decode(secret.split('.').nth(1).expect("payload")).expect("b64")).expect("json");
        assert_eq!(
            payload,
            json!({"iss": "TEAM123456", "iat": NOW, "exp": NOW + CLIENT_SECRET_TTL, "aud": APPLE_ISS, "sub": APP})
        );
        assert!(
            format!("{:?}", key()).contains("KEY1234567") && !format!("{:?}", key()).contains("PRIVATE"),
            "Debug hides the key"
        );
    }

    #[test]
    fn client_secret_signature_verifies_only_with_its_public_key() {
        let secret = client_secret(&key(), APP, NOW).expect("sign");
        let mut v = Validation::new(Algorithm::ES256);
        v.validate_exp = false;
        v.validate_aud = false;
        let public = DecodingKey::from_ec_pem(EC_PUB.as_bytes()).expect("ec public pem");
        assert!(decode::<Value>(&secret, &public, &v).is_ok(), "ES256 client secret verifies");
        let other = DecodingKey::from_ec_pem(EC_OTHER_PUB.as_bytes()).expect("other ec public pem");
        assert!(decode::<Value>(&secret, &other, &v).is_err(), "wrong public key is refused");
    }

    #[test]
    fn non_ec_private_key_is_refused_at_configuration() {
        assert_eq!(AppleSignInKey::new("TEAM123456", "KEY1234567", RSA_PEM), Err("invalid_private_key"));
    }

    type Calls = Arc<Mutex<Vec<HashMap<String, String>>>>;

    async fn fake_apple(status: StatusCode, reply: Value) -> (String, Calls) {
        let calls: Calls = Arc::default();
        let handler = move |State(c): State<Calls>, Form(f): Form<HashMap<String, String>>| {
            let reply = reply.clone();
            async move {
                c.lock().expect("calls").push(f);
                (status, axum::Json(reply))
            }
        };
        let app = Router::new()
            .route("/auth/revoke", post(handler.clone()))
            .route("/auth/token", post(handler))
            .with_state(calls.clone());
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.expect("bind fake");
        let addr = listener.local_addr().expect("fake addr");
        tokio::spawn(async move { axum::serve(listener, app).await.expect("fake serves") });
        (format!("http://{addr}"), calls)
    }

    #[tokio::test]
    async fn revoke_posts_the_refresh_token_once_with_a_client_secret() {
        let (base, calls) = fake_apple(StatusCode::OK, json!({})).await;
        revoke_at(&reqwest::Client::new(), &base, &key(), APP, "r-token").await.expect("revoked");
        let calls = calls.lock().expect("calls").clone();
        assert_eq!(calls.len(), 1, "exactly one revoke call");
        let form = &calls[0];
        assert_eq!(form["client_id"], APP);
        assert_eq!(form["token"], "r-token");
        assert_eq!(form["token_type_hint"], "refresh_token");
        assert_eq!(decode_header(&form["client_secret"]).expect("jwt").alg, Algorithm::ES256);

        let (base, _) = fake_apple(StatusCode::BAD_REQUEST, json!({"error": "invalid_client"})).await;
        assert_eq!(revoke_at(&reqwest::Client::new(), &base, &key(), APP, "r").await, Err("provider_error"));
    }

    #[tokio::test]
    async fn code_exchange_keeps_the_refresh_token_only_for_the_same_user() {
        let id_token = |sub: &str| format!("e30.{}.sig", URL_SAFE_NO_PAD.encode(json!({"sub": sub}).to_string()));
        let (base, calls) = fake_apple(StatusCode::OK, json!({"refresh_token": "r-1", "id_token": id_token("u1")})).await;
        let http = reqwest::Client::new();
        assert_eq!(exchange_at(&http, &base, &key(), APP, "code-1", "u1").await, Ok("r-1".into()));
        assert_eq!(calls.lock().expect("calls")[0]["grant_type"], "authorization_code");
        assert_eq!(exchange_at(&http, &base, &key(), APP, "code-1", "u2").await, Err("user_mismatch"));
        let (base, _) = fake_apple(StatusCode::BAD_REQUEST, json!({"error": "invalid_grant"})).await;
        assert_eq!(exchange_at(&http, &base, &key(), APP, "used", "u1").await, Err("provider_error"));
    }
}
