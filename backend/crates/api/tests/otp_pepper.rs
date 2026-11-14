//! Login-code hashes: OTP_PEPPER is the primary key for new codes, and jwt_secret still verifies codes
//! issued before the pepper was set.

mod common;

use api::auth;
use common::test_config;

const PHONE: &str = "01012345678";
const PEPPER: &[u8] = b"otp-pepper-otp-pepper-otp-pepper-0000";

#[test]
fn new_codes_use_the_pepper_and_old_codes_still_verify() {
    let mut cfg = test_config();
    let old = auth::otp_hash(&cfg.jwt_secret, PHONE, "123456");
    assert_eq!(cfg.otp_key(), cfg.jwt_secret.as_slice(), "without a pepper the jwt secret is the key");

    cfg.otp_pepper = Some(PEPPER.to_vec());
    assert_eq!(cfg.otp_key(), PEPPER, "new codes are hashed with the pepper");
    assert_ne!(auth::otp_hash(cfg.otp_key(), PHONE, "123456"), old, "pepper changes the digest");

    let verifies = cfg.otp_keys().into_iter().any(|key| auth::otp_hash(key, PHONE, "123456") == old);
    assert!(verifies, "a code hashed with jwt_secret before the rollout still verifies");
    assert_eq!(cfg.otp_keys().len(), 2);
}

#[test]
fn wrong_code_matches_no_key() {
    let mut cfg = test_config();
    cfg.otp_pepper = Some(PEPPER.to_vec());
    let stored = auth::otp_hash(cfg.otp_key(), PHONE, "123456");
    let matches = cfg.otp_keys().into_iter().any(|key| auth::otp_hash(key, PHONE, "654321") == stored);
    assert!(!matches);
}
