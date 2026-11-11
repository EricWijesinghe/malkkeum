//! Peak pricing: weekend, Korean public holiday, Seollal/Chuseok period and evening-hour surcharges.
//! Pure: callers pass the UTC start instant; all calendar math happens in KST (UTC+9).

use crate::{DomainError, Won};
use chrono::{DateTime, Datelike, FixedOffset, NaiveDate, Timelike, Utc, Weekday};
use serde::{Deserialize, Serialize};

const FULL_BPS: i64 = 10_000;
const KST_OFFSET_SECS: i32 = 9 * 3600;
const MAX_HOUR: u32 = 24;

fn kst_offset() -> FixedOffset {
    FixedOffset::east_opt(KST_OFFSET_SECS).expect("KST offset is a valid constant")
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum DayKind {
    /// Public holiday or its substitute holiday (대체공휴일).
    Public,
    /// Day inside the Seollal (설날) or Chuseok (추석) holiday block, including its substitute days.
    LunarPeriod,
}

/// Korean public holidays and lunar-holiday blocks, KST calendar dates.
///
/// Source: 대한민국 공휴일 (행정안전부 「관공서의 공휴일에 관한 규정」, 대체공휴일 적용 대상 포함),
/// 음력 기반 날짜(설날·부처님오신날·추석)는 한국천문연구원 음력 달력 기준.
/// shortcut: 2027-2028 entries are hand-derived from the statute and lunar calendar and not yet
/// re-checked against the KASI published table, verify before go-live.
/// Not included: 임시공휴일 (ad-hoc holidays declared by the government) and 현충일 substitutes (not legally substitutable).
const KR_HOLIDAYS: &[(i32, u32, u32, DayKind)] = &[
    // 2026
    (2026, 1, 1, DayKind::Public),
    (2026, 2, 16, DayKind::LunarPeriod),
    (2026, 2, 17, DayKind::LunarPeriod),
    (2026, 2, 18, DayKind::LunarPeriod),
    (2026, 3, 1, DayKind::Public),
    (2026, 3, 2, DayKind::Public), // substitute for 3/1 (Sunday)
    (2026, 5, 5, DayKind::Public),
    (2026, 5, 24, DayKind::Public), // 부처님오신날
    (2026, 5, 25, DayKind::Public), // substitute (Sunday)
    (2026, 6, 6, DayKind::Public),
    (2026, 8, 15, DayKind::Public),
    (2026, 8, 17, DayKind::Public), // substitute (Saturday)
    (2026, 9, 24, DayKind::LunarPeriod),
    (2026, 9, 25, DayKind::LunarPeriod),
    (2026, 9, 26, DayKind::LunarPeriod),
    (2026, 10, 3, DayKind::Public),
    (2026, 10, 5, DayKind::Public), // substitute (Saturday)
    (2026, 10, 9, DayKind::Public),
    (2026, 12, 25, DayKind::Public),
    // 2027
    (2027, 1, 1, DayKind::Public),
    (2027, 2, 5, DayKind::LunarPeriod),
    (2027, 2, 6, DayKind::LunarPeriod),
    (2027, 2, 7, DayKind::LunarPeriod),
    (2027, 2, 8, DayKind::LunarPeriod), // substitute for 설날 (Saturday)
    (2027, 3, 1, DayKind::Public),
    (2027, 5, 5, DayKind::Public),
    (2027, 5, 13, DayKind::Public), // 부처님오신날
    (2027, 6, 6, DayKind::Public),
    (2027, 8, 15, DayKind::Public),
    (2027, 8, 16, DayKind::Public), // substitute (Sunday)
    (2027, 10, 3, DayKind::Public),
    (2027, 10, 4, DayKind::Public), // substitute (Sunday)
    (2027, 10, 9, DayKind::Public),
    (2027, 10, 11, DayKind::Public), // substitute (Saturday)
    (2027, 10, 14, DayKind::LunarPeriod),
    (2027, 10, 15, DayKind::LunarPeriod),
    (2027, 10, 16, DayKind::LunarPeriod),
    (2027, 12, 25, DayKind::Public),
    (2027, 12, 27, DayKind::Public), // substitute (Saturday)
    // 2028
    (2028, 1, 1, DayKind::Public),
    (2028, 1, 25, DayKind::LunarPeriod),
    (2028, 1, 26, DayKind::LunarPeriod),
    (2028, 1, 27, DayKind::LunarPeriod),
    (2028, 3, 1, DayKind::Public),
    (2028, 5, 2, DayKind::Public), // 부처님오신날
    (2028, 5, 5, DayKind::Public),
    (2028, 6, 6, DayKind::Public),
    (2028, 8, 15, DayKind::Public),
    (2028, 10, 2, DayKind::LunarPeriod),
    (2028, 10, 3, DayKind::LunarPeriod), // 추석 and 개천절 overlap
    (2028, 10, 4, DayKind::LunarPeriod),
    (2028, 10, 5, DayKind::Public), // substitute for overlapping 개천절
    (2028, 10, 9, DayKind::Public),
    (2028, 12, 25, DayKind::Public),
];

/// Looks up the holiday kind for a KST calendar date, if any.
pub fn holiday_kind(date: NaiveDate) -> Option<DayKind> {
    KR_HOLIDAYS.iter().find_map(|&(y, m, d, kind)| {
        (NaiveDate::from_ymd_opt(y, m, d) == Some(date)).then_some(kind)
    })
}

/// Owner-configurable surcharges, in basis points (10_000 = 100%) of the pre-VAT amount.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PeakConfig {
    pub weekend_bps: i64,
    pub public_holiday_bps: i64,
    pub lunar_period_bps: i64,
    pub evening_bps: i64,
    /// KST hour, inclusive. Evening window is `[evening_start_hour, evening_end_hour)`.
    pub evening_start_hour: u32,
    pub evening_end_hour: u32,
    /// Hard cap on the total surcharge.
    pub max_bps: i64,
}

impl Default for PeakConfig {
    /// Prototype values; the business confirms final numbers.
    fn default() -> Self {
        Self {
            weekend_bps: 1_000,
            public_holiday_bps: 2_000,
            lunar_period_bps: 3_000,
            evening_bps: 1_000,
            evening_start_hour: 18,
            evening_end_hour: 22,
            max_bps: 5_000,
        }
    }
}

impl PeakConfig {
    /// Rejects inconsistent owner input before it is stored or used.
    pub fn validate(&self) -> Result<(), DomainError> {
        let rates = [self.weekend_bps, self.public_holiday_bps, self.lunar_period_bps, self.evening_bps, self.max_bps];
        if rates.iter().any(|&r| !(0..=FULL_BPS).contains(&r)) {
            return Err(DomainError::OutOfRange("peak_bps"));
        }
        if self.evening_start_hour >= self.evening_end_hour || self.evening_end_hour > MAX_HOUR {
            return Err(DomainError::OutOfRange("evening_hours"));
        }
        Ok(())
    }
}

/// Itemised surcharge so the quote breakdown can show each reason.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PeakSurcharge {
    pub bps: i64,
    /// Day-type component: weekend, public holiday or lunar period (the largest applies, not a sum).
    pub day_bps: i64,
    pub day_kind: Option<DayKind>,
    pub is_weekend: bool,
    pub evening_bps: i64,
}

impl PeakSurcharge {
    /// Surcharge amount on a pre-VAT base, rounded to 100 won like quotes.
    pub fn amount_on(&self, base: Won) -> Won {
        base.times_bps(self.bps).round100()
    }
}

/// UTC instant of a KST visit date and start hour (hour 0-23).
pub fn kst_to_utc(date: NaiveDate, hour: u32) -> Option<DateTime<Utc>> {
    date.and_hms_opt(hour, 0, 0)?
        .and_local_timezone(kst_offset())
        .single()
        .map(|d| d.with_timezone(&Utc))
}

/// Surcharge for a booking starting at `start` (UTC instant).
/// Rules: day-type = max(weekend, public holiday, lunar period); evening is added on top;
/// the total is capped at `max_bps`.
pub fn peak_surcharge(config: &PeakConfig, start: DateTime<Utc>) -> PeakSurcharge {
    let local = start.with_timezone(&kst_offset());
    let date = local.date_naive();
    let is_weekend = matches!(date.weekday(), Weekday::Sat | Weekday::Sun);
    let day_kind = holiday_kind(date);
    let weekend_bps = if is_weekend { config.weekend_bps } else { 0 };
    let holiday_bps = match day_kind {
        Some(DayKind::Public) => config.public_holiday_bps,
        Some(DayKind::LunarPeriod) => config.lunar_period_bps,
        None => 0,
    };
    let day_bps = weekend_bps.max(holiday_bps);
    let hour = local.hour();
    let in_evening = (config.evening_start_hour..config.evening_end_hour).contains(&hour);
    let evening_bps = if in_evening { config.evening_bps } else { 0 };
    PeakSurcharge {
        bps: (day_bps + evening_bps).min(config.max_bps),
        day_bps,
        day_kind,
        is_weekend,
        evening_bps,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    fn kst(y: i32, m: u32, d: u32, h: u32) -> DateTime<Utc> {
        // KST is UTC+9: subtract 9 hours to get the UTC instant.
        Utc.with_ymd_and_hms(y, m, d, h, 0, 0).unwrap() - chrono::Duration::hours(9)
    }

    #[test]
    fn weekday_daytime_has_no_surcharge() {
        // 2026-11-11 is a Wednesday, 10:00 KST.
        let s = peak_surcharge(&PeakConfig::default(), kst(2026, 11, 11, 10));
        assert_eq!((s.bps, s.day_bps, s.evening_bps, s.is_weekend), (0, 0, 0, false));
        assert_eq!(s.day_kind, None);
    }

    #[test]
    fn saturday_is_weekend_surcharge() {
        // 2026-11-14 is a Saturday.
        let s = peak_surcharge(&PeakConfig::default(), kst(2026, 11, 14, 10));
        assert_eq!((s.bps, s.day_bps, s.is_weekend), (1_000, 1_000, true));
    }

    #[test]
    fn sunday_evening_stacks_day_and_evening() {
        // 2026-11-15 is a Sunday, 19:00 KST: weekend 10% + evening 10%.
        let s = peak_surcharge(&PeakConfig::default(), kst(2026, 11, 15, 19));
        assert_eq!((s.day_bps, s.evening_bps, s.bps), (1_000, 1_000, 2_000));
    }

    #[test]
    fn evening_window_end_is_exclusive() {
        let c = PeakConfig::default();
        assert_eq!(peak_surcharge(&c, kst(2026, 11, 11, 17)).evening_bps, 0);
        assert_eq!(peak_surcharge(&c, kst(2026, 11, 11, 18)).evening_bps, 1_000);
        assert_eq!(peak_surcharge(&c, kst(2026, 11, 11, 21)).evening_bps, 1_000);
        assert_eq!(peak_surcharge(&c, kst(2026, 11, 11, 22)).evening_bps, 0);
    }

    #[test]
    fn public_holiday_on_weekday_uses_holiday_rate() {
        // 2026-10-09 (한글날) is a Friday.
        let s = peak_surcharge(&PeakConfig::default(), kst(2026, 10, 9, 10));
        assert_eq!((s.day_kind, s.day_bps, s.bps), (Some(DayKind::Public), 2_000, 2_000));
    }

    #[test]
    fn chuseok_period_uses_lunar_rate_not_sum_with_weekend() {
        // 2026-09-26 is a Saturday inside the 추석 block: max(weekend 10%, lunar 30%) = 30%, not 40%.
        let s = peak_surcharge(&PeakConfig::default(), kst(2026, 9, 26, 10));
        assert_eq!((s.day_kind, s.day_bps, s.bps), (Some(DayKind::LunarPeriod), 3_000, 3_000));
    }

    #[test]
    fn substitute_holiday_counts_as_public() {
        // 2026-03-02 is the substitute for 삼일절 (Sunday 3/1).
        let s = peak_surcharge(&PeakConfig::default(), kst(2026, 3, 2, 10));
        assert_eq!(s.day_kind, Some(DayKind::Public));
    }

    #[test]
    fn total_is_capped_at_max() {
        let c = PeakConfig { max_bps: 2_500, ..PeakConfig::default() };
        // Chuseok Saturday evening would be 30% + 10% = 40%, capped to 25%.
        let s = peak_surcharge(&c, kst(2026, 9, 26, 19));
        assert_eq!(s.bps, 2_500);
    }

    #[test]
    fn kst_date_boundary_is_used_not_utc() {
        // 2026-11-14 23:30 UTC is already 2026-11-15 08:30 KST (Sunday).
        let utc = Utc.with_ymd_and_hms(2026, 11, 14, 23, 30, 0).unwrap();
        let s = peak_surcharge(&PeakConfig::default(), utc);
        assert!(s.is_weekend);
    }

    #[test]
    fn amount_on_rounds_to_100_won() {
        let s = PeakSurcharge { bps: 1_000, day_bps: 1_000, day_kind: None, is_weekend: true, evening_bps: 0 };
        assert_eq!(s.amount_on(Won(185_000)), Won(18_500));
        assert_eq!(s.amount_on(Won(180_000 + 1_234)), Won(18_100));
    }

    #[test]
    fn kst_to_utc_converts_visit_slot() {
        let d = NaiveDate::from_ymd_opt(2026, 11, 11).unwrap();
        assert_eq!(kst_to_utc(d, 10), Some(Utc.with_ymd_and_hms(2026, 11, 11, 1, 0, 0).unwrap()));
        assert_eq!(kst_to_utc(d, 24), None);
    }

    #[test]
    fn validate_rejects_bad_config() {
        assert!(PeakConfig::default().validate().is_ok());
        let bad_rate = PeakConfig { weekend_bps: 10_001, ..PeakConfig::default() };
        assert_eq!(bad_rate.validate(), Err(DomainError::OutOfRange("peak_bps")));
        let bad_hours = PeakConfig { evening_start_hour: 22, evening_end_hour: 18, ..PeakConfig::default() };
        assert_eq!(bad_hours.validate(), Err(DomainError::OutOfRange("evening_hours")));
    }

    #[test]
    fn every_holiday_entry_is_a_real_date() {
        for &(y, m, d, _) in KR_HOLIDAYS {
            assert!(NaiveDate::from_ymd_opt(y, m, d).is_some(), "invalid holiday {y}-{m}-{d}");
        }
    }
}
