//! Partner quality score: rating, completion, on-time check-in, reliability and complaints.
//! Every rate is Bayesian-smoothed toward a prior so a new partner with 1 job is not 0% or 100%.
//! Pure: the API layer aggregates counts from bookings, check-ins, ratings and cases.

use crate::DomainError;
use serde::{Deserialize, Serialize};

const SCORE_MAX: f64 = 100.0;
const RATING_MIN: f64 = 1.0;
const RATING_SPAN: f64 = 4.0;
/// Prior mean for a 1-5 rating (smoothed toward this when few ratings exist).
const RATING_PRIOR_MEAN: f64 = 4.5;
/// Prior mean for every rate component (completion, on-time, reliability, complaints).
const RATE_PRIOR: f64 = 0.9;
/// Pseudo-count: how many observations the prior is worth.
const PRIOR_WEIGHT: f64 = 5.0;

/// Raw counts for one partner over the scoring window (typically the last 90 days).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
pub struct QualityInputs {
    /// Sum of 1-5 star ratings and how many ratings were given.
    pub rating_sum: u32,
    pub rating_count: u32,
    pub jobs_assigned: u32,
    pub jobs_completed: u32,
    pub checkins: u32,
    pub checkins_on_time: u32,
    /// Partner-caused cancellations and no-shows (from cases).
    pub cancellations_or_no_shows: u32,
    /// Complaint cases opened against the partner.
    pub complaints: u32,
}

impl QualityInputs {
    /// Rejects counts that cannot happen, so a bad aggregation shows up as an error, not a score.
    pub fn validate(&self) -> Result<(), DomainError> {
        let rating_ok = self.rating_sum >= self.rating_count && self.rating_sum <= self.rating_count.saturating_mul(5);
        if !rating_ok {
            return Err(DomainError::OutOfRange("rating_sum"));
        }
        if self.jobs_completed > self.jobs_assigned || self.checkins_on_time > self.checkins {
            return Err(DomainError::OutOfRange("quality_counts"));
        }
        Ok(())
    }
}

/// Owner-configurable thresholds on the 0-100 score.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct QualityThresholds {
    /// Score below this sends an automatic warning notification.
    pub warning_below: u8,
    /// Score below this auto-pauses new job offers (owner can override).
    pub pause_below: u8,
}

impl Default for QualityThresholds {
    fn default() -> Self {
        Self { warning_below: 75, pause_below: 60 }
    }
}

impl QualityThresholds {
    pub fn validate(&self) -> Result<(), DomainError> {
        if self.pause_below > self.warning_below || self.warning_below > 100 {
            return Err(DomainError::OutOfRange("quality_thresholds"));
        }
        Ok(())
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct QualityComponents {
    pub rating: f64,
    pub completion: f64,
    pub on_time: f64,
    pub reliability: f64,
    pub complaints: f64,
}

/// Shrinks an observed rate toward `prior` with `PRIOR_WEIGHT` pseudo-observations.
fn smooth(successes: f64, total: f64, prior: f64) -> f64 {
    (successes + prior * PRIOR_WEIGHT) / (total + PRIOR_WEIGHT)
}

/// Normalised 0..=1 component values.
pub fn components(i: &QualityInputs) -> QualityComponents {
    let rating_avg = smooth(f64::from(i.rating_sum), f64::from(i.rating_count), RATING_PRIOR_MEAN);
    let rating = ((rating_avg - RATING_MIN) / RATING_SPAN).clamp(0.0, 1.0);
    let completion = smooth(f64::from(i.jobs_completed), f64::from(i.jobs_assigned), RATE_PRIOR);
    let on_time = smooth(f64::from(i.checkins_on_time), f64::from(i.checkins), RATE_PRIOR);
    let bad = f64::from(i.cancellations_or_no_shows);
    let reliability = smooth(f64::from(i.jobs_assigned) - bad, f64::from(i.jobs_assigned), RATE_PRIOR);
    let complaint_free = smooth(f64::from(i.jobs_completed) - f64::from(i.complaints), f64::from(i.jobs_completed), RATE_PRIOR);
    QualityComponents {
        rating,
        completion,
        on_time,
        reliability: reliability.clamp(0.0, 1.0),
        complaints: complaint_free.clamp(0.0, 1.0),
    }
}

/// Weighted 0-100 score, rounded to the nearest integer.
pub fn score(i: &QualityInputs) -> u8 {
    let c = components(i);
    let weighted = c.rating * 0.35 + c.completion * 0.20 + c.on_time * 0.20 + c.reliability * 0.15 + c.complaints * 0.10;
    (weighted * SCORE_MAX).round().clamp(0.0, SCORE_MAX) as u8
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum QualityStatus {
    Ok,
    Warning,
    /// Auto-paused from new job offers.
    Paused,
    /// Score is below the pause floor but the owner lifted the pause.
    OverriddenByOwner,
}

/// Owner decision that lifts an auto-pause. Stored per partner.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
pub struct OwnerOverride {
    pub lift_pause: bool,
}

/// Status for a score. The pause floor wins over the warning band; an owner override only
/// changes a paused partner into `OverriddenByOwner`, it never hides a warning.
pub fn status(score: u8, t: QualityThresholds, owner: OwnerOverride) -> QualityStatus {
    if score < t.pause_below {
        if owner.lift_pause {
            QualityStatus::OverriddenByOwner
        } else {
            QualityStatus::Paused
        }
    } else if score < t.warning_below {
        QualityStatus::Warning
    } else {
        QualityStatus::Ok
    }
}

/// Only partners that are not auto-paused get new job offers.
pub fn can_receive_offers(status: QualityStatus) -> bool {
    !matches!(status, QualityStatus::Paused)
}

/// True when a partner has just dropped into the warning band (or pause), so a notification is due
/// exactly once per transition instead of on every recalculation.
pub fn should_notify_warning(previous: Option<QualityStatus>, current: QualityStatus) -> bool {
    let was_bad = matches!(previous, Some(QualityStatus::Warning | QualityStatus::Paused));
    matches!(current, QualityStatus::Warning | QualityStatus::Paused) && !was_bad
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum QualityTip {
    ImproveRating,
    CompleteAssignedJobs,
    CheckInOnTime,
    AvoidCancellations,
    ReduceComplaints,
}

/// Up to three tips, weakest component first, for components below 0.9.
/// Dispatch: order candidates by `score` descending, after dropping `can_receive_offers == false`.
pub fn tips(c: &QualityComponents) -> Vec<QualityTip> {
    let mut ranked = [
        (c.rating, QualityTip::ImproveRating),
        (c.completion, QualityTip::CompleteAssignedJobs),
        (c.on_time, QualityTip::CheckInOnTime),
        (c.reliability, QualityTip::AvoidCancellations),
        (c.complaints, QualityTip::ReduceComplaints),
    ];
    ranked.sort_by(|a, b| a.0.total_cmp(&b.0));
    ranked
        .into_iter()
        .filter(|(v, _)| *v < 0.9)
        .take(3)
        .map(|(_, t)| t)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn perfect() -> QualityInputs {
        QualityInputs {
            rating_sum: 50,
            rating_count: 10,
            jobs_assigned: 40,
            jobs_completed: 40,
            checkins: 40,
            checkins_on_time: 40,
            cancellations_or_no_shows: 0,
            complaints: 0,
        }
    }

    #[test]
    fn new_partner_with_no_history_scores_near_prior() {
        // No data: every component equals its prior, so the score is high but not 100.
        let s = score(&QualityInputs::default());
        assert!((88..=95).contains(&s), "got {s}");
    }

    #[test]
    fn one_bad_rating_does_not_zero_a_new_partner() {
        let one_bad = QualityInputs { rating_sum: 1, rating_count: 1, ..QualityInputs::default() };
        let c = components(&one_bad);
        assert!(c.rating > 0.5, "smoothed rating should stay near prior, got {}", c.rating);
    }

    #[test]
    fn perfect_record_scores_high() {
        assert!(score(&perfect()) >= 95);
    }

    #[test]
    fn late_checkins_lower_the_score() {
        let late = QualityInputs { checkins_on_time: 10, ..perfect() };
        assert!(score(&late) < score(&perfect()));
    }

    #[test]
    fn cancellations_and_complaints_lower_the_score() {
        let cancels = QualityInputs { cancellations_or_no_shows: 12, ..perfect() };
        let complaints = QualityInputs { complaints: 12, ..perfect() };
        assert!(score(&cancels) < score(&perfect()));
        assert!(score(&complaints) < score(&perfect()));
    }

    #[test]
    fn score_is_within_0_and_100() {
        let worst = QualityInputs {
            rating_sum: 500,
            rating_count: 500,
            jobs_assigned: 500,
            jobs_completed: 0,
            checkins: 500,
            checkins_on_time: 0,
            cancellations_or_no_shows: 500,
            complaints: 500,
        };
        assert!(worst.validate().is_ok());
        assert!(score(&worst) <= 100);
        assert!(score(&worst) < 30);
    }

    #[test]
    fn validate_rejects_impossible_counts() {
        assert!(perfect().validate().is_ok());
        assert!(QualityInputs { rating_sum: 1, rating_count: 2, ..perfect() }.validate().is_err());
        assert!(QualityInputs { rating_sum: 11, rating_count: 2, ..perfect() }.validate().is_err());
        assert!(QualityInputs { jobs_completed: 41, ..perfect() }.validate().is_err());
        assert!(QualityInputs { checkins_on_time: 41, ..perfect() }.validate().is_err());
    }

    #[test]
    fn status_bands() {
        let t = QualityThresholds::default();
        let none = OwnerOverride::default();
        assert_eq!(status(90, t, none), QualityStatus::Ok);
        assert_eq!(status(74, t, none), QualityStatus::Warning);
        assert_eq!(status(59, t, none), QualityStatus::Paused);
        assert_eq!(status(75, t, none), QualityStatus::Ok);
        assert_eq!(status(60, t, none), QualityStatus::Warning);
    }

    #[test]
    fn owner_override_lifts_pause_only() {
        let t = QualityThresholds::default();
        let lift = OwnerOverride { lift_pause: true };
        assert_eq!(status(50, t, lift), QualityStatus::OverriddenByOwner);
        assert!(can_receive_offers(QualityStatus::OverriddenByOwner));
        assert_eq!(status(70, t, lift), QualityStatus::Warning);
    }

    #[test]
    fn paused_partner_gets_no_offers() {
        assert!(!can_receive_offers(QualityStatus::Paused));
        assert!(can_receive_offers(QualityStatus::Warning));
        assert!(can_receive_offers(QualityStatus::Ok));
    }

    #[test]
    fn warning_notification_fires_once_per_transition() {
        assert!(should_notify_warning(Some(QualityStatus::Ok), QualityStatus::Warning));
        assert!(should_notify_warning(None, QualityStatus::Warning));
        assert!(!should_notify_warning(Some(QualityStatus::Warning), QualityStatus::Warning));
        assert!(!should_notify_warning(Some(QualityStatus::Warning), QualityStatus::Paused));
        assert!(!should_notify_warning(Some(QualityStatus::Ok), QualityStatus::Ok));
    }

    #[test]
    fn thresholds_must_be_ordered() {
        assert!(QualityThresholds { warning_below: 75, pause_below: 60 }.validate().is_ok());
        assert!(QualityThresholds { warning_below: 50, pause_below: 60 }.validate().is_err());
        assert!(QualityThresholds { warning_below: 101, pause_below: 60 }.validate().is_err());
    }

    #[test]
    fn tips_point_at_weakest_components() {
        let late = QualityInputs { checkins_on_time: 0, ..perfect() };
        let t = tips(&components(&late));
        assert_eq!(t.first(), Some(&QualityTip::CheckInOnTime));
        assert!(t.len() <= 3);
        assert!(tips(&components(&perfect())).is_empty());
    }

}
