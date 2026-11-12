//! Optional customer tip after a completed job. 100% goes to the partner; the platform keeps nothing.

use crate::{DomainError, Won};

/// Quick-pick amounts shown in the app (won).
pub const TIP_PRESETS: [Won; 3] = [Won(5_000), Won(10_000), Won(20_000)];
/// Upper bound for a custom tip (won). Keeps typos from becoming large payouts.
pub const MAX_TIP: Won = Won(300_000);
const TIP_STEP: Won = Won(100);

/// A tip may be added only once the job is completed and only one tip per booking exists.
pub fn check_tip_allowed(completed: bool, existing_tip: Option<Won>) -> Result<(), DomainError> {
    if !completed || existing_tip.is_some() {
        return Err(DomainError::TipNotAllowed);
    }
    Ok(())
}

/// Validates a tip amount. Zero means "no tip" and is accepted.
pub fn validate_tip(amount: Won) -> Result<Won, DomainError> {
    if amount == Won::ZERO {
        return Ok(Won::ZERO);
    }
    if amount.0 < 0 || amount > MAX_TIP {
        return Err(DomainError::OutOfRange("tip_amount"));
    }
    if amount.0 % TIP_STEP.0 != 0 {
        return Err(DomainError::OutOfRange("tip_amount"));
    }
    Ok(amount)
}

/// Settlement split of a tip: the partner receives the whole amount.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct TipSplit {
    pub partner: Won,
    pub platform: Won,
}

pub fn split_tip(tip: Won) -> TipSplit {
    TipSplit { partner: tip, platform: Won::ZERO }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn only_completed_jobs_without_tip_accept_a_tip() {
        assert!(check_tip_allowed(true, None).is_ok());
        assert_eq!(check_tip_allowed(false, None), Err(DomainError::TipNotAllowed));
        assert_eq!(check_tip_allowed(true, Some(Won(5_000))), Err(DomainError::TipNotAllowed));
    }

    #[test]
    fn zero_means_no_tip_and_presets_are_valid() {
        assert_eq!(validate_tip(Won::ZERO), Ok(Won::ZERO));
        for p in TIP_PRESETS {
            assert_eq!(validate_tip(p), Ok(p));
        }
    }

    #[test]
    fn custom_tip_must_be_in_100_won_steps_and_within_cap() {
        assert_eq!(validate_tip(Won(7_300)), Ok(Won(7_300)));
        assert_eq!(validate_tip(Won(7_350)), Err(DomainError::OutOfRange("tip_amount")));
        assert_eq!(validate_tip(Won(-1_000)), Err(DomainError::OutOfRange("tip_amount")));
        assert_eq!(validate_tip(Won(MAX_TIP.0 + 100)), Err(DomainError::OutOfRange("tip_amount")));
        assert_eq!(validate_tip(MAX_TIP), Ok(MAX_TIP));
    }

    #[test]
    fn partner_gets_one_hundred_percent() {
        let s = split_tip(Won(10_000));
        assert_eq!((s.partner, s.platform), (Won(10_000), Won::ZERO));
    }
}
