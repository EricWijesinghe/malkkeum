//! Wire contract shared by every route: framework failures use the error envelope, lists page by
//! opaque cursor, bodies have per-group size limits, and deprecated routes announce their sunset.

use crate::error::{ApiError, ApiResult};
use axum::{
    Json,
    body::Body,
    extract::Request,
    http::{HeaderName, HeaderValue, StatusCode, header},
    middleware::Next,
    response::{IntoResponse, Response},
};
use base64::{Engine, engine::general_purpose::URL_SAFE_NO_PAD};
use chrono::{DateTime, NaiveDate, SecondsFormat, Utc};
use serde::{Deserialize, Serialize};
use serde_json::json;

/// Default JSON body ceiling for every route not listed below.
pub const JSON_BODY_LIMIT: usize = 1024 * 1024;
/// Login and OTP bodies are tiny; capping them shrinks the unauthenticated attack surface.
pub const AUTH_BODY_LIMIT: usize = 16 * 1024;
/// Multipart photo uploads.
pub const UPLOAD_BODY_LIMIT: usize = 12 * 1024 * 1024;

/// Free-text fields (names, titles) in characters; e-mail and password in bytes (argon2 cost grows with length).
pub const MAX_TEXT_CHARS: usize = 200;
pub const MAX_EMAIL_BYTES: usize = 254;
pub const MAX_PASSWORD_BYTES: usize = 256;

pub const DEFAULT_PAGE: i64 = 50;
pub const MAX_PAGE: i64 = 100;
/// Set on a list response when more rows may follow; pass back as `cursor`.
pub const NEXT_CURSOR: HeaderName = HeaderName::from_static("x-next-cursor");

/// Stable code for a framework-generated failure (unknown route, bad method, rejected body, timeout).
fn framework_code(status: StatusCode) -> &'static str {
    match status.as_u16() {
        400 => "bad_request",
        404 => "not_found",
        405 => "method_not_allowed",
        408 => "timeout",
        413 => "payload_too_large",
        415 => "unsupported_media_type",
        422 => "invalid_body",
        429 => "rate_limited",
        _ if status.is_server_error() => "internal",
        _ => "bad_request",
    }
}

/// Rewrites non-JSON error bodies (router 404/405, JSON rejections, body limits) into `{"error":{"code"}}`.
pub async fn error_envelope(req: Request, next: Next) -> Response {
    let res = next.run(req).await;
    let status = res.status();
    let is_json = res
        .headers()
        .get(header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .is_some_and(|v| v.starts_with("application/json"));
    if !(status.is_client_error() || status.is_server_error()) || is_json {
        return res;
    }
    let (mut parts, _) = res.into_parts();
    parts.headers.remove(header::CONTENT_LENGTH);
    parts.headers.insert(header::CONTENT_TYPE, HeaderValue::from_static("application/json"));
    let body = json!({ "error": { "code": framework_code(status) } }).to_string();
    Response::from_parts(parts, Body::from(body))
}

/// Query params every growing list accepts.
#[derive(Debug, Deserialize, Default)]
pub struct PageQuery {
    pub limit: Option<i64>,
    pub cursor: Option<String>,
}

/// Parses one decoded cursor part; a malformed part is the client's error.
pub fn cursor_part<T: std::str::FromStr>(part: &str) -> ApiResult<T> {
    part.parse().map_err(|_| ApiError::BadRequest("invalid_cursor"))
}

/// `limit` query value: default [`DEFAULT_PAGE`], must be 1..=[`MAX_PAGE`].
pub fn page_limit(limit: Option<i64>) -> ApiResult<i64> {
    match limit {
        None => Ok(DEFAULT_PAGE),
        Some(n) if (1..=MAX_PAGE).contains(&n) => Ok(n),
        Some(_) => Err(ApiError::BadRequest("invalid_limit")),
    }
}

/// RFC 3339 with microseconds: the form Postgres keeps, so a cursor round-trips exactly.
pub fn ts_key(t: DateTime<Utc>) -> String {
    t.to_rfc3339_opts(SecondsFormat::Micros, true)
}

/// Opaque cursor: URL-safe base64 of the sort-key parts joined by `|`.
pub fn encode_cursor(parts: &[&str]) -> String {
    URL_SAFE_NO_PAD.encode(parts.join("|"))
}

/// Parses a cursor into exactly `n` parts. Anything else is a client error, never a silent first page.
pub fn decode_cursor(cursor: Option<&str>, n: usize) -> ApiResult<Option<Vec<String>>> {
    let Some(c) = cursor else { return Ok(None) };
    let bytes = URL_SAFE_NO_PAD.decode(c).map_err(|_| ApiError::BadRequest("invalid_cursor"))?;
    let text = String::from_utf8(bytes).map_err(|_| ApiError::BadRequest("invalid_cursor"))?;
    let parts: Vec<String> = text.split('|').map(str::to_owned).collect();
    if parts.len() != n {
        return Err(ApiError::BadRequest("invalid_cursor"));
    }
    Ok(Some(parts))
}

/// JSON array body plus `X-Next-Cursor` when the page came back full.
pub fn paged<T: Serialize>(rows: Vec<T>, limit: i64, cursor_of: impl FnOnce(&T) -> String) -> Response {
    let next = if i64::try_from(rows.len()).is_ok_and(|n| n == limit) { rows.last().map(cursor_of) } else { None };
    let mut res = Json(rows).into_response();
    if let Some(value) = next.and_then(|c| HeaderValue::from_str(&c).ok()) {
        res.headers_mut().insert(NEXT_CURSOR, value);
    }
    res
}

/// Adds `Deprecation`, `Sunset` (RFC 9745, RFC 8594) and a successor `Link` to every response of the route.
pub async fn deprecated_route(req: Request, next: Next, sunset: NaiveDate, successor: &'static str) -> Response {
    let mut res = next.run(req).await;
    let h = res.headers_mut();
    h.insert(HeaderName::from_static("deprecation"), HeaderValue::from_static("true"));
    if let Ok(v) = HeaderValue::from_str(&sunset.format("%a, %d %b %Y 00:00:00 GMT").to_string()) {
        h.insert(HeaderName::from_static("sunset"), v);
    }
    h.insert(header::LINK, HeaderValue::from_str(&format!("<{successor}>; rel=\"successor-version\"")).unwrap_or(HeaderValue::from_static("")));
    res
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{Router, routing::get};
    use tower::ServiceExt;

    #[test]
    fn limit_is_bounded() {
        assert_eq!(page_limit(None).ok(), Some(DEFAULT_PAGE));
        assert_eq!(page_limit(Some(MAX_PAGE)).ok(), Some(MAX_PAGE));
        assert!(page_limit(Some(0)).is_err());
        assert!(page_limit(Some(MAX_PAGE + 1)).is_err());
    }

    #[test]
    fn cursor_round_trips_and_rejects_garbage() {
        let c = encode_cursor(&["2026-01-02", "9", "abc"]);
        assert_eq!(decode_cursor(Some(&c), 3).ok().flatten(), Some(vec!["2026-01-02".into(), "9".into(), "abc".into()]));
        assert!(decode_cursor(Some(&c), 2).is_err());
        assert!(decode_cursor(Some("%%%"), 1).is_err());
        assert_eq!(decode_cursor(None, 2).ok().flatten(), None);
    }

    #[test]
    fn timestamp_key_keeps_micros() {
        let t = DateTime::parse_from_rfc3339("2026-03-04T05:06:07.123456789Z").expect("ts").with_timezone(&Utc);
        assert_eq!(ts_key(t), "2026-03-04T05:06:07.123456Z");
    }

    #[test]
    fn paged_sets_cursor_only_on_full_page() {
        let full = paged(vec![1, 2], 2, |n| n.to_string());
        assert_eq!(full.headers().get(NEXT_CURSOR).and_then(|v| v.to_str().ok()), Some("2"));
        let short = paged(vec![1], 2, |n| n.to_string());
        assert!(short.headers().get(NEXT_CURSOR).is_none());
    }

    #[tokio::test]
    async fn framework_errors_use_envelope() {
        let app = Router::new().route("/a", get(|| async { "ok" })).layer(axum::middleware::from_fn(error_envelope));
        let res = app.clone().oneshot(Request::builder().uri("/nope").body(Body::empty()).expect("req")).await.expect("svc");
        assert_eq!(res.status(), StatusCode::NOT_FOUND);
        let body = axum::body::to_bytes(res.into_body(), 1024).await.expect("body");
        assert_eq!(&body[..], br#"{"error":{"code":"not_found"}}"#);
    }

    #[test]
    fn sunset_is_http_date() {
        let d = NaiveDate::from_ymd_opt(2027, 6, 30).expect("date");
        assert_eq!(d.format("%a, %d %b %Y 00:00:00 GMT").to_string(), "Wed, 30 Jun 2027 00:00:00 GMT");
    }
}
