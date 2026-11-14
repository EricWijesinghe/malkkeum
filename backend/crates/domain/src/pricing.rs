use crate::{
    DomainError, Won,
    catalog::{Pricing, Service},
    coupon::Coupon,
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PriceBreakdown {
    pub list_price: Won,
    pub discount: Won,
    pub total: Won,
    pub minutes: u32,
}

/// Server-authoritative price for a fixed / unit booking (paid in full).
pub fn price_booking(service: &Service, unit_index: Option<usize>, coupon: Option<&Coupon>, now: DateTime<Utc>) -> Result<PriceBreakdown, DomainError> {
    price_booking_with(service, unit_index, &[], coupon, now)
}

/// Like `price_booking`, with one count per option for counts services (`counts` wins over `unit_index`).
pub fn price_booking_with(
    service: &Service,
    unit_index: Option<usize>,
    counts: &[u8],
    coupon: Option<&Coupon>,
    now: DateTime<Utc>,
) -> Result<PriceBreakdown, DomainError> {
    let (list_price, minutes) = match &service.pricing {
        Pricing::Counts { .. } => service.count_price(&service.counts_for(unit_index, counts)?)?,
        _ if counts.is_empty() => service.list_price(unit_index)?,
        _ => return Err(DomainError::InvalidUnit),
    };
    let discount = match coupon {
        Some(c) => c.discount_for(list_price, &service.code, now)?,
        None => Won::ZERO,
    };
    Ok(PriceBreakdown {
        list_price,
        discount,
        total: list_price.saturating_sub(discount),
        minutes,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::catalog::default_catalog;
    use chrono::TimeZone;

    #[test]
    fn bathroom_with_welcome_coupon() {
        let now = Utc.with_ymd_and_hms(2026, 11, 10, 0, 0, 0).unwrap();
        let bath = default_catalog().into_iter().find(|s| s.code == "bathroom").unwrap();
        let c = Coupon::issue(Won(5_000), None, now);
        let p = price_booking(&bath, Some(1), Some(&c), now).unwrap();
        assert_eq!((p.list_price, p.discount, p.total, p.minutes), (Won(52_000), Won(5_000), Won(47_000), 120));
    }

    fn by_code(code: &str) -> Service {
        default_catalog().into_iter().find(|s| s.code == code).unwrap()
    }

    fn now() -> DateTime<Utc> {
        Utc.with_ymd_and_hms(2026, 11, 10, 0, 0, 0).unwrap()
    }

    #[test]
    fn counts_example_aircon_total_and_minutes() {
        let p = price_booking_with(&by_code("aircon"), None, &[0, 2, 1, 0], None, now()).unwrap();
        // 2 stand + 1 two_in_one is 417,000 before the discount; 10% off = 375,300.
        assert_eq!((p.list_price, p.total, p.minutes), (Won(375_300), Won(375_300), 420));
    }

    #[test]
    fn counts_example_stand_two_wall_one() {
        let p = price_booking_with(&by_code("aircon"), None, &[1, 2, 0, 0], None, now()).unwrap();
        assert_eq!((p.list_price, p.total, p.minutes), (Won(285_300), Won(285_300), 330));
    }

    #[test]
    fn counts_example_window_three_small_two_large() {
        let p = price_booking_with(&by_code("window"), None, &[3, 2], None, now()).unwrap();
        assert_eq!((p.list_price, p.minutes), (Won(57_000), 95));
    }

    #[test]
    fn counts_example_disinfection_pest_and_sanitize() {
        let p = price_booking_with(&by_code("disinfection"), None, &[1, 0, 1, 0], None, now()).unwrap();
        assert_eq!((p.list_price, p.total), (Won(162_000), Won(162_000)));
    }

    #[test]
    fn legacy_mattress_unit_index_prices_one_mattress() {
        let p = price_booking(&by_code("mattress"), Some(0), None, now()).unwrap();
        assert_eq!((p.list_price, p.minutes), (Won(59_000), 60));
        assert_eq!(price_booking(&by_code("mattress"), Some(1), None, now()), Err(DomainError::InvalidUnit));
    }

    #[test]
    fn counts_mattress_two_pieces_take_fifteen_percent_off() {
        // 2 x 59,000 = 118,000, -15% = 100,300 (rounded to 100 won).
        let p = price_booking_with(&by_code("mattress"), None, &[2], None, now()).unwrap();
        assert_eq!(p.total, Won(100_300));
    }

    #[test]
    fn counts_rejected_on_a_unit_service() {
        assert_eq!(
            price_booking_with(&by_code("bathroom"), Some(0), &[1, 0, 0, 0], None, now()),
            Err(DomainError::InvalidUnit)
        );
    }
}
