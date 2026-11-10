use crate::DomainError;
use chrono::NaiveDate;
use serde::{Deserialize, Serialize};

/// Free cancellation until this many days before the visit (spec rule 6).
pub const FREE_CANCEL_DAYS: i64 = 2;

/// Customer-facing booking status. Numbers match the spec (0-3) and the DB.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum BookingStatus {
    Consultation,
    Confirmed,
    TeamAssigned,
    Completed,
    Cancelled,
}

impl BookingStatus {
    pub fn as_i16(self) -> i16 {
        match self {
            Self::Consultation => 0,
            Self::Confirmed => 1,
            Self::TeamAssigned => 2,
            Self::Completed => 3,
            Self::Cancelled => -1,
        }
    }

    pub fn from_i16(v: i16) -> Option<Self> {
        Some(match v {
            0 => Self::Consultation,
            1 => Self::Confirmed,
            2 => Self::TeamAssigned,
            3 => Self::Completed,
            -1 => Self::Cancelled,
            _ => return None,
        })
    }

    /// Fixed / unit bookings start confirmed (paid); quote bookings start in consultation.
    pub fn initial(is_quote: bool) -> Self {
        if is_quote { Self::Consultation } else { Self::Confirmed }
    }

    pub fn is_terminal(self) -> bool {
        matches!(self, Self::Completed | Self::Cancelled)
    }

    /// The only legal moves. TeamAssigned -> Confirmed covers un-assigning a pro.
    pub fn transition(self, to: Self) -> Result<Self, DomainError> {
        use BookingStatus::*;
        let ok = matches!(
            (self, to),
            (Consultation, Confirmed) | (Confirmed, TeamAssigned) | (TeamAssigned, Completed) | (TeamAssigned, Confirmed)
        ) || (to == Cancelled && !self.is_terminal());
        if ok { Ok(to) } else { Err(DomainError::InvalidTransition) }
    }
}

/// Whether the customer may cancel without a fee right now.
pub fn is_free_cancellation(status: BookingStatus, today: NaiveDate, visit: NaiveDate) -> bool {
    status == BookingStatus::Consultation || (visit - today).num_days() >= FREE_CANCEL_DAYS
}

/// Customer self-service cancel. Late cancels go through the consultation team
/// until the fee policy (decision #7) is set.
pub fn customer_cancel(status: BookingStatus, today: NaiveDate, visit: NaiveDate) -> Result<BookingStatus, DomainError> {
    if !is_free_cancellation(status, today, visit) {
        return Err(DomainError::CancellationWindowClosed);
    }
    status.transition(BookingStatus::Cancelled)
}

#[cfg(test)]
mod tests {
    use super::BookingStatus::*;
    use super::*;

    fn d(day: u32) -> NaiveDate {
        NaiveDate::from_ymd_opt(2026, 11, day).unwrap()
    }

    #[test]
    fn roundtrip_numbers() {
        for s in [Consultation, Confirmed, TeamAssigned, Completed, Cancelled] {
            assert_eq!(BookingStatus::from_i16(s.as_i16()), Some(s));
        }
        assert_eq!(BookingStatus::from_i16(7), None);
    }

    #[test]
    fn legal_and_illegal_transitions() {
        assert_eq!(Consultation.transition(Confirmed), Ok(Confirmed));
        assert_eq!(Confirmed.transition(TeamAssigned), Ok(TeamAssigned));
        assert_eq!(TeamAssigned.transition(Completed), Ok(Completed));
        assert_eq!(Confirmed.transition(Completed), Err(DomainError::InvalidTransition));
        assert_eq!(Completed.transition(Cancelled), Err(DomainError::InvalidTransition));
        assert_eq!(Cancelled.transition(Confirmed), Err(DomainError::InvalidTransition));
        assert_eq!(TeamAssigned.transition(Cancelled), Ok(Cancelled));
    }

    #[test]
    fn free_cancel_window() {
        assert!(customer_cancel(Confirmed, d(10), d(12)).is_ok());
        assert_eq!(customer_cancel(Confirmed, d(11), d(12)), Err(DomainError::CancellationWindowClosed));
        assert!(customer_cancel(Consultation, d(11), d(12)).is_ok());
    }
}
