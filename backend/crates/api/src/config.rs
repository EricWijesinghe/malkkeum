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
    /// Kakao REST app id: a Kakao token is only accepted if it was issued to this app.
    pub kakao_app_id: Option<String>,
    pub google_client_ids: Vec<String>,
    pub apple_client_ids: Vec<String>,
    pub portone: PortOne,
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
        let local = ["//127.0.0.1", "//localhost", "//10.0.2.2", "//192.168."]
            .iter()
            .any(|h| public_base_url.contains(h));
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
            kakao_app_id: opt("KAKAO_APP_ID"),
            google_client_ids: list("GOOGLE_CLIENT_IDS"),
            apple_client_ids: list("APPLE_CLIENT_IDS"),
            portone: portone()?,
        })
    }
}
