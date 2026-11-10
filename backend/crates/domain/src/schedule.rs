use crate::DomainError;
use chrono::NaiveDate;
use serde::{Deserialize, Serialize};

/// Spec rule 2: bookable from tomorrow up to 60 days ahead.
pub const MAX_DAYS_AHEAD: i64 = 60;
/// Arrival windows (start hour) for fixed / unit services.
pub const STANDARD_SLOTS: [u8; 4] = [8, 9, 13, 14];
/// Arrival windows for quote services: morning 08-09, afternoon 13-14.
pub const QUOTE_SLOTS: [u8; 2] = [8, 13];
const NOON: u8 = 12;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum DayPart {
    Morning,
    Afternoon,
}

pub fn day_part(start_hour: u8) -> DayPart {
    if start_hour < NOON { DayPart::Morning } else { DayPart::Afternoon }
}

pub fn check_date(today: NaiveDate, visit: NaiveDate) -> Result<(), DomainError> {
    let days = (visit - today).num_days();
    if (1..=MAX_DAYS_AHEAD).contains(&days) {
        Ok(())
    } else {
        Err(DomainError::DateOutOfRange { max_days: MAX_DAYS_AHEAD })
    }
}

pub fn check_slot(is_quote: bool, start_hour: u8) -> Result<(), DomainError> {
    let allowed: &[u8] = if is_quote { &QUOTE_SLOTS } else { &STANDARD_SLOTS };
    if allowed.contains(&start_hour) {
        Ok(())
    } else {
        Err(DomainError::InvalidSlot)
    }
}

/// Capacity is configured per slot in admin (decision #6). `None` = unlimited.
pub fn check_capacity(already_booked: u32, capacity: Option<u32>) -> Result<(), DomainError> {
    match capacity {
        Some(cap) if already_booked >= cap => Err(DomainError::SlotFull),
        _ => Ok(()),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn d(y: i32, m: u32, day: u32) -> NaiveDate {
        NaiveDate::from_ymd_opt(y, m, day).unwrap()
    }

    #[test]
    fn date_window() {
        let today = d(2026, 11, 10);
        assert!(check_date(today, today).is_err());
        assert!(check_date(today, d(2026, 11, 11)).is_ok());
        assert!(check_date(today, d(2027, 1, 9)).is_ok()); // +60
        assert!(check_date(today, d(2027, 1, 10)).is_err()); // +61
    }

    #[test]
    fn slots_by_kind() {
        assert!(check_slot(false, 9).is_ok());
        assert!(check_slot(false, 10).is_err());
        assert!(check_slot(true, 13).is_ok());
        assert!(check_slot(true, 9).is_err());
        assert_eq!(day_part(14), DayPart::Afternoon);
    }

    #[test]
    fn capacity() {
        assert!(check_capacity(2, Some(3)).is_ok());
        assert_eq!(check_capacity(3, Some(3)), Err(DomainError::SlotFull));
        assert!(check_capacity(99, None).is_ok());
    }
}
