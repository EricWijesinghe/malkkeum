//! Field-level encryption for sensitive values (bank account numbers).

use aes_gcm::{
    Aes256Gcm, Key, KeyInit, Nonce,
    aead::{Aead, Payload},
};
use base64::{Engine, engine::general_purpose::STANDARD};
use rand::{RngCore, rngs::OsRng};

const NONCE_LEN: usize = 12;
/// Prefix on every new ciphertext: format version 1 (AAD-bound). Values without it are the legacy
/// format (no AAD), still read so existing rows keep working until they are rewritten.
const V1_PREFIX: &str = "v1:";

/// Column labels bound as AAD. A ciphertext moved to another column fails to decrypt.
pub mod aad {
    pub const PAYOUT_ACCOUNT: &str = "payout_accounts.account_enc";
    pub const RECEIPT_IDENTITY: &str = "cash_receipts.identity_enc";
    pub const ACCESS_CODE: &str = "bookings.access_code_enc";
    pub const STAFF_TOTP: &str = "staff.totp_secret";
    pub const SOCIAL_TOKEN: &str = "social_tokens.refresh_token_enc";
    pub const INTEGRATION: &str = "integration_settings.secret";
}

pub fn encrypt(key: &[u8; 32], aad: &str, plaintext: &str) -> String {
    let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(key));
    let mut nonce = [0u8; NONCE_LEN];
    OsRng.fill_bytes(&mut nonce);
    let ct = cipher
        .encrypt(
            Nonce::from_slice(&nonce),
            Payload {
                msg: plaintext.as_bytes(),
                aad: aad.as_bytes(),
            },
        )
        .expect("AES-GCM encryption cannot fail for valid key");
    let mut out = nonce.to_vec();
    out.extend(ct);
    format!("{V1_PREFIX}{}", STANDARD.encode(out))
}

pub fn decrypt(key: &[u8; 32], aad: &str, encoded: &str) -> Option<String> {
    let (body, aad): (&str, &[u8]) = match encoded.strip_prefix(V1_PREFIX) {
        Some(body) => (body, aad.as_bytes()),
        None => (encoded, b""),
    };
    let raw = STANDARD.decode(body).ok()?;
    if raw.len() <= NONCE_LEN {
        return None;
    }
    let (nonce, ct) = raw.split_at(NONCE_LEN);
    let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(key));
    let plain = cipher.decrypt(Nonce::from_slice(nonce), Payload { msg: ct, aad }).ok()?;
    String::from_utf8(plain).ok()
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
        let enc = encrypt(&key, aad::PAYOUT_ACCOUNT, "110-123-456789");
        assert!(enc.starts_with(V1_PREFIX));
        assert_eq!(decrypt(&key, aad::PAYOUT_ACCOUNT, &enc).as_deref(), Some("110-123-456789"));
        assert_eq!(decrypt(&[8u8; 32], aad::PAYOUT_ACCOUNT, &enc), None);
    }

    #[test]
    fn ciphertext_is_bound_to_its_column() {
        let key = [7u8; 32];
        let enc = encrypt(&key, aad::PAYOUT_ACCOUNT, "secret");
        assert_eq!(decrypt(&key, aad::ACCESS_CODE, &enc), None, "moved to another column must not decrypt");
        let mut flipped = enc.clone();
        flipped.push('A');
        assert_eq!(decrypt(&key, aad::PAYOUT_ACCOUNT, &flipped), None, "trailing garbage is rejected");
    }

    #[test]
    fn legacy_values_without_prefix_still_decrypt() {
        use aes_gcm::aead::Aead;
        let key = [7u8; 32];
        let nonce = [1u8; NONCE_LEN];
        let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(&key));
        let ct = cipher.encrypt(Nonce::from_slice(&nonce), b"old-value".as_ref()).expect("encrypt");
        let legacy = STANDARD.encode([nonce.to_vec(), ct].concat());
        assert_eq!(decrypt(&key, aad::ACCESS_CODE, &legacy).as_deref(), Some("old-value"));
        assert_eq!(decrypt(&key, aad::ACCESS_CODE, "v1:!!"), None, "malformed v1 value is rejected");
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
