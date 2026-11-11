//! RFC 6238 TOTP (HMAC-SHA1, 6 digits, 30 s steps) for staff two-factor sign-in.

use data_encoding::BASE32_NOPAD;
use hmac::{Hmac, Mac};
use rand::{RngCore, rngs::OsRng};
use sha1::Sha1;
use subtle::ConstantTimeEq;

pub const STEP_SECS: i64 = 30;
pub const DIGITS: u32 = 6;
/// Accept the previous and next step to absorb clock drift.
const WINDOW: i64 = 1;
/// 160-bit secret, the HMAC-SHA1 block-friendly size RFC 4226 recommends.
const SECRET_BYTES: usize = 20;

pub fn new_secret() -> Vec<u8> {
    let mut s = vec![0u8; SECRET_BYTES];
    OsRng.fill_bytes(&mut s);
    s
}

/// Six-digit code for one counter value (RFC 4226 dynamic truncation).
pub fn code_at(secret: &[u8], counter: u64) -> u32 {
    let mut mac = Hmac::<Sha1>::new_from_slice(secret).expect("HMAC accepts any key length");
    mac.update(&counter.to_be_bytes());
    let digest = mac.finalize().into_bytes();
    let offset = (digest[digest.len() - 1] & 0x0f) as usize;
    let bin = u32::from_be_bytes([digest[offset] & 0x7f, digest[offset + 1], digest[offset + 2], digest[offset + 3]]);
    bin % 10u32.pow(DIGITS)
}

/// Checks a submitted code against the window around `now` (unix seconds).
/// Returns the matched step so the caller can refuse the same step twice (replay).
/// `last_step` is the newest step already accepted for this secret.
pub fn verify(secret: &[u8], code: &str, now: i64, last_step: Option<i64>) -> Option<i64> {
    if code.len() != DIGITS as usize || !code.bytes().all(|b| b.is_ascii_digit()) {
        return None;
    }
    let current = now.div_euclid(STEP_SECS);
    (current - WINDOW..=current + WINDOW)
        .filter(|step| *step >= 0 && last_step.is_none_or(|last| *step > last))
        .find(|step| {
            let expected = format!("{:0width$}", code_at(secret, *step as u64), width = DIGITS as usize);
            bool::from(expected.as_bytes().ct_eq(code.as_bytes()))
        })
}

/// Base32 secret as shown to the user and in the QR code.
pub fn encode_secret(secret: &[u8]) -> String {
    BASE32_NOPAD.encode(secret)
}

pub fn decode_secret(encoded: &str) -> Option<Vec<u8>> {
    BASE32_NOPAD.decode(encoded.as_bytes()).ok()
}

/// `otpauth://` URI for authenticator apps. Labels are percent-encoded by the caller.
pub fn otpauth_uri(issuer: &str, account: &str, secret: &[u8]) -> String {
    let enc = |s: &str| s.bytes().map(|b| if b.is_ascii_alphanumeric() || b"-._~".contains(&b) { (b as char).to_string() } else { format!("%{b:02X}") }).collect::<String>();
    format!(
        "otpauth://totp/{}:{}?secret={}&issuer={}&algorithm=SHA1&digits={DIGITS}&period={STEP_SECS}",
        enc(issuer),
        enc(account),
        encode_secret(secret),
        enc(issuer)
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    /// RFC 6238 appendix B, SHA1 seed "12345678901234567890"; 8-digit values truncated to 6.
    const SEED: &[u8] = b"12345678901234567890";

    #[test]
    fn matches_rfc6238_vectors() {
        assert_eq!(code_at(SEED, 1), 287082, "T=59");
        assert_eq!(code_at(SEED, 37037036), 81804, "T=1111111109 (8-digit 07081804)");
    }

    #[test]
    fn accepts_adjacent_steps_and_rejects_far_ones() {
        let now = 59;
        assert!(verify(SEED, "287082", now, None).is_some());
        assert!(verify(SEED, &format!("{:06}", code_at(SEED, 0)), now, None).is_some(), "previous step");
        assert!(verify(SEED, &format!("{:06}", code_at(SEED, 5)), now, None).is_none(), "far step");
    }

    #[test]
    fn same_step_cannot_be_used_twice() {
        let now = 59;
        let step = verify(SEED, "287082", now, None).expect("first use");
        assert_eq!(verify(SEED, "287082", now, Some(step)), None, "replay refused");
    }

    #[test]
    fn malformed_codes_are_refused() {
        for bad in ["", "12345", "1234567", "28708a", " 287082"] {
            assert_eq!(verify(SEED, bad, 59, None), None, "{bad:?}");
        }
    }

    #[test]
    fn secret_roundtrip_and_uri() {
        let secret = new_secret();
        assert_eq!(decode_secret(&encode_secret(&secret)).as_deref(), Some(secret.as_slice()));
        let uri = otpauth_uri("Malkkeum", "a@b.kr", SEED);
        assert!(uri.starts_with("otpauth://totp/Malkkeum:a%40b.kr?secret="));
        assert!(uri.contains("digits=6&period=30"));
    }
}
