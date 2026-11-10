//! Tokens, roles, password + OTP hashing, and the request extractor.

use crate::{error::ApiError, state::AppState};
use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier, password_hash::SaltString};
use axum::{extract::FromRequestParts, http::request::Parts};
use chrono::{Duration, Utc};
use jsonwebtoken::{DecodingKey, EncodingKey, Header, Validation, decode, encode};
use rand::{Rng, RngCore, rngs::OsRng};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use uuid::Uuid;

pub const ACCESS_TTL_MIN: i64 = 15;
pub const REFRESH_TTL_DAYS: i64 = 30;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Role {
    Customer,
    Pro,
    StaffAdmin,
    StaffConsultant,
}

impl Role {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Customer => "customer",
            Self::Pro => "pro",
            Self::StaffAdmin => "staff_admin",
            Self::StaffConsultant => "staff_consultant",
        }
    }
    pub fn parse(s: &str) -> Option<Self> {
        Some(match s {
            "customer" => Self::Customer,
            "pro" => Self::Pro,
            "staff_admin" => Self::StaffAdmin,
            "staff_consultant" => Self::StaffConsultant,
            _ => return None,
        })
    }
    pub fn is_staff(self) -> bool {
        matches!(self, Self::StaffAdmin | Self::StaffConsultant)
    }
}

#[derive(Debug, Serialize, Deserialize)]
struct Claims {
    sub: Uuid,
    role: Role,
    exp: i64,
    iat: i64,
}

/// Authenticated caller. Use the narrower extractors in handlers.
#[derive(Debug, Clone, Copy)]
pub struct Auth {
    pub id: Uuid,
    pub role: Role,
}

pub fn issue_access(secret: &[u8], id: Uuid, role: Role) -> Result<String, ApiError> {
    let now = Utc::now();
    let claims = Claims {
        sub: id,
        role,
        iat: now.timestamp(),
        exp: (now + Duration::minutes(ACCESS_TTL_MIN)).timestamp(),
    };
    encode(&Header::default(), &claims, &EncodingKey::from_secret(secret)).map_err(|e| ApiError::Internal(e.to_string()))
}

pub fn verify_access(secret: &[u8], token: &str) -> Result<Auth, ApiError> {
    let data = decode::<Claims>(token, &DecodingKey::from_secret(secret), &Validation::default()).map_err(|_| ApiError::Unauthorized)?;
    Ok(Auth {
        id: data.claims.sub,
        role: data.claims.role,
    })
}

/// Opaque refresh token; only its SHA-256 is stored.
pub fn new_refresh_token() -> (String, String) {
    let mut bytes = [0u8; 32];
    OsRng.fill_bytes(&mut bytes);
    let token = hex::encode(bytes);
    let hash = sha256_hex(token.as_bytes());
    (token, hash)
}

pub fn sha256_hex(data: &[u8]) -> String {
    hex::encode(Sha256::digest(data))
}

pub fn otp_code() -> String {
    format!("{:06}", OsRng.gen_range(0..1_000_000))
}

/// Codes are short, so they are peppered with the server secret before hashing.
pub fn otp_hash(secret: &[u8], phone: &str, code: &str) -> String {
    let mut h = Sha256::new();
    h.update(secret);
    h.update(phone.as_bytes());
    h.update(code.as_bytes());
    hex::encode(h.finalize())
}

pub fn hash_password(password: &str) -> Result<String, ApiError> {
    let salt = SaltString::generate(&mut OsRng);
    Argon2::default()
        .hash_password(password.as_bytes(), &salt)
        .map(|h| h.to_string())
        .map_err(|e| ApiError::Internal(e.to_string()))
}

/// Argon2 is deliberately slow and memory-hungry: run it off the async workers and cap
/// concurrency so a burst of login attempts can't stall every other request.
pub async fn verify_password_blocking(password: String, hash: String) -> Result<bool, ApiError> {
    static LIMIT: std::sync::OnceLock<tokio::sync::Semaphore> = std::sync::OnceLock::new();
    let _permit = LIMIT
        .get_or_init(|| tokio::sync::Semaphore::new(PASSWORD_CONCURRENCY))
        .acquire()
        .await
        .map_err(|e| ApiError::Internal(e.to_string()))?;
    tokio::task::spawn_blocking(move || verify_password(&password, &hash))
        .await
        .map_err(|e| ApiError::Internal(e.to_string()))
}

const PASSWORD_CONCURRENCY: usize = 4;

pub fn verify_password(password: &str, hash: &str) -> bool {
    PasswordHash::new(hash).is_ok_and(|parsed| Argon2::default().verify_password(password.as_bytes(), &parsed).is_ok())
}

/// Korean mobile numbers only: 010-1234-5678 -> 01012345678.
pub fn normalize_phone(raw: &str) -> Option<String> {
    let digits: String = raw.chars().filter(|c| c.is_ascii_digit()).collect();
    let digits = digits.strip_prefix("82").map(|d| format!("0{d}")).unwrap_or(digits);
    let valid = digits.len() >= 10 && digits.len() <= 11 && digits.starts_with("01") && matches!(digits.as_bytes()[2], b'0' | b'1' | b'6' | b'7' | b'8' | b'9');
    valid.then_some(digits)
}

/// Show only the family name: 김지은 -> 김*은 (2 chars: 김*).
pub fn mask_name(name: &str) -> String {
    let chars: Vec<char> = name.chars().collect();
    match chars.len() {
        0 => String::new(),
        1 => "*".into(),
        2 => format!("{}*", chars[0]),
        n => format!("{}{}{}", chars[0], "*".repeat(n - 2), chars[n - 1]),
    }
}

fn bearer(parts: &Parts) -> Option<&str> {
    parts.headers.get(axum::http::header::AUTHORIZATION)?.to_str().ok()?.strip_prefix("Bearer ")
}

impl FromRequestParts<AppState> for Auth {
    type Rejection = ApiError;
    async fn from_request_parts(parts: &mut Parts, state: &AppState) -> Result<Self, Self::Rejection> {
        let token = bearer(parts).ok_or(ApiError::Unauthorized)?;
        verify_access(&state.config.jwt_secret, token)
    }
}

macro_rules! role_extractor {
    ($name:ident, $check:expr) => {
        #[derive(Debug, Clone, Copy)]
        pub struct $name(pub Auth);
        impl FromRequestParts<AppState> for $name {
            type Rejection = ApiError;
            async fn from_request_parts(parts: &mut Parts, state: &AppState) -> Result<Self, Self::Rejection> {
                let auth = Auth::from_request_parts(parts, state).await?;
                let check: fn(Role) -> bool = $check;
                if check(auth.role) { Ok(Self(auth)) } else { Err(ApiError::Forbidden) }
            }
        }
    };
}

role_extractor!(Customer, |r| r == Role::Customer);
role_extractor!(Pro, |r| r == Role::Pro);
role_extractor!(Staff, |r| r.is_staff());
role_extractor!(Admin, |r| r == Role::StaffAdmin);

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn phone_normalization() {
        assert_eq!(normalize_phone("010-1234-5678").as_deref(), Some("01012345678"));
        assert_eq!(normalize_phone("+82 10 1234 5678").as_deref(), Some("01012345678"));
        assert_eq!(normalize_phone("02-123-4567"), None);
        assert_eq!(normalize_phone("0101234"), None);
    }

    #[test]
    fn name_masking() {
        assert_eq!(mask_name("김지은"), "김*은");
        assert_eq!(mask_name("남궁민수"), "남**수");
        assert_eq!(mask_name("이준"), "이*");
    }

    #[test]
    fn token_roundtrip_and_tamper() {
        let secret = b"0123456789abcdef0123456789abcdef";
        let id = Uuid::now_v7();
        let t = issue_access(secret, id, Role::Pro).unwrap();
        let a = verify_access(secret, &t).unwrap();
        assert_eq!((a.id, a.role), (id, Role::Pro));
        assert!(verify_access(b"another-secret-another-secret-xx", &t).is_err());
    }

    #[test]
    fn password_hashing() {
        let h = hash_password("correct horse battery").unwrap();
        assert!(verify_password("correct horse battery", &h));
        assert!(!verify_password("wrong", &h));
    }
}
