use crate::{DomainError, Won, catalog::Service, coupon::Coupon};
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
pub fn price_booking(
    service: &Service,
    unit_index: Option<usize>,
    coupon: Option<&Coupon>,
    now: DateTime<Utc>,
) -> Result<PriceBreakdown, DomainError> {
    let (list_price, minutes) = service.list_price(unit_index)?;
    let discount = match coupon {
        Some(c) => c.discount_for(list_price, &service.code, now)?,
        None => Won::ZERO,
    };
    Ok(PriceBreakdown { list_price, discount, total: list_price.saturating_sub(discount), minutes })
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
}
