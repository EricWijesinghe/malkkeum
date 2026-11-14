//! Keys bundle: the two secrets a restore on a fresh server cannot run without (DATA_KEY and JWT_SECRET),
//! sealed under a passphrase the server generates and shows once. `routes/keys.rs` makes and tests it;
//! `api keys-open` (run by the host agent for `keys-restore`) prints the two lines back.
//!
//! File format: "MKK1" | 16-byte PBKDF2 salt | 12-byte nonce | AES-256-GCM ciphertext+tag.
//! Key = PBKDF2-HMAC-SHA256(canonical passphrase, salt, 600 000). The magic is the AAD.
//! Plaintext = JSON `{"DATA_KEY": "<64 hex>", "JWT_SECRET": "<text>"}` with no other fields.

use aes_gcm::{
    Aes256Gcm, Key, KeyInit, Nonce,
    aead::{Aead, Payload},
};
use hmac::{Hmac, Mac};
use rand::{RngCore, rngs::OsRng};
use serde::{Deserialize, Serialize};
use sha2::Sha256;
use subtle::ConstantTimeEq;

const MAGIC: &[u8; 4] = b"MKK1";
const SALT_LEN: usize = 16;
const NONCE_LEN: usize = 12;
const HEADER_LEN: usize = MAGIC.len() + SALT_LEN + NONCE_LEN;
const ITERATIONS: u32 = 600_000;
/// Largest bundle accepted. A real one is a few hundred bytes; the host job blob cap is 4 KB.
pub const MAX_BUNDLE_BYTES: usize = 4096;
/// Passphrase alphabet: 32 symbols, no 0/1/I/O, so typed characters are not misread.
const PASS_ALPHABET: &[u8] = b"ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const PASS_GROUPS: usize = 5;
const PASS_GROUP_LEN: usize = 4;

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum BundleError {
    /// Wrong passphrase, damaged or foreign bytes. The cause is deliberately not separated.
    #[error("bundle could not be opened")]
    Invalid,
    /// The live key material cannot be written as a bundle (not text, empty, or contains a line break).
    #[error("key material cannot be bundled")]
    Unusable,
}

/// The two allowlisted secrets. Deliberately not `Debug` so they cannot be logged by accident.
pub struct Keys {
    data_key: [u8; 32],
    jwt_secret: String,
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE", deny_unknown_fields)]
struct Plain {
    data_key: String,
    jwt_secret: String,
}

impl Keys {
    pub fn from_parts(data_key: [u8; 32], jwt_secret: &[u8]) -> Result<Self, BundleError> {
        let jwt_secret = String::from_utf8(jwt_secret.to_vec()).map_err(|_| BundleError::Unusable)?;
        if jwt_secret.is_empty() || jwt_secret.contains(['\n', '\r']) {
            return Err(BundleError::Unusable);
        }
        Ok(Self { data_key, jwt_secret })
    }

    /// Constant-time comparison against the live keys.
    pub fn matches(&self, data_key: &[u8; 32], jwt_secret: &[u8]) -> bool {
        let key_ok = bool::from(self.data_key.ct_eq(data_key));
        let secret_ok = bool::from(self.jwt_secret.as_bytes().ct_eq(jwt_secret));
        key_ok & secret_ok
    }

    /// The two lines `api keys-open` prints. Nothing else leaves the process on stdout.
    pub fn lines(&self) -> String {
        format!("DATA_KEY={}\nJWT_SECRET={}\n", hex::encode(self.data_key), self.jwt_secret)
    }
}

/// A new passphrase for display, e.g. `ABCD-EFGH-JKLM-NPQR-STUV`. Drawn from the OS CSPRNG.
pub fn new_passphrase() -> String {
    let mut groups = Vec::with_capacity(PASS_GROUPS);
    for _ in 0..PASS_GROUPS {
        let group: String = (0..PASS_GROUP_LEN)
            .map(|_| char::from(PASS_ALPHABET[(OsRng.next_u32() as usize) % PASS_ALPHABET.len()]))
            .collect();
        groups.push(group);
    }
    groups.join("-")
}

/// What the owner typed, reduced to letters and digits in upper case. Dashes, spaces and case do not matter.
fn canonical(passphrase: &str) -> String {
    passphrase.chars().filter(char::is_ascii_alphanumeric).map(|c| c.to_ascii_uppercase()).collect()
}

/// PBKDF2-HMAC-SHA256 for one 32-byte block (RFC 8018 section 5.2).
fn derive(passphrase: &str, salt: &[u8]) -> [u8; 32] {
    let base = <Hmac<Sha256> as Mac>::new_from_slice(canonical(passphrase).as_bytes()).expect("HMAC takes any key length");
    let mut first = base.clone();
    first.update(salt);
    first.update(&1u32.to_be_bytes());
    let mut u: [u8; 32] = first.finalize().into_bytes().into();
    let mut out = u;
    for _ in 1..ITERATIONS {
        let mut mac = base.clone();
        mac.update(&u);
        u = mac.finalize().into_bytes().into();
        for (o, b) in out.iter_mut().zip(u) {
            *o ^= b;
        }
    }
    out
}

fn cipher_for(passphrase: &str, salt: &[u8]) -> Aes256Gcm {
    let key = derive(passphrase, salt);
    Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(&key))
}

/// Seals the keys under `passphrase`. Callers open the result again before showing the passphrase.
pub fn seal(keys: &Keys, passphrase: &str) -> Result<Vec<u8>, BundleError> {
    let plain = serde_json::to_vec(&Plain {
        data_key: hex::encode(keys.data_key),
        jwt_secret: keys.jwt_secret.clone(),
    })
    .map_err(|_| BundleError::Unusable)?;
    let mut salt = [0u8; SALT_LEN];
    let mut nonce = [0u8; NONCE_LEN];
    OsRng.fill_bytes(&mut salt);
    OsRng.fill_bytes(&mut nonce);
    let ct = cipher_for(passphrase, &salt)
        .encrypt(Nonce::from_slice(&nonce), Payload { msg: &plain, aad: MAGIC })
        .map_err(|_| BundleError::Unusable)?;
    let mut out = Vec::with_capacity(HEADER_LEN + ct.len());
    out.extend_from_slice(MAGIC);
    out.extend_from_slice(&salt);
    out.extend_from_slice(&nonce);
    out.extend_from_slice(&ct);
    Ok(out)
}

/// Opens a bundle made by [`seal`]. A changed byte, wrong passphrase or malformed plaintext is `Invalid`.
pub fn open(bundle: &[u8], passphrase: &str) -> Result<Keys, BundleError> {
    if bundle.len() <= HEADER_LEN || bundle.len() > MAX_BUNDLE_BYTES || &bundle[..MAGIC.len()] != MAGIC {
        return Err(BundleError::Invalid);
    }
    let salt = &bundle[MAGIC.len()..MAGIC.len() + SALT_LEN];
    let nonce = &bundle[MAGIC.len() + SALT_LEN..HEADER_LEN];
    let plain = cipher_for(passphrase, salt)
        .decrypt(
            Nonce::from_slice(nonce),
            Payload {
                msg: &bundle[HEADER_LEN..],
                aad: MAGIC,
            },
        )
        .map_err(|_| BundleError::Invalid)?;
    let parsed: Plain = serde_json::from_slice(&plain).map_err(|_| BundleError::Invalid)?;
    let data_key: [u8; 32] = hex::decode(&parsed.data_key).ok().and_then(|b| b.try_into().ok()).ok_or(BundleError::Invalid)?;
    Keys::from_parts(data_key, parsed.jwt_secret.as_bytes()).map_err(|_| BundleError::Invalid)
}

/// `api keys-open <bundle file>`, run by the host agent. The passphrase comes from `KEYS_PASSPHRASE`.
/// Prints exactly the two allowlisted lines on success; errors go to stderr without any key material.
pub fn cli(args: &[String]) -> i32 {
    let [_, path] = args else {
        eprintln!("usage: api keys-open <bundle file>");
        return 2;
    };
    let Ok(passphrase) = std::env::var("KEYS_PASSPHRASE") else {
        eprintln!("KEYS_PASSPHRASE is not set");
        return 2;
    };
    let bytes = match std::fs::read(path) {
        Ok(b) => b,
        Err(_) => {
            eprintln!("bundle file cannot be read");
            return 1;
        }
    };
    match open(&bytes, &passphrase) {
        Ok(keys) => {
            print!("{}", keys.lines());
            0
        }
        Err(e) => {
            eprintln!("{e}");
            1
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const PASS: &str = "ABCD-EFGH-JKLM-NPQR-STUV";
    const JWT: &[u8] = b"jwt-secret-for-tests-0000000000000000";

    fn sample() -> Keys {
        Keys::from_parts([7u8; 32], JWT).expect("keys")
    }

    #[test]
    fn round_trip_restores_both_keys() {
        let sealed = seal(&sample(), PASS).expect("seal");
        let opened = open(&sealed, PASS).expect("open");
        assert!(opened.matches(&[7u8; 32], JWT));
    }

    #[test]
    fn wrong_passphrase_and_flipped_byte_fail() {
        let sealed = seal(&sample(), PASS).expect("seal");
        assert_eq!(open(&sealed, "ABCD-EFGH-JKLM-NPQR-STUW").err(), Some(BundleError::Invalid));
        let mut tampered = sealed.clone();
        let last = tampered.len() - 1;
        tampered[last] ^= 0x01;
        assert_eq!(open(&tampered, PASS).err(), Some(BundleError::Invalid));
    }

    #[test]
    fn passphrase_typed_loosely_still_opens() {
        let sealed = seal(&sample(), PASS).expect("seal");
        assert!(open(&sealed, "abcd efgh-jklm-npqr-stuv").is_ok());
    }

    #[test]
    fn output_holds_exactly_two_keys() {
        let lines = sample().lines();
        let parts: Vec<&str> = lines.lines().collect();
        assert_eq!(parts.len(), 2, "{lines:?}");
        assert_eq!(parts[0], format!("DATA_KEY={}", "07".repeat(32)));
        assert_eq!(parts[1].strip_prefix("JWT_SECRET="), std::str::from_utf8(JWT).ok());
    }

    #[test]
    fn line_breaks_and_empty_secrets_are_refused() {
        assert!(Keys::from_parts([0u8; 32], b"a\nB=c").is_err());
        assert!(Keys::from_parts([0u8; 32], b"").is_err());
        assert!(Keys::from_parts([0u8; 32], &[0xff, 0xfe]).is_err());
    }

    #[test]
    fn generated_passphrases_have_the_shape() {
        let p = new_passphrase();
        assert_eq!(p.len(), PASS_GROUPS * PASS_GROUP_LEN + PASS_GROUPS - 1);
        assert!(p.bytes().filter(|b| *b != b'-').all(|b| PASS_ALPHABET.contains(&b)), "{p}");
    }
}
