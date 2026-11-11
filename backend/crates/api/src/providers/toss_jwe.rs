//! JWE body encryption for Toss payouts (지급대행). Per the guide (guides/v2/payouts): the request body
//! is a compact JWE, `alg` = `dir` (the 64-hex security key is used directly), `enc` = `A256GCM`, with
//! custom protected headers `iat` (ISO 8601 with offset) and `nonce` (unique value). Responses come back
//! encrypted with the same key. Only the key bytes are used; there is no wrapped content key.

use aes_gcm::{
    Aes256Gcm, Key, KeyInit, Nonce,
    aead::{Aead, Payload},
};
use base64::{Engine, engine::general_purpose::URL_SAFE_NO_PAD};
use chrono::Utc;
use rand::{RngCore, rngs::OsRng};
use serde_json::{Value, json};

const IV_LEN: usize = 12;
const TAG_LEN: usize = 16;

/// Decodes the 64-character hex security key into the 32 bytes used as the AES key.
pub fn key_bytes(security_key: &str) -> Result<[u8; 32], &'static str> {
    let raw = hex::decode(security_key.trim()).map_err(|_| "invalid_security_key")?;
    raw.try_into().map_err(|_| "invalid_security_key")
}

/// Encrypts `plaintext` as a compact JWE with the given `iat` and `nonce` (exposed for tests).
pub fn seal_with(key: &[u8; 32], plaintext: &[u8], iat: &str, nonce: &str) -> String {
    let header = json!({ "alg": "dir", "enc": "A256GCM", "iat": iat, "nonce": nonce });
    let protected = URL_SAFE_NO_PAD.encode(header.to_string());
    let mut iv = [0u8; IV_LEN];
    OsRng.fill_bytes(&mut iv);
    let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(key));
    // aes-gcm appends the 16-byte tag to the ciphertext; the protected header is the AAD.
    let sealed = cipher
        .encrypt(Nonce::from_slice(&iv), Payload { msg: plaintext, aad: protected.as_bytes() })
        .expect("AES-GCM encryption cannot fail for a 32-byte key");
    let (ct, tag) = sealed.split_at(sealed.len() - TAG_LEN);
    format!("{protected}..{}.{}.{}", URL_SAFE_NO_PAD.encode(iv), URL_SAFE_NO_PAD.encode(ct), URL_SAFE_NO_PAD.encode(tag))
}

/// Encrypts a JSON body with the current time and a random nonce.
pub fn seal(key: &[u8; 32], body: &Value) -> String {
    let iat = Utc::now().format("%Y-%m-%dT%H:%M:%S%:z").to_string();
    let mut n = [0u8; 16];
    OsRng.fill_bytes(&mut n);
    let nonce: String = n.iter().map(|b| format!("{b:02x}")).collect();
    seal_with(key, body.to_string().as_bytes(), &iat, &nonce)
}

/// Decrypts a compact JWE from Toss. Rejects any header that is not `dir` + `A256GCM`, and any tampering.
pub fn open(key: &[u8; 32], compact: &str) -> Result<Value, &'static str> {
    let parts: Vec<&str> = compact.trim().split('.').collect();
    let &[protected, cek, iv, ct, tag] = parts.as_slice() else { return Err("jwe_format") };
    if !cek.is_empty() {
        return Err("jwe_format");
    }
    let header: Value = serde_json::from_slice(&URL_SAFE_NO_PAD.decode(protected).map_err(|_| "jwe_format")?).map_err(|_| "jwe_format")?;
    if header["alg"] != "dir" || header["enc"] != "A256GCM" {
        return Err("jwe_algorithm");
    }
    let iv = URL_SAFE_NO_PAD.decode(iv).map_err(|_| "jwe_format")?;
    let tag = URL_SAFE_NO_PAD.decode(tag).map_err(|_| "jwe_format")?;
    if iv.len() != IV_LEN || tag.len() != TAG_LEN {
        return Err("jwe_format");
    }
    let mut sealed = URL_SAFE_NO_PAD.decode(ct).map_err(|_| "jwe_format")?;
    sealed.extend_from_slice(&tag);
    let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(key));
    let plain = cipher
        .decrypt(Nonce::from_slice(&iv), Payload { msg: &sealed, aad: protected.as_bytes() })
        .map_err(|_| "jwe_auth")?;
    serde_json::from_slice(&plain).map_err(|_| "jwe_payload")
}

#[cfg(test)]
mod tests {
    use super::*;

    const KEY_HEX: &str = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

    fn key() -> [u8; 32] {
        key_bytes(KEY_HEX).unwrap()
    }

    #[test]
    fn security_key_must_be_64_hex_chars() {
        assert_eq!(key()[0], 0x01);
        assert_eq!(key_bytes("abcd"), Err("invalid_security_key"));
        assert_eq!(key_bytes(&"zz".repeat(32)), Err("invalid_security_key"));
    }

    #[test]
    fn compact_form_has_empty_cek_and_documented_headers() {
        let jwe = seal_with(&key(), br#"{"a":1}"#, "2026-11-11T10:00:00+09:00", "n-1");
        let parts: Vec<&str> = jwe.split('.').collect();
        assert_eq!(parts.len(), 5);
        assert_eq!(parts[1], "", "dir mode carries no encrypted key");
        let header: Value = serde_json::from_slice(&URL_SAFE_NO_PAD.decode(parts[0]).unwrap()).unwrap();
        assert_eq!(header, json!({"alg": "dir", "enc": "A256GCM", "iat": "2026-11-11T10:00:00+09:00", "nonce": "n-1"}));
        assert_eq!(URL_SAFE_NO_PAD.decode(parts[2]).unwrap().len(), IV_LEN);
        assert_eq!(URL_SAFE_NO_PAD.decode(parts[4]).unwrap().len(), TAG_LEN);
    }

    #[test]
    fn round_trips_a_request_body() {
        let body = json!({"refPayoutId": "p-1", "amount": {"currency": "KRW", "value": 120000}});
        let jwe = seal(&key(), &body);
        assert_eq!(open(&key(), &jwe).unwrap(), body);
    }

    #[test]
    fn wrong_key_or_tampered_text_is_refused() {
        let jwe = seal(&key(), &json!({"x": 1}));
        assert_eq!(open(&[9u8; 32], &jwe), Err("jwe_auth"));
        let mut parts: Vec<String> = jwe.split('.').map(String::from).collect();
        let mut ct = URL_SAFE_NO_PAD.decode(&parts[3]).unwrap();
        ct[0] ^= 1;
        parts[3] = URL_SAFE_NO_PAD.encode(ct);
        assert_eq!(open(&key(), &parts.join(".")), Err("jwe_auth"));
    }

    #[test]
    fn foreign_algorithms_and_shapes_are_refused() {
        let header = URL_SAFE_NO_PAD.encode(r#"{"alg":"RSA-OAEP","enc":"A256GCM"}"#);
        assert_eq!(open(&key(), &format!("{header}..x.y.z")), Err("jwe_algorithm"));
        assert_eq!(open(&key(), "a.b.c"), Err("jwe_format"));
        assert_eq!(open(&key(), "a..b.c.d"), Err("jwe_format"));
    }
}
