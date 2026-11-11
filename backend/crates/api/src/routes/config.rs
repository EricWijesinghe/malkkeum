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
    extract::State,
    http::header,
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
    let v: Option<Value> = sqlx::query_scalar("SELECT value FROM settings WHERE key = $1").bind(key).fetch_optional(db).await?;
    Ok(v.unwrap_or_else(|| json!({})))
}

async fn public_config(State(s): State<AppState>) -> ApiResult<Response> {
    let doc = match cached() {
        Some(d) => d,
        None => {
            let d = public_document(&load(&s.db, CONFIG_KEY).await?, &load(&s.db, BUSINESS_KEY).await?);
            remember(&d);
            d
        }
    };
    Ok(([(header::CACHE_CONTROL, CACHE_CONTROL)], Json(doc)).into_response())
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

    #[test]
    fn empty_stored_config_is_all_on() {
        let doc = public_document(&json!({}), &json!({}));
        assert_eq!(doc["maintenance"]["on"], json!(false));
        assert_eq!(doc["app_versions"], json!({}));
    }
}
