//! Malkkeum points: a loyalty programme, NOT stored value. There is no cash top-up, so points
//! are never prepaid e-money (선불전자지급수단). See docs/finance-tax.md.
//! Pure functions: the API passes the ledger facts and "now" in, gets amounts out.

use crate::{DomainError, Won};
use chrono::{DateTime, Duration, Utc};
use serde::{Deserialize, Serialize};

pub const DEFAULT_EXPIRY_DAYS: i64 = 365;
pub const DEFAULT_NOTIFY_DAYS: i64 = 30;
const MAX_EARN_BPS: i64 = 1_000;
const MAX_EXPIRY_DAYS: i64 = 1_825;
const MAX_USE_BPS: i64 = 10_000;
const MAX_GRANT: i64 = 100_000;

/// Owner-configured programme. Off by default; amounts are whole points (1 point = 1 won).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct PointsPolicy {
    pub enabled: bool,
    /// Cashback on cash actually paid for a completed booking, in basis points.
    pub earn_bps: i64,
    pub welcome_points: i64,
    pub referral_points: i64,
    pub expiry_days: i64,
    pub notify_days: i64,
    /// Largest share of a booking total that points may cover, in basis points.
    pub max_use_bps: i64,
}

impl Default for PointsPolicy {
    fn default() -> Self {
        Self {
            enabled: false,
            earn_bps: 100,
            welcome_points: 3_000,
            referral_points: 3_000,
            expiry_days: DEFAULT_EXPIRY_DAYS,
            notify_days: DEFAULT_NOTIFY_DAYS,
            max_use_bps: MAX_USE_BPS,
        }
    }
}

impl PointsPolicy {
    pub fn validate(&self) -> Result<(), DomainError> {
        let checks = [
            ((0..=MAX_EARN_BPS).contains(&self.earn_bps), "points_earn_bps"),
            ((0..=MAX_GRANT).contains(&self.welcome_points), "points_welcome"),
            ((0..=MAX_GRANT).contains(&self.referral_points), "points_referral"),
            ((1..=MAX_EXPIRY_DAYS).contains(&self.expiry_days), "points_expiry_days"),
            ((1..=self.expiry_days).contains(&self.notify_days), "points_notify_days"),
            ((0..=MAX_USE_BPS).contains(&self.max_use_bps), "points_max_use_bps"),
        ];
        match checks.iter().find(|(ok, _)| !ok) {
            Some(&(_, field)) => Err(DomainError::OutOfRange(field)),
            None => Ok(()),
        }
    }

    /// Lifetime of a newly issued lot, counted from issue time.
    pub fn expires_at(&self, issued: DateTime<Utc>) -> DateTime<Utc> {
        issued + Duration::days(self.expiry_days)
    }
}

/// Cashback on the cash the customer actually paid. Points used to pay are never re-earned.
pub fn cashback(cash_paid: Won, earn_bps: i64) -> i64 {
    cash_paid.times_bps(earn_bps).0.max(0)
}

/// One issued lot of points (an earn, welcome, referral, refund or grant row). Consumption
/// (spend, expiry, deduction) is summed from later rows that point at the lot.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Lot<K> {
    pub id: K,
    pub issued: i64,
    pub consumed: i64,
    pub expires_at: DateTime<Utc>,
}

impl<K> Lot<K> {
    pub fn remaining(&self) -> i64 {
        self.issued - self.consumed
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PointsError {
    Insufficient { available: i64 },
    OverCap { cap: i64 },
    NonPositive,
}

impl PointsError {
    pub fn code(self) -> &'static str {
        match self {
            Self::Insufficient { .. } => "points_insufficient",
            Self::OverCap { .. } => "points_over_cap",
            Self::NonPositive => "points_non_positive",
        }
    }
}

/// Points that can still be spent: live lots only, expired ones are gone.
pub fn available<K>(lots: &[Lot<K>], now: DateTime<Utc>) -> i64 {
    lots.iter().filter(|l| l.expires_at > now).map(Lot::remaining).sum()
}

/// Points that lapse within `days` (and are still live): drives the "expiring soon" banner.
pub fn expiring_within<K>(lots: &[Lot<K>], now: DateTime<Utc>, days: i64) -> i64 {
    let horizon = now + Duration::days(days);
    lots.iter().filter(|l| l.expires_at > now && l.expires_at <= horizon).map(Lot::remaining).sum()
}

/// Spends `amount` from live lots, soonest-expiring first (FIFO by expiry). Returns one
/// allocation per lot used; the caller writes one spend row per allocation.
pub fn allocate<K: Copy>(lots: &[Lot<K>], amount: i64, now: DateTime<Utc>) -> Result<Vec<(K, i64)>, PointsError> {
    if amount <= 0 {
        return Err(PointsError::NonPositive);
    }
    let mut live: Vec<&Lot<K>> = lots.iter().filter(|l| l.expires_at > now && l.remaining() > 0).collect();
    live.sort_by_key(|l| l.expires_at);
    let total: i64 = live.iter().map(|l| l.remaining()).sum();
    if total < amount {
        return Err(PointsError::Insufficient { available: total });
    }
    let mut left = amount;
    let mut out = Vec::new();
    for lot in live {
        if left == 0 {
            break;
        }
        let take = lot.remaining().min(left);
        out.push((lot.id, take));
        left -= take;
    }
    Ok(out)
}

/// Lots past their expiry that still hold points: the expiry job writes one `expire` row each.
pub fn lapsed<K: Copy>(lots: &[Lot<K>], now: DateTime<Utc>) -> Vec<(K, i64)> {
    lots.iter().filter(|l| l.expires_at <= now && l.remaining() > 0).map(|l| (l.id, l.remaining())).collect()
}

/// How a booking total is paid: points first (capped), the rest through the PG.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Split {
    pub points: i64,
    pub pg: Won,
}

/// Validates a customer's request to pay `requested` points toward `total`. Asking for more
/// than they hold or more than the owner's cap is refused (never silently reduced).
pub fn split_payment(total: Won, requested: i64, available: i64, max_use_bps: i64) -> Result<Split, PointsError> {
    if requested < 0 {
        return Err(PointsError::NonPositive);
    }
    if requested == 0 {
        return Ok(Split { points: 0, pg: total });
    }
    let cap = total.times_bps(max_use_bps).0;
    if requested > cap {
        return Err(PointsError::OverCap { cap });
    }
    if requested > available {
        return Err(PointsError::Insufficient { available });
    }
    Ok(Split { points: requested, pg: Won(total.0 - requested) })
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    fn at(day: i64) -> DateTime<Utc> {
        Utc.with_ymd_and_hms(2026, 1, 1, 0, 0, 0).unwrap() + Duration::days(day)
    }

    fn lot(id: u8, issued: i64, consumed: i64, expires_day: i64) -> Lot<u8> {
        Lot { id, issued, consumed, expires_at: at(expires_day) }
    }

    #[test]
    fn cashback_is_rounded_on_cash_paid_only() {
        assert_eq!(cashback(Won(52_000), 100), 520);
        assert_eq!(cashback(Won(0), 500), 0);
        assert_eq!(cashback(Won(47_000), 0), 0, "owner switched cashback off");
    }

    #[test]
    fn balance_excludes_expired_lots() {
        let lots = [lot(1, 1_000, 0, 10), lot(2, 500, 200, 100)];
        assert_eq!(available(&lots, at(5)), 1_300);
        assert_eq!(available(&lots, at(10)), 300, "lot 1 lapses at its expiry instant");
    }

    #[test]
    fn expiring_soon_counts_only_the_notify_window() {
        let lots = [lot(1, 1_000, 0, 20), lot(2, 500, 0, 60)];
        assert_eq!(expiring_within(&lots, at(0), 30), 1_000);
        assert_eq!(expiring_within(&lots, at(0), 90), 1_500);
    }

    #[test]
    fn spend_takes_soonest_expiring_lots_first() {
        let lots = [lot(1, 1_000, 0, 50), lot(2, 800, 0, 20), lot(3, 500, 0, 90)];
        let got = allocate(&lots, 1_500, at(0)).unwrap();
        assert_eq!(got, vec![(2, 800), (1, 700)]);
    }

    #[test]
    fn spend_never_uses_expired_or_empty_lots() {
        let lots = [lot(1, 1_000, 1_000, 50), lot(2, 800, 0, 10)];
        assert_eq!(allocate(&lots, 800, at(10)), Err(PointsError::Insufficient { available: 0 }));
        assert_eq!(allocate(&lots, 0, at(0)), Err(PointsError::NonPositive));
    }

    #[test]
    fn spend_refuses_more_than_available() {
        let lots = [lot(1, 300, 0, 50)];
        assert_eq!(allocate(&lots, 301, at(0)), Err(PointsError::Insufficient { available: 300 }));
    }

    #[test]
    fn expiry_writes_only_the_unspent_remainder() {
        let lots = [lot(1, 1_000, 400, 10), lot(2, 500, 0, 10), lot(3, 900, 0, 99)];
        assert_eq!(lapsed(&lots, at(10)), vec![(1, 600), (2, 500)]);
        assert!(lapsed(&lots, at(9)).is_empty());
    }

    #[test]
    fn split_pays_points_first_and_the_rest_by_pg() {
        let s = split_payment(Won(52_000), 10_000, 20_000, 10_000).unwrap();
        assert_eq!(s, Split { points: 10_000, pg: Won(42_000) });
        assert_eq!(split_payment(Won(52_000), 0, 20_000, 10_000).unwrap().pg, Won(52_000));
    }

    #[test]
    fn split_refuses_over_balance_and_over_cap() {
        assert_eq!(split_payment(Won(52_000), 9_000, 8_000, 10_000), Err(PointsError::Insufficient { available: 8_000 }));
        assert_eq!(split_payment(Won(52_000), 20_000, 90_000, 3_000), Err(PointsError::OverCap { cap: 15_600 }));
        assert_eq!(split_payment(Won(52_000), -1, 0, 10_000), Err(PointsError::NonPositive));
    }

    #[test]
    fn policy_defaults_are_off_with_one_year_expiry_and_30_day_notice() {
        let p = PointsPolicy::default();
        assert!(!p.enabled);
        assert_eq!((p.expiry_days, p.notify_days), (365, 30));
        assert!(p.validate().is_ok());
        assert!(PointsPolicy { earn_bps: 1_001, ..p }.validate().is_err());
        assert!(PointsPolicy { notify_days: 366, ..p }.validate().is_err(), "notice cannot exceed lifetime");
    }
}
