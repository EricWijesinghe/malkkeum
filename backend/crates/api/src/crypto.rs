//! Field-level encryption for sensitive values (bank account numbers).

use aes_gcm::{Aes256Gcm, Key, KeyInit, Nonce, aead::Aead};
use base64::{Engine, engine::general_purpose::STANDARD};
use rand::{RngCore, rngs::OsRng};

const NONCE_LEN: usize = 12;

pub fn encrypt(key: &[u8; 32], plaintext: &str) -> String {
    let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(key));
    let mut nonce = [0u8; NONCE_LEN];
    OsRng.fill_bytes(&mut nonce);
    let ct = cipher
        .encrypt(Nonce::from_slice(&nonce), plaintext.as_bytes())
        .expect("AES-GCM encryption cannot fail for valid key");
    let mut out = nonce.to_vec();
    out.extend(ct);
    STANDARD.encode(out)
}

pub fn decrypt(key: &[u8; 32], encoded: &str) -> Option<String> {
    let raw = STANDARD.decode(encoded).ok()?;
    if raw.len() <= NONCE_LEN {
        return None;
    }
    let (nonce, ct) = raw.split_at(NONCE_LEN);
    let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(key));
    String::from_utf8(cipher.decrypt(Nonce::from_slice(nonce), ct).ok()?).ok()
}

/// Derivation label for the referral-phone pepper. Changing it (or DATA_KEY) makes old digests unmatchable.
const PHONE_PEPPER_LABEL: &[u8] = b"malkkeum/referral-phone/v1";

fn hmac_sha256(key: &[u8], msg: &[u8]) -> [u8; 32] {
    use hmac::{Hmac, Mac};
    let mut mac = <Hmac<sha2::Sha256> as Mac>::new_from_slice(key).expect("HMAC takes any key length");
    mac.update(msg);
    mac.finalize().into_bytes().into()
}

/// Keyed, non-reversible stand-in for a phone kept after account deletion (`hmac:<hex>`). The pepper is
/// derived from DATA_KEY and never stored, so the 10^8 Korean mobile numbers cannot be enumerated from the DB.
pub fn phone_digest(data_key: &[u8; 32], phone: &str) -> String {
    let pepper = hmac_sha256(data_key, PHONE_PEPPER_LABEL);
    format!("hmac:{}", hex::encode(hmac_sha256(&pepper, phone.as_bytes())))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn roundtrip_and_tamper() {
        let key = [7u8; 32];
        let enc = encrypt(&key, "110-123-456789");
        assert_eq!(decrypt(&key, &enc).as_deref(), Some("110-123-456789"));
        assert_eq!(decrypt(&[8u8; 32], &enc), None);
    }

    #[test]
    fn phone_digest_is_keyed_and_stable() {
        use sha2::{Digest, Sha256};
        let d = phone_digest(&[7u8; 32], "01012345678");
        assert_eq!(d, phone_digest(&[7u8; 32], "01012345678"));
        assert_ne!(d, phone_digest(&[8u8; 32], "01012345678"), "depends on the server key");
        assert!(d.starts_with("hmac:") && d.len() == 5 + 64);
        assert!(!d.contains(&hex::encode(Sha256::digest(b"01012345678"))), "not a plain hash");
    }
}
