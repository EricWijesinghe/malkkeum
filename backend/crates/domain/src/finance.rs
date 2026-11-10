//! Owner finance rules: reporting periods, chart buckets, VAT estimate and CSV escaping.
//! Pure: callers pass the anchor date (KST) and get inclusive date ranges back.

use crate::{DomainError, Won};
use chrono::{Datelike, Duration, NaiveDate};

/// Korean VAT rate (10%) applied to the platform fee for the estimate.
pub const VAT_BPS: i64 = 1_000;
/// Longest custom range the reports accept (two years plus a little).
pub const MAX_RANGE_DAYS: i64 = 800;
/// UTF-8 byte order mark: makes Excel read Korean text correctly.
pub const CSV_BOM: &str = "\u{feff}";

/// Inclusive `[from, to]` range for a named period. `kind` is day | week | month | custom.
/// `week` runs Monday to Sunday. `custom` needs both `from` and `to`.
pub fn period(kind: &str, anchor: NaiveDate, from: Option<NaiveDate>, to: Option<NaiveDate>) -> Result<(NaiveDate, NaiveDate), DomainError> {
    let range = match kind {
        "day" => (anchor, anchor),
        "week" => {
            let monday = anchor - Duration::days(i64::from(anchor.weekday().num_days_from_monday()));
            (monday, monday + Duration::days(6))
        }
        "month" => {
            let first = month_start(anchor.year(), anchor.month());
            (first, last_day_of_month(first))
        }
        "custom" => (from.ok_or(DomainError::OutOfRange("from"))?, to.ok_or(DomainError::OutOfRange("to"))?),
        _ => return Err(DomainError::OutOfRange("period")),
    };
    if range.0 > range.1 || (range.1 - range.0).num_days() >= MAX_RANGE_DAYS {
        return Err(DomainError::OutOfRange("period"));
    }
    Ok(range)
}

/// Chart grain. Buckets are keyed by their first day (Monday for weeks, the 1st for months).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Grain {
    Day,
    Week,
    Month,
}

impl Grain {
    /// SQL `date_trunc` unit for this grain.
    pub fn trunc_unit(self) -> &'static str {
        match self {
            Grain::Day => "day",
            Grain::Week => "week",
            Grain::Month => "month",
        }
    }

    pub fn parse(s: &str) -> Option<Grain> {
        match s {
            "day" => Some(Grain::Day),
            "week" => Some(Grain::Week),
            "month" => Some(Grain::Month),
            _ => None,
        }
    }
}

/// The last `count` buckets ending with the one containing `today`: `(first_key, today)`.
pub fn series_range(grain: Grain, today: NaiveDate, count: u32) -> (NaiveDate, NaiveDate) {
    let back = i64::from(count.max(1)) - 1;
    let first = match grain {
        Grain::Day => today - Duration::days(back),
        Grain::Week => buckets(Grain::Week, today, today)[0] - Duration::days(7 * back),
        Grain::Month => {
            let total = today.year() * 12 + today.month0() as i32 - back as i32;
            month_start(total.div_euclid(12), total.rem_euclid(12) as u32 + 1)
        }
    };
    (first, today)
}

/// Share of `whole` in basis points (10_000 = 100%), rounded half-up. Zero when `whole` is zero.
pub fn ratio_bps(part: i64, whole: i64) -> i64 {
    if whole <= 0 { 0 } else { (part * 10_000 + whole / 2) / whole }
}

/// Every bucket key from the one containing `from` up to the one containing `to`, in order.
pub fn buckets(grain: Grain, from: NaiveDate, to: NaiveDate) -> Vec<NaiveDate> {
    let mut out = Vec::new();
    let mut cur = match grain {
        Grain::Day => from,
        Grain::Week => from - Duration::days(i64::from(from.weekday().num_days_from_monday())),
        Grain::Month => month_start(from.year(), from.month()),
    };
    while cur <= to {
        out.push(cur);
        cur = match grain {
            Grain::Day => cur + Duration::days(1),
            Grain::Week => cur + Duration::days(7),
            Grain::Month => next_month(cur),
        };
    }
    out
}

/// Estimated VAT owed on the platform fee (fee is VAT-inclusive, so this is an estimate only).
pub fn vat_estimate(fee: Won) -> Won {
    fee.times_bps(VAT_BPS)
}

/// One CSV cell. Text is guarded against spreadsheet formula injection; numbers stay numeric.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Cell {
    Text(String),
    Number(i64),
}

/// Escapes one text cell: formula triggers get a leading apostrophe, then RFC 4180 quoting.
pub fn csv_text(v: &str) -> String {
    let guarded = if v.starts_with(['=', '+', '-', '@', '\t', '\r']) { format!("'{v}") } else { v.to_string() };
    if guarded.contains([',', '"', '\n', '\r']) { format!("\"{}\"", guarded.replace('"', "\"\"")) } else { guarded }
}

/// A whole CSV document: BOM, then `\r\n` line endings.
pub fn csv_document(rows: &[Vec<Cell>]) -> String {
    let mut out = String::from(CSV_BOM);
    for row in rows {
        let line: Vec<String> = row
            .iter()
            .map(|c| match c {
                Cell::Text(t) => csv_text(t),
                Cell::Number(w) => w.to_string(),
            })
            .collect();
        out.push_str(&line.join(","));
        out.push_str("\r\n");
    }
    out
}

fn month_start(year: i32, month: u32) -> NaiveDate {
    NaiveDate::from_ymd_opt(year, month, 1).expect("valid month")
}

fn next_month(first: NaiveDate) -> NaiveDate {
    if first.month() == 12 { month_start(first.year() + 1, 1) } else { month_start(first.year(), first.month() + 1) }
}

fn last_day_of_month(first: NaiveDate) -> NaiveDate {
    next_month(first) - Duration::days(1)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn d(y: i32, m: u32, day: u32) -> NaiveDate {
        NaiveDate::from_ymd_opt(y, m, day).unwrap()
    }

    #[test]
    fn day_and_week_periods() {
        assert_eq!(period("day", d(2026, 11, 11), None, None).unwrap(), (d(2026, 11, 11), d(2026, 11, 11)));
        // 2026-11-11 is a Wednesday: the week runs Mon 9th to Sun 15th.
        assert_eq!(period("week", d(2026, 11, 11), None, None).unwrap(), (d(2026, 11, 9), d(2026, 11, 15)));
        // Sunday belongs to the week that started the Monday before.
        assert_eq!(period("week", d(2026, 11, 15), None, None).unwrap(), (d(2026, 11, 9), d(2026, 11, 15)));
    }

    #[test]
    fn month_period_handles_leap_february_and_december() {
        assert_eq!(period("month", d(2028, 2, 10), None, None).unwrap(), (d(2028, 2, 1), d(2028, 2, 29)));
        assert_eq!(period("month", d(2026, 2, 1), None, None).unwrap(), (d(2026, 2, 1), d(2026, 2, 28)));
        assert_eq!(period("month", d(2026, 12, 31), None, None).unwrap(), (d(2026, 12, 1), d(2026, 12, 31)));
    }

    #[test]
    fn custom_period_validates_order_presence_and_span() {
        assert!(period("custom", d(2026, 1, 1), Some(d(2026, 1, 5)), Some(d(2026, 1, 1))).is_err());
        assert!(period("custom", d(2026, 1, 1), None, Some(d(2026, 1, 5))).is_err());
        assert!(period("custom", d(2026, 1, 1), Some(d(2026, 1, 1)), Some(d(2029, 1, 1))).is_err());
        assert!(period("nope", d(2026, 1, 1), None, None).is_err());
        assert_eq!(
            period("custom", d(2026, 1, 1), Some(d(2026, 1, 1)), Some(d(2026, 1, 3))).unwrap(),
            (d(2026, 1, 1), d(2026, 1, 3))
        );
    }

    #[test]
    fn buckets_for_days_and_months() {
        assert_eq!(buckets(Grain::Day, d(2026, 1, 30), d(2026, 2, 1)).len(), 3);
        assert_eq!(
            buckets(Grain::Month, d(2026, 11, 20), d(2027, 1, 3)),
            vec![d(2026, 11, 1), d(2026, 12, 1), d(2027, 1, 1)]
        );
        assert!(buckets(Grain::Day, d(2026, 2, 2), d(2026, 2, 1)).is_empty());
    }

    #[test]
    fn weekly_buckets_start_on_monday() {
        // 2026-11-11 is a Wednesday, so its week starts on Monday 2026-11-09.
        assert_eq!(buckets(Grain::Week, d(2026, 11, 11), d(2026, 11, 25)), vec![d(2026, 11, 9), d(2026, 11, 16), d(2026, 11, 23)]);
    }

    #[test]
    fn series_ranges_cover_the_last_n_buckets() {
        assert_eq!(series_range(Grain::Day, d(2026, 11, 11), 30), (d(2026, 10, 13), d(2026, 11, 11)));
        assert_eq!(series_range(Grain::Week, d(2026, 11, 11), 12), (d(2026, 8, 24), d(2026, 11, 11)));
        assert_eq!(series_range(Grain::Month, d(2026, 11, 11), 12), (d(2025, 12, 1), d(2026, 11, 11)));
        assert_eq!(series_range(Grain::Month, d(2026, 1, 5), 12), (d(2025, 2, 1), d(2026, 1, 5)));
        assert_eq!(buckets(Grain::Month, d(2025, 12, 1), d(2026, 11, 11)).len(), 12);
    }

    #[test]
    fn ratio_in_basis_points_rounds_half_up() {
        assert_eq!(ratio_bps(1, 3), 3_333);
        assert_eq!(ratio_bps(2, 3), 6_667);
        assert_eq!(ratio_bps(0, 0), 0);
    }

    #[test]
    fn vat_estimate_is_ten_percent_of_fee() {
        assert_eq!(vat_estimate(Won(10_400)), Won(1_040));
        assert_eq!(vat_estimate(Won(0)), Won(0));
    }

    #[test]
    fn csv_text_guards_formulas_and_quotes() {
        assert_eq!(csv_text("=SUM(A1)"), "'=SUM(A1)");
        assert_eq!(csv_text("+1+1"), "'+1+1");
        assert_eq!(csv_text("-2"), "'-2");
        assert_eq!(csv_text("@cmd"), "'@cmd");
        assert_eq!(csv_text("a,b"), "\"a,b\"");
        assert_eq!(csv_text("say \"hi\""), "\"say \"\"hi\"\"\"");
        assert_eq!(csv_text("줄\n바꿈"), "\"줄\n바꿈\"");
        assert_eq!(csv_text("정상 텍스트"), "정상 텍스트");
    }

    #[test]
    fn csv_document_has_bom_crlf_and_numeric_cells() {
        let doc = csv_document(&[
            vec![Cell::Text("구분".into()), Cell::Text("금액".into())],
            vec![Cell::Text("=evil".into()), Cell::Number(-5_000)],
        ]);
        assert_eq!(doc, "\u{feff}구분,금액\r\n'=evil,-5000\r\n");
    }
}
