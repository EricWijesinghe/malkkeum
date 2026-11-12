//! Waitlist for a full slot. When capacity frees, the first eligible entry gets a time-limited hold.

use crate::DomainError;
use chrono::{DateTime, Duration, NaiveDate, Utc};

/// How long an offered slot is held for the customer to accept (minutes).
pub const OFFER_HOLD_MINUTES: i64 = 15;
const MAX_HOUR: u32 = 24;

/// A date plus a half-open hour window `[start_hour, end_hour)` in KST.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct SlotRange {
    pub date: NaiveDate,
    pub start_hour: u32,
    pub end_hour: u32,
}

impl SlotRange {
    pub fn validate(&self) -> Result<(), DomainError> {
        if self.start_hour >= self.end_hour || self.end_hour > MAX_HOUR {
            return Err(DomainError::OutOfRange("slot_hours"));
        }
        Ok(())
    }

    /// True when both ranges fall on the same date and share at least one hour.
    pub fn overlaps(&self, other: &SlotRange) -> bool {
        self.date == other.date && self.start_hour < other.end_hour && other.start_hour < self.end_hour
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WaitEntry {
    pub customer_id: i64,
    pub range: SlotRange,
    pub joined_at: DateTime<Utc>,
    /// An entry with a live offer is not offered a second slot at the same time.
    pub has_live_offer: bool,
}

/// Index of the entry that should receive the freed slot: first come, first served among entries
/// whose range overlaps the freed range and that have no live offer. `queue` must be in join order.
pub fn pick_next_offer(queue: &[WaitEntry], freed: &SlotRange) -> Option<usize> {
    queue
        .iter()
        .position(|e| !e.has_live_offer && e.range.overlaps(freed))
}

/// Expiry instant for an offer made at `offered_at`.
pub fn offer_expires_at(offered_at: DateTime<Utc>) -> DateTime<Utc> {
    offered_at + Duration::minutes(OFFER_HOLD_MINUTES)
}

/// An offer can be accepted only strictly before its expiry.
pub fn check_offer_open(expires_at: DateTime<Utc>, now: DateTime<Utc>) -> Result<(), DomainError> {
    if now < expires_at {
        Ok(())
    } else {
        Err(DomainError::OfferExpired)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    fn range(day: u32, start: u32, end: u32) -> SlotRange {
        SlotRange { date: NaiveDate::from_ymd_opt(2026, 11, day).unwrap(), start_hour: start, end_hour: end }
    }

    fn entry(id: i64, r: SlotRange, minute: u32) -> WaitEntry {
        WaitEntry {
            customer_id: id,
            range: r,
            joined_at: Utc.with_ymd_and_hms(2026, 11, 1, 0, minute, 0).unwrap(),
            has_live_offer: false,
        }
    }

    #[test]
    fn overlap_needs_same_day_and_shared_hour() {
        assert!(range(12, 9, 12).overlaps(&range(12, 11, 13)));
        assert!(!range(12, 9, 12).overlaps(&range(12, 12, 14)), "end is exclusive");
        assert!(!range(12, 9, 12).overlaps(&range(13, 9, 12)));
    }

    #[test]
    fn range_validation() {
        assert!(range(12, 9, 12).validate().is_ok());
        assert!(range(12, 12, 12).validate().is_err());
        assert!(range(12, 20, 25).validate().is_err());
    }

    #[test]
    fn first_joined_overlapping_entry_wins() {
        let freed = range(12, 10, 11);
        let q = vec![entry(1, range(13, 9, 12), 0), entry(2, range(12, 9, 11), 1), entry(3, range(12, 10, 12), 2)];
        assert_eq!(pick_next_offer(&q, &freed), Some(1));
    }

    #[test]
    fn entries_with_live_offer_are_skipped() {
        let freed = range(12, 10, 11);
        let mut first = entry(1, range(12, 9, 12), 0);
        first.has_live_offer = true;
        let q = vec![first, entry(2, range(12, 9, 12), 1)];
        assert_eq!(pick_next_offer(&q, &freed), Some(1));
    }

    #[test]
    fn no_match_returns_none() {
        let q = vec![entry(1, range(12, 15, 17), 0)];
        assert_eq!(pick_next_offer(&q, &range(12, 9, 10)), None);
    }

    #[test]
    fn hold_is_fifteen_minutes_and_closes_at_expiry() {
        let at = Utc.with_ymd_and_hms(2026, 11, 1, 0, 0, 0).unwrap();
        let exp = offer_expires_at(at);
        assert_eq!(exp - at, Duration::minutes(15));
        assert!(check_offer_open(exp, at + Duration::minutes(14)).is_ok());
        assert_eq!(check_offer_open(exp, exp), Err(DomainError::OfferExpired));
    }
}
