//! 현금영수증 rules: which payments may carry one and how the customer identity is checked. Pure.
//! ACCOUNTANT: mandatory issuance (의무발행) applies to cash-type sales by listed businesses; confirm the
//! industry list covers cleaning services before relying on `MANDATORY_ISSUE_MIN`.

use crate::{DomainError, Won};

/// 의무발행 threshold: cash-type sales of this amount or more must be receipted (소득세법 시행령; ACCOUNTANT: confirm).
pub const MANDATORY_ISSUE_MIN: Won = Won(100_000);

/// Payment methods a 현금영수증 can be issued for (bank transfer and virtual account, per `routes/payments.rs::METHODS`).
pub fn cash_eligible(method: &str) -> bool {
    matches!(method, "transfer" | "virtual_account")
}

/// Strips the separators customers type (spaces and hyphens) and keeps the digits only.
fn digits(raw: &str) -> String {
    raw.chars().filter(|c| !c.is_whitespace() && *c != '-').collect()
}

/// 휴대폰번호 for 소득공제용: 01[016789] followed by 7 or 8 digits.
pub fn normalize_phone(raw: &str) -> Result<String, DomainError> {
    let d = digits(raw);
    let ok = d.len() >= 10 && d.len() <= 11 && d.starts_with("01") && d.bytes().all(|b| b.is_ascii_digit()) && matches!(d.as_bytes()[2], b'0' | b'1' | b'6' | b'7' | b'8' | b'9');
    if ok { Ok(d) } else { Err(DomainError::OutOfRange("phone")) }
}

/// 사업자등록번호 for 지출증빙용: 10 digits with the official check digit.
pub fn normalize_business_number(raw: &str) -> Result<String, DomainError> {
    let d = digits(raw);
    if d.len() != 10 || !d.bytes().all(|b| b.is_ascii_digit()) {
        return Err(DomainError::OutOfRange("business_number"));
    }
    let v: Vec<u32> = d.bytes().map(|b| u32::from(b - b'0')).collect();
    const WEIGHTS: [u32; 9] = [1, 3, 7, 1, 3, 7, 1, 3, 5];
    let mut sum: u32 = (0..9).map(|i| v[i] * WEIGHTS[i]).sum();
    sum += v[8] * 5 / 10;
    if (10 - sum % 10) % 10 == v[9] { Ok(d) } else { Err(DomainError::OutOfRange("business_number")) }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn phone_accepts_hyphenated_mobile_numbers() {
        assert_eq!(normalize_phone("010-1234-5678").unwrap(), "01012345678");
        assert_eq!(normalize_phone("01012345678").unwrap(), "01012345678");
        assert_eq!(normalize_phone("011 123 4567").unwrap(), "0111234567");
    }

    #[test]
    fn phone_rejects_landlines_and_garbage() {
        assert!(normalize_phone("02-123-4567").is_err());
        assert!(normalize_phone("010-12").is_err());
        assert!(normalize_phone("010abc45678").is_err());
    }

    #[test]
    fn business_number_checks_the_check_digit() {
        // Published sample number with a valid check digit.
        assert_eq!(normalize_business_number("220-81-62517").unwrap(), "2208162517");
        assert!(normalize_business_number("220-81-62518").is_err());
        assert!(normalize_business_number("220-81-6251").is_err());
    }

    #[test]
    fn only_bank_transfer_and_virtual_account_are_cash_eligible() {
        assert!(cash_eligible("transfer"));
        assert!(cash_eligible("virtual_account"));
        assert!(!cash_eligible("card"));
        assert!(!cash_eligible("kakaopay"));
    }
}
