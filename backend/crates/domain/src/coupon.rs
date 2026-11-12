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
        Self {
            amount,
            service_code,
            issued_at: now,
            expires_at: now + Duration::days(COUPON_LIFETIME_DAYS),
            used: false,
        }
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

/// Most coupons one sign-up may receive.
pub const MAX_WELCOME_COUPONS: usize = 3;
/// Most won one sign-up may receive across all its welcome coupons (also the largest single coupon).
pub const MAX_WELCOME_TOTAL: i64 = 50_000;
const DEFAULT_WELCOME_AMOUNT: i64 = 15_000;

/// One coupon of the welcome pack. `service_code: None` = any service.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct WelcomeCoupon {
    pub amount: Won,
    #[serde(default)]
    pub service_code: Option<String>,
}

/// Owner-configured coupons issued once per account at sign-up (setting `welcome_pack`).
/// An empty list switches the pack off.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(transparent)]
pub struct WelcomePack(pub Vec<WelcomeCoupon>);

impl Default for WelcomePack {
    /// One "first cleaning" coupon for any service.
    fn default() -> Self {
        Self(vec![WelcomeCoupon { amount: Won(DEFAULT_WELCOME_AMOUNT), service_code: None }])
    }
}

impl WelcomePack {
    /// Amounts are whole 100-won steps within bounds; the caller checks service codes against the catalogue.
    pub fn validate(&self) -> Result<(), DomainError> {
        if self.0.len() > MAX_WELCOME_COUPONS {
            return Err(DomainError::OutOfRange("welcome_pack"));
        }
        let ok = |c: &WelcomeCoupon| (1..=MAX_WELCOME_TOTAL).contains(&c.amount.0) && c.amount.round100() == c.amount;
        if !self.0.iter().all(ok) {
            return Err(DomainError::OutOfRange("welcome_amount"));
        }
        if self.0.iter().map(|c| c.amount.0).sum::<i64>() > MAX_WELCOME_TOTAL {
            return Err(DomainError::OutOfRange("welcome_total"));
        }
        Ok(())
    }

    /// The coupons one sign-up receives. Capped here too (count and total), so a setting stored
    /// before the caps, or edited by hand, can never issue more than one pack's worth.
    pub fn issue(&self, now: DateTime<Utc>) -> Vec<Coupon> {
        let mut total = 0i64;
        self.0
            .iter()
            .filter(|c| c.amount.0 > 0)
            .take(MAX_WELCOME_COUPONS)
            .take_while(|c| {
                total += c.amount.0;
                total <= MAX_WELCOME_TOTAL
            })
            .map(|c| Coupon::issue(c.amount, c.service_code.clone(), now))
            .collect()
    }
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
        let studio = Coupon::issue(Won(10_000), Some("studio".into()), now());
        let any = Coupon::issue(Won(5_000), None, now());
        assert_eq!(studio.check("bathroom", now()), Err(DomainError::CouponWrongService));
        assert!(any.check("bathroom", now()).is_ok());
        let used = Coupon { used: true, ..any.clone() };
        assert_eq!(used.check("bathroom", now()), Err(DomainError::CouponUsed));
        assert_eq!(any.check("bathroom", now() + Duration::days(14)), Err(DomainError::CouponExpired));
        assert!(any.check("bathroom", now() + Duration::days(13)).is_ok());
    }

    #[test]
    fn default_welcome_pack_is_one_15000_coupon_for_any_service() {
        let issued = WelcomePack::default().issue(now());
        assert_eq!(issued.len(), 1);
        assert_eq!((issued[0].amount, issued[0].service_code.clone()), (Won(15_000), None));
        assert_eq!(issued[0].expires_at, now() + Duration::days(COUPON_LIFETIME_DAYS));
        assert_eq!(serde_json::to_value(WelcomePack::default()).unwrap(), serde_json::json!([{ "amount": 15000, "service_code": null }]));
    }

    #[test]
    fn welcome_pack_bounds() {
        let pack = |amounts: &[i64]| WelcomePack(amounts.iter().map(|a| WelcomeCoupon { amount: Won(*a), service_code: None }).collect());
        assert!(pack(&[]).validate().is_ok(), "empty = switched off");
        assert!(pack(&[15_000, 35_000]).validate().is_ok(), "exactly the 50,000 total");
        assert!(pack(&[10_000; 3]).validate().is_ok(), "exactly three coupons");
        for bad in [0, -100, 15_050, 50_100, 100_000] {
            assert_eq!(pack(&[bad]).validate(), Err(DomainError::OutOfRange("welcome_amount")), "{bad}");
        }
        assert_eq!(pack(&[1_000; 4]).validate(), Err(DomainError::OutOfRange("welcome_pack")));
        assert_eq!(pack(&[30_000, 20_100]).validate(), Err(DomainError::OutOfRange("welcome_total")));
        let parsed: WelcomePack = serde_json::from_value(serde_json::json!([{ "amount": 7000 }])).unwrap();
        assert_eq!(parsed.0[0].service_code, None);
    }

    #[test]
    fn issue_caps_a_stored_pack_at_three_coupons_and_50000() {
        let pack = |amounts: &[i64]| WelcomePack(amounts.iter().map(|a| WelcomeCoupon { amount: Won(*a), service_code: None }).collect());
        let won = |p: WelcomePack| p.issue(now()).iter().map(|c| c.amount.0).collect::<Vec<_>>();
        // The old limit allowed 5 x 100,000; a pack stored back then issues nothing above the caps.
        assert_eq!(won(pack(&[100_000; 5])), Vec::<i64>::new());
        assert_eq!(won(pack(&[10_000; 5])), vec![10_000; 3]);
        assert_eq!(won(pack(&[20_000, 20_000, 20_000])), vec![20_000, 20_000]);
        assert_eq!(won(WelcomePack::default()), vec![15_000]);
    }
}
