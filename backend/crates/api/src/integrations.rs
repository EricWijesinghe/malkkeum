//! Integration keys the owner enters in the console setup wizard.
//!
//! Each wizard card ("section") is stored as one AES-GCM encrypted JSON object in
//! `integration_settings`. A section saved in the console replaces the matching env vars, so a
//! non-technical install never edits config files; env vars stay as a developer fallback.
//! Saving swaps the live keys in [`crate::providers::Providers`] without a restart.

use crate::{
    ai::{self, AiConfig, Mode},
    config::{Config, PortOne, SolapiConfig},
    crypto,
    providers::fcm::ServiceAccount,
};
use base64::{Engine, engine::general_purpose::STANDARD};
use serde_json::{Map, Value, json};
use sqlx::PgPool;
use std::collections::HashMap;

/// Live keys for every external service. Built from env, then overlaid with console sections.
#[derive(Clone, Debug, Default)]
pub struct Integrations {
    pub kakao_app_id: Option<String>,
    pub naver_client_id: Option<String>,
    pub google_client_ids: Vec<String>,
    pub apple_client_ids: Vec<String>,
    pub portone: PortOne,
    pub solapi: Option<SolapiConfig>,
    pub fcm: Option<ServiceAccount>,
    /// AI support agent. Console-only (no env fallback).
    pub ai: Option<AiConfig>,
    pub backup: Option<S3Config>,
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
            naver_client_id: None,
            google_client_ids: c.google_client_ids.clone(),
            apple_client_ids: c.apple_client_ids.clone(),
            portone: c.portone.clone(),
            solapi: c.solapi.clone(),
            fcm: c.fcm.clone(),
            ai: None,
            backup: None,
        }
    }

    /// Whether the env (not the console) already provides this section.
    pub fn has(&self, s: Section) -> bool {
        match s {
            Section::Portone => self.portone.api_secret.is_some() && self.portone.store_id.is_some(),
            Section::Solapi => self.solapi.is_some(),
            Section::Push => self.fcm.is_some(),
            Section::Kakao => self.kakao_app_id.is_some(),
            Section::Naver => self.naver_client_id.is_some(),
            Section::Google => !self.google_client_ids.is_empty(),
            Section::Apple => !self.apple_client_ids.is_empty(),
            Section::Ai => self.ai.is_some(),
            Section::Backup => self.backup.is_some(),
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
}

impl Section {
    pub const ALL: [Section; 9] = [Self::Portone, Self::Solapi, Self::Push, Self::Kakao, Self::Naver, Self::Google, Self::Apple, Self::Ai, Self::Backup];

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
            Self::Google | Self::Apple => &CLIENT_ID_FIELDS,
            Self::Ai => &AI_FIELDS,
            Self::Backup => &BACKUP_FIELDS,
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
const KAKAO_FIELDS: [Field; 1] = [f("app_id", Kind::Text, true)];
const NAVER_FIELDS: [Field; 1] = [f("client_id", Kind::Text, true)];
const CLIENT_ID_FIELDS: [Field; 1] = [f("client_ids", Kind::List, true)];
const AI_FIELDS: [Field; 3] = [f("api_key", Kind::Secret, true), f("model", Kind::Text, false), f("mode", Kind::Text, false)];
const BACKUP_FIELDS: [Field; 6] = [
    f("endpoint", Kind::Text, true),
    f("region", Kind::Text, true),
    f("bucket", Kind::Text, true),
    f("access_key", Kind::Secret, true),
    f("secret_key", Kind::Secret, true),
    f("retention_days", Kind::Text, false),
];
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
            };
        }
        Section::Solapi => {
            let sender = digits(&required(v, "sender")?);
            if !(8..=12).contains(&sender.len()) {
                return Err(Invalid("invalid_sender"));
            }
            out.solapi = Some(SolapiConfig {
                api_key: required(v, "api_key")?,
                api_secret: required(v, "api_secret")?,
                sender,
                pf_id: text(v, "pf_id"),
                templates: string_map(v, "templates")?,
            });
        }
        Section::Push => out.fcm = Some(service_account(v)?),
        Section::Backup => out.backup = Some(s3_config(v)?),
        Section::Kakao => out.kakao_app_id = Some(required(v, "app_id")?),
        Section::Naver => out.naver_client_id = Some(required(v, "client_id")?),
        Section::Ai => {
            let mode = Mode::parse(text(v, "mode").as_deref()).ok_or(Invalid("invalid_mode"))?;
            let model = text(v, "model").unwrap_or_else(|| ai::DEFAULT_MODEL.to_string());
            if model.len() > 64 || !model.chars().all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '.') {
                return Err(Invalid("invalid_model"));
            }
            out.ai = Some(AiConfig { api_key: required(v, "api_key")?, model, mode });
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
    let rows: Vec<(String, String)> = sqlx::query_as("SELECT section, secret FROM integration_settings").fetch_all(db).await?;
    let mut out = Integrations::from_config(config);
    for (code, enc) in rows {
        let Some(section) = Section::parse(&code) else { continue };
        let Some(values) = decode(&config.data_key, &enc) else {
            tracing::warn!(section = code, "setup section cannot be decrypted; ignored");
            continue;
        };
        match apply(&out, section, &values) {
            Ok(next) => out = next,
            Err(Invalid(reason)) => tracing::warn!(section = code, reason, "setup section invalid; ignored"),
        }
    }
    Ok(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn obj(v: Value) -> Map<String, Value> {
        v.as_object().cloned().unwrap()
    }

    #[test]
    fn portone_requires_store_and_secret_and_checks_webhook_format() {
        let base = Integrations::default();
        assert_eq!(
            apply(&base, Section::Portone, &obj(json!({"store_id": "s"}))).unwrap_err(),
            Invalid("missing_field")
        );
        let bad = json!({"store_id": "s", "api_secret": "k", "webhook_secret": "nope"});
        assert_eq!(apply(&base, Section::Portone, &obj(bad)).unwrap_err(), Invalid("invalid_webhook_secret"));
        let ok = json!({"store_id": "store-1", "api_secret": "k", "webhook_secret": "whsec_aGVsbG8=", "channel_keys": "{\"card\":\"ch-1\"}"});
        let out = apply(&base, Section::Portone, &obj(ok)).unwrap();
        assert_eq!(out.portone.store_id.as_deref(), Some("store-1"));
        assert_eq!(out.portone.channel_keys.get("card").map(String::as_str), Some("ch-1"));
        assert!(out.has(Section::Portone));
    }

    #[test]
    fn solapi_sender_is_normalised_to_digits() {
        let v = json!({"api_key": "k", "api_secret": "s", "sender": "02-1234-5678"});
        let out = apply(&Integrations::default(), Section::Solapi, &obj(v)).unwrap();
        assert_eq!(out.solapi.unwrap().sender, "0212345678");
        let short = json!({"api_key": "k", "api_secret": "s", "sender": "12"});
        assert_eq!(
            apply(&Integrations::default(), Section::Solapi, &obj(short)).unwrap_err(),
            Invalid("invalid_sender")
        );
    }

    #[test]
    fn push_needs_a_real_key_file() {
        let bad = json!({"service_account": "{\"project_id\":\"p\",\"client_email\":\"e\",\"private_key\":\"x\"}"});
        assert_eq!(
            apply(&Integrations::default(), Section::Push, &obj(bad)).unwrap_err(),
            Invalid("invalid_service_account")
        );
        let good = json!({"service_account": {"project_id": "p", "client_email": "a@p.iam", "private_key": "-----BEGIN PRIVATE KEY-----\nx"}});
        assert!(apply(&Integrations::default(), Section::Push, &obj(good)).unwrap().fcm.is_some());
    }

    #[test]
    fn google_accepts_comma_list_or_array() {
        let out = apply(&Integrations::default(), Section::Google, &obj(json!({"client_ids": "a.apps, b.apps"}))).unwrap();
        assert_eq!(out.google_client_ids, vec!["a.apps", "b.apps"]);
        let out = apply(&Integrations::default(), Section::Apple, &obj(json!({"client_ids": ["com.x"]}))).unwrap();
        assert_eq!(out.apple_client_ids, vec!["com.x"]);
    }

    #[test]
    fn merge_keeps_blank_secrets_clears_null_and_drops_unknown() {
        let current = obj(json!({"store_id": "s", "api_secret": "old", "webhook_secret": "whsec_x"}));
        let incoming = obj(json!({"api_secret": "", "webhook_secret": null, "store_id": "s2", "evil": "x"}));
        let out = merge(Section::Portone, &current, &incoming);
        assert_eq!(out.get("api_secret"), Some(&json!("old")));
        assert_eq!(out.get("store_id"), Some(&json!("s2")));
        assert!(!out.contains_key("webhook_secret"));
        assert!(!out.contains_key("evil"));
    }

    #[test]
    fn preview_masks_secrets_and_shows_key_file_email() {
        assert_eq!(preview(Kind::Secret, &json!("abcdef123456")), json!("••••3456"));
        assert_eq!(preview(Kind::Secret, &json!("ab")), json!("••••ab"));
        assert_eq!(preview(Kind::File, &json!({"client_email": "push@p.iam"})), json!("push@p.iam"));
        assert_eq!(preview(Kind::Text, &json!("store-1")), json!("store-1"));
    }

    #[test]
    fn ai_defaults_to_offline_and_validates_mode_and_model() {
        let base = Integrations::default();
        let out = apply(&base, Section::Ai, &obj(json!({"api_key": "sk-ant-x"}))).unwrap();
        let ai = out.ai.clone().expect("ai config");
        assert_eq!((ai.model.as_str(), ai.mode), (ai::DEFAULT_MODEL, Mode::Offline));
        assert!(out.has(Section::Ai));
        let always = json!({"api_key": "k", "mode": "always_first", "model": "claude-opus-5-5"});
        assert_eq!(apply(&base, Section::Ai, &obj(always)).unwrap().ai.unwrap().mode, Mode::AlwaysFirst);
        assert_eq!(apply(&base, Section::Ai, &obj(json!({"api_key": "k", "mode": "daytime"}))).unwrap_err(), Invalid("invalid_mode"));
        assert_eq!(apply(&base, Section::Ai, &obj(json!({"api_key": "k", "model": "x y"}))).unwrap_err(), Invalid("invalid_model"));
        assert_eq!(apply(&base, Section::Ai, &obj(json!({"model": "claude-opus-5-5"}))).unwrap_err(), Invalid("missing_field"));
    }

    #[test]
    fn backup_endpoint_must_be_a_public_host() {
        for bad in ["https://127.0.0.1", "https://10.0.0.5:9000", "https://169.254.169.254/latest", "https://[::1]", "https://localhost", "https://minio.internal"] {
            assert!(!public_host(bad), "{bad}");
        }
        for good in ["https://acc.r2.cloudflarestorage.com", "https://kr.object.ncloudstorage.com", "https://s3.ap-northeast-2.amazonaws.com:443"] {
            assert!(public_host(good), "{good}");
        }
    }

    #[test]
    fn backup_section_validates_endpoint_bucket_and_retention() {
        let good = json!({"endpoint": "https://acc.r2.cloudflarestorage.com/", "region": "auto", "bucket": "malkkeum-backup", "access_key": "AK", "secret_key": "SK"});
        let out = apply(&Integrations::default(), Section::Backup, &obj(good.clone())).unwrap();
        let cfg = out.backup.clone().expect("backup configured");
        assert_eq!(cfg.endpoint, "https://acc.r2.cloudflarestorage.com");
        assert_eq!(cfg.retention_days, 30);
        assert!(out.has(Section::Backup));
        let mut insecure = good.clone();
        insecure["endpoint"] = json!("http://plain.example");
        assert_eq!(apply(&Integrations::default(), Section::Backup, &obj(insecure)).unwrap_err(), Invalid("invalid_endpoint"));
        let mut bucket = good.clone();
        bucket["bucket"] = json!("Bad_Bucket");
        assert_eq!(apply(&Integrations::default(), Section::Backup, &obj(bucket)).unwrap_err(), Invalid("invalid_bucket"));
        let mut keep = good;
        keep["retention_days"] = json!("0");
        assert_eq!(apply(&Integrations::default(), Section::Backup, &obj(keep)).unwrap_err(), Invalid("invalid_retention"));
    }

    #[test]
    fn every_section_code_round_trips() {
        for s in Section::ALL {
            assert_eq!(Section::parse(s.code()), Some(s));
            assert!(s.fields().iter().any(|f| f.required));
        }
        assert_eq!(Section::parse("nope"), None);
    }
}
