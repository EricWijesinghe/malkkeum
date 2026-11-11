//! Cancellation and reschedule fee policy. Owner-configurable; the built-in default keeps the
//! original rule (free until 2 calendar days before the visit, later cancels go to staff).
//! Days are KST calendar days between today and the visit date, so the default matches the old rule exactly.

use serde::{Deserialize, Serialize};

/// Built-in default. Also read by `scripts/build_legal.py` so the terms page uses the same numbers.
pub const DEFAULT_JSON: &str = include_str!("cancel_policy_default.json");

pub const MAX_TIERS: usize = 10;
/// Rank of "closed" (no self-serve cancel): the most severe outcome, above any percent.
const CLOSED_RANK: u16 = 101;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
pub enum Outcome {
    Free,
    Fee { percent: u8 },
    /// Customer cannot cancel in-app; the consultation team handles it.
    Closed,
}

/// Applies when `days_before >= min_days`. `percent: None` means closed (staff only).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct Tier {
    pub min_days: i64,
    pub percent: Option<u8>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CancelPolicy {
    /// Strictly descending `min_days`. The first tier whose `min_days` is reached wins; none reached = closed.
    pub tiers: Vec<Tier>,
    /// Floor for any fee above 0 won (capped at what was paid).
    pub min_fee: i64,
    /// Reschedule is self-serve while `days_before >= reschedule_min_days`.
    pub reschedule_min_days: i64,
}

/// What a cancellation would cost now. `fee` and `refund` are 0 and `paid` only when the outcome is not closed.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
pub struct Quote {
    pub outcome: Outcome,
    pub paid: i64,
    pub fee: i64,
    pub refund: i64,
}

fn rank(percent: Option<u8>) -> u16 {
    percent.map_or(CLOSED_RANK, u16::from)
}

impl CancelPolicy {
    /// Checks shape and monotonicity: the closer to the visit, the higher (or equal) the penalty.
    pub fn validate(&self) -> Result<(), &'static str> {
        if self.tiers.is_empty() || self.tiers.len() > MAX_TIERS {
            return Err("invalid_policy");
        }
        if self.min_fee < 0 || !(0..=30).contains(&self.reschedule_min_days) {
            return Err("invalid_policy");
        }
        if self.tiers.iter().any(|t| t.percent.is_some_and(|p| p > 100)) {
            return Err("invalid_policy");
        }
        for pair in self.tiers.windows(2) {
            let (earlier, later) = (pair[0], pair[1]);
            if later.min_days >= earlier.min_days || rank(later.percent) < rank(earlier.percent) {
                return Err("invalid_policy");
            }
        }
        Ok(())
    }

    pub fn outcome(&self, days_before: i64) -> Outcome {
        let percent = self.tiers.iter().find(|t| days_before >= t.min_days).and_then(|t| t.percent);
        match percent {
            None => Outcome::Closed,
            Some(0) => Outcome::Free,
            Some(p) => Outcome::Fee { percent: p },
        }
    }

    /// Fee and refund for cancelling `paid` won, `days_before` days ahead. None when closed.
    pub fn quote(&self, days_before: i64, paid: i64) -> Option<Quote> {
        let paid = paid.max(0);
        let outcome = self.outcome(days_before);
        let fee = match outcome {
            Outcome::Closed => return None,
            Outcome::Free => 0,
            Outcome::Fee { percent } => (paid * i64::from(percent) / 100).max(self.min_fee).min(paid),
        };
        Some(Quote { outcome, paid, fee, refund: paid - fee })
    }

    pub fn reschedule_allowed(&self, days_before: i64) -> bool {
        days_before >= self.reschedule_min_days
    }
}

impl Default for CancelPolicy {
    fn default() -> Self {
        serde_json::from_str(DEFAULT_JSON).expect("built-in cancel policy is valid JSON")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn policy(tiers: &[(i64, Option<u8>)], min_fee: i64) -> CancelPolicy {
        CancelPolicy {
            tiers: tiers.iter().map(|&(min_days, percent)| Tier { min_days, percent }).collect(),
            min_fee,
            reschedule_min_days: 2,
        }
    }

    /// Small deterministic generator so the sweeps below need no extra crate.
    struct Rng(u64);
    impl Rng {
        fn next(&mut self) -> u64 {
            self.0 ^= self.0 << 13;
            self.0 ^= self.0 >> 7;
            self.0 ^= self.0 << 17;
            self.0
        }
        fn range(&mut self, lo: i64, hi: i64) -> i64 {
            lo + (self.next() % (hi - lo + 1) as u64) as i64
        }
    }

    /// Random policy shaped like the owner UI can produce: descending days, non-decreasing penalties.
    fn random_valid(rng: &mut Rng) -> CancelPolicy {
        let n = rng.range(1, 5) as usize;
        let mut days = rng.range(0, 10);
        let mut pct: u8 = 0;
        let mut tiers = Vec::new();
        for _ in 0..n {
            let closed = rng.range(0, 9) == 0;
            tiers.push((days, if closed { None } else { Some(pct) }));
            days -= rng.range(1, 4);
            if !closed {
                pct = (i64::from(pct) + rng.range(0, 40)).min(100) as u8;
            }
        }
        policy(&tiers, rng.range(0, 20_000))
    }

    #[test]
    fn default_keeps_the_old_rule() {
        let p = CancelPolicy::default();
        assert_eq!(p.validate(), Ok(()));
        assert_eq!(p.outcome(2), Outcome::Free);
        assert_eq!(p.outcome(30), Outcome::Free);
        assert_eq!(p.outcome(1), Outcome::Closed);
        assert_eq!(p.outcome(0), Outcome::Closed);
        assert_eq!(p.outcome(-1), Outcome::Closed);
        assert!(p.reschedule_allowed(2));
        assert!(!p.reschedule_allowed(1));
    }

    #[test]
    fn fee_is_percent_with_floor_and_cap() {
        let p = policy(&[(2, Some(0)), (1, Some(30)), (0, Some(100))], 5_000);
        assert_eq!(p.quote(1, 100_000).unwrap().fee, 30_000);
        assert_eq!(p.quote(1, 10_000).unwrap().fee, 5_000, "floor applies");
        assert_eq!(p.quote(0, 3_000).unwrap().fee, 3_000, "fee never exceeds what was paid");
        let free = p.quote(2, 100_000).unwrap();
        assert_eq!((free.fee, free.refund), (0, 100_000));
    }

    #[test]
    fn closed_tiers_have_no_quote() {
        assert_eq!(CancelPolicy::default().quote(1, 50_000), None);
    }

    #[test]
    fn invalid_policies_are_rejected() {
        assert!(policy(&[], 0).validate().is_err());
        assert!(policy(&[(1, Some(0)), (2, Some(0))], 0).validate().is_err(), "days must descend");
        assert!(policy(&[(2, Some(50)), (1, Some(20))], 0).validate().is_err(), "penalty must not drop closer to visit");
        assert!(policy(&[(2, Some(0)), (1, None), (0, Some(50))], 0).validate().is_err(), "closed is most severe");
        assert!(policy(&[(2, Some(101))], 0).validate().is_err());
        assert!(policy(&[(2, Some(0))], -1).validate().is_err());
    }

    /// Property: for any valid policy and payment, a closer visit never costs less, closed never
    /// reopens closer to the visit, and fee + refund always equals the amount paid within bounds.
    #[test]
    fn fee_is_monotonic_in_days_and_bounded_by_payment() {
        let mut rng = Rng(0x9E37_79B9_7F4A_7C15);
        for _ in 0..2_000 {
            let p = random_valid(&mut rng);
            assert_eq!(p.validate(), Ok(()), "{p:?}");
            let paid = rng.range(0, 2_000_000);
            let mut prev: Option<Option<i64>> = None;
            // Walk from far ahead towards the visit (days descending).
            for days in (-3..=40).rev() {
                let quote = p.quote(days, paid);
                let fee = quote.map(|q| q.fee);
                if let Some(q) = quote {
                    assert!((0..=paid).contains(&q.fee), "fee out of bounds: {p:?} paid={paid} days={days}");
                    assert_eq!(q.fee + q.refund, paid);
                }
                match prev {
                    // Closing as the visit nears is fine; reopening or a smaller fee is not.
                    Some(Some(before)) => {
                        if let Some(now) = fee {
                            assert!(now >= before, "fee dropped: {p:?} paid={paid} days={days}");
                        }
                    }
                    Some(None) => assert!(fee.is_none(), "closed then reopened: {p:?} days={days}"),
                    None => {}
                }
                prev = Some(fee);
            }
        }
    }

    /// Property: every policy the owner UI can express passes validation.
    #[test]
    fn generated_policies_are_valid() {
        let mut rng = Rng(0xDEAD_BEEF_CAFE_F00D);
        for _ in 0..2_000 {
            assert_eq!(random_valid(&mut rng).validate(), Ok(()));
        }
    }
}
