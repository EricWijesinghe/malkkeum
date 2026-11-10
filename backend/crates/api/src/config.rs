use std::{env, net::SocketAddr, path::PathBuf};

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
    /// Dev mode: fake SMS/payment/push providers, OTP code echoed in logs.
    pub dev_mode: bool,
    pub allowed_origins: Vec<String>,
    pub seed_admin: Option<(String, String)>,
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
        })
    }
}
