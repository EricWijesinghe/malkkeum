//! Remote config: feature flags, maintenance mode and store version floors in one public document.
//! Apps read `GET /v1/config` (cached 30 s, here and at the edge); the console writes it.
use super::audit;
use crate::{
    auth::Admin,
    error::{ApiError, ApiResult},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Request, State},
    http::header,
    middleware::Next,
    response::{IntoResponse, Response},
    routing::get,
};
use serde_json::{Map, Value, json};
use sqlx::PgPool;
use std::sync::Mutex;
use std::time::{Duration, Instant};

const CONFIG_KEY: &str = "app_config";
const BUSINESS_KEY: &str = "business";
/// Features the apps can hide. Missing flags default to on.
pub const FLAGS: [&str; 4] = ["booking", "chat", "ai", "payments"];
const MAX_MESSAGE_CHARS: usize = 200;
const CACHE_TTL: Duration = Duration::from_secs(30);
const CACHE_CONTROL: &str = "public, max-age=30";

static CACHE: Mutex<Option<(Instant, Value)>> = Mutex::new(None);

pub fn routes() -> Router<AppState> {
    Router::new().route("/config", get(public_config))
}

pub fn admin_routes() -> Router<AppState> {
    Router::new().route("/config", get(admin_config).put(put_config))
}

/// Stored shape: `{"flags": {"booking": true, ...}, "maintenance": {"on": false, "message": ""}}`.
pub fn clean_config(input: &Value) -> Result<Value, ApiError> {
    let obj = input.as_object().ok_or(ApiError::BadRequest("invalid_input"))?;
    let given = match obj.get("flags") {
        None | Some(Value::Null) => Map::new(),
        Some(Value::Object(f)) => f.clone(),
        Some(_) => return Err(ApiError::BadRequest("invalid_input")),
    };
    if let Some(unknown) = given.keys().find(|k| !FLAGS.contains(&k.as_str())) {
        tracing::debug!(flag = %unknown, "unknown config flag");
        return Err(ApiError::BadRequest("unknown_flag"));
    }
    let mut flags = Map::new();
    for f in FLAGS {
        let on = match given.get(f) {
            None | Some(Value::Null) => true,
            Some(Value::Bool(b)) => *b,
            Some(_) => return Err(ApiError::BadRequest("invalid_input")),
        };
        flags.insert(f.into(), json!(on));
    }
    let m = obj.get("maintenance").cloned().unwrap_or(Value::Null);
    let on = match m.get("on") {
        None | Some(Value::Null) => false,
        Some(Value::Bool(b)) => *b,
        Some(_) => return Err(ApiError::BadRequest("invalid_input")),
    };
    let message = match m.get("message") {
        None | Some(Value::Null) => String::new(),
        Some(Value::String(s)) => {
            let t = s.trim();
            if t.chars().count() > MAX_MESSAGE_CHARS {
                return Err(ApiError::BadRequest("field_too_long"));
            }
            t.to_string()
        }
        Some(_) => return Err(ApiError::BadRequest("invalid_input")),
    };
    Ok(json!({ "flags": flags, "maintenance": { "on": on, "message": message } }))
}

/// What apps receive: flags with defaults applied, maintenance, and the store version floors from the
/// business profile (`app_versions`), so one call replaces `/brand` for version gating.
pub fn public_document(config: &Value, business: &Value) -> Value {
    let mut flags = Map::new();
    for f in FLAGS {
        flags.insert(f.into(), json!(config["flags"][f].as_bool().unwrap_or(true)));
    }
    json!({
        "flags": flags,
        "maintenance": {
            "on": config["maintenance"]["on"].as_bool().unwrap_or(false),
            "message": config["maintenance"]["message"].as_str().unwrap_or(""),
        },
        "app_versions": business.get("app_versions").cloned().unwrap_or_else(|| json!({})),
    })
}

/// Called after any write that changes what [`public_document`] returns.
pub fn invalidate() {
    if let Ok(mut c) = CACHE.lock() {
        *c = None;
    }
}

fn cached() -> Option<Value> {
    let c = CACHE.lock().ok()?;
    c.as_ref().filter(|(t, _)| t.elapsed() < CACHE_TTL).map(|(_, v)| v.clone())
}

fn remember(v: &Value) {
    if let Ok(mut c) = CACHE.lock() {
        *c = Some((Instant::now(), v.clone()));
    }
}

async fn load(db: &PgPool, key: &str) -> Result<Value, sqlx::Error> {
    let v: Option<Value> = sqlx::query_scalar("SELECT value FROM settings WHERE key = $1")
        .bind(key)
        .fetch_optional(db)
        .await?;
    Ok(v.unwrap_or_else(|| json!({})))
}

/// The public document, from the 30 s cache when fresh.
async fn current_document(db: &PgPool) -> Result<Value, sqlx::Error> {
    if let Some(d) = cached() {
        return Ok(d);
    }
    let d = public_document(&load(db, CONFIG_KEY).await?, &load(db, BUSINESS_KEY).await?);
    remember(&d);
    Ok(d)
}

async fn public_config(State(s): State<AppState>) -> ApiResult<Response> {
    let doc = current_document(&s.db).await?;
    Ok(([(header::CACHE_CONTROL, CACHE_CONTROL)], Json(doc)).into_response())
}

/// Whether a feature is on right now (for handlers that cannot be told apart by path, such as AI replies).
pub async fn feature_enabled(db: &PgPool, feature: &str) -> Result<bool, sqlx::Error> {
    Ok(flag_value(&current_document(db).await?, feature))
}

fn flag_value(doc: &Value, feature: &str) -> bool {
    doc["flags"][feature].as_bool().unwrap_or(true)
}

/// Paths open even in maintenance: the config itself, the admin console, webhooks, the setup wizard, brand.
const OPEN_PREFIXES: [&str; 5] = ["/v1/config", "/v1/admin", "/v1/webhooks", "/v1/setup", "/v1/brand"];

/// Which feature a request belongs to. Order matters: payment paths under booking are checked first.
pub fn feature_for(path: &str) -> Option<&'static str> {
    if path.starts_with("/v1/ai/") || (path.starts_with("/v1/chat/threads/") && path.ends_with("/ai")) {
        Some("ai")
    } else if path.ends_with("/deposit") || path.ends_with("/balance") || path.starts_with("/v1/checkouts") || path.starts_with("/v1/payments") {
        Some("payments")
    } else if path.starts_with("/v1/chat") || path.starts_with("/v1/partner/threads") {
        Some("chat")
    } else if path.starts_with("/v1/bookings") || path.starts_with("/v1/quote") {
        Some("booking")
    } else {
        None
    }
}

/// Stable error code for a refused request, or None when it may proceed. Maintenance blocks every
/// `/v1` path except the open ones; a disabled feature blocks its own paths (reads and writes alike).
pub fn block_code(doc: &Value, path: &str) -> Option<&'static str> {
    if !path.starts_with("/v1/") || OPEN_PREFIXES.iter().any(|p| path.starts_with(p)) {
        return None;
    }
    if doc["maintenance"]["on"].as_bool() == Some(true) {
        return Some("maintenance");
    }
    match feature_for(path)? {
        f if flag_value(doc, f) => None,
        "ai" => Some("ai_disabled"),
        "payments" => Some("payments_disabled"),
        "chat" => Some("chat_disabled"),
        _ => Some("booking_disabled"),
    }
}

/// Route layer: refuses requests to switched-off features with 503 and a stable code. Reads the
/// same cache as `GET /v1/config`. A database error lets the request through (logged): flags are not a
/// security boundary, and a broken database fails the request anyway.
pub async fn enforce(State(s): State<AppState>, req: Request, next: Next) -> Response {
    match current_document(&s.db).await {
        Ok(doc) => match block_code(&doc, req.uri().path()) {
            Some(code) => ApiError::Unavailable(code).into_response(),
            None => next.run(req).await,
        },
        Err(e) => {
            tracing::warn!(error = %e, "feature flags unreadable; serving request");
            next.run(req).await
        }
    }
}

async fn admin_config(State(s): State<AppState>, Admin(_): Admin) -> ApiResult<Json<Value>> {
    Ok(Json(public_document(&load(&s.db, CONFIG_KEY).await?, &load(&s.db, BUSINESS_KEY).await?)))
}

async fn put_config(State(s): State<AppState>, Admin(a): Admin, Json(input): Json<Value>) -> ApiResult<Json<Value>> {
    let value = clean_config(&input)?;
    sqlx::query("INSERT INTO settings (key, value) VALUES ($1, $2) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()")
        .bind(CONFIG_KEY)
        .bind(&value)
        .execute(&s.db)
        .await?;
    invalidate();
    audit(&s.db, a.role.as_str(), Some(a.id), "config.update", CONFIG_KEY, json!({})).await?;
    Ok(Json(public_document(&value, &load(&s.db, BUSINESS_KEY).await?)))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn unknown_flags_are_rejected() {
        let err = clean_config(&json!({ "flags": { "teleport": false } })).unwrap_err();
        assert!(matches!(err, ApiError::BadRequest("unknown_flag")));
    }

    #[test]
    fn flags_must_be_booleans() {
        assert!(clean_config(&json!({ "flags": { "chat": "no" } })).is_err());
        assert!(clean_config(&json!({ "maintenance": { "on": 1 } })).is_err());
    }

    #[test]
    fn missing_flags_default_on_and_maintenance_defaults_off() {
        let v = clean_config(&json!({})).unwrap();
        for f in FLAGS {
            assert_eq!(v["flags"][f], json!(true));
        }
        assert_eq!(v["maintenance"]["on"], json!(false));
    }

    #[test]
    fn maintenance_message_is_trimmed_and_capped() {
        let v = clean_config(&json!({ "maintenance": { "on": true, "message": "  점검 중  " } })).unwrap();
        assert_eq!(v["maintenance"]["message"], json!("점검 중"));
        let long = "가".repeat(MAX_MESSAGE_CHARS + 1);
        let err = clean_config(&json!({ "maintenance": { "message": long } })).unwrap_err();
        assert!(matches!(err, ApiError::BadRequest("field_too_long")));
    }

    #[test]
    fn public_document_merges_version_floors_and_fills_defaults() {
        let config = json!({ "flags": { "ai": false }, "maintenance": { "on": true, "message": "곧 돌아와요" } });
        let business = json!({ "app_versions": { "customer": { "min_app_version": "1.0.0" } }, "name": "x" });
        let doc = public_document(&config, &business);
        assert_eq!(doc["flags"]["ai"], json!(false));
        assert_eq!(doc["flags"]["booking"], json!(true));
        assert_eq!(doc["maintenance"]["on"], json!(true));
        assert_eq!(doc["app_versions"]["customer"]["min_app_version"], json!("1.0.0"));
        assert!(doc.get("name").is_none(), "business profile fields stay private");
    }

    fn doc(flags: Value, maintenance: bool) -> Value {
        public_document(&json!({ "flags": flags, "maintenance": { "on": maintenance } }), &json!({}))
    }

    #[test]
    fn disabled_feature_blocks_its_paths_with_its_code() {
        let d = doc(json!({ "booking": false }), false);
        assert_eq!(block_code(&d, "/v1/bookings"), Some("booking_disabled"));
        assert_eq!(block_code(&d, "/v1/quote/estimate"), Some("booking_disabled"));
        assert_eq!(block_code(&d, "/v1/chat/threads"), None);
    }

    #[test]
    fn payment_paths_are_payments_even_under_bookings() {
        let d = doc(json!({ "payments": false }), false);
        assert_eq!(block_code(&d, "/v1/bookings/abc/deposit"), Some("payments_disabled"));
        assert_eq!(block_code(&d, "/v1/checkouts"), Some("payments_disabled"));
        assert_eq!(block_code(&d, "/v1/bookings"), None);
    }

    #[test]
    fn ai_and_chat_have_their_own_codes() {
        let d = doc(json!({ "ai": false, "chat": false }), false);
        assert_eq!(block_code(&d, "/v1/chat/threads/9/ai"), Some("ai_disabled"));
        assert_eq!(block_code(&d, "/v1/ai/usage"), Some("ai_disabled"));
        assert_eq!(block_code(&d, "/v1/chat/threads"), Some("chat_disabled"));
        assert_eq!(block_code(&d, "/v1/partner/threads"), Some("chat_disabled"));
    }

    #[test]
    fn maintenance_blocks_public_api_but_not_admin_config_or_webhooks() {
        let d = doc(json!({}), true);
        assert_eq!(block_code(&d, "/v1/bookings"), Some("maintenance"));
        assert_eq!(block_code(&d, "/v1/auth/otp"), Some("maintenance"));
        assert_eq!(block_code(&d, "/v1/config"), None);
        assert_eq!(block_code(&d, "/v1/admin/config"), None);
        assert_eq!(block_code(&d, "/v1/webhooks/toss"), None);
        assert_eq!(block_code(&d, "/v1/setup"), None);
        assert_eq!(block_code(&d, "/health"), None);
    }

    #[test]
    fn enabled_features_pass() {
        assert_eq!(block_code(&doc(json!({}), false), "/v1/bookings"), None);
    }

    #[test]
    fn empty_stored_config_is_all_on() {
        let doc = public_document(&json!({}), &json!({}));
        assert_eq!(doc["maintenance"]["on"], json!(false));
        assert_eq!(doc["app_versions"], json!({}));
    }
}
