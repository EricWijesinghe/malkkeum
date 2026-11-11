//! Tokens, roles, password + OTP hashing, and the request extractor.

use crate::{error::ApiError, state::AppState};
use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier, password_hash::SaltString};
use axum::{extract::FromRequestParts, http::request::Parts};
use chrono::{Duration, Utc};
use jsonwebtoken::{Algorithm, DecodingKey, EncodingKey, Header, Validation, decode, decode_header, encode};
use rand::{Rng, RngCore, rngs::OsRng};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use uuid::Uuid;

pub const ACCESS_TTL_MIN: i64 = 15;
pub const REFRESH_TTL_DAYS: i64 = 30;
/// Issuer and audience stamped on every access token and required on verify.
pub const JWT_ISS: &str = "malkkeum-api";
pub const JWT_AUD: &str = "malkkeum-api";
/// Tolerated clock drift between the signer and the verifier.
const CLOCK_SKEW_SECS: u64 = 30;
/// NIST SP 800-63B: length is the composition rule; no forced character classes.
pub const MIN_PASSWORD_CHARS: usize = 12;
pub const MAX_PASSWORD_BYTES: usize = 256;
/// Known-breached passwords, lowercase, one per line. Starter list: replace with a full top-N dump.
const BREACHED_PASSWORDS: &str = include_str!("data/breached_passwords.txt");

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Role {
    Customer,
    Pro,
    /// Team member of a pro's team: sees assigned jobs only, never payouts. Subject is `team_members.id`.
    Member,
    StaffAdmin,
    StaffConsultant,
}

impl Role {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Customer => "customer",
            Self::Pro => "pro",
            Self::Member => "member",
            Self::StaffAdmin => "staff_admin",
            Self::StaffConsultant => "staff_consultant",
        }
    }
    pub fn parse(s: &str) -> Option<Self> {
        Some(match s {
            "customer" => Self::Customer,
            "pro" => Self::Pro,
            "member" => Self::Member,
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
    iss: String,
    aud: String,
}

/// Authenticated caller. Use the narrower extractors in handlers.
#[derive(Debug, Clone, Copy)]
pub struct Auth {
    pub id: Uuid,
    pub role: Role,
}

/// Public fingerprint of a signing key, carried in the token header so verifiers pick the right key during rotation.
pub fn key_id(secret: &[u8]) -> String {
    sha256_hex(secret)[..16].to_string()
}

pub fn issue_access(secret: &[u8], id: Uuid, role: Role) -> Result<String, ApiError> {
    let now = Utc::now();
    let claims = Claims {
        sub: id,
        role,
        iat: now.timestamp(),
        exp: (now + Duration::minutes(ACCESS_TTL_MIN)).timestamp(),
        iss: JWT_ISS.into(),
        aud: JWT_AUD.into(),
    };
    let header = Header {
        kid: Some(key_id(secret)),
        ..Header::default()
    };
    encode(&header, &claims, &EncodingKey::from_secret(secret)).map_err(|e| ApiError::Internal(e.to_string()))
}

/// Verifies against the key named by the token's `kid`. `keys` is the current secret plus, during
/// rotation, the previous one; a token that names no listed key, or has no `kid`, is refused.
pub fn verify_access(keys: &[&[u8]], token: &str) -> Result<Auth, ApiError> {
    let kid = decode_header(token).ok().and_then(|h| h.kid).ok_or(ApiError::Unauthorized)?;
    let key = keys.iter().find(|k| key_id(k) == kid).ok_or(ApiError::Unauthorized)?;
    let mut validation = Validation::new(Algorithm::HS256);
    validation.leeway = CLOCK_SKEW_SECS;
    validation.set_issuer(&[JWT_ISS]);
    validation.set_audience(&[JWT_AUD]);
    validation.set_required_spec_claims(&["exp", "iss", "aud", "sub"]);
    let data = decode::<Claims>(token, &DecodingKey::from_secret(key), &validation).map_err(|_| ApiError::Unauthorized)?;
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

/// Policy for passwords a person chooses: length floor, byte cap, and no known-breached values.
pub fn check_password_policy(password: &str) -> Result<(), &'static str> {
    if password.chars().count() < MIN_PASSWORD_CHARS || password.len() > MAX_PASSWORD_BYTES {
        return Err("weak_password");
    }
    let lowered = password.to_lowercase();
    if BREACHED_PASSWORDS.lines().any(|p| p == lowered) {
        return Err("breached_password");
    }
    Ok(())
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
        verify_access(&state.config.jwt_keys(), token)
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

fn is_member_role(r: Role) -> bool {
    r == Role::Member
}

role_extractor!(Customer, |r| r == Role::Customer);
role_extractor!(Pro, |r| r == Role::Pro);
role_extractor!(Member, is_member_role);
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

    const OLD: &[u8] = b"old-key-old-key-old-key-old-key-00";
    const NEW: &[u8] = b"new-key-new-key-new-key-new-key-11";

    fn sign(claims: &Claims, secret: &[u8], kid: Option<String>) -> String {
        let header = Header { kid, ..Header::default() };
        encode(&header, claims, &EncodingKey::from_secret(secret)).unwrap()
    }

    fn claims(exp_offset_secs: i64, iss: &str, aud: &str) -> Claims {
        let now = Utc::now().timestamp();
        Claims { sub: Uuid::now_v7(), role: Role::Pro, exp: now + exp_offset_secs, iat: now, iss: iss.into(), aud: aud.into() }
    }

    #[test]
    fn token_roundtrip_and_tamper() {
        let id = Uuid::now_v7();
        let t = issue_access(NEW, id, Role::Pro).unwrap();
        let a = verify_access(&[NEW], &t).unwrap();
        assert_eq!((a.id, a.role), (id, Role::Pro));
        assert!(verify_access(&[OLD], &t).is_err());
    }

    #[test]
    fn rotation_accepts_previous_key_and_refuses_retired_one() {
        let t_old = issue_access(OLD, Uuid::now_v7(), Role::Customer).unwrap();
        let t_new = issue_access(NEW, Uuid::now_v7(), Role::Customer).unwrap();
        assert!(verify_access(&[NEW, OLD], &t_old).is_ok(), "previous key still verifies during rotation");
        assert!(verify_access(&[NEW, OLD], &t_new).is_ok());
        assert!(verify_access(&[NEW], &t_old).is_err(), "retired key is refused once dropped");
    }

    #[test]
    fn token_without_kid_or_with_unknown_kid_is_refused() {
        let good = claims(600, JWT_ISS, JWT_AUD);
        assert!(verify_access(&[NEW], &sign(&good, NEW, None)).is_err());
        assert!(verify_access(&[NEW], &sign(&good, NEW, Some("0000000000000000".into()))).is_err());
    }

    #[test]
    fn issuer_audience_and_expiry_are_enforced() {
        let kid = Some(key_id(NEW));
        assert!(verify_access(&[NEW], &sign(&claims(600, JWT_ISS, JWT_AUD), NEW, kid.clone())).is_ok());
        assert!(verify_access(&[NEW], &sign(&claims(600, "evil", JWT_AUD), NEW, kid.clone())).is_err(), "wrong iss");
        assert!(verify_access(&[NEW], &sign(&claims(600, JWT_ISS, "other-svc"), NEW, kid.clone())).is_err(), "wrong aud");
        assert!(verify_access(&[NEW], &sign(&claims(-120, JWT_ISS, JWT_AUD), NEW, kid.clone())).is_err(), "expired beyond skew");
        assert!(verify_access(&[NEW], &sign(&claims(-10, JWT_ISS, JWT_AUD), NEW, kid)).is_ok(), "expired within clock skew");
    }

    #[test]
    fn password_policy_length_and_breach_list() {
        assert_eq!(check_password_policy("short-pass1"), Err("weak_password"));
        assert_eq!(check_password_policy("Password1234"), Err("breached_password"));
        assert_eq!(check_password_policy("correct horse battery"), Ok(()));
        assert_eq!(check_password_policy("aaaaaaaaaaaaaaaa"), Ok(()), "no composition rules");
        assert_eq!(check_password_policy(&"가".repeat(100)), Err("weak_password"), "byte cap");
    }

    #[test]
    fn member_role_parses_and_only_members_pass_the_extractor_check() {
        assert_eq!(Role::parse("member"), Some(Role::Member));
        assert_eq!(Role::Member.as_str(), "member");
        assert!(!Role::Member.is_staff());
        assert!(is_member_role(Role::Member));
        assert!(!is_member_role(Role::Pro));
        assert!(!is_member_role(Role::Customer));
        assert!(!is_member_role(Role::StaffAdmin));
    }

    #[test]
    fn password_hashing() {
        let h = hash_password("correct horse battery").unwrap();
        assert!(verify_password("correct horse battery", &h));
        assert!(!verify_password("wrong", &h));
    }
}
