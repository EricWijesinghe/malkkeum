//! Setup wizard API: first admin in the browser (one-time setup code), business profile, and the
//! integration cards (save, clear, test connection). The console's wizard is the only client.

use super::audit;
use crate::{
    auth::{Admin, hash_password},
    error::{ApiError, ApiResult},
    integrations::{self, Invalid, Kind, Section},
    providers::{fcm, portone, sms},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Path, State},
    routing::{get, post, put},
};
use chrono::Utc;
use rand::{Rng, rngs::OsRng};
use reqwest::StatusCode;
use serde::Deserialize;
use serde_json::{Map, Value, json};
use sqlx::PgPool;
use subtle::ConstantTimeEq;

const MIN_ADMIN_PASSWORD: usize = 12;
const MAX_FIELD_CHARS: usize = 200;
const SETUP_CODE_LEN: usize = 12;
/// No 0/O/1/I/L: the code is read off a screen and typed by hand.
const SETUP_ALPHABET: &[u8] = b"23456789ABCDEFGHJKMNPQRSTUVWXYZ";
const SETUP_CODE_KEY: &str = "setup_code";
const BUSINESS_KEY: &str = "business";

pub fn public_routes() -> Router<AppState> {
    Router::new()
        .route("/setup", get(state))
        .route("/setup/admin", post(create_admin))
        .route("/brand", get(brand))
}

pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/setup", get(overview))
        .route("/setup/business", put(put_business))
        .route("/setup/{section}", put(put_section).delete(clear_section))
        .route("/setup/{section}/test", post(test_section))
}

async fn has_staff(db: &PgPool) -> Result<bool, sqlx::Error> {
    sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM staff)").fetch_one(db).await
}

fn random_code() -> String {
    let mut rng = OsRng;
    (0..SETUP_CODE_LEN)
        .map(|_| SETUP_ALPHABET[rng.gen_range(0..SETUP_ALPHABET.len())] as char)
        .collect()
}

/// On a fresh install (no staff yet) makes sure a setup code exists and prints it, so the person
/// installing can open the console and create the owner's account. `SETUP_CODE` (set by the
/// installer) wins; otherwise a random code is kept in the database across restarts.
pub async fn ensure_setup_code(db: &PgPool, from_env: Option<&str>) -> Result<(), sqlx::Error> {
    if has_staff(db).await? {
        return Ok(());
    }
    let code = match from_env {
        Some(c) => c.to_string(),
        None => {
            let saved: Option<Value> = sqlx::query_scalar("SELECT value FROM settings WHERE key = $1")
                .bind(SETUP_CODE_KEY)
                .fetch_optional(db)
                .await?;
            match saved.and_then(|v| v["code"].as_str().map(String::from)) {
                Some(c) => c,
                None => random_code(),
            }
        }
    };
    sqlx::query("INSERT INTO settings (key, value) VALUES ($1, $2) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()")
        .bind(SETUP_CODE_KEY)
        .bind(json!({ "code": code }))
        .execute(db)
        .await?;
    tracing::warn!("first-run setup: open the console and enter setup code {code}");
    Ok(())
}

/// Public: whether the console should show "create the owner account" instead of login.
async fn state(State(s): State<AppState>) -> ApiResult<Json<Value>> {
    Ok(Json(json!({ "needs_admin": !has_staff(&s.db).await?, "dev_mode": s.config.dev_mode })))
}

#[derive(Deserialize)]
struct NewAdmin {
    code: String,
    email: String,
    name: String,
    password: String,
}

async fn create_admin(State(s): State<AppState>, Json(req): Json<NewAdmin>) -> ApiResult<Json<Value>> {
    let email = req.email.trim().to_lowercase();
    let name = req.name.trim();
    if !email.contains('@') || email.len() > MAX_FIELD_CHARS || name.is_empty() || name.chars().count() > MAX_FIELD_CHARS {
        return Err(ApiError::BadRequest("invalid_input"));
    }
    if req.password.chars().count() < MIN_ADMIN_PASSWORD || req.password.len() > 256 {
        return Err(ApiError::BadRequest("weak_password"));
    }
    let hash = hash_password(&req.password)?;
    let mut tx = s.db.begin().await?;
    // Serialises concurrent attempts: only the first one can create the owner.
    sqlx::query("LOCK TABLE staff IN EXCLUSIVE MODE").execute(&mut *tx).await?;
    let exists: bool = sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM staff)").fetch_one(&mut *tx).await?;
    if exists {
        return Err(ApiError::Conflict("already_set_up"));
    }
    let saved: Option<Value> = sqlx::query_scalar("SELECT value FROM settings WHERE key = $1")
        .bind(SETUP_CODE_KEY)
        .fetch_optional(&mut *tx)
        .await?;
    let expected = saved.and_then(|v| v["code"].as_str().map(String::from)).unwrap_or_default();
    let given = req.code.trim().to_uppercase().replace(['-', ' '], "");
    if expected.is_empty() || !bool::from(given.as_bytes().ct_eq(expected.as_bytes())) {
        return Err(ApiError::Forbidden);
    }
    let id: uuid::Uuid = sqlx::query_scalar("INSERT INTO staff (email, name, password_hash, role) VALUES ($1, $2, $3, 'admin') RETURNING id")
        .bind(&email)
        .bind(name)
        .bind(hash)
        .fetch_one(&mut *tx)
        .await?;
    sqlx::query("DELETE FROM settings WHERE key = $1")
        .bind(SETUP_CODE_KEY)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    audit(&s.db, "staff_admin", Some(id), "setup.create_admin", &email, json!({})).await?;
    Ok(Json(json!({ "ok": true })))
}

async fn business(db: &PgPool) -> Result<Value, sqlx::Error> {
    let v: Option<Value> = sqlx::query_scalar("SELECT value FROM settings WHERE key = $1")
        .bind(BUSINESS_KEY)
        .fetch_optional(db)
        .await?;
    Ok(v.unwrap_or_else(|| json!({})))
}

/// Public business profile: app header, website footer (사업자 정보), support contact.
async fn brand(State(s): State<AppState>) -> ApiResult<Json<Value>> {
    Ok(Json(business(&s.db).await?))
}

const BUSINESS_TEXT: [&str; 4] = ["name", "support_phone", "support_email", "support_hours"];
/// Store pages the website's download buttons point to.
const STORE_LINKS: [&str; 4] = ["app_store_url", "play_store_url", "partner_app_store_url", "partner_play_store_url"];
const COMPANY_TEXT: [&str; 7] = [
    "legal_name",
    "ceo",
    "registration_no",
    "mail_order_no",
    "address",
    "privacy_officer",
    "privacy_email",
];

fn clean_text(v: &Value, key: &str) -> Result<Option<String>, ApiError> {
    match v.get(key) {
        None | Some(Value::Null) => Ok(None),
        Some(Value::String(s)) => {
            let t = s.trim();
            if t.chars().count() > MAX_FIELD_CHARS {
                return Err(ApiError::BadRequest("field_too_long"));
            }
            Ok((!t.is_empty()).then(|| t.to_string()))
        }
        _ => Err(ApiError::BadRequest("invalid_input")),
    }
}

pub fn is_hex_color(s: &str) -> bool {
    s.len() == 7 && s.starts_with('#') && s[1..].bytes().all(|b| b.is_ascii_hexdigit())
}

/// Only our own uploads or https images: the logo is shown in every app and on the website.
pub fn is_logo_url(base: &str, s: &str) -> bool {
    crate::util::is_own_upload(base, s) || (s.starts_with("/files/") && !s.contains("..")) || (s.starts_with("https://") && !s.contains(char::is_whitespace))
}

/// Validated business profile; unknown keys are dropped.
pub fn clean_business(base: &str, input: &Value) -> Result<Value, ApiError> {
    let mut out = Map::new();
    for k in BUSINESS_TEXT {
        if let Some(t) = clean_text(input, k)? {
            out.insert(k.into(), json!(t));
        }
    }
    if let Some(c) = clean_text(input, "primary_color")? {
        if !is_hex_color(&c) {
            return Err(ApiError::BadRequest("invalid_color"));
        }
        out.insert("primary_color".into(), json!(c.to_uppercase()));
    }
    if let Some(u) = clean_text(input, "logo_url")? {
        if !is_logo_url(base, &u) {
            return Err(ApiError::BadRequest("invalid_logo"));
        }
        out.insert("logo_url".into(), json!(u));
    }
    for k in STORE_LINKS {
        if let Some(u) = clean_text(input, k)? {
            if !u.starts_with("https://") || u.contains(char::is_whitespace) {
                return Err(ApiError::BadRequest("invalid_link"));
            }
            out.insert(k.into(), json!(u));
        }
    }
    let empty = json!({});
    let company_in = input.get("company").unwrap_or(&empty);
    let mut company = Map::new();
    for k in COMPANY_TEXT {
        if let Some(t) = clean_text(company_in, k)? {
            company.insert(k.into(), json!(t));
        }
    }
    out.insert("company".into(), Value::Object(company));
    if !out.contains_key("name") {
        return Err(ApiError::BadRequest("missing_field"));
    }
    Ok(Value::Object(out))
}

async fn put_business(State(s): State<AppState>, Admin(a): Admin, Json(input): Json<Value>) -> ApiResult<Json<Value>> {
    let value = clean_business(&s.config.public_base_url, &input)?;
    sqlx::query("INSERT INTO settings (key, value) VALUES ($1, $2) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()")
        .bind(BUSINESS_KEY)
        .bind(&value)
        .execute(&s.db)
        .await?;
    audit(&s.db, a.role.as_str(), Some(a.id), "setup.business", BUSINESS_KEY, json!({})).await?;
    Ok(Json(value))
}

fn section(code: &str) -> ApiResult<Section> {
    Section::parse(code).ok_or(ApiError::NotFound)
}

fn kind_name(k: Kind) -> &'static str {
    match k {
        Kind::Text => "text",
        Kind::Secret => "secret",
        Kind::List => "list",
        Kind::Map => "map",
        Kind::File => "file",
    }
}

async fn card(s: &AppState, sec: Section, last_test: Option<Value>) -> ApiResult<Value> {
    let saved = integrations::load_section(&s.db, &s.config.data_key, sec).await?;
    let fields: Vec<Value> = sec
        .fields()
        .iter()
        .map(|f| {
            let v = saved.get(f.name);
            json!({
                "name": f.name,
                "kind": kind_name(f.kind),
                "required": f.required,
                "set": v.is_some(),
                "preview": v.map(|v| integrations::preview(f.kind, v)),
            })
        })
        .collect();
    let env = integrations::Integrations::from_config(&s.config).has(sec);
    let source = if !saved.is_empty() {
        "console"
    } else if env {
        "env"
    } else {
        "none"
    };
    Ok(json!({ "code": sec.code(), "source": source, "configured": source != "none", "fields": fields, "last_test": last_test }))
}

/// Everything the wizard and the status page need in one call.
async fn overview(State(s): State<AppState>, Admin(_): Admin) -> ApiResult<Json<Value>> {
    let tests: Vec<(String, Option<Value>)> = sqlx::query_as("SELECT section, last_test FROM integration_settings").fetch_all(&s.db).await?;
    let mut cards = Vec::new();
    for sec in Section::ALL {
        let last = tests.iter().find(|(c, _)| c == sec.code()).and_then(|(_, t)| t.clone());
        cards.push(card(&s, sec, last).await?);
    }
    let counts: (i64, i64, i64, i64) = sqlx::query_as(
        "SELECT (SELECT count(*) FROM staff WHERE active),
                (SELECT count(*) FROM pros WHERE status = 'verified'),
                (SELECT count(*) FROM services WHERE active),
                (SELECT count(*) FROM bookings)",
    )
    .fetch_one(&s.db)
    .await?;
    Ok(Json(json!({
        "business": business(&s.db).await?,
        "integrations": cards,
        "counts": { "staff": counts.0, "verified_pros": counts.1, "active_services": counts.2, "bookings": counts.3 },
        "dev_mode": s.config.dev_mode,
        "public_base_url": s.config.public_base_url,
        "webhook_url": format!("{}/v1/webhooks/portone", s.config.public_base_url.trim_end_matches('/')),
    })))
}

/// Recomputes the live keys from env + every saved section and hands them to the providers.
pub async fn reload(s: &AppState) -> Result<(), sqlx::Error> {
    let integ = integrations::load(&s.db, &s.config).await?;
    s.providers.set_integrations(integ);
    Ok(())
}

async fn put_section(State(s): State<AppState>, Admin(a): Admin, Path(code): Path<String>, Json(input): Json<Value>) -> ApiResult<Json<Value>> {
    let sec = section(&code)?;
    let incoming = input.as_object().ok_or(ApiError::BadRequest("invalid_input"))?;
    let current = integrations::load_section(&s.db, &s.config.data_key, sec).await?;
    let merged = integrations::merge(sec, &current, incoming);
    // Validate against env-only keys so this section stands on its own.
    integrations::apply(&integrations::Integrations::from_config(&s.config), sec, &merged).map_err(|Invalid(code)| ApiError::BadRequest(code))?;
    integrations::save_section(&s.db, &s.config.data_key, sec, &merged, a.id).await?;
    reload(&s).await?;
    audit(
        &s.db,
        a.role.as_str(),
        Some(a.id),
        "setup.integration",
        sec.code(),
        json!({ "fields": merged.keys().collect::<Vec<_>>() }),
    )
    .await?;
    Ok(Json(card(&s, sec, None).await?))
}

async fn clear_section(State(s): State<AppState>, Admin(a): Admin, Path(code): Path<String>) -> ApiResult<Json<Value>> {
    let sec = section(&code)?;
    integrations::delete_section(&s.db, sec).await?;
    reload(&s).await?;
    audit(&s.db, a.role.as_str(), Some(a.id), "setup.integration_cleared", sec.code(), json!({})).await?;
    Ok(Json(card(&s, sec, None).await?))
}

/// Maps an HTTP status from a provider's check call to the wizard's result code.
pub fn check_result(status: StatusCode, ok_statuses: &[StatusCode]) -> (bool, &'static str) {
    if ok_statuses.contains(&status) {
        (true, "connected")
    } else if status == StatusCode::UNAUTHORIZED || status == StatusCode::FORBIDDEN {
        (false, "invalid_key")
    } else {
        (false, "provider_error")
    }
}

async fn probe(s: &AppState, sec: Section) -> (bool, &'static str) {
    let integ = s.providers.integ();
    let http = s.providers.http();
    match sec {
        Section::Portone => match integ.portone.api_secret.as_deref() {
            None => (false, "not_configured"),
            Some(secret) => match portone::check(http, secret).await {
                Ok(st) => check_result(st, &[StatusCode::NOT_FOUND, StatusCode::OK]),
                Err(_) => (false, "unreachable"),
            },
        },
        Section::Solapi => match integ.solapi.as_ref() {
            None => (false, "not_configured"),
            Some(cfg) => match sms::check(http, cfg).await {
                Ok(st) => check_result(st, &[StatusCode::OK]),
                Err(_) => (false, "unreachable"),
            },
        },
        Section::Push => match integ.fcm.as_ref() {
            None => (false, "not_configured"),
            Some(acc) => match fcm::exchange(http, acc, Utc::now().timestamp()).await {
                Ok(_) => (true, "connected"),
                Err(_) => (false, "invalid_key"),
            },
        },
        // Login keys can only be proven by a real sign-in from the app.
        _ if integ.has(sec) => (true, "saved_check_in_app"),
        _ => (false, "not_configured"),
    }
}

async fn test_section(State(s): State<AppState>, Admin(a): Admin, Path(code): Path<String>) -> ApiResult<Json<Value>> {
    let sec = section(&code)?;
    let (ok, result) = probe(&s, sec).await;
    let record = json!({ "ok": ok, "code": result, "at": Utc::now() });
    sqlx::query("UPDATE integration_settings SET last_test = $2 WHERE section = $1")
        .bind(sec.code())
        .bind(&record)
        .execute(&s.db)
        .await?;
    audit(&s.db, a.role.as_str(), Some(a.id), "setup.test", sec.code(), record.clone()).await?;
    Ok(Json(record))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn setup_code_uses_unambiguous_characters() {
        let c = random_code();
        assert_eq!(c.len(), SETUP_CODE_LEN);
        assert!(c.bytes().all(|b| SETUP_ALPHABET.contains(&b)));
        assert!(!c.contains(['0', 'O', '1', 'I', 'L']));
    }

    #[test]
    fn business_profile_is_validated_and_trimmed() {
        let v = clean_business(
            "http://127.0.0.1:8080",
            &json!({
                "name": "  말끔 ", "primary_color": "#3b5bfd", "logo_url": "/files/logo.png",
                "company": { "ceo": "홍길동", "unknown": "x" }, "evil": 1
            }),
        )
        .unwrap();
        assert_eq!(v["name"], "말끔");
        assert_eq!(v["primary_color"], "#3B5BFD");
        assert_eq!(v["company"]["ceo"], "홍길동");
        assert!(v["company"].get("unknown").is_none());
        assert!(v.get("evil").is_none());
    }

    #[test]
    fn business_profile_rejects_bad_values() {
        let err = |v: Value| clean_business("http://127.0.0.1:8080", &v).unwrap_err().to_string();
        assert!(err(json!({})).contains("missing_field"));
        assert!(err(json!({"name": "a", "primary_color": "blue"})).contains("invalid_color"));
        assert!(err(json!({"name": "a", "logo_url": "javascript:alert(1)"})).contains("invalid_logo"));
        assert!(err(json!({"name": "a", "logo_url": "/files/../etc/passwd"})).contains("invalid_logo"));
        assert!(err(json!({"name": "x".repeat(201)})).contains("field_too_long"));
        assert!(err(json!({"name": "a", "play_store_url": "http://x"})).contains("invalid_link"));
    }

    #[test]
    fn provider_status_maps_to_wizard_result() {
        assert_eq!(check_result(StatusCode::NOT_FOUND, &[StatusCode::NOT_FOUND]), (true, "connected"));
        assert_eq!(check_result(StatusCode::UNAUTHORIZED, &[StatusCode::OK]), (false, "invalid_key"));
        assert_eq!(check_result(StatusCode::BAD_GATEWAY, &[StatusCode::OK]), (false, "provider_error"));
    }
}
