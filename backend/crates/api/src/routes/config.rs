//! Remote config: feature flags, maintenance mode and store version floors in one public document.
//! Apps read `GET /v1/config` (cached 30 s, here and at the edge); the console writes it.
//! Maintenance lives in the settings registry (`ops` group), so the owner sets it in the same place as the limits.
use super::audit;
use crate::{
    auth::Admin,
    config::Config,
    error::{ApiError, ApiResult},
    settings_registry,
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Request, State},
    http::{Method, header},
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
const MAINTENANCE_ON: &str = "maintenance_on";
const MAINTENANCE_MESSAGE: &str = "maintenance_message";
/// Features the apps can hide. Missing flags default to on.
pub const FLAGS: [&str; 4] = ["booking", "chat", "ai", "payments"];
const MAX_MESSAGE_CHARS: usize = 200;
const CACHE_TTL: Duration = Duration::from_secs(30);
const CACHE_CONTROL: &str = "public, max-age=30";

/// One entry, tagged with the database it was read from (one per process in production; tests share a process).
static CACHE: Mutex<Option<(String, Instant, Value)>> = Mutex::new(None);

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
pub fn public_document(config: &Value, business: &Value, maintenance: &Value) -> Value {
    let mut flags = Map::new();
    for f in FLAGS {
        flags.insert(f.into(), json!(config["flags"][f].as_bool().unwrap_or(true)));
    }
    json!({
        "flags": flags,
        "maintenance": {
            "on": maintenance["on"].as_bool().unwrap_or(false),
            "message": maintenance["message"].as_str().unwrap_or(""),
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

fn cache_key(db: &PgPool) -> String {
    db.connect_options().get_database().unwrap_or_default().to_string()
}

fn cached(key: &str) -> Option<Value> {
    let c = CACHE.lock().ok()?;
    c.as_ref().filter(|(k, t, _)| k == key && t.elapsed() < CACHE_TTL).map(|(_, _, v)| v.clone())
}

fn remember(key: String, v: &Value) {
    if let Ok(mut c) = CACHE.lock() {
        *c = Some((key, Instant::now(), v.clone()));
    }
}

async fn load(db: &PgPool, key: &str) -> Result<Value, sqlx::Error> {
    let v: Option<Value> = sqlx::query_scalar("SELECT value FROM settings WHERE key = $1")
        .bind(key)
        .fetch_optional(db)
        .await?;
    Ok(v.unwrap_or_else(|| json!({})))
}

/// The owner's maintenance switch and message, read from the settings registry (env seeds apply).
async fn maintenance_state(db: &PgPool, cfg: &Config) -> ApiResult<Value> {
    Ok(json!({
        "on": settings_registry::get_flag(db, cfg, MAINTENANCE_ON).await?,
        "message": settings_registry::get_text(db, cfg, MAINTENANCE_MESSAGE).await?,
    }))
}

/// The public document, from the 30 s cache when fresh.
async fn current_document(db: &PgPool, cfg: &Config) -> ApiResult<Value> {
    let key = cache_key(db);
    if let Some(d) = cached(&key) {
        return Ok(d);
    }
    let d = public_document(&load(db, CONFIG_KEY).await?, &load(db, BUSINESS_KEY).await?, &maintenance_state(db, cfg).await?);
    remember(key, &d);
    Ok(d)
}

async fn public_config(State(s): State<AppState>) -> ApiResult<Response> {
    let doc = current_document(&s.db, &s.config).await?;
    Ok(([(header::CACHE_CONTROL, CACHE_CONTROL)], Json(doc)).into_response())
}

/// Whether a feature is on right now (for handlers that cannot be told apart by path, such as AI replies).
pub async fn feature_enabled(db: &PgPool, cfg: &Config, feature: &str) -> ApiResult<bool> {
    Ok(flag_value(&current_document(db, cfg).await?, feature))
}

fn flag_value(doc: &Value, feature: &str) -> bool {
    doc["flags"][feature].as_bool().unwrap_or(true)
}

/// Paths open even in maintenance: the config itself, the admin console (staff login, token refresh and
/// logout included, so the owner can sign in and switch maintenance off), webhooks, setup, brand.
const OPEN_PREFIXES: [&str; 8] = [
    "/v1/config",
    "/v1/admin",
    "/v1/webhooks",
    "/v1/setup",
    "/v1/brand",
    "/v1/auth/staff/",
    "/v1/auth/refresh",
    "/v1/auth/logout",
];

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

/// Creating a booking by path: a direct booking, accepting a waitlist offer, or a recurring subscription.
/// Checkouts that create a booking are refused in their handlers (`maintenance_on`), not here.
fn is_new_booking(path: &str) -> bool {
    path == "/v1/bookings" || path == "/v1/subscriptions" || (path.starts_with("/v1/waitlist/") && path.ends_with("/accept"))
}

/// Whether maintenance is on right now, for handlers that refuse by what they create.
pub async fn maintenance_on(db: &PgPool, cfg: &Config) -> ApiResult<bool> {
    let doc = current_document(db, cfg).await?;
    Ok(doc["maintenance"]["on"].as_bool() == Some(true))
}

/// Stable error code for a refused request, or None when it may proceed. Maintenance refuses new bookings
/// only; reads, cancellations and payments on existing bookings stay open. A disabled feature blocks its
/// own paths (reads and writes alike).
pub fn block_code(doc: &Value, method: &Method, path: &str) -> Option<&'static str> {
    if !path.starts_with("/v1/") || OPEN_PREFIXES.iter().any(|p| path.starts_with(p)) {
        return None;
    }
    if doc["maintenance"]["on"].as_bool() == Some(true) && *method == Method::POST && is_new_booking(path) {
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
    match current_document(&s.db, &s.config).await {
        Ok(doc) => match block_code(&doc, req.method(), req.uri().path()) {
            Some(code) => ApiError::Unavailable(code).into_response(),
            None => next.run(req).await,
        },
        Err(e) => {
            tracing::warn!(error = ?e, "feature flags unreadable; serving request");
            next.run(req).await
        }
    }
}

async fn admin_config(State(s): State<AppState>, Admin(_): Admin) -> ApiResult<Json<Value>> {
    let maintenance = maintenance_state(&s.db, &s.config).await?;
    Ok(Json(public_document(
        &load(&s.db, CONFIG_KEY).await?,
        &load(&s.db, BUSINESS_KEY).await?,
        &maintenance,
    )))
}

async fn put_config(State(s): State<AppState>, Admin(a): Admin, Json(input): Json<Value>) -> ApiResult<Json<Value>> {
    let value = clean_config(&input)?;
    settings_registry::ensure_can_write(&s.db, a.id).await?;
    let m = &value["maintenance"];
    let values = Map::from_iter([
        (MAINTENANCE_ON.to_string(), m["on"].clone()),
        (MAINTENANCE_MESSAGE.to_string(), m["message"].clone()),
    ]);
    settings_registry::save_group(&s.db, &s.config, "ops", a.id, &values).await?;
    let stored = json!({ "flags": value["flags"] });
    sqlx::query("INSERT INTO settings (key, value) VALUES ($1, $2) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()")
        .bind(CONFIG_KEY)
        .bind(&stored)
        .execute(&s.db)
        .await?;
    invalidate();
    audit(&s.db, a.role.as_str(), Some(a.id), "config.update", CONFIG_KEY, json!({})).await?;
    Ok(Json(public_document(&stored, &load(&s.db, BUSINESS_KEY).await?, m)))
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
        let maintenance = json!({ "on": true, "message": "곧 돌아와요" });
        let doc = public_document(&config, &business, &maintenance);
        assert_eq!(doc["flags"]["ai"], json!(false));
        assert_eq!(doc["flags"]["booking"], json!(true));
        assert_eq!(doc["maintenance"], json!({ "on": true, "message": "곧 돌아와요" }));
        assert_eq!(doc["app_versions"]["customer"]["min_app_version"], json!("1.0.0"));
        assert!(doc.get("name").is_none(), "business profile fields stay private");
    }

    fn doc(flags: Value, maintenance: bool) -> Value {
        public_document(&json!({ "flags": flags }), &json!({}), &json!({ "on": maintenance }))
    }

    #[test]
    fn disabled_feature_blocks_its_paths_with_its_code() {
        let d = doc(json!({ "booking": false }), false);
        assert_eq!(block_code(&d, &Method::GET, "/v1/bookings"), Some("booking_disabled"));
        assert_eq!(block_code(&d, &Method::GET, "/v1/quote/estimate"), Some("booking_disabled"));
        assert_eq!(block_code(&d, &Method::GET, "/v1/chat/threads"), None);
    }

    #[test]
    fn payment_paths_are_payments_even_under_bookings() {
        let d = doc(json!({ "payments": false }), false);
        assert_eq!(block_code(&d, &Method::GET, "/v1/bookings/abc/deposit"), Some("payments_disabled"));
        assert_eq!(block_code(&d, &Method::GET, "/v1/checkouts"), Some("payments_disabled"));
        assert_eq!(block_code(&d, &Method::GET, "/v1/bookings"), None);
    }

    #[test]
    fn ai_and_chat_have_their_own_codes() {
        let d = doc(json!({ "ai": false, "chat": false }), false);
        assert_eq!(block_code(&d, &Method::GET, "/v1/chat/threads/9/ai"), Some("ai_disabled"));
        assert_eq!(block_code(&d, &Method::GET, "/v1/ai/usage"), Some("ai_disabled"));
        assert_eq!(block_code(&d, &Method::GET, "/v1/chat/threads"), Some("chat_disabled"));
        assert_eq!(block_code(&d, &Method::GET, "/v1/partner/threads"), Some("chat_disabled"));
    }

    #[test]
    fn maintenance_refuses_new_bookings_only() {
        let d = doc(json!({}), true);
        assert_eq!(block_code(&d, &Method::POST, "/v1/bookings"), Some("maintenance"));
        assert_eq!(block_code(&d, &Method::POST, "/v1/waitlist/9/accept"), Some("maintenance"));
        assert_eq!(block_code(&d, &Method::POST, "/v1/subscriptions"), Some("maintenance"));
        assert_eq!(block_code(&d, &Method::GET, "/v1/subscriptions"), None, "reads stay open");
        assert_eq!(block_code(&d, &Method::POST, "/v1/subscriptions/abc/pause"), None, "pausing stays open");
        assert_eq!(block_code(&d, &Method::GET, "/v1/bookings"), None, "reads stay open");
        assert_eq!(block_code(&d, &Method::POST, "/v1/bookings/abc/cancel"), None, "cancelling stays open");
        assert_eq!(block_code(&d, &Method::POST, "/v1/bookings/abc/deposit"), None);
        assert_eq!(block_code(&d, &Method::POST, "/v1/auth/otp"), None);
        assert_eq!(block_code(&d, &Method::GET, "/v1/config"), None);
        assert_eq!(block_code(&d, &Method::POST, "/v1/admin/config"), None);
        assert_eq!(block_code(&d, &Method::POST, "/v1/webhooks/toss"), None);
        assert_eq!(block_code(&d, &Method::GET, "/health"), None);
    }

    #[test]
    fn enabled_features_pass() {
        assert_eq!(block_code(&doc(json!({}), false), &Method::POST, "/v1/bookings"), None);
    }

    #[test]
    fn empty_stored_config_is_all_on() {
        let doc = public_document(&json!({}), &json!({}), &json!({}));
        assert_eq!(doc["maintenance"]["on"], json!(false));
        assert_eq!(doc["app_versions"], json!({}));
    }
}
