//! Korean tax rules for owner compliance exports. Pure: amounts and dates in, numbers out.
//! Rules marked `ACCOUNTANT` are not verified against a statute text and must be confirmed (see docs/finance-tax.md).

use crate::finance::{self, Cell};
use crate::{DomainError, Won};
use chrono::NaiveDate;

/// 사업소득 원천징수 세율 3% (소득세법 제129조 일대; ACCOUNTANT: confirm article and rate).
const BUSINESS_INCOME_TAX_BPS: i64 = 300;

/// Withholding split for one payout to a sole-proprietor / freelancer partner.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Withholding {
    pub gross: Won,
    pub income_tax: Won,
    pub local_tax: Won,
    pub net: Won,
}

/// 사업소득 원천징수: income tax = 3% of gross, floored to won. Local income tax = 10% of the income tax,
/// floored to 10 won. ACCOUNTANT: confirm base amount (gross vs net-of-fee) and both rounding units.
pub fn business_withholding(gross: Won) -> Withholding {
    let gross = gross.0.max(0);
    let income_tax = gross * BUSINESS_INCOME_TAX_BPS / 10_000;
    let local_tax = income_tax / 100 * 10;
    Withholding {
        gross: Won(gross),
        income_tax: Won(income_tax),
        local_tax: Won(local_tax),
        net: Won(gross - income_tax - local_tax),
    }
}

/// Inclusive date range of a Korean calendar quarter (1..=4).
pub fn quarter_range(year: i32, quarter: u32) -> Result<(NaiveDate, NaiveDate), DomainError> {
    let (start_m, end_m, end_d) = match quarter {
        1 => (1, 3, 31),
        2 => (4, 6, 30),
        3 => (7, 9, 30),
        4 => (10, 12, 31),
        _ => return Err(DomainError::OutOfRange("quarter")),
    };
    let from = NaiveDate::from_ymd_opt(year, start_m, 1).ok_or(DomainError::OutOfRange("year"))?;
    let to = NaiveDate::from_ymd_opt(year, end_m, end_d).ok_or(DomainError::OutOfRange("year"))?;
    Ok((from, to))
}

/// One payment method's paid sales in the period.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct VatMethod {
    pub method: String,
    pub count: i64,
    pub amount: i64,
}

/// Raw period totals gathered by the API from the database.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct VatInput {
    pub methods: Vec<VatMethod>,
    /// Platform fee (settlements.fee) in the period; the existing finance VAT basis.
    pub platform_fee: Won,
    /// Refunds recorded on payments created in the period. ACCOUNTANT: refunds by payment date, not refund date.
    pub refunds: Won,
}

/// Quarterly VAT summary: sales by payment method, then the fee-based VAT estimate.
/// Cash receipt / tax invoice split is added with those features.
pub fn vat_document(input: &VatInput) -> Vec<Vec<Cell>> {
    let text = |s: &str| Cell::Text(s.to_string());
    let mut doc = vec![vec![text("결제수단"), text("건수"), text("결제액")]];
    let mut count = 0;
    let mut amount = 0;
    for m in &input.methods {
        count += m.count;
        amount += m.amount;
        doc.push(vec![text(&m.method), Cell::Number(m.count), Cell::Number(m.amount)]);
    }
    doc.push(vec![text("합계"), Cell::Number(count), Cell::Number(amount)]);
    doc.push(vec![text("환불액"), Cell::Number(0), Cell::Number(input.refunds.0)]);
    doc.push(vec![text("플랫폼수수료(과세표준 추정)"), Cell::Number(0), Cell::Number(input.platform_fee.0)]);
    doc.push(vec![text("부가세 추정(수수료의 10%)"), Cell::Number(0), Cell::Number(finance::vat_estimate(input.platform_fee).0)]);
    doc
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn withholding_floors_income_tax_and_local_tax() {
        let w = business_withholding(Won(123_456));
        assert_eq!(w.income_tax, Won(3_703)); // 3% = 3703.68
        assert_eq!(w.local_tax, Won(370)); // 10% of 3703, floored to 10 won
        assert_eq!(w.net, Won(119_383));
        assert_eq!(w.income_tax.0 + w.local_tax.0 + w.net.0, 123_456);
    }

    #[test]
    fn withholding_round_numbers_and_zero() {
        let w = business_withholding(Won(100_000));
        assert_eq!((w.income_tax, w.local_tax, w.net), (Won(3_000), Won(300), Won(96_700)));
        let z = business_withholding(Won(0));
        assert_eq!((z.income_tax, z.local_tax, z.net), (Won(0), Won(0), Won(0)));
        assert_eq!(business_withholding(Won(-5)).net, Won(0));
    }

    #[test]
    fn quarter_ranges_cover_the_year_without_gaps() {
        assert_eq!(quarter_range(2026, 1).unwrap(), (NaiveDate::from_ymd_opt(2026, 1, 1).unwrap(), NaiveDate::from_ymd_opt(2026, 3, 31).unwrap()));
        assert_eq!(quarter_range(2026, 4).unwrap().1, NaiveDate::from_ymd_opt(2026, 12, 31).unwrap());
        assert!(quarter_range(2026, 0).is_err());
        assert!(quarter_range(2026, 5).is_err());
    }

    #[test]
    fn vat_document_matches_golden() {
        let input = VatInput {
            methods: vec![
                VatMethod { method: "card".into(), count: 3, amount: 330_000 },
                VatMethod { method: "transfer".into(), count: 1, amount: 110_000 },
            ],
            platform_fee: Won(88_000),
            refunds: Won(22_000),
        };
        let out = finance::csv_document(&vat_document(&input));
        let golden = include_str!("../tests/golden/vat_2026q3.csv");
        // Git may check the fixture out with LF; compare line endings loosely.
        assert_eq!(out.trim_start_matches(finance::CSV_BOM).replace("\r\n", "\n"), golden.replace("\r\n", "\n"));
    }
}
