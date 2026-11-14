//! Logging setup and request ids. Every request carries an `x-request-id`: a sane incoming value is
//! kept (so a proxy or the app can correlate), anything else is replaced by a generated UUID. The id
//! is echoed on the response, recorded on the request span, and returned in error bodies.

use axum::{
    extract::Request,
    http::{HeaderName, HeaderValue},
    middleware::Next,
    response::Response,
};
use tracing_subscriber::EnvFilter;
use uuid::Uuid;

pub const REQUEST_ID_HEADER: HeaderName = HeaderName::from_static("x-request-id");
const MAX_INCOMING_ID: usize = 128;

tokio::task_local! {
    static REQUEST_ID: String;
}

/// Installs the global subscriber. `LOG_FORMAT=json` emits one JSON object per event (production);
/// anything else keeps the human-readable format (local development).
pub fn init_logging(default_filter: &str) {
    let filter = EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new(default_filter));
    let builder = tracing_subscriber::fmt().with_env_filter(filter);
    if std::env::var("LOG_FORMAT").is_ok_and(|v| v.eq_ignore_ascii_case("json")) {
        builder.json().init();
    } else {
        builder.init();
    }
}

/// The id of the request being handled, if called from within one (used for error bodies).
pub fn current_request_id() -> Option<String> {
    REQUEST_ID.try_with(Clone::clone).ok()
}

/// Accepts a client id only when it is short and made of token-safe characters; otherwise generates one.
pub fn accept_request_id(incoming: Option<&str>) -> String {
    match incoming {
        Some(id)
            if !id.is_empty() && id.len() <= MAX_INCOMING_ID && id.bytes().all(|b| b.is_ascii_alphanumeric() || matches!(b, b'-' | b'_' | b'.' | b':')) =>
        {
            id.to_string()
        }
        _ => Uuid::now_v7().to_string(),
    }
}

/// Stores the id in the request extensions (the trace span reads it), scopes it for error
/// rendering, and echoes it on the response.
pub async fn request_id(mut req: Request, next: Next) -> Response {
    let incoming = req.headers().get(&REQUEST_ID_HEADER).and_then(|v| v.to_str().ok());
    let id = accept_request_id(incoming);
    req.extensions_mut().insert(RequestId(id.clone()));
    let mut resp = REQUEST_ID.scope(id.clone(), next.run(req)).await;
    if let Ok(value) = HeaderValue::from_str(&id) {
        resp.headers_mut().insert(REQUEST_ID_HEADER, value);
    }
    resp
}

/// Request-extension form of the id, read by the trace span.
#[derive(Clone, Debug)]
pub struct RequestId(pub String);

#[cfg(test)]
mod tests {
    use super::accept_request_id;

    #[test]
    fn keeps_sane_incoming_ids_and_replaces_the_rest() {
        assert_eq!(accept_request_id(Some("abc-123_x.y:z")), "abc-123_x.y:z");
        assert_ne!(accept_request_id(Some("has space")), "has space");
        assert_ne!(accept_request_id(Some("")), "");
        assert_ne!(accept_request_id(Some(&"a".repeat(129))), "a".repeat(129));
        assert_eq!(accept_request_id(None).len(), 36, "generated UUID");
    }
}
