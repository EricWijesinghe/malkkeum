//! Social sign-in: verifies a provider token server-side and returns the provider's stable user id.
//! Dev mode accepts `dev:<id>` for any provider without network.

use super::{Providers, apple};
use crate::{
    crypto,
    error::{ApiError, ApiResult},
};
use jsonwebtoken::{Algorithm, DecodingKey, Validation, decode, decode_header};
use serde::Deserialize;
use serde_json::Value;
use std::{
    sync::Mutex,
    time::{Duration, Instant},
};

pub(super) const APPLE_ISS: &str = "https://appleid.apple.com";
const APPLE_KEYS_URL: &str = "https://appleid.apple.com/auth/keys";
const GOOGLE_JWKS_URL: &str = "https://www.googleapis.com/oauth2/v3/certs";
const GOOGLE_ISSUERS: [&str; 2] = ["accounts.google.com", "https://accounts.google.com"];
const KEYS_TTL: Duration = Duration::from_secs(6 * 60 * 60);
/// An unknown `kid` may refetch the key set, but no more often than this (bogus kids must not hammer the provider).
const UNKNOWN_KID_REFETCH: Duration = Duration::from_secs(5 * 60);
const DEV_ID_MAX: usize = 128;

pub struct SocialUser {
    pub provider_user_id: String,
    pub email: Option<String>,
    /// Our app the token was issued to (id-token `aud`). Apple's code exchange and revoke use it as `client_id`.
    pub audience: Option<String>,
    /// Provider refresh token, kept encrypted only to revoke the sign-in on account deletion (Naver).
    pub refresh_token: Option<String>,
}

pub async fn verify(p: &Providers, provider: &str, token: &str, nonce: Option<&str>) -> ApiResult<SocialUser> {
    if p.cfg().dev_mode
        && let Some(id) = token.strip_prefix("dev:")
    {
        if id.is_empty() || id.len() > DEV_ID_MAX {
            return Err(ApiError::BadRequest("invalid_token"));
        }
        return Ok(SocialUser {
            provider_user_id: id.into(),
            email: None,
            audience: None,
            refresh_token: None,
        });
    }
    match provider {
        "kakao" => kakao(p, token).await,
        "naver" => naver(p, token).await,
        "google" => google(p, token, nonce).await,
        "apple" => apple(p, token, nonce).await,
        _ => Err(ApiError::BadRequest("invalid_provider")),
    }
}

/// Shared by the id-token providers: issuer, audience (our client id), and expiry all must hold.
pub fn id_claims_ok(issuer_ok: bool, audience: &str, client_ids: &[String], exp: i64, now: i64) -> bool {
    issuer_ok && exp > now && client_ids.iter().any(|c| c == audience)
}

/// Replay check. A token that carries a nonce must be presented with the raw nonce the app generated. Providers
/// store `sha256(raw)` in the token (the raw value when the app sent it unhashed). A token without a nonce passes.
pub fn nonce_ok(token_nonce: Option<&str>, raw: Option<&str>) -> bool {
    match (token_nonce, raw) {
        (Some(t), Some(r)) => t == r || t == crate::auth::sha256_hex(r.as_bytes()),
        (Some(_), None) => false,
        (None, _) => true,
    }
}

fn json_text(v: &Value) -> String {
    match v {
        Value::String(s) => s.clone(),
        Value::Number(n) => n.to_string(),
        _ => String::new(),
    }
}

pub(super) fn unreachable_provider(_: reqwest::Error) -> ApiError {
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
        audience: None,
        refresh_token: None,
    })
}

/// Naver tokens are issued per app and its profile call does not name the app, so a token from another app
/// would pass a profile check. The app sends the login code instead; we redeem it with our own client id and
/// secret, so the access token we get back was issued to our app.
async fn naver(p: &Providers, token: &str) -> ApiResult<SocialUser> {
    let (code, state) = split_naver_code(token).ok_or(ApiError::BadRequest("invalid_token"))?;
    let integ = p.integ();
    let (Some(client_id), Some(secret)) = (integ.naver_client_id.as_deref(), integ.naver_client_secret.as_deref()) else {
        return Err(ApiError::Unavailable("provider_not_configured"));
    };
    // Form POST keeps client_secret out of the URL (proxy and access logs). Naver's guide lists GET and POST;
    // POST is the form used by working examples. Residual: confirm in a real login (see DEPLOY.md).
    let form = form_body(&[("grant_type", "authorization_code"), ("client_id", client_id), ("client_secret", secret), ("code", code), ("state", state)]);
    let resp = p
        .http()
        .post(NAVER_TOKEN_URL)
        .header(reqwest::header::CONTENT_TYPE, "application/x-www-form-urlencoded")
        .body(form)
        .send()
        .await
        .map_err(unreachable_provider)?;
    let status = resp.status();
    if status.is_server_error() {
        return Err(ApiError::Unavailable("provider_unreachable"));
    }
    if !status.is_success() {
        return Err(ApiError::Unauthorized);
    }
    let reply = resp.json::<Value>().await.map_err(unreachable_provider)?;
    let access = naver_access_token(&reply)?;
    let mut user = naver_profile(&bearer_json(p, NAVER_PROFILE_URL, &access).await?)?;
    user.refresh_token = reply["refresh_token"].as_str().filter(|t| !t.is_empty()).map(str::to_string);
    Ok(user)
}

// Source: https://developers.naver.com/docs/login/api/api.md (token: nid.naver.com/oauth2.0/token, profile:
// openapi.naver.com/v1/nid/me, profile body `{resultcode, message, response: {id, ...}}`). The developers.naver.com
// pages were not fetchable from this machine; these URLs match what the code has always used. Unverified this session.
const NAVER_TOKEN_URL: &str = "https://nid.naver.com/oauth2.0/token";
const NAVER_PROFILE_URL: &str = "https://openapi.naver.com/v1/nid/me";
const NAVER_PARAM_MAX: usize = 512;

/// `application/x-www-form-urlencoded` body; reqwest here has no `form` feature, so encode through `Url`.
pub(super) fn form_body(pairs: &[(&str, &str)]) -> String {
    let mut u = reqwest::Url::parse("http://form.invalid/").expect("static url");
    u.query_pairs_mut().extend_pairs(pairs.iter().copied());
    u.query().unwrap_or_default().to_string()
}

/// The app sends `code:state`. Both are opaque strings; neither may be empty or contain a colon.
fn split_naver_code(token: &str) -> Option<(&str, &str)> {
    let (code, state) = token.split_once(':')?;
    let ok = |s: &str| !s.is_empty() && s.len() <= NAVER_PARAM_MAX && !s.contains(':');
    (ok(code) && ok(state)).then_some((code, state))
}

/// Token endpoint reply: `access_token` on success; a rejected or reused code has no `access_token`.
fn naver_access_token(v: &Value) -> ApiResult<String> {
    match v["access_token"].as_str() {
        Some(t) if !t.is_empty() => Ok(t.to_string()),
        _ => Err(ApiError::Unauthorized),
    }
}

fn naver_profile(v: &Value) -> ApiResult<SocialUser> {
    let id = json_text(&v["response"]["id"]);
    if id.is_empty() {
        return Err(ApiError::Unauthorized);
    }
    Ok(SocialUser {
        provider_user_id: id,
        email: v["response"]["email"].as_str().map(str::to_string),
        audience: None,
        refresh_token: None,
    })
}

#[derive(Deserialize, Clone)]
pub(super) struct Jwk {
    pub(super) kid: String,
    pub(super) n: String,
    pub(super) e: String,
}

#[derive(Deserialize)]
struct Jwks {
    keys: Vec<Jwk>,
}

/// Claims shared by Apple and Google id tokens. `nonce` is present only when the app requested one.
#[derive(Deserialize)]
struct IdClaims {
    iss: String,
    aud: String,
    sub: String,
    exp: i64,
    email: Option<String>,
    nonce: Option<String>,
}

/// One provider's signing keys, cached process-wide.
pub struct KeyCache {
    url: &'static str,
    slot: Mutex<Option<(Instant, Vec<Jwk>)>>,
    /// Last fetch attempt, successful or not: refetches are rate-limited even while the provider fails.
    attempt: Mutex<Option<Instant>>,
    /// Single flight: one fetch at a time; the others wait and reuse its result.
    fetching: tokio::sync::Mutex<()>,
}

pub(super) static APPLE_KEYS: KeyCache = KeyCache::new(APPLE_KEYS_URL);
static GOOGLE_KEYS: KeyCache = KeyCache::new(GOOGLE_JWKS_URL);

/// Whether a cached key set may answer. A known kid is served for the full TTL; an unknown kid is served from the
/// cache (and refused) until the set is old enough to refetch, so a rotated key is picked up within minutes.
pub fn use_cache(age: Duration, kid_known: bool) -> bool {
    if kid_known { age < KEYS_TTL } else { age < UNKNOWN_KID_REFETCH }
}

/// A new fetch may start only once the last attempt is older than the unknown-kid wait.
pub fn may_refetch(last_attempt_age: Option<Duration>) -> bool {
    last_attempt_age.is_none_or(|a| a >= UNKNOWN_KID_REFETCH)
}

impl KeyCache {
    const fn new(url: &'static str) -> Self {
        Self { url, slot: Mutex::new(None), attempt: Mutex::new(None), fetching: tokio::sync::Mutex::const_new(()) }
    }

    fn stored(&self) -> Option<(Instant, Vec<Jwk>)> {
        self.slot.lock().ok()?.clone()
    }

    /// The cache's answer for `kid`, or None when it is stale for this kid.
    fn lookup(&self, kid: &str) -> Option<ApiResult<Jwk>> {
        let (at, keys) = self.stored()?;
        let known = keys.into_iter().find(|k| k.kid == kid);
        use_cache(at.elapsed(), known.is_some()).then(|| known.ok_or(ApiError::Unauthorized))
    }

    async fn fetch(&self, p: &Providers) -> ApiResult<Vec<Jwk>> {
        if let Ok(mut a) = self.attempt.lock() {
            *a = Some(Instant::now());
        }
        let jwks: Jwks = p.http().get(self.url).send().await.map_err(unreachable_provider)?.json().await.map_err(unreachable_provider)?;
        if let Ok(mut guard) = self.slot.lock() {
            *guard = Some((Instant::now(), jwks.keys.clone()));
        }
        Ok(jwks.keys)
    }
}

/// The key for `kid`: from cache when `use_cache` allows, otherwise refetched (one fetch at a time, at most one per
/// `UNKNOWN_KID_REFETCH`). Inside that wait a stale key set still answers; with none the provider counts as down.
pub(super) async fn signing_key(p: &Providers, cache: &KeyCache, kid: &str) -> ApiResult<Jwk> {
    if let Some(r) = cache.lookup(kid) {
        return r;
    }
    let _flight = cache.fetching.lock().await;
    if let Some(r) = cache.lookup(kid) {
        return r;
    }
    let last = cache.attempt.lock().ok().and_then(|a| a.map(|t| t.elapsed()));
    if !may_refetch(last) {
        let stale = cache.stored().and_then(|(_, keys)| keys.into_iter().find(|k| k.kid == kid));
        return stale.ok_or(ApiError::Unavailable("provider_unreachable"));
    }
    cache.fetch(p).await?.into_iter().find(|k| k.kid == kid).ok_or(ApiError::Unauthorized)
}

/// id-token check shared by Apple and Google: RS256 signature against the provider's keys, then issuer, audience
/// (one of our client ids), expiry, and nonce.
async fn verify_id_token(p: &Providers, cache: &KeyCache, token: &str, issuers: &[&str], ids: &[String], nonce: Option<&str>) -> ApiResult<SocialUser> {
    if ids.is_empty() {
        return Err(ApiError::Unavailable("provider_not_configured"));
    }
    let kid = decode_header(token).map_err(|_| ApiError::Unauthorized)?.kid.ok_or(ApiError::Unauthorized)?;
    let jwk = signing_key(p, cache, &kid).await?;
    let key = DecodingKey::from_rsa_components(&jwk.n, &jwk.e).map_err(|_| ApiError::Unauthorized)?;
    // Signature and algorithm (RS256 only) are checked by jsonwebtoken; the claims below are checked here.
    let mut v = Validation::new(Algorithm::RS256);
    v.validate_exp = false;
    v.validate_aud = false;
    v.required_spec_claims.clear();
    let c = decode::<IdClaims>(token, &key, &v).map_err(|_| ApiError::Unauthorized)?.claims;
    let issuer_ok = issuers.contains(&c.iss.as_str());
    if !id_claims_ok(issuer_ok, &c.aud, ids, c.exp, chrono::Utc::now().timestamp()) || !nonce_ok(c.nonce.as_deref(), nonce) {
        return Err(ApiError::Unauthorized);
    }
    Ok(SocialUser {
        provider_user_id: c.sub,
        email: c.email,
        audience: Some(c.aud),
        refresh_token: None,
    })
}

async fn google(p: &Providers, token: &str, nonce: Option<&str>) -> ApiResult<SocialUser> {
    let integ = p.integ();
    verify_id_token(p, &GOOGLE_KEYS, token, &GOOGLE_ISSUERS, &integ.google_client_ids, nonce).await
}

async fn apple(p: &Providers, token: &str, nonce: Option<&str>) -> ApiResult<SocialUser> {
    let integ = p.integ();
    verify_id_token(p, &APPLE_KEYS, token, &[APPLE_ISS], &integ.apple_client_ids, nonce).await
}

// Kakao: https://developers.kakao.com/docs/en/kakaologin/rest-api (Unlink: `Authorization: KakaoAK <admin key>`,
// form `target_id_type=user_id&target_id=<id>`, 200 `{id}`), checked 2026-11.
// Naver: https://developers.naver.com/docs/login/devguide/devguide.md (refresh, then `grant_type=delete` with
// `service_provider=NAVER`; errors come back as 200 bodies). Page not fetchable here; confirm in a live unlink.
const KAKAO_UNLINK_URL: &str = "https://kapi.kakao.com/v1/user/unlink";

/// Why a provider unlink did not happen. Logged; account deletion goes on regardless.
pub type UnlinkResult = Result<(), &'static str>;

/// Form POST to a provider; the JSON reply on 2xx (Null when the body is not JSON).
async fn post_form(p: &Providers, url: &str, auth: Option<String>, form: String) -> Result<Value, &'static str> {
    let mut req = p.http().post(url).header(reqwest::header::CONTENT_TYPE, "application/x-www-form-urlencoded").body(form);
    if let Some(a) = auth {
        req = req.header(reqwest::header::AUTHORIZATION, a);
    }
    let resp = req.send().await.map_err(|_| "provider_unreachable")?;
    if !resp.status().is_success() {
        return Err("provider_error");
    }
    Ok(resp.json::<Value>().await.unwrap_or(Value::Null))
}

/// Kakao: unlink by user id with the Admin key (no user token needed).
async fn kakao_unlink(p: &Providers, user_id: &str) -> UnlinkResult {
    let admin = p.integ().kakao_admin_key.clone().ok_or("not_configured")?;
    let form = form_body(&[("target_id_type", "user_id"), ("target_id", user_id)]);
    post_form(p, KAKAO_UNLINK_URL, Some(format!("KakaoAK {admin}")), form).await.map(|_| ())
}

/// Naver: trade the stored refresh token for an access token, then delete it (this disconnects the app).
async fn naver_delete(p: &Providers, refresh: Option<&str>) -> UnlinkResult {
    let refresh = refresh.ok_or("no_token")?;
    let integ = p.integ();
    let (Some(id), Some(secret)) = (integ.naver_client_id.as_deref(), integ.naver_client_secret.as_deref()) else {
        return Err("not_configured");
    };
    let form = form_body(&[("grant_type", "refresh_token"), ("client_id", id), ("client_secret", secret), ("refresh_token", refresh)]);
    let access = naver_access_token(&post_form(p, NAVER_TOKEN_URL, None, form).await?).map_err(|_| "token_expired")?;
    let form = form_body(&[("grant_type", "delete"), ("client_id", id), ("client_secret", secret), ("access_token", &access), ("service_provider", "NAVER")]);
    let reply = post_form(p, NAVER_TOKEN_URL, None, form).await?;
    if reply["result"] == "success" { Ok(()) } else { Err("provider_error") }
}

/// One social sign-in of an account, read inside the deletion transaction so it can be unlinked after commit.
pub struct Link {
    provider: String,
    user_id: String,
    client_id: Option<String>,
    token: Option<String>,
}

/// The account's sign-ins with their decrypted refresh tokens. Run in the deletion transaction, before the
/// identities are deleted; the provider calls happen after commit (`unlink`), so no lock is held over HTTP.
pub async fn links(conn: &mut sqlx::PgConnection, data_key: &[u8; 32], role: &str, subject: uuid::Uuid) -> sqlx::Result<Vec<Link>> {
    let rows: Vec<(String, String, Option<String>, Option<String>)> = sqlx::query_as(
        "SELECT i.provider, i.provider_user_id, t.client_id, t.refresh_token_enc
         FROM user_identities i LEFT JOIN social_tokens t ON t.identity_id = i.id WHERE i.role = $1 AND i.subject_id = $2",
    )
    .bind(role)
    .bind(subject)
    .fetch_all(conn)
    .await?;
    Ok(rows
        .into_iter()
        .map(|(provider, user_id, client_id, enc)| Link { provider, user_id, client_id, token: enc.and_then(|e| crypto::decrypt(data_key, &e)) })
        .collect())
}

/// Disconnects each sign-in at its provider: Apple revoke (5.1.1(v)), Kakao unlink, Naver token delete. Google
/// has no stored token (follow-up). Best effort: a missing key or a provider error is logged without token
/// values and never undoes the deletion.
pub async fn unlink(p: &Providers, role: &str, subject: uuid::Uuid, links: Vec<Link>) {
    for l in links {
        let result = if p.cfg().dev_mode {
            tracing::info!(target: "fake_social", provider = l.provider, has_token = l.token.is_some(), "social sign-in unlinked");
            Ok(())
        } else {
            match l.provider.as_str() {
                "apple" => apple::revoke(p, l.client_id.as_deref(), l.token.as_deref()).await,
                "kakao" => kakao_unlink(p, &l.user_id).await,
                "naver" => naver_delete(p, l.token.as_deref()).await,
                _ => Err("unsupported"),
            }
        };
        if let Err(reason) = result {
            tracing::warn!(provider = l.provider, role, %subject, reason, "social sign-in not unlinked at the provider");
        }
    }
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
    fn nonce_must_match_when_the_token_carries_one() {
        let raw = "rawnonce123";
        let hashed = crate::auth::sha256_hex(raw.as_bytes());
        assert!(nonce_ok(Some(&hashed), Some(raw)), "sha256 of the raw nonce");
        assert!(nonce_ok(Some(raw), Some(raw)), "unhashed nonce sent to the provider");
        assert!(!nonce_ok(Some(&hashed), Some("other")), "a different nonce is a replay");
        assert!(!nonce_ok(Some(&hashed), None), "token has a nonce but the app sent none");
        assert!(nonce_ok(None, None), "no nonce anywhere");
        assert!(nonce_ok(None, Some(raw)), "client nonce the token does not echo is not checkable");
    }

    #[test]
    fn known_kid_is_served_from_cache_for_the_ttl_unknown_kid_only_after_the_short_wait() {
        assert!(use_cache(Duration::from_secs(60), true));
        assert!(!use_cache(KEYS_TTL, true), "stale known key set refetches");
        assert!(use_cache(Duration::from_secs(60), false), "unknown kid inside the wait does not refetch");
        assert!(!use_cache(UNKNOWN_KID_REFETCH, false), "unknown kid after the wait refetches (rotation)");
    }

    #[test]
    fn refetch_waits_after_any_attempt_even_a_failed_one() {
        assert!(may_refetch(None), "never fetched");
        assert!(!may_refetch(Some(Duration::from_secs(1))), "just tried");
        assert!(may_refetch(Some(UNKNOWN_KID_REFETCH)));
    }

    #[test]
    fn provider_ids_accept_numbers_and_strings() {
        assert_eq!(json_text(&serde_json::json!(42)), "42");
        assert_eq!(json_text(&serde_json::json!("abc")), "abc");
        assert_eq!(json_text(&serde_json::json!(null)), "");
    }

    #[test]
    fn naver_code_needs_code_and_state_without_colons() {
        assert_eq!(split_naver_code("abc:xyz"), Some(("abc", "xyz")));
        assert_eq!(split_naver_code("abc"), None);
        assert_eq!(split_naver_code(":xyz"), None);
        assert_eq!(split_naver_code("abc:"), None);
        assert_eq!(split_naver_code("abc:x:y"), None);
        let long = "a".repeat(NAVER_PARAM_MAX + 1);
        assert_eq!(split_naver_code(&format!("{long}:xyz")), None);
    }

    #[test]
    fn naver_token_reply_needs_access_token() {
        let ok = serde_json::json!({"access_token": "t0k", "token_type": "bearer", "expires_in": "3600"});
        assert_eq!(naver_access_token(&ok).ok().as_deref(), Some("t0k"));
        let rejected = serde_json::json!({"error": "invalid_request", "error_description": "reused code"});
        assert!(naver_access_token(&rejected).is_err());
        assert!(naver_access_token(&serde_json::json!({"access_token": ""})).is_err());
    }

    #[test]
    fn naver_profile_needs_id() {
        let me = serde_json::json!({"resultcode": "00", "response": {"id": "12345", "email": "a@example.com"}});
        let user = naver_profile(&me).expect("profile");
        assert_eq!(user.provider_user_id, "12345");
        assert_eq!(user.email.as_deref(), Some("a@example.com"));
        assert!(naver_profile(&serde_json::json!({"response": {}})).is_err());
    }
}
