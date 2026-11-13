//! Integration keys the owner enters in the console setup wizard.
//!
//! Each wizard card ("section") is stored as one AES-GCM encrypted JSON object in
//! `integration_settings`. A section saved in the console replaces the matching env vars, so a
//! non-technical install never edits config files; env vars stay as a developer fallback.
//! Saving swaps the live keys in [`crate::providers::Providers`] without a restart.

use crate::{
    ai::{self, AiConfig, Caps, Mode},
    config::{AppleSignInKey, Config, PortOne, SolapiConfig},
    crypto,
    providers::fcm::ServiceAccount,
};
use base64::{Engine, engine::general_purpose::STANDARD};
use serde_json::{Map, Value, json};
use sqlx::PgPool;
use std::{collections::HashMap, ops::RangeInclusive};

/// Live keys for every external service. Built from env, then overlaid with console sections.
#[derive(Clone, Debug, Default)]
pub struct Integrations {
    pub kakao_app_id: Option<String>,
    /// Kakao Admin key: unlinks the Kakao account on account deletion (providers/social.rs). Optional.
    pub kakao_admin_key: Option<String>,
    pub naver_client_id: Option<String>,
    /// Naver app secret: the server exchanges each Naver login code with it (providers/social.rs).
    pub naver_client_secret: Option<String>,
    pub google_client_ids: Vec<String>,
    pub apple_client_ids: Vec<String>,
    /// Sign in with Apple key: code exchange at sign-in and token revocation on deletion. Optional.
    pub apple_signin: Option<AppleSignInKey>,
    pub portone: PortOne,
    pub solapi: Option<SolapiConfig>,
    pub fcm: Option<ServiceAccount>,
    /// AI support agent. Console-only (no env fallback).
    pub ai: Option<AiConfig>,
    pub backup: Option<S3Config>,
    /// 도로명주소 검색 승인키 (juso.go.kr `confmKey`). Console-only.
    pub juso_confm_key: Option<String>,
    /// Partner payout provider. None means `manual` (owner transfers and confirms).
    pub payout: Option<PayoutSettings>,
    /// True when Toss payouts may be enabled: env `TOSS_PAYOUTS_ENABLED=1` and the saved sandbox key passed
    /// the console test (see `toss_ready`). Set by the loader, never by the console.
    pub payout_toss_ready: bool,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum PayoutMode {
    Manual,
    Toss,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct PayoutSettings {
    pub mode: PayoutMode,
    /// Toss payouts secret key (Basic auth). Required when mode is `toss`.
    pub secret_key: Option<String>,
    /// Toss security key (보안 키, 64 hex chars): the AES key for JWE request and response bodies.
    pub security_key: Option<String>,
}

/// Env switch that must be on before Toss payouts can be enabled from the console.
pub const TOSS_ENV: &str = "TOSS_PAYOUTS_ENABLED";
/// Only Toss sandbox keys can pass the connection test that unlocks Toss payouts.
const SANDBOX_KEY_PREFIX: &str = "test_sk_";

/// Short, non-reversible id of a secret, stored with the test result so a changed key must be re-tested.
pub fn key_fingerprint(secret: &str) -> String {
    use sha2::{Digest, Sha256};
    Sha256::digest(secret.as_bytes()).iter().take(8).map(|b| format!("{b:02x}")).collect()
}

/// Toss payouts open only when the env switch is on AND the last sandbox test recorded success for this key.
pub fn toss_ready(env_enabled: bool, last_test: Option<&Value>, secret: &str) -> bool {
    env_enabled
        && last_test.is_some_and(|t| t["ok"] == json!(true) && t["code"] == json!("sandbox_connected") && t["key_fp"] == json!(key_fingerprint(secret)))
}

pub fn toss_env_enabled() -> bool {
    std::env::var(TOSS_ENV).is_ok_and(|v| v == "1")
}

/// Whether a payout secret is a sandbox key (the only kind the connection test accepts).
pub fn is_sandbox_key(secret: &str) -> bool {
    secret.starts_with(SANDBOX_KEY_PREFIX)
}

/// S3-compatible offsite backup target (AWS S3, Cloudflare R2, Naver Cloud Object Storage, Backblaze B2).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct S3Config {
    pub endpoint: String,
    pub region: String,
    pub bucket: String,
    pub access_key: String,
    pub secret_key: String,
    pub retention_days: u32,
}

impl Integrations {
    pub fn from_config(c: &Config) -> Self {
        Self {
            kakao_app_id: c.kakao_app_id.clone(),
            kakao_admin_key: c.kakao_admin_key.clone(),
            naver_client_id: None,
            naver_client_secret: None,
            google_client_ids: c.google_client_ids.clone(),
            apple_client_ids: c.apple_client_ids.clone(),
            apple_signin: c.apple_signin.clone(),
            portone: c.portone.clone(),
            solapi: c.solapi.clone(),
            fcm: c.fcm.clone(),
            ai: None,
            backup: None,
            payout: None,
            payout_toss_ready: false,
            juso_confm_key: None,
        }
    }

    /// Whether the env (not the console) already provides this section.
    pub fn has(&self, s: Section) -> bool {
        match s {
            Section::Portone => self.portone.api_secret.is_some() && self.portone.store_id.is_some(),
            Section::Solapi => self.solapi.is_some(),
            Section::Push => self.fcm.is_some(),
            Section::Kakao => self.kakao_app_id.is_some(),
            Section::Naver => self.naver_client_id.is_some() && self.naver_client_secret.is_some(),
            Section::Google => !self.google_client_ids.is_empty(),
            Section::Apple => !self.apple_client_ids.is_empty(),
            Section::Ai => self.ai.is_some(),
            Section::Backup => self.backup.is_some(),
            Section::Payout => self.payout.is_some(),
            Section::Juso => self.juso_confm_key.is_some(),
        }
    }
}

/// How a field is entered and shown in the wizard.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Kind {
    /// One line of text.
    Text,
    /// Shown masked (last 4 characters) once saved.
    Secret,
    /// Comma separated list.
    List,
    /// JSON object (method -> channel key, event -> template id).
    Map,
    /// Pasted file contents (Firebase key JSON). Secret.
    File,
}

pub struct Field {
    pub name: &'static str,
    pub kind: Kind,
    pub required: bool,
}

const fn f(name: &'static str, kind: Kind, required: bool) -> Field {
    Field { name, kind, required }
}

/// One card in the setup wizard.
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub enum Section {
    Portone,
    Solapi,
    Push,
    Kakao,
    Naver,
    Google,
    Apple,
    Ai,
    Backup,
    Payout,
    Juso,
}

impl Section {
    pub const ALL: [Section; 11] = [Self::Portone, Self::Solapi, Self::Push, Self::Kakao, Self::Naver, Self::Google, Self::Apple, Self::Ai, Self::Backup, Self::Payout, Self::Juso];

    pub fn code(self) -> &'static str {
        match self {
            Self::Portone => "portone",
            Self::Solapi => "solapi",
            Self::Push => "push",
            Self::Kakao => "kakao",
            Self::Naver => "naver",
            Self::Google => "google",
            Self::Apple => "apple",
            Self::Ai => "ai",
            Self::Backup => "backup",
            Self::Payout => "payout",
            Self::Juso => "juso",
        }
    }

    pub fn parse(code: &str) -> Option<Self> {
        Self::ALL.into_iter().find(|s| s.code() == code)
    }

    pub fn fields(self) -> &'static [Field] {
        match self {
            Self::Portone => &PORTONE_FIELDS,
            Self::Solapi => &SOLAPI_FIELDS,
            Self::Push => &PUSH_FIELDS,
            Self::Kakao => &KAKAO_FIELDS,
            Self::Naver => &NAVER_FIELDS,
            Self::Google => &CLIENT_ID_FIELDS,
            Self::Apple => &APPLE_FIELDS,
            Self::Ai => &AI_FIELDS,
            Self::Backup => &BACKUP_FIELDS,
            Self::Payout => &PAYOUT_FIELDS,
            Self::Juso => &JUSO_FIELDS,
        }
    }
}

const PORTONE_FIELDS: [Field; 4] = [
    f("store_id", Kind::Text, true),
    f("api_secret", Kind::Secret, true),
    f("webhook_secret", Kind::Secret, false),
    f("channel_keys", Kind::Map, false),
];
const SOLAPI_FIELDS: [Field; 5] = [
    f("api_key", Kind::Secret, true),
    f("api_secret", Kind::Secret, true),
    f("sender", Kind::Text, true),
    f("pf_id", Kind::Text, false),
    f("templates", Kind::Map, false),
];
const PUSH_FIELDS: [Field; 1] = [f("service_account", Kind::File, true)];
const KAKAO_FIELDS: [Field; 2] = [f("app_id", Kind::Text, true), f("admin_key", Kind::Secret, false)];
const NAVER_FIELDS: [Field; 2] = [f("client_id", Kind::Text, true), f("client_secret", Kind::Secret, true)];
const CLIENT_ID_FIELDS: [Field; 1] = [f("client_ids", Kind::List, true)];
/// The key fields are optional together: without them sign-in works but deletion cannot revoke the Apple token.
const APPLE_FIELDS: [Field; 4] = [
    f("client_ids", Kind::List, true),
    f("team_id", Kind::Text, false),
    f("key_id", Kind::Text, false),
    f("private_key", Kind::File, false),
];
const AI_FIELDS: [Field; 6] = [
    f("api_key", Kind::Secret, true),
    f("model", Kind::Text, false),
    f("mode", Kind::Text, false),
    f("thread_hourly_cap", Kind::Text, false),
    f("member_daily_cap", Kind::Text, false),
    f("daily_cap", Kind::Text, false),
];
const BACKUP_FIELDS: [Field; 6] = [
    f("endpoint", Kind::Text, true),
    f("region", Kind::Text, true),
    f("bucket", Kind::Text, true),
    f("access_key", Kind::Secret, true),
    f("secret_key", Kind::Secret, true),
    f("retention_days", Kind::Text, false),
];
const PAYOUT_FIELDS: [Field; 3] = [f("mode", Kind::Text, true), f("secret_key", Kind::Secret, false), f("security_key", Kind::Secret, false)];
const JUSO_FIELDS: [Field; 1] = [f("confm_key", Kind::Secret, true)];
const BACKUP_RETENTION_DEFAULT: u32 = 30;
const BACKUP_RETENTION_MAX: u32 = 3650;

/// A wizard value that fails validation. The code maps to a Korean message in the console.
#[derive(Debug, PartialEq, Eq)]
pub struct Invalid(pub &'static str);

fn text(v: &Map<String, Value>, k: &str) -> Option<String> {
    v.get(k).and_then(Value::as_str).map(str::trim).filter(|s| !s.is_empty()).map(String::from)
}

fn required(v: &Map<String, Value>, k: &str) -> Result<String, Invalid> {
    text(v, k).ok_or(Invalid("missing_field"))
}

fn list(v: &Map<String, Value>, k: &str) -> Vec<String> {
    match v.get(k) {
        Some(Value::Array(a)) => a
            .iter()
            .filter_map(Value::as_str)
            .map(|s| s.trim().to_string())
            .filter(|s| !s.is_empty())
            .collect(),
        Some(Value::String(s)) => s.split(',').map(|s| s.trim().to_string()).filter(|s| !s.is_empty()).collect(),
        _ => Vec::new(),
    }
}

fn string_map(v: &Map<String, Value>, k: &str) -> Result<HashMap<String, String>, Invalid> {
    let raw = match v.get(k) {
        None | Some(Value::Null) => return Ok(HashMap::new()),
        Some(Value::String(s)) if s.trim().is_empty() => return Ok(HashMap::new()),
        Some(Value::String(s)) => serde_json::from_str::<Value>(s).map_err(|_| Invalid("invalid_map"))?,
        Some(other) => other.clone(),
    };
    let obj = raw.as_object().ok_or(Invalid("invalid_map"))?;
    obj.iter()
        .map(|(key, val)| val.as_str().map(|s| (key.clone(), s.trim().to_string())).ok_or(Invalid("invalid_map")))
        .collect()
}

/// An optional reply cap. Blank or missing keeps the default; a number outside `range` is refused.
fn cap(v: &Map<String, Value>, k: &str, default: u32, range: RangeInclusive<u32>) -> Result<u32, Invalid> {
    let raw = match v.get(k) {
        None | Some(Value::Null) => return Ok(default),
        Some(Value::String(s)) if s.trim().is_empty() => return Ok(default),
        Some(Value::String(s)) => s.trim().to_string(),
        Some(Value::Number(n)) => n.to_string(),
        Some(_) => return Err(Invalid("invalid_cap")),
    };
    raw.parse::<u32>().ok().filter(|n| range.contains(n)).ok_or(Invalid("invalid_cap"))
}

fn digits(s: &str) -> String {
    s.chars().filter(char::is_ascii_digit).collect()
}

fn check_webhook_secret(s: &str) -> Result<(), Invalid> {
    let raw = s.strip_prefix("whsec_").ok_or(Invalid("invalid_webhook_secret"))?;
    STANDARD.decode(raw).map(|_| ()).map_err(|_| Invalid("invalid_webhook_secret"))
}

/// Backup targets are public object stores; refuse loopback/private/link-local hosts so a saved
/// endpoint can't be used to probe services inside the server's network.
fn public_host(endpoint: &str) -> bool {
    let rest = endpoint.trim_start_matches("https://");
    let authority = rest.split(['/', '?', '#']).next().unwrap_or("");
    let host = authority.rsplit_once('@').map_or(authority, |(_, h)| h);
    let host = host.strip_prefix('[').and_then(|h| h.split_once(']')).map_or_else(|| host.rsplit_once(':').map_or(host, |(h, _)| h), |(h, _)| h);
    let lower = host.to_ascii_lowercase();
    if lower.is_empty() || lower == "localhost" || lower.ends_with(".localhost") || lower.ends_with(".internal") || lower.ends_with(".local") {
        return false;
    }
    match lower.parse::<std::net::IpAddr>() {
        Ok(std::net::IpAddr::V4(ip)) => !(ip.is_loopback() || ip.is_private() || ip.is_link_local() || ip.is_unspecified() || ip.is_broadcast()),
        Ok(std::net::IpAddr::V6(ip)) => !(ip.is_loopback() || ip.is_unspecified() || (ip.segments()[0] & 0xfe00) == 0xfc00 || (ip.segments()[0] & 0xffc0) == 0xfe80),
        Err(_) => true,
    }
}

fn s3_config(v: &Map<String, Value>) -> Result<S3Config, Invalid> {
    let endpoint = required(v, "endpoint")?.trim_end_matches('/').to_string();
    if !endpoint.starts_with("https://") || endpoint.contains(char::is_whitespace) || !public_host(&endpoint) {
        return Err(Invalid("invalid_endpoint"));
    }
    let region = required(v, "region")?;
    if !region.chars().all(|c| c.is_ascii_alphanumeric() || c == '-') {
        return Err(Invalid("invalid_region"));
    }
    let bucket = required(v, "bucket")?;
    let bucket_ok = (3..=63).contains(&bucket.len())
        && bucket.chars().all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '-' || c == '.');
    if !bucket_ok {
        return Err(Invalid("invalid_bucket"));
    }
    let retention_days = match text(v, "retention_days") {
        None => BACKUP_RETENTION_DEFAULT,
        Some(d) => d.parse::<u32>().ok().filter(|d| (1..=BACKUP_RETENTION_MAX).contains(d)).ok_or(Invalid("invalid_retention"))?,
    };
    Ok(S3Config {
        endpoint,
        region,
        bucket,
        access_key: required(v, "access_key")?,
        secret_key: required(v, "secret_key")?,
        retention_days,
    })
}

fn payout_settings(v: &Map<String, Value>, toss_ready: bool) -> Result<PayoutSettings, Invalid> {
    let mode = match text(v, "mode").as_deref() {
        Some("manual") => PayoutMode::Manual,
        Some("toss") => PayoutMode::Toss,
        _ => return Err(Invalid("invalid_mode")),
    };
    let secret_key = text(v, "secret_key");
    let security_key = text(v, "security_key");
    if mode == PayoutMode::Toss {
        let (Some(_), Some(security)) = (&secret_key, &security_key) else {
            return Err(Invalid("missing_field"));
        };
        crate::providers::toss_jwe::key_bytes(security).map_err(|_| Invalid("invalid_security_key"))?;
        if !toss_ready {
            return Err(Invalid("toss_unverified"));
        }
    }
    Ok(PayoutSettings { mode, secret_key, security_key })
}

/// Team id, key id and .p8 key go together: all three or none.
fn apple_key(v: &Map<String, Value>) -> Result<Option<AppleSignInKey>, Invalid> {
    match (text(v, "team_id"), text(v, "key_id"), text(v, "private_key")) {
        (None, None, None) => Ok(None),
        (Some(team), Some(key), Some(pem)) => AppleSignInKey::new(&team, &key, &pem).map(Some).map_err(Invalid),
        _ => Err(Invalid("missing_field")),
    }
}

fn service_account(v: &Map<String, Value>) -> Result<ServiceAccount, Invalid> {
    let parsed = match v.get("service_account") {
        Some(Value::String(s)) => serde_json::from_str::<ServiceAccount>(s.trim()),
        Some(obj @ Value::Object(_)) => serde_json::from_value::<ServiceAccount>(obj.clone()),
        _ => return Err(Invalid("missing_field")),
    };
    let acc = parsed.map_err(|_| Invalid("invalid_service_account"))?;
    if !acc.private_key.contains("PRIVATE KEY") {
        return Err(Invalid("invalid_service_account"));
    }
    Ok(acc)
}

/// Overlays one console section onto `base`. Fails when a value is missing or malformed.
pub fn apply(base: &Integrations, section: Section, v: &Map<String, Value>) -> Result<Integrations, Invalid> {
    let mut out = base.clone();
    match section {
        Section::Portone => {
            let webhook_secret = text(v, "webhook_secret");
            if let Some(w) = &webhook_secret {
                check_webhook_secret(w)?;
            }
            out.portone = PortOne {
                api_secret: Some(required(v, "api_secret")?),
                webhook_secret,
                store_id: Some(required(v, "store_id")?),
                channel_keys: string_map(v, "channel_keys")?,
                cash_receipts: base.portone.cash_receipts,
            };
        }
        Section::Solapi => {
            let sender = digits(&required(v, "sender")?);
            if !(8..=12).contains(&sender.len()) {
                return Err(Invalid("invalid_sender"));
            }
            let templates = string_map(v, "templates")?;
            // A misspelled key would silently fall back to SMS for that alert, so refuse it here.
            if templates.keys().any(|k| !crate::providers::sms::TEMPLATE_KEYS.contains(&k.as_str())) {
                return Err(Invalid("unknown_template_key"));
            }
            out.solapi = Some(SolapiConfig {
                api_key: required(v, "api_key")?,
                api_secret: required(v, "api_secret")?,
                sender,
                pf_id: text(v, "pf_id"),
                templates,
            });
        }
        Section::Push => out.fcm = Some(service_account(v)?),
        Section::Backup => out.backup = Some(s3_config(v)?),
        Section::Payout => out.payout = Some(payout_settings(v, base.payout_toss_ready)?),
        Section::Kakao => {
            out.kakao_app_id = Some(required(v, "app_id")?);
            out.kakao_admin_key = text(v, "admin_key");
        }
        Section::Naver => {
            out.naver_client_id = Some(required(v, "client_id")?);
            out.naver_client_secret = Some(required(v, "client_secret")?);
        }
        Section::Juso => out.juso_confm_key = Some(required(v, "confm_key")?),
        Section::Ai => {
            let mode = Mode::parse(text(v, "mode").as_deref()).ok_or(Invalid("invalid_mode"))?;
            let model = text(v, "model").unwrap_or_else(|| ai::DEFAULT_MODEL.to_string());
            if model.len() > 64 || !model.chars().all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '.') {
                return Err(Invalid("invalid_model"));
            }
            let caps = Caps {
                thread_hourly: cap(v, "thread_hourly_cap", ai::DEFAULT_THREAD_HOURLY_CAP, ai::THREAD_HOURLY_RANGE)?,
                member_daily: cap(v, "member_daily_cap", ai::DEFAULT_MEMBER_DAILY_CAP, ai::MEMBER_DAILY_RANGE)?,
                daily: cap(v, "daily_cap", ai::DEFAULT_DAILY_CAP, ai::DAILY_RANGE)?,
            };
            out.ai = Some(AiConfig { api_key: required(v, "api_key")?, model, mode, caps });
        }
        Section::Google | Section::Apple => {
            let ids = list(v, "client_ids");
            if ids.is_empty() {
                return Err(Invalid("missing_field"));
            }
            if section == Section::Google {
                out.google_client_ids = ids;
            } else {
                out.apple_client_ids = ids;
                out.apple_signin = apple_key(v)?;
            }
        }
    }
    Ok(out)
}

/// New stored values: `incoming` over `current`. A blank or missing field keeps the saved value
/// (the wizard never sends secrets back); `null` clears it. Unknown fields are dropped.
pub fn merge(section: Section, current: &Map<String, Value>, incoming: &Map<String, Value>) -> Map<String, Value> {
    let mut out = Map::new();
    for field in section.fields() {
        let next = match incoming.get(field.name) {
            Some(Value::Null) => None,
            Some(Value::String(s)) if s.trim().is_empty() => current.get(field.name).cloned(),
            Some(v) => Some(v.clone()),
            None => current.get(field.name).cloned(),
        };
        if let Some(v) = next {
            out.insert(field.name.to_string(), v);
        }
    }
    out
}

const MASK: &str = "••••";

/// What the wizard shows for a saved value: secrets end in their last 4 characters only.
pub fn preview(kind: Kind, v: &Value) -> Value {
    match kind {
        Kind::Secret => {
            let s = v.as_str().unwrap_or_default();
            let tail: String = s.chars().rev().take(4).collect::<Vec<_>>().into_iter().rev().collect();
            json!(format!("{MASK}{tail}"))
        }
        Kind::File => {
            let email = match v {
                Value::String(s) => serde_json::from_str::<Value>(s).ok().and_then(|j| j["client_email"].as_str().map(String::from)),
                Value::Object(o) => o.get("client_email").and_then(Value::as_str).map(String::from),
                _ => None,
            };
            json!(email.unwrap_or_else(|| MASK.to_string()))
        }
        _ => v.clone(),
    }
}

/// Saved console values for one section, decrypted. Empty when nothing was saved.
pub async fn load_section(db: &PgPool, key: &[u8; 32], section: Section) -> Result<Map<String, Value>, sqlx::Error> {
    let row: Option<String> = sqlx::query_scalar("SELECT secret FROM integration_settings WHERE section = $1")
        .bind(section.code())
        .fetch_optional(db)
        .await?;
    Ok(row.and_then(|enc| decode(key, &enc)).unwrap_or_default())
}

fn decode(key: &[u8; 32], enc: &str) -> Option<Map<String, Value>> {
    let plain = crypto::decrypt(key, enc)?;
    serde_json::from_str::<Value>(&plain).ok()?.as_object().cloned()
}

pub async fn save_section(db: &PgPool, key: &[u8; 32], section: Section, values: &Map<String, Value>, by: uuid::Uuid) -> Result<(), sqlx::Error> {
    let enc = crypto::encrypt(key, &Value::Object(values.clone()).to_string());
    sqlx::query(
        "INSERT INTO integration_settings (section, secret, updated_by) VALUES ($1, $2, $3)
         ON CONFLICT (section) DO UPDATE SET secret = EXCLUDED.secret, updated_by = EXCLUDED.updated_by, updated_at = now(), last_test = NULL",
    )
    .bind(section.code())
    .bind(enc)
    .bind(by)
    .execute(db)
    .await
    .map(|_| ())
}

pub async fn delete_section(db: &PgPool, section: Section) -> Result<(), sqlx::Error> {
    sqlx::query("DELETE FROM integration_settings WHERE section = $1")
        .bind(section.code())
        .execute(db)
        .await
        .map(|_| ())
}

/// Env keys overlaid with every saved console section. A section that no longer validates
/// (e.g. after DATA_KEY rotation) is skipped with a warning so the server still starts.
pub async fn load(db: &PgPool, config: &Config) -> Result<Integrations, sqlx::Error> {
    let rows: Vec<(String, String, Option<Value>)> = sqlx::query_as("SELECT section, secret, last_test FROM integration_settings").fetch_all(db).await?;
    let mut out = Integrations::from_config(config);
    for (code, enc, last_test) in rows {
        let Some(section) = Section::parse(&code) else { continue };
        let Some(values) = decode(&config.data_key, &enc) else {
            tracing::warn!(section = code, "setup section cannot be decrypted; ignored");
            continue;
        };
        if section == Section::Payout {
            let secret = values.get("secret_key").and_then(Value::as_str).unwrap_or_default();
            out.payout_toss_ready = toss_ready(toss_env_enabled(), last_test.as_ref(), secret);
        }
        match apply(&out, section, &values) {
            Ok(next) => out = next,
            Err(Invalid(reason)) => tracing::warn!(section = code, reason, "setup section invalid; ignored"),
        }
    }
    Ok(out)
}

#[cfg(test)]
mod tests;
