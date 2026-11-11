//! Regular cleaning subscriptions: visit schedule, per-visit price, charge retry policy, MRR and churn.
//! Pure and deterministic. Money is integer won; dates are KST calendar dates chosen by the caller.

use crate::DomainError;
use chrono::{Datelike, Duration, NaiveDate, Weekday};
use serde::{Deserialize, Serialize};

/// Visits are generated this many days ahead of "today".
pub const HORIZON_DAYS: i64 = 28;
/// The owner's discount cannot exceed this, so a subscription never sells below cost by accident.
pub const MAX_DISCOUNT_PERCENT: u8 = 30;
/// Consecutive declined charges before the subscription is paused for payment.
pub const PAUSE_AFTER_FAILURES: u32 = 3;
/// Hours between charge attempts for the same visit while the subscription is not paused.
pub const RETRY_AFTER_HOURS: i64 = 6;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Cadence {
    Weekly,
    Biweekly,
    Every4Weeks,
}

impl Cadence {
    pub const fn weeks(self) -> i64 {
        match self {
            Self::Weekly => 1,
            Self::Biweekly => 2,
            Self::Every4Weeks => 4,
        }
    }

    /// The customer-facing cadence in weeks: only 1, 2 and 4 are offered.
    pub fn from_weeks(weeks: i64) -> Result<Self, DomainError> {
        match weeks {
            1 => Ok(Self::Weekly),
            2 => Ok(Self::Biweekly),
            4 => Ok(Self::Every4Weeks),
            _ => Err(DomainError::OutOfRange("cadence_weeks")),
        }
    }
}

/// The owner's subscription settings (stored under the `subscription_policy` setting key).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
pub struct Policy {
    #[serde(default)]
    pub discount_percent: u8,
}

impl Policy {
    pub fn validate(&self) -> Result<(), DomainError> {
        if self.discount_percent > MAX_DISCOUNT_PERCENT {
            Err(DomainError::OutOfRange("discount_percent"))
        } else {
            Ok(())
        }
    }
}

/// Weekday from the 0 = Monday convention the partner prefs and the apps use.
pub fn weekday_from_index(index: u8) -> Result<Weekday, DomainError> {
    Weekday::try_from(index).map_err(|_| DomainError::OutOfRange("weekday"))
}

/// The first `weekday` on or after `earliest` (at most six days later).
pub fn first_visit(earliest: NaiveDate, weekday: Weekday) -> NaiveDate {
    let ahead = i64::from(weekday.num_days_from_monday()) - i64::from(earliest.weekday().num_days_from_monday());
    earliest + Duration::days(ahead.rem_euclid(7))
}

/// Visit dates of a subscription anchored at `anchor`, inside `[from, until]`, in order.
pub fn visit_dates(anchor: NaiveDate, cadence: Cadence, from: NaiveDate, until: NaiveDate) -> Vec<NaiveDate> {
    let step = cadence.weeks() * 7;
    let mut date = anchor;
    if from > anchor {
        let periods = (from - anchor).num_days().div_ceil(step);
        date = anchor + Duration::days(periods * step);
    }
    let mut out = Vec::new();
    while date <= until {
        out.push(date);
        date += Duration::days(step);
    }
    out
}

/// Per-visit price after the owner's discount. Rounds the discount down to the won.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
pub struct VisitPrice {
    pub discount: i64,
    pub total: i64,
}

pub fn visit_price(list: i64, discount_percent: u8) -> Result<VisitPrice, DomainError> {
    if discount_percent > MAX_DISCOUNT_PERCENT {
        return Err(DomainError::OutOfRange("discount_percent"));
    }
    let list = list.max(0);
    let discount = list * i64::from(discount_percent) / 100;
    Ok(VisitPrice { discount, total: list - discount })
}

/// Monthly recurring revenue of one subscription: per-visit price times visits per month (52 / 12 / weeks), rounded.
pub fn monthly_equivalent(per_visit: i64, cadence: Cadence) -> i64 {
    let num = per_visit.max(0) * 52;
    let den = 12 * cadence.weeks();
    (num + den / 2) / den
}

/// Days a subscription was live inside `[month_start, month_end]`. `ended` is the last live day (inclusive),
/// `None` while still active.
pub fn active_days(started: NaiveDate, ended: Option<NaiveDate>, month_start: NaiveDate, month_end: NaiveDate) -> u32 {
    let from = started.max(month_start);
    let to = ended.map_or(month_end, |e| e.min(month_end));
    if to < from { 0 } else { ((to - from).num_days() + 1) as u32 }
}

/// Share of a monthly amount for `active_days` of `days_in_month`, rounded half up to the won.
pub fn prorate(monthly: i64, active_days: u32, days_in_month: u32) -> i64 {
    if days_in_month == 0 {
        return 0;
    }
    let days = i64::from(active_days.min(days_in_month));
    let dim = i64::from(days_in_month);
    (2 * monthly * days + dim) / (2 * dim)
}

/// What to do after a declined charge.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Retry {
    After { hours: i64 },
    Pause,
}

/// `consecutive_failures` counts declines since the last successful charge, including the one just seen.
pub fn after_failure(consecutive_failures: u32) -> Retry {
    if consecutive_failures >= PAUSE_AFTER_FAILURES {
        Retry::Pause
    } else {
        Retry::After { hours: RETRY_AFTER_HOURS }
    }
}

/// Churn in basis points: subscriptions cancelled in the period over those active at its start. None without a base.
pub fn churn_bps(active_at_start: u32, cancelled_in_period: u32) -> Option<i64> {
    if active_at_start == 0 {
        None
    } else {
        Some(i64::from(cancelled_in_period) * 10_000 / i64::from(active_at_start))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn d(y: i32, m: u32, day: u32) -> NaiveDate {
        NaiveDate::from_ymd_opt(y, m, day).unwrap()
    }

    /// Every day of 2026 and 2027 as a deterministic sweep (no RNG, so failures reproduce).
    fn days() -> impl Iterator<Item = NaiveDate> {
        let start = d(2026, 1, 1);
        (0..730).map(move |i| start + Duration::days(i))
    }

    #[test]
    fn cadence_weeks_round_trip() {
        for c in [Cadence::Weekly, Cadence::Biweekly, Cadence::Every4Weeks] {
            assert_eq!(Cadence::from_weeks(c.weeks()), Ok(c));
        }
        assert_eq!(Cadence::from_weeks(3), Err(DomainError::OutOfRange("cadence_weeks")));
    }

    #[test]
    fn first_visit_is_the_requested_weekday_within_six_days() {
        for earliest in days() {
            for wd in 0..7u8 {
                let weekday = weekday_from_index(wd).unwrap();
                let v = first_visit(earliest, weekday);
                assert_eq!(v.weekday(), weekday, "{earliest} -> {v}");
                assert!(v >= earliest && (v - earliest).num_days() <= 6, "{earliest} -> {v}");
            }
        }
    }

    #[test]
    fn weekday_index_is_monday_based() {
        assert_eq!(weekday_from_index(0), Ok(Weekday::Mon));
        assert_eq!(weekday_from_index(6), Ok(Weekday::Sun));
        assert!(weekday_from_index(7).is_err());
    }

    #[test]
    fn visits_step_by_cadence_and_stay_in_window() {
        let anchor = d(2026, 11, 16); // a Monday
        assert_eq!(visit_dates(anchor, Cadence::Weekly, d(2026, 11, 1), d(2026, 11, 30)), vec![d(2026, 11, 16), d(2026, 11, 23), d(2026, 11, 30)]);
        assert_eq!(visit_dates(anchor, Cadence::Biweekly, d(2026, 11, 17), d(2026, 12, 15)), vec![d(2026, 11, 30), d(2026, 12, 14)]);
        assert_eq!(visit_dates(anchor, Cadence::Every4Weeks, d(2026, 11, 1), d(2026, 12, 31)), vec![d(2026, 11, 16), d(2026, 12, 14)]);
        assert!(visit_dates(anchor, Cadence::Weekly, d(2026, 12, 1), d(2026, 11, 1)).is_empty());
    }

    #[test]
    fn visit_schedule_properties_hold_for_every_cadence_and_window() {
        for cadence in [Cadence::Weekly, Cadence::Biweekly, Cadence::Every4Weeks] {
            let step = cadence.weeks() * 7;
            for anchor_offset in (0..400).step_by(13) {
                let anchor = d(2026, 1, 1) + Duration::days(anchor_offset);
                for from_offset in (0..420).step_by(29) {
                    let from = d(2026, 1, 1) + Duration::days(from_offset);
                    let until = from + Duration::days(HORIZON_DAYS);
                    let got = visit_dates(anchor, cadence, from, until);
                    assert!(got.iter().all(|v| *v >= from && *v <= until), "window {from}..{until}: {got:?}");
                    assert!(got.iter().all(|v| (*v - anchor).num_days().rem_euclid(step) == 0), "off-cadence: {got:?}");
                    assert!(got.windows(2).all(|w| (w[1] - w[0]).num_days() == step), "gap: {got:?}");
                    // Nothing on the cadence inside the window is missed.
                    let expected = (0..=HORIZON_DAYS).map(|i| from + Duration::days(i)).filter(|v| (*v - anchor).num_days() >= 0 && (*v - anchor).num_days().rem_euclid(step) == 0).count();
                    assert_eq!(got.len(), expected, "anchor {anchor} window {from}");
                }
            }
        }
    }

    #[test]
    fn visit_price_discounts_and_bounds() {
        assert_eq!(visit_price(50_000, 0), Ok(VisitPrice { discount: 0, total: 50_000 }));
        assert_eq!(visit_price(50_000, 10), Ok(VisitPrice { discount: 5_000, total: 45_000 }));
        // Rounds the discount down: 10% of 12_345 is 1_234.5 -> 1_234.
        assert_eq!(visit_price(12_345, 10).unwrap().discount, 1_234);
        assert_eq!(visit_price(50_000, 31), Err(DomainError::OutOfRange("discount_percent")));
        for list in (0..200_000).step_by(997) {
            for pct in 0..=MAX_DISCOUNT_PERCENT {
                let p = visit_price(list, pct).unwrap();
                assert_eq!(p.total + p.discount, list);
                assert!(p.discount >= 0 && p.total >= 0);
            }
        }
    }

    #[test]
    fn monthly_equivalent_matches_visits_per_month() {
        assert_eq!(monthly_equivalent(50_000, Cadence::Weekly), 216_667); // 52 / 12 visits
        assert_eq!(monthly_equivalent(50_000, Cadence::Biweekly), 108_333);
        assert_eq!(monthly_equivalent(50_000, Cadence::Every4Weeks), 54_167);
        for per_visit in (0..300_000).step_by(1_000) {
            assert!(monthly_equivalent(per_visit, Cadence::Weekly) >= monthly_equivalent(per_visit, Cadence::Biweekly));
            assert!(monthly_equivalent(per_visit, Cadence::Biweekly) >= monthly_equivalent(per_visit, Cadence::Every4Weeks));
        }
    }

    #[test]
    fn prorated_parts_never_exceed_the_month() {
        let (ms, me) = (d(2026, 2, 1), d(2026, 2, 28));
        assert_eq!(prorate(280_000, 28, 28), 280_000);
        assert_eq!(prorate(280_000, 14, 28), 140_000);
        assert_eq!(prorate(100, 0, 28), 0);
        assert_eq!(prorate(100, 1, 0), 0);
        let mut last = 0;
        for used in 0..=28u32 {
            let part = prorate(280_000, used, 28);
            assert!(part >= last && part <= 280_000, "not monotone at {used}");
            last = part;
        }
        // Active window math agrees with the calendar.
        assert_eq!(active_days(d(2026, 2, 10), None, ms, me), 19);
        assert_eq!(active_days(d(2026, 1, 1), Some(d(2026, 2, 5)), ms, me), 5);
        assert_eq!(active_days(d(2026, 3, 1), None, ms, me), 0);
        assert_eq!(active_days(d(2025, 1, 1), Some(d(2025, 1, 2)), ms, me), 0);
    }

    #[test]
    fn active_days_partition_a_month_when_a_subscription_moves_between_months() {
        // A sub ending on day N of a month and the next one starting on N+1 cover every day once.
        for end in 1..28u32 {
            let ended = d(2026, 3, end);
            let a = active_days(d(2026, 1, 1), Some(ended), d(2026, 3, 1), d(2026, 3, 31));
            let b = active_days(ended + Duration::days(1), None, d(2026, 3, 1), d(2026, 3, 31));
            assert_eq!(a + b, 31, "end {ended}");
        }
    }

    #[test]
    fn failures_retry_then_pause() {
        assert_eq!(after_failure(1), Retry::After { hours: RETRY_AFTER_HOURS });
        assert_eq!(after_failure(PAUSE_AFTER_FAILURES - 1), Retry::After { hours: RETRY_AFTER_HOURS });
        assert_eq!(after_failure(PAUSE_AFTER_FAILURES), Retry::Pause);
        assert_eq!(after_failure(9), Retry::Pause);
    }

    #[test]
    fn churn_needs_a_base() {
        assert_eq!(churn_bps(0, 3), None);
        assert_eq!(churn_bps(200, 10), Some(500)); // 5.00%
        assert_eq!(churn_bps(50, 0), Some(0));
    }

    #[test]
    fn policy_bounds() {
        assert!(Policy::default().validate().is_ok());
        assert!(Policy { discount_percent: MAX_DISCOUNT_PERCENT }.validate().is_ok());
        assert!(Policy { discount_percent: MAX_DISCOUNT_PERCENT + 1 }.validate().is_err());
    }
}
