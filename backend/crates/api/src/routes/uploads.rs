//! Photo uploads (chat photos, completion photos). Validated by magic bytes, stored under random names.
//! Files are never mounted publicly: `/v1/files/<name>?exp=&sig=` serves them when the HMAC (key derived
//! from DATA_KEY) over name and expiry checks out. Stored values are `/files/<name>`; `sign_json` turns
//! every such path in a JSON response into a fresh signed URL, so handlers never store expiring links.

use crate::{
    auth::Auth,
    config::Config,
    error::{ApiError, ApiResult},
    ratelimit::within_quota,
    state::AppState,
    util::IMAGE_EXTS,
};
use axum::{
    Json, Router,
    body::Body,
    extract::{Multipart, Path, Query, Request, State},
    http::{HeaderValue, header},
    middleware::Next,
    response::{IntoResponse, Response},
    routing::{get, post},
};
use chrono::Utc;
use hmac::{Hmac, Mac};
use rand::{RngCore, rngs::OsRng};
use serde::Deserialize;
use serde_json::{Value, json};
use sha2::Sha256;

const MAX_IMAGE_BYTES: usize = 10 * 1024 * 1024;
/// How long a signed file URL stays valid; apps get fresh ones on every API read.
const URL_TTL_SECS: i64 = 3600;
const KEY_CONTEXT: &[u8] = b"malkkeum/file-urls/v1";
const MAX_JSON_BYTES: usize = 16 * 1024 * 1024;

pub fn routes() -> Router<AppState> {
    Router::new().route("/uploads", post(upload)).route("/files/{name}", get(serve))
}

fn sniff(bytes: &[u8]) -> Option<&'static str> {
    match bytes {
        [0xFF, 0xD8, 0xFF, ..] => Some("jpg"),
        [0x89, b'P', b'N', b'G', ..] => Some("png"),
        [b'R', b'I', b'F', b'F', _, _, _, _, b'W', b'E', b'B', b'P', ..] => Some("webp"),
        [_, _, _, _, b'f', b't', b'y', b'p', b'h', b'e', b'i', b'c', ..] => Some("heic"),
        _ => None,
    }
}

/// Key for file URL signatures, derived from DATA_KEY so the owner keeps one secret to protect.
pub fn url_key(config: &Config) -> [u8; 32] {
    let mut mac = <Hmac<Sha256> as Mac>::new_from_slice(&config.data_key).expect("HMAC takes any key length");
    mac.update(KEY_CONTEXT);
    mac.finalize().into_bytes().into()
}

fn tag(key: &[u8; 32], name: &str, exp: i64) -> Hmac<Sha256> {
    let mut mac = <Hmac<Sha256> as Mac>::new_from_slice(key).expect("HMAC takes any key length");
    mac.update(format!("{name}\n{exp}").as_bytes());
    mac
}

/// Hex HMAC-SHA256 over the file name and expiry (unix seconds).
pub fn sign(key: &[u8; 32], name: &str, exp: i64) -> String {
    hex::encode(tag(key, name, exp).finalize().into_bytes())
}

/// True only when the signature matches (constant-time) and `now` is not past `exp`.
pub fn verify(key: &[u8; 32], name: &str, exp: i64, sig: &str, now: i64) -> bool {
    if now > exp {
        return false;
    }
    let Ok(raw) = hex::decode(sig) else {
        return false;
    };
    tag(key, name, exp).verify_slice(&raw).is_ok()
}

/// Names we serve: one plain file name with an image extension. No separators, no leading dot.
pub fn safe_name(name: &str) -> bool {
    let chars_ok = name.bytes().all(|b| b.is_ascii_alphanumeric() || matches!(b, b'.' | b'-' | b'_'));
    let ext_ok = name.rsplit_once('.').is_some_and(|(_, ext)| IMAGE_EXTS.contains(&ext));
    chars_ok && ext_ok && !name.starts_with('.') && name.len() <= 100
}

fn mime(name: &str) -> &'static str {
    match name.rsplit_once('.').map(|(_, ext)| ext) {
        Some("jpg") => "image/jpeg",
        Some("png") => "image/png",
        Some("webp") => "image/webp",
        Some("heic") => "image/heic",
        _ => "application/octet-stream",
    }
}

/// Replaces every stored `/files/<name>` (or base-prefixed legacy form) in a JSON value with a signed URL.
pub fn sign_urls(config: &Config, v: &mut Value) {
    match v {
        Value::String(s) => {
            if let Some(url) = signed_for(config, s.as_str()) {
                *s = url;
            }
        }
        Value::Array(items) => items.iter_mut().for_each(|x| sign_urls(config, x)),
        Value::Object(map) => map.values_mut().for_each(|x| sign_urls(config, x)),
        _ => {}
    }
}

fn signed_for(config: &Config, stored: &str) -> Option<String> {
    let path = stored.strip_prefix(config.public_base_url.as_str()).unwrap_or(stored);
    let name = path.strip_prefix("/files/")?;
    if !safe_name(name) {
        return None;
    }
    let exp = Utc::now().timestamp() + URL_TTL_SECS;
    let sig = sign(&url_key(config), name, exp);
    Some(format!("{}/v1/files/{name}?exp={exp}&sig={sig}", config.public_base_url))
}

/// Signs upload paths in every JSON response (runs after the handler, before the bytes leave).
pub async fn sign_json(State(s): State<AppState>, req: Request, next: Next) -> Response {
    let res = next.run(req).await;
    let is_json = res.headers().get(header::CONTENT_TYPE).is_some_and(|t| t.as_bytes().starts_with(b"application/json"));
    if !is_json {
        return res;
    }
    let (mut parts, body) = res.into_parts();
    let Ok(bytes) = axum::body::to_bytes(body, MAX_JSON_BYTES).await else {
        return ApiError::Internal("response too large to sign".into()).into_response();
    };
    let Ok(mut value) = serde_json::from_slice::<Value>(&bytes) else {
        return Response::from_parts(parts, Body::from(bytes));
    };
    sign_urls(&s.config, &mut value);
    let Ok(out) = serde_json::to_vec(&value) else {
        return ApiError::Internal("re-encoding signed response".into()).into_response();
    };
    parts.headers.remove(header::CONTENT_LENGTH);
    Response::from_parts(parts, Body::from(out))
}

#[derive(Deserialize)]
struct Signed {
    exp: Option<i64>,
    sig: Option<String>,
}

async fn serve(State(s): State<AppState>, Path(name): Path<String>, Query(q): Query<Signed>) -> ApiResult<Response> {
    if !safe_name(&name) {
        return Err(ApiError::NotFound);
    }
    let (Some(exp), Some(sig)) = (q.exp, q.sig) else {
        return Err(ApiError::Forbidden);
    };
    if !verify(&url_key(&s.config), &name, exp, &sig, Utc::now().timestamp()) {
        return Err(ApiError::Forbidden);
    }
    let bytes = tokio::fs::read(s.config.upload_dir.join(&name)).await.map_err(|_| ApiError::NotFound)?;
    let headers = [
        (header::CONTENT_TYPE, HeaderValue::from_static(mime(&name))),
        (header::X_CONTENT_TYPE_OPTIONS, HeaderValue::from_static("nosniff")),
        (header::CACHE_CONTROL, HeaderValue::from_static("private, max-age=3600")),
    ];
    Ok((headers, bytes).into_response())
}

async fn upload(State(s): State<AppState>, a: Auth, mut form: Multipart) -> ApiResult<Json<Value>> {
    let field = form
        .next_field()
        .await
        .map_err(|_| ApiError::BadRequest("invalid_upload"))?
        .ok_or(ApiError::BadRequest("invalid_upload"))?;
    let bytes = field.bytes().await.map_err(|_| ApiError::BadRequest("invalid_upload"))?;
    if bytes.len() > MAX_IMAGE_BYTES {
        return Err(ApiError::BadRequest("file_too_large"));
    }
    let ext = sniff(&bytes).ok_or(ApiError::BadRequest("unsupported_image"))?;
    let mut name = [0u8; 16];
    OsRng.fill_bytes(&mut name);
    let file = format!("{}.{ext}", hex::encode(name));
    let size = i64::try_from(bytes.len()).unwrap_or(i64::MAX);
    // Quota check, row insert and file write share one transaction: a failed write leaves no row.
    let mut tx = s.db.begin().await?;
    sqlx::query("SELECT pg_advisory_xact_lock(hashtext($1))")
        .bind(format!("upload:{}", a.id))
        .execute(&mut *tx)
        .await?;
    let used: i64 = sqlx::query_scalar("SELECT count(*) FROM uploads WHERE owner_role = $1 AND owner_id = $2 AND created_at > now() - interval '24 hours'")
        .bind(a.role.as_str())
        .bind(a.id)
        .fetch_one(&mut *tx)
        .await?;
    if !within_quota(used, s.config.upload_daily_quota) {
        return Err(ApiError::Quota("upload_quota"));
    }
    sqlx::query("INSERT INTO uploads (owner_role, owner_id, file, bytes) VALUES ($1, $2, $3, $4)")
        .bind(a.role.as_str())
        .bind(a.id)
        .bind(&file)
        .bind(size)
        .execute(&mut *tx)
        .await?;
    tokio::fs::write(s.config.upload_dir.join(&file), &bytes)
        .await
        .map_err(|e| ApiError::Internal(e.to_string()))?;
    tx.commit().await?;
    // Relative path; sign_json makes it a signed absolute URL on the way out.
    Ok(Json(json!({ "url": format!("/files/{file}") })))
}

#[cfg(test)]
mod tests {
    use super::*;

    const KEY: [u8; 32] = [9; 32];
    const NAME: &str = "0123456789abcdef0123456789abcdef.jpg";

    #[test]
    fn sniffs_images_only() {
        assert_eq!(sniff(&[0xFF, 0xD8, 0xFF, 0xE0]), Some("jpg"));
        assert_eq!(sniff(b"\x89PNG\r\n"), Some("png"));
        assert_eq!(sniff(b"<html>"), None);
    }

    #[test]
    fn valid_signature_within_expiry() {
        let sig = sign(&KEY, NAME, 2_000);
        assert!(verify(&KEY, NAME, 2_000, &sig, 1_000));
        assert!(verify(&KEY, NAME, 2_000, &sig, 2_000), "expiry instant is still valid");
    }

    #[test]
    fn expired_signature_is_rejected() {
        let sig = sign(&KEY, NAME, 2_000);
        assert!(!verify(&KEY, NAME, 2_000, &sig, 2_001));
    }

    #[test]
    fn tampered_name_expiry_or_signature_is_rejected() {
        let sig = sign(&KEY, NAME, 2_000);
        assert!(!verify(&KEY, "fedcba9876543210fedcba9876543210.jpg", 2_000, &sig, 1_000), "other file");
        assert!(!verify(&KEY, NAME, 9_999, &sig, 1_000), "extended expiry");
        let flipped = format!("{}{}", if sig.starts_with('0') { "1" } else { "0" }, &sig[1..]);
        assert!(!verify(&KEY, NAME, 2_000, &flipped, 1_000), "flipped sig");
        assert!(!verify(&KEY, NAME, 2_000, &sig[..60], 1_000), "truncated sig");
        assert!(!verify(&KEY, NAME, 2_000, "not-hex", 1_000));
        assert!(!verify(&[1; 32], NAME, 2_000, &sig, 1_000), "other key");
    }

    #[test]
    fn traversal_names_are_not_served() {
        assert!(safe_name(NAME));
        assert!(safe_name("logo.png"));
        for bad in ["../secret.jpg", "..%2Fsecret.jpg", "a/b.jpg", "a\\b.jpg", "..jpg", ".env.png", "x.svg", "x", ""] {
            assert!(!safe_name(bad), "{bad} must be rejected");
        }
    }
}
