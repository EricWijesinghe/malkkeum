use crate::providers::fcm::ServiceAccount;
use base64::{Engine, engine::general_purpose::STANDARD};
use std::{collections::HashMap, env, net::SocketAddr, path::PathBuf};

const MIN_SECRET_BYTES: usize = 32;

/// Runtime configuration, read once from the environment and validated at startup.
#[derive(Clone, Debug)]
pub struct Config {
    pub database_url: String,
    pub bind: SocketAddr,
    pub jwt_secret: Vec<u8>,
    /// Key for encrypting payout account numbers at rest (32 bytes, hex).
    pub data_key: [u8; 32],
    pub upload_dir: PathBuf,
    pub public_base_url: String,
    /// Dev mode: fake SMS/payment/push/social/identity providers, OTP code echoed in logs.
    pub dev_mode: bool,
    pub allowed_origins: Vec<String>,
    pub seed_admin: Option<(String, String)>,
    /// One-time code for creating the owner account in the console (installer sets it; random otherwise).
    pub setup_code: Option<String>,
    /// Kakao REST app id: a Kakao token is only accepted if it was issued to this app.
    pub kakao_app_id: Option<String>,
    pub google_client_ids: Vec<String>,
    pub apple_client_ids: Vec<String>,
    pub portone: PortOne,
    /// Solapi SMS + KakaoTalk AlimTalk. None: no SMS outside dev mode (503 provider_not_configured).
    pub solapi: Option<SolapiConfig>,
    /// Firebase service account for FCM HTTP v1 push. None: no push outside dev mode.
    pub fcm: Option<ServiceAccount>,
    /// Behind a reverse proxy: rate limits key on the right-most X-Forwarded-For entry.
    pub trusted_proxy: bool,
    pub rate_auth_per_min: u32,
    pub rate_upload_per_min: u32,
    pub rate_general_per_min: u32,
    pub upload_daily_quota: u32,
    pub max_open_quote_requests: u32,
    pub max_threads_per_day: u32,
    /// Checkout reconciler period (seconds).
    pub reconcile_interval_secs: u64,
    /// Anthropic API root for the AI support agent (tests point it at a fake server).
    pub anthropic_base_url: String,
    /// SHA-256 of the Android app signing certificate(s) (Play App Signing key). Empty: no assetlinks.json.
    pub android_cert_sha256: Vec<String>,
    /// Apple Team ID. None: no apple-app-site-association.
    pub apple_team_id: Option<String>,
}

/// Solapi REST API v4 credentials and AlimTalk routing.
#[derive(Clone, Debug)]
pub struct SolapiConfig {
    pub api_key: String,
    pub api_secret: String,
    /// Registered sender number (digits only).
    pub sender: String,
    /// KakaoTalk channel (PF) id; AlimTalk is skipped without it.
    pub pf_id: Option<String>,
    /// Event kind (e.g. `booking.status`) -> approved AlimTalk template id.
    pub templates: HashMap<String, String>,
}

/// PortOne V2 (payments, identity verification, webhooks). All optional until a real account exists.
#[derive(Clone, Debug, Default)]
pub struct PortOne {
    pub api_secret: Option<String>,
    /// Standard Webhooks secret, `whsec_<base64>`.
    pub webhook_secret: Option<String>,
    pub store_id: Option<String>,
    /// Payment method code -> PortOne channel key.
    pub channel_keys: HashMap<String, String>,
}

#[derive(Debug, thiserror::Error)]
pub enum ConfigError {
    #[error("missing env var {0}")]
    Missing(&'static str),
    #[error("invalid env var {0}: {1}")]
    Invalid(&'static str, String),
}

fn req(key: &'static str) -> Result<String, ConfigError> {
    env::var(key).map_err(|_| ConfigError::Missing(key))
}

/// Trimmed, non-empty value of an optional env var.
fn opt(key: &str) -> Option<String> {
    env::var(key).ok().map(|v| v.trim().to_string()).filter(|v| !v.is_empty())
}

fn flag(key: &str) -> bool {
    opt(key).is_some_and(|v| v == "1" || v == "true")
}

/// Numeric env var with a default; values below `min` are refused at startup.
fn number<T>(key: &'static str, default: T, min: T) -> Result<T, ConfigError>
where
    T: std::str::FromStr + PartialOrd + std::fmt::Display + Copy,
{
    let Some(raw) = opt(key) else {
        return Ok(default);
    };
    let value: T = raw.parse().map_err(|_| ConfigError::Invalid(key, format!("not a number: {raw}")))?;
    if value < min {
        return Err(ConfigError::Invalid(key, format!("must be at least {min}")));
    }
    Ok(value)
}

fn list(key: &str) -> Vec<String> {
    opt(key)
        .map(|v| v.split(',').map(|s| s.trim().to_string()).filter(|s| !s.is_empty()).collect())
        .unwrap_or_default()
}

fn portone() -> Result<PortOne, ConfigError> {
    let webhook_secret = opt("PORTONE_WEBHOOK_SECRET");
    if let Some(w) = &webhook_secret {
        let raw = w
            .strip_prefix("whsec_")
            .ok_or_else(|| ConfigError::Invalid("PORTONE_WEBHOOK_SECRET", "must start with whsec_".into()))?;
        STANDARD
            .decode(raw)
            .map_err(|e| ConfigError::Invalid("PORTONE_WEBHOOK_SECRET", e.to_string()))?;
    }
    let channel_keys = match opt("PORTONE_CHANNEL_KEYS") {
        Some(j) => serde_json::from_str(&j).map_err(|e| ConfigError::Invalid("PORTONE_CHANNEL_KEYS", e.to_string()))?,
        None => HashMap::new(),
    };
    Ok(PortOne {
        api_secret: opt("PORTONE_API_SECRET"),
        webhook_secret,
        store_id: opt("PORTONE_STORE_ID"),
        channel_keys,
    })
}

fn solapi() -> Result<Option<SolapiConfig>, ConfigError> {
    let (api_key, api_secret) = match (opt("SOLAPI_API_KEY"), opt("SOLAPI_API_SECRET")) {
        (None, None) => return Ok(None),
        (Some(k), Some(s)) => (k, s),
        _ => {
            return Err(ConfigError::Invalid(
                "SOLAPI_API_KEY",
                "set SOLAPI_API_KEY and SOLAPI_API_SECRET together".into(),
            ));
        }
    };
    let sender = opt("SMS_SENDER").ok_or(ConfigError::Missing("SMS_SENDER"))?;
    let templates: HashMap<String, String> = match opt("ALIMTALK_TEMPLATES") {
        Some(j) => serde_json::from_str(&j).map_err(|e| ConfigError::Invalid("ALIMTALK_TEMPLATES", e.to_string()))?,
        None => HashMap::new(),
    };
    Ok(Some(SolapiConfig {
        api_key,
        api_secret,
        sender,
        pf_id: opt("ALIMTALK_PF_ID"),
        templates,
    }))
}

/// `FCM_SERVICE_ACCOUNT` is either the JSON itself or a path to the downloaded key file.
fn fcm_account() -> Result<Option<ServiceAccount>, ConfigError> {
    let Some(raw) = opt("FCM_SERVICE_ACCOUNT") else {
        return Ok(None);
    };
    let json = if raw.starts_with('{') {
        raw
    } else {
        std::fs::read_to_string(&raw).map_err(|e| ConfigError::Invalid("FCM_SERVICE_ACCOUNT", format!("cannot read file: {e}")))?
    };
    serde_json::from_str(&json)
        .map(Some)
        .map_err(|e| ConfigError::Invalid("FCM_SERVICE_ACCOUNT", e.to_string()))
}

impl Config {
    pub fn from_env() -> Result<Self, ConfigError> {
        let jwt_secret = req("JWT_SECRET")?.into_bytes();
        if jwt_secret.len() < MIN_SECRET_BYTES {
            return Err(ConfigError::Invalid("JWT_SECRET", format!("needs at least {MIN_SECRET_BYTES} bytes")));
        }
        let key_hex = req("DATA_KEY")?;
        let key_vec = hex::decode(&key_hex).map_err(|e| ConfigError::Invalid("DATA_KEY", e.to_string()))?;
        let data_key: [u8; 32] = key_vec
            .try_into()
            .map_err(|_| ConfigError::Invalid("DATA_KEY", "must be 64 hex chars".into()))?;
        let bind = env::var("BIND_ADDR").unwrap_or_else(|_| "127.0.0.1:8080".into());
        let seed_admin = match (env::var("SEED_ADMIN_EMAIL"), env::var("SEED_ADMIN_PASSWORD")) {
            (Ok(e), Ok(p)) if !e.is_empty() && p.len() >= 12 => Some((e, p)),
            _ => None,
        };
        let public_base_url = env::var("PUBLIC_BASE_URL").unwrap_or_else(|_| "http://127.0.0.1:8080".into());
        let dev_mode = env::var("DEV_MODE").map(|v| v == "1" || v == "true").unwrap_or(false);
        // Dev mode returns login codes in API responses: never allow it on a public address.
        let local = is_private_url(&public_base_url);
        if dev_mode && !local {
            return Err(ConfigError::Invalid(
                "DEV_MODE",
                "refusing to run dev mode with a public PUBLIC_BASE_URL".into(),
            ));
        }
        Ok(Self {
            database_url: req("DATABASE_URL")?,
            bind: bind.parse().map_err(|_| ConfigError::Invalid("BIND_ADDR", bind.clone()))?,
            jwt_secret,
            data_key,
            upload_dir: env::var("UPLOAD_DIR").unwrap_or_else(|_| "./data/uploads".into()).into(),
            public_base_url,
            dev_mode,
            allowed_origins: env::var("ALLOWED_ORIGINS")
                .map(|v| v.split(',').map(|s| s.trim().to_string()).filter(|s| !s.is_empty()).collect())
                .unwrap_or_default(),
            seed_admin,
            setup_code: opt("SETUP_CODE").map(|c| c.to_uppercase().replace(['-', ' '], "")),
            kakao_app_id: opt("KAKAO_APP_ID"),
            google_client_ids: list("GOOGLE_CLIENT_IDS"),
            apple_client_ids: list("APPLE_CLIENT_IDS"),
            portone: portone()?,
            solapi: solapi()?,
            fcm: fcm_account()?,
            trusted_proxy: flag("TRUSTED_PROXY"),
            rate_auth_per_min: number("RATE_LIMIT_AUTH_PER_MIN", 20, 1)?,
            rate_upload_per_min: number("RATE_LIMIT_UPLOAD_PER_MIN", 30, 1)?,
            rate_general_per_min: number("RATE_LIMIT_GENERAL_PER_MIN", 300, 1)?,
            upload_daily_quota: number("UPLOAD_DAILY_QUOTA", 100, 1)?,
            max_open_quote_requests: number("MAX_OPEN_QUOTE_REQUESTS", 3, 1)?,
            max_threads_per_day: number("MAX_CHAT_THREADS_PER_DAY", 10, 1)?,
            reconcile_interval_secs: number("RECONCILE_INTERVAL_SECS", 60, 10)?,
            anthropic_base_url: opt("ANTHROPIC_BASE_URL").unwrap_or_else(|| "https://api.anthropic.com".into()),
            android_cert_sha256: cert_fingerprints("ANDROID_CERT_SHA256", list("ANDROID_CERT_SHA256"))?,
            apple_team_id: team_id(opt("APPLE_TEAM_ID"))?,
        })
    }
}

/// True for loopback and RFC 1918 hosts (home/office networks), where dev mode may run for demos.
fn is_private_url(url: &str) -> bool {
    let host = url.split("//").nth(1).unwrap_or("").split(['/', ':']).next().unwrap_or("");
    if host == "localhost" {
        return true;
    }
    host.parse::<std::net::Ipv4Addr>().is_ok_and(|ip| ip.is_loopback() || ip.is_private())
}

#[cfg(test)]
mod private_url_tests {
    use super::is_private_url;

    #[test]
    fn only_loopback_and_private_networks_count_as_local() {
        for ok in ["http://127.0.0.1:8080", "http://localhost:8080", "http://10.0.2.2:8080", "http://192.168.0.5:8080", "http://172.25.243.168:8080"] {
            assert!(is_private_url(ok), "{ok}");
        }
        for bad in ["https://malkkeum.kr", "http://172.32.0.1", "http://8.8.8.8", "https://192.168.evil.com", "http://localhost.evil.com"] {
            assert!(!is_private_url(bad), "{bad}");
        }
    }
}

const SHA256_BYTES: usize = 32;
const TEAM_ID_LEN: usize = 10;

/// Upper-cased `AA:BB:..` form, 32 hex pairs, as Android's assetlinks.json expects.
fn cert_fingerprints(key: &'static str, values: Vec<String>) -> Result<Vec<String>, ConfigError> {
    values
        .into_iter()
        .map(|v| {
            let v = v.to_ascii_uppercase();
            let parts: Vec<&str> = v.split(':').collect();
            let ok = parts.len() == SHA256_BYTES && parts.iter().all(|p| p.len() == 2 && p.bytes().all(|b| b.is_ascii_hexdigit()));
            if ok { Ok(v) } else { Err(ConfigError::Invalid(key, format!("not a SHA-256 fingerprint: {v}"))) }
        })
        .collect()
}

fn team_id(raw: Option<String>) -> Result<Option<String>, ConfigError> {
    match raw {
        Some(t) if t.len() == TEAM_ID_LEN && t.bytes().all(|b| b.is_ascii_alphanumeric()) => Ok(Some(t)),
        Some(t) => Err(ConfigError::Invalid("APPLE_TEAM_ID", format!("not a 10-character Team ID: {t}"))),
        None => Ok(None),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fingerprints_are_normalised_and_checked() {
        let good = (0..32).map(|_| "ab").collect::<Vec<_>>().join(":");
        assert_eq!(cert_fingerprints("K", vec![good.clone()]).expect("ok"), vec![good.to_uppercase()]);
        assert!(cert_fingerprints("K", vec!["AB:CD".into()]).is_err(), "too short");
        assert!(cert_fingerprints("K", vec![good.replacen("ab", "zz", 1)]).is_err(), "not hex");
        assert!(cert_fingerprints("K", Vec::new()).expect("empty ok").is_empty());
    }

    #[test]
    fn team_id_is_ten_alphanumerics() {
        assert_eq!(team_id(Some("ABCDE12345".into())).expect("ok"), Some("ABCDE12345".into()));
        assert_eq!(team_id(None).expect("unset"), None);
        assert!(team_id(Some("short".into())).is_err());
        assert!(team_id(Some("ABCDE-1234".into())).is_err());
    }
}
