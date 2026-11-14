use crate::{DomainError, Won};
use serde::{Deserialize, Serialize};

/// How a service is booked and priced.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum Pricing {
    /// One price, paid in full at booking.
    Fixed { price: Won, minutes: u32 },
    /// Customer picks one option (count / size), paid in full at booking.
    Unit { units: Vec<UnitOption> },
    /// Estimate first, final price agreed in chat, 10% deposit confirms.
    Quote,
    /// Customer buys each option 0..=`max_each` times (CR-7.1). Two or more items get `multi_discount_bps` off.
    Counts {
        units: Vec<CountUnit>,
        max_each: Option<u8>,
        multi_discount_bps: i64,
    },
}

/// One counted option. `label_key` is the stable id the apps match art and add-ons on; `label` is the owner's display text.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CountUnit {
    pub label_key: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub label: Option<String>,
    pub minutes: u32,
    pub price: Won,
}

/// Smallest booking length for counted pricing, in minutes.
pub const MIN_COUNT_MINUTES: u32 = 60;
/// Hard cap on one option's count, whatever the owner sets as `max_each`.
pub const MAX_COUNT: u8 = 20;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct UnitOption {
    pub label_key: String,
    pub minutes: u32,
    pub price: Won,
}

/// A bookable service. Rows live in the database and are editable in admin;
/// `default_catalog` seeds a fresh install with the prototype's sample prices.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Service {
    pub code: String,
    pub pricing: Pricing,
    /// Customer must have cleaning tools ready (studio, kitchen, bathroom).
    pub needs_preparation: bool,
    /// Studio rule: maximum address size in pyeong, if any.
    pub max_pyeong: Option<u16>,
}

impl Service {
    pub fn is_quote(&self) -> bool {
        matches!(self.pricing, Pricing::Quote)
    }

    /// Price and duration for an optional unit choice. Quote services have no list price.
    pub fn list_price(&self, unit_index: Option<usize>) -> Result<(Won, u32), DomainError> {
        match (&self.pricing, unit_index) {
            (Pricing::Fixed { price, minutes }, None) => Ok((*price, *minutes)),
            (Pricing::Unit { units }, Some(i)) => units.get(i).map(|u| (u.price, u.minutes)).ok_or(DomainError::InvalidUnit),
            _ => Err(DomainError::InvalidUnit),
        }
    }

    /// Price (VAT included) and minutes for a counted basket: one count per option, catalogue order.
    /// Minutes never fall below one hour. Two or more items get the discount, rounded to 100 won.
    pub fn count_price(&self, counts: &[u8]) -> Result<(Won, u32), DomainError> {
        let Pricing::Counts {
            units,
            max_each,
            multi_discount_bps,
        } = &self.pricing
        else {
            return Err(DomainError::InvalidUnit);
        };
        if counts.len() != units.len() {
            return Err(DomainError::InvalidUnit);
        }
        let cap = max_each.unwrap_or(MAX_COUNT).min(MAX_COUNT);
        if counts.iter().any(|&n| n > cap) {
            return Err(DomainError::OutOfRange("count"));
        }
        let items: u32 = counts.iter().map(|&n| u32::from(n)).sum();
        if items == 0 {
            return Err(DomainError::OutOfRange("count"));
        }
        let total: i64 = units.iter().zip(counts).map(|(u, &n)| u.price.0 * i64::from(n)).sum();
        let minutes: u32 = units.iter().zip(counts).map(|(u, &n)| u.minutes * u32::from(n)).sum();
        let off = if items >= 2 {
            Won(total).times_bps(*multi_discount_bps).round100()
        } else {
            Won::ZERO
        };
        Ok((Won(total) - off, minutes.max(MIN_COUNT_MINUTES)))
    }

    /// Spec rule 1: studio cleaning only for small homes.
    pub fn check_address_size(&self, size_pyeong: u16) -> Result<(), DomainError> {
        match self.max_pyeong {
            Some(max) if size_pyeong > max => Err(DomainError::StudioTooLarge { max }),
            _ => Ok(()),
        }
    }
}

fn unit(label_key: &str, minutes: u32, price: i64) -> UnitOption {
    UnitOption {
        label_key: label_key.into(),
        minutes,
        price: Won(price),
    }
}

fn service(code: &str, pricing: Pricing, prep: bool, max_pyeong: Option<u16>) -> Service {
    Service {
        code: code.into(),
        pricing,
        needs_preparation: prep,
        max_pyeong,
    }
}

/// The 8 launch services with the spec's sample prices (VAT included).
pub fn default_catalog() -> Vec<Service> {
    use Pricing::*;
    vec![
        service(
            "studio",
            Fixed {
                price: Won(45_000),
                minutes: 120,
            },
            true,
            Some(10),
        ),
        service(
            "kitchen",
            Fixed {
                price: Won(45_000),
                minutes: 120,
            },
            true,
            None,
        ),
        service(
            "bathroom",
            Unit {
                units: vec![
                    unit("count_1", 120, 39_000),
                    unit("count_2", 120, 52_000),
                    unit("count_3", 180, 69_000),
                    unit("count_4", 240, 84_000),
                ],
            },
            true,
            None,
        ),
        service(
            "mattress",
            Unit {
                units: vec![
                    unit("count_1", 60, 59_000),
                    unit("count_2", 90, 99_000),
                    unit("count_3", 120, 139_000),
                    unit("count_4", 150, 175_000),
                ],
            },
            false,
            None,
        ),
        service(
            "aircon",
            Unit {
                units: vec![
                    unit("wall", 90, 79_000),
                    unit("stand", 120, 119_000),
                    unit("two_in_one", 180, 179_000),
                    unit("ceiling", 120, 139_000),
                ],
            },
            false,
            None,
        ),
        service(
            "sofa",
            Unit {
                units: vec![
                    unit("seat_1_2", 60, 59_000),
                    unit("seat_3", 90, 79_000),
                    unit("seat_4_plus", 120, 99_000),
                    unit("l_shape", 150, 119_000),
                ],
            },
            false,
            None,
        ),
        service("move_out", Quote, false, None),
        service("move_in", Quote, false, None),
    ]
}

#[cfg(test)]
mod tests {
    use super::*;

    fn by_code(code: &str) -> Service {
        default_catalog().into_iter().find(|s| s.code == code).unwrap()
    }

    #[test]
    fn catalog_has_eight_services() {
        assert_eq!(default_catalog().len(), 8);
    }

    #[test]
    fn unit_price_lookup() {
        assert_eq!(by_code("bathroom").list_price(Some(1)), Ok((Won(52_000), 120)));
        assert_eq!(by_code("bathroom").list_price(Some(9)), Err(DomainError::InvalidUnit));
        assert_eq!(by_code("bathroom").list_price(None), Err(DomainError::InvalidUnit));
        assert_eq!(by_code("studio").list_price(None), Ok((Won(45_000), 120)));
        assert!(by_code("move_in").list_price(None).is_err());
    }

    fn counted(units: &[(i64, u32)], max_each: Option<u8>, bps: i64) -> Service {
        let units = units
            .iter()
            .enumerate()
            .map(|(i, &(price, minutes))| CountUnit {
                label_key: format!("o{i}"),
                label: None,
                minutes,
                price: Won(price),
            })
            .collect();
        service(
            "counted",
            Pricing::Counts {
                units,
                max_each,
                multi_discount_bps: bps,
            },
            false,
            None,
        )
    }

    #[test]
    fn counted_basket_takes_discount_from_two_items() {
        // Aircon example from the change request: 2 stand (119,000) + 1 wall (79,000) = 317,000, 10% off.
        let aircon = counted(&[(79_000, 90), (119_000, 120)], Some(5), 1000);
        assert_eq!(aircon.count_price(&[1, 2]), Ok((Won(285_300), 330)));
        // Mattress-style single item: no discount, one hour minimum.
        assert_eq!(aircon.count_price(&[1, 0]), Ok((Won(79_000), 90)));
    }

    #[test]
    fn counted_window_and_disinfection_examples() {
        // Windows: 3 small (9,000 / 15 min) + 2 large (15,000 / 25 min) = 57,000 won, 1h35m, no discount.
        let window = counted(&[(9_000, 15), (15_000, 25)], None, 0);
        assert_eq!(window.count_price(&[3, 2]), Ok((Won(57_000), 95)));
        // Disinfection: pest 80,000 + sanitize 100,000 = 180,000, 10% off -> 162,000.
        let disinfection = counted(&[(80_000, 90), (100_000, 90)], Some(1), 1000);
        assert_eq!(disinfection.count_price(&[1, 1]), Ok((Won(162_000), 180)));
        assert_eq!(disinfection.count_price(&[2, 0]), Err(DomainError::OutOfRange("count")));
    }

    #[test]
    fn counted_basket_refuses_empty_and_wrong_shape() {
        let s = counted(&[(9_000, 15)], None, 0);
        assert_eq!(s.count_price(&[0]), Err(DomainError::OutOfRange("count")));
        assert_eq!(s.count_price(&[1, 1]), Err(DomainError::InvalidUnit));
        assert_eq!(s.count_price(&[21]), Err(DomainError::OutOfRange("count")));
        assert_eq!(by_code("bathroom").count_price(&[1, 0, 0, 0]), Err(DomainError::InvalidUnit));
    }

    #[test]
    fn studio_rule() {
        let studio = by_code("studio");
        assert!(studio.check_address_size(10).is_ok());
        assert_eq!(studio.check_address_size(15), Err(DomainError::StudioTooLarge { max: 10 }));
        assert!(by_code("kitchen").check_address_size(60).is_ok());
    }
}
