use crate::DomainError;
use crate::cancel_policy::{CancelPolicy, Outcome, Quote};
use serde::{Deserialize, Serialize};

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

/// What a customer cancel costs. Consultation (no money taken yet) is always free; otherwise the policy decides.
/// None means the customer cannot cancel in-app (staff handle it).
pub fn cancel_quote(policy: &CancelPolicy, status: BookingStatus, days_before: i64, paid: i64) -> Option<Quote> {
    if status == BookingStatus::Consultation {
        return Some(Quote { outcome: Outcome::Free, paid: 0, fee: 0, refund: 0 });
    }
    policy.quote(days_before, paid)
}

#[cfg(test)]
mod tests {
    use super::BookingStatus::*;
    use super::*;

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
    fn consultation_is_free_and_closed_policy_blocks_self_serve() {
        let p = CancelPolicy::default();
        let q = cancel_quote(&p, Consultation, 0, 0).unwrap();
        assert_eq!((q.fee, q.refund), (0, 0));
        assert_eq!(cancel_quote(&p, Confirmed, 1, 45_000), None);
        assert_eq!(cancel_quote(&p, Confirmed, 2, 45_000).unwrap().refund, 45_000);
    }
}
