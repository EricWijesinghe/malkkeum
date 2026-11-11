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

/// Splits a VAT-inclusive amount into (공급가액, 세액). VAT is 1/11 of the total, floored; supply is the rest.
/// ACCOUNTANT: confirm the rounding rule for 세금계산서 against the invoice rules.
pub fn split_vat_inclusive(total: i64) -> (i64, i64) {
    let vat = total / 11;
    (total - vat, vat)
}

/// One 세금계산서 line, one per settled checkout that the customer asked to be invoiced.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct InvoiceRow {
    pub day: NaiveDate,
    pub business_number: String,
    pub company_name: String,
    pub representative: String,
    pub business_type: String,
    pub business_item: String,
    pub address: String,
    pub email: String,
    pub item_name: String,
    pub total: i64,
}

/// Column layout of the owner's 홈택스 upload sheet. UNVERIFIED: the 홈택스 일괄작성 양식 was not available to
/// check when this was written. Map these columns to the downloaded template with the accountant before uploading.
pub const TAX_INVOICE_HEADERS: [&str; 12] = [
    "작성일자", "사업자등록번호", "상호", "대표자", "업태", "종목", "주소", "이메일", "품목", "공급가액", "세액", "합계",
];

/// Rows for the owner's 홈택스 upload, in request order. Supplier columns are filled on 홈택스 from the owner's login.
pub fn tax_invoice_document(rows: &[InvoiceRow]) -> Vec<Vec<Cell>> {
    let text = |s: &str| Cell::Text(s.to_string());
    let mut doc = vec![TAX_INVOICE_HEADERS.iter().map(|h| text(h)).collect::<Vec<_>>()];
    for r in rows {
        let (supply, vat) = split_vat_inclusive(r.total);
        doc.push(vec![
            text(&r.day.to_string()),
            text(&r.business_number),
            text(&r.company_name),
            text(&r.representative),
            text(&r.business_type),
            text(&r.business_item),
            text(&r.address),
            text(&r.email),
            text(&r.item_name),
            Cell::Number(supply),
            Cell::Number(vat),
            Cell::Number(r.total),
        ]);
    }
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
    fn vat_split_is_one_eleventh_floored() {
        assert_eq!(split_vat_inclusive(110_000), (100_000, 10_000));
        assert_eq!(split_vat_inclusive(100_000), (90_910, 9_090));
        assert_eq!(split_vat_inclusive(0), (0, 0));
    }

    #[test]
    fn tax_invoice_document_matches_golden() {
        let rows = vec![InvoiceRow {
            day: NaiveDate::from_ymd_opt(2026, 8, 14).unwrap(),
            business_number: "2208162517".into(),
            company_name: "말끔주식회사".into(),
            representative: "홍길동".into(),
            business_type: "서비스".into(),
            business_item: "청소".into(),
            address: "서울특별시 강남구 테헤란로 1".into(),
            email: "tax@example.test".into(),
            item_name: "청소 서비스".into(),
            total: 110_000,
        }];
        let out = finance::csv_document(&tax_invoice_document(&rows));
        let golden = include_str!("../tests/golden/tax_invoice_2026q3.csv");
        assert_eq!(out.trim_start_matches(finance::CSV_BOM).replace("\r\n", "\n"), golden.replace("\r\n", "\n"));
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
