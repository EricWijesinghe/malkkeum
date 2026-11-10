use crate::{DomainError, Won};
use chrono::{DateTime, Duration, Utc};
use serde::{Deserialize, Serialize};

/// Spec rule 5: every coupon lives 14 days from issue.
pub const COUPON_LIFETIME_DAYS: i64 = 14;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Coupon {
    pub amount: Won,
    /// `None` = any service.
    pub service_code: Option<String>,
    pub issued_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
    pub used: bool,
}

impl Coupon {
    pub fn issue(amount: Won, service_code: Option<String>, now: DateTime<Utc>) -> Self {
        Self { amount, service_code, issued_at: now, expires_at: now + Duration::days(COUPON_LIFETIME_DAYS), used: false }
    }

    pub fn check(&self, service_code: &str, now: DateTime<Utc>) -> Result<(), DomainError> {
        if self.used {
            return Err(DomainError::CouponUsed);
        }
        if now >= self.expires_at {
            return Err(DomainError::CouponExpired);
        }
        match &self.service_code {
            Some(code) if code != service_code => Err(DomainError::CouponWrongService),
            _ => Ok(()),
        }
    }

    /// Discount is capped at the price so a total never goes negative.
    pub fn discount_for(&self, price: Won, service_code: &str, now: DateTime<Utc>) -> Result<Won, DomainError> {
        self.check(service_code, now)?;
        Ok(self.amount.min(price))
    }
}

/// The once-per-account welcome pack (studio 10,000 + any service 5,000).
pub fn welcome_pack(now: DateTime<Utc>) -> [Coupon; 2] {
    [Coupon::issue(Won(10_000), Some("studio".into()), now), Coupon::issue(Won(5_000), None, now)]
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    fn now() -> DateTime<Utc> {
        Utc.with_ymd_and_hms(2026, 11, 10, 3, 0, 0).unwrap()
    }

    #[test]
    fn caps_discount_at_price() {
        let c = Coupon::issue(Won(10_000), None, now());
        assert_eq!(c.discount_for(Won(7_000), "kitchen", now()), Ok(Won(7_000)));
    }

    #[test]
    fn rejects_wrong_service_used_and_expired() {
        let [studio, any] = welcome_pack(now());
        assert_eq!(studio.check("bathroom", now()), Err(DomainError::CouponWrongService));
        assert!(any.check("bathroom", now()).is_ok());
        let used = Coupon { used: true, ..any.clone() };
        assert_eq!(used.check("bathroom", now()), Err(DomainError::CouponUsed));
        assert_eq!(any.check("bathroom", now() + Duration::days(14)), Err(DomainError::CouponExpired));
        assert!(any.check("bathroom", now() + Duration::days(13)).is_ok());
    }
}
