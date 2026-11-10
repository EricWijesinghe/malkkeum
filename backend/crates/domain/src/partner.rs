//! Partner (pro) rules: job visibility, payout math, weekly settlement date.

use crate::{
    Won,
    schedule::{DayPart, day_part},
};
use chrono::{Datelike, Duration, NaiveDate, Weekday};
use serde::{Deserialize, Serialize};
use std::collections::HashSet;

/// Platform fee default (prototype 20%, decision #2).
pub const DEFAULT_FEE_BPS: i64 = 2_000;
pub const PAYOUT_WEEKDAY: Weekday = Weekday::Wed;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Payout {
    pub gross: Won,
    pub fee: Won,
    pub net: Won,
}

pub fn payout(gross: Won, fee_bps: i64) -> Payout {
    let fee = gross.times_bps(fee_bps);
    Payout { gross, fee, net: gross - fee }
}

/// The first payout weekday strictly after the completion date.
pub fn payout_date(completed: NaiveDate) -> NaiveDate {
    let target = PAYOUT_WEEKDAY.num_days_from_monday() as i64;
    let current = completed.weekday().num_days_from_monday() as i64;
    let ahead = (target - current).rem_euclid(7);
    completed + Duration::days(if ahead == 0 { 7 } else { ahead })
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct PartnerPrefs {
    pub services: HashSet<String>,
    pub districts: HashSet<String>,
    pub weekdays: HashSet<u8>,
    pub day_parts: HashSet<DayPart>,
    pub days_off: HashSet<NaiveDate>,
    pub verified_and_active: bool,
}

/// What a pro can see before accepting (no address, no customer).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct JobFacts<'a> {
    pub service_code: &'a str,
    pub district_code: &'a str,
    pub visit_date: NaiveDate,
    pub start_hour: u8,
}

/// Partner spec rule 1.
pub fn is_visible(p: &PartnerPrefs, j: &JobFacts<'_>) -> bool {
    let weekday = j.visit_date.weekday().num_days_from_monday() as u8;
    p.verified_and_active
        && p.services.contains(j.service_code)
        && p.districts.contains(j.district_code)
        && p.weekdays.contains(&weekday)
        && p.day_parts.contains(&day_part(j.start_hour))
        && !p.days_off.contains(&j.visit_date)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn d(m: u32, day: u32) -> NaiveDate {
        NaiveDate::from_ymd_opt(2026, m, day).unwrap()
    }

    #[test]
    fn fee_and_net() {
        assert_eq!(
            payout(Won(52_000), DEFAULT_FEE_BPS),
            Payout {
                gross: Won(52_000),
                fee: Won(10_400),
                net: Won(41_600)
            }
        );
    }

    #[test]
    fn next_wednesday_strictly_after() {
        assert_eq!(payout_date(d(11, 13)), d(11, 18)); // Fri -> Wed
        assert_eq!(payout_date(d(11, 11)), d(11, 18)); // Wed -> next Wed
        assert_eq!(payout_date(d(11, 10)), d(11, 11)); // Tue -> Wed
    }

    #[test]
    fn visibility_filters() {
        let prefs = PartnerPrefs {
            services: ["bathroom".to_string()].into(),
            districts: ["11680".to_string()].into(),
            weekdays: (0..5).collect(),
            day_parts: [DayPart::Morning].into(),
            days_off: [d(11, 20)].into(),
            verified_and_active: true,
        };
        let job = JobFacts {
            service_code: "bathroom",
            district_code: "11680",
            visit_date: d(11, 13),
            start_hour: 9,
        };
        assert!(is_visible(&prefs, &job));
        assert!(!is_visible(&prefs, &JobFacts { start_hour: 13, ..job.clone() }));
        assert!(!is_visible(
            &prefs,
            &JobFacts {
                visit_date: d(11, 14),
                ..job.clone()
            }
        )); // Saturday
        assert!(!is_visible(
            &prefs,
            &JobFacts {
                visit_date: d(11, 20),
                ..job.clone()
            }
        )); // day off
        assert!(!is_visible(
            &prefs,
            &JobFacts {
                service_code: "sofa",
                ..job.clone()
            }
        ));
        assert!(!is_visible(
            &PartnerPrefs {
                verified_and_active: false,
                ..prefs.clone()
            },
            &job
        ));
    }
}
