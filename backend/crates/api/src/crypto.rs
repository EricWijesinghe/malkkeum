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
}
