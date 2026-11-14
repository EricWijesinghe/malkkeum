use crate::{DomainError, Won};
use serde::{Deserialize, Serialize};

/// A counts booking must take at least this long: the visit fee covers the trip.
pub const MIN_COUNT_MINUTES: u32 = 60;
/// Per-option ceiling for counts services that set no `max_each`.
pub const MAX_COUNT: u8 = 20;
const FULL_BPS: i64 = 10_000;

/// How a service is booked and priced.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum Pricing {
    /// One price, paid in full at booking.
    Fixed { price: Won, minutes: u32 },
    /// Customer picks one option (count / size), paid in full at booking.
    Unit { units: Vec<UnitOption> },
    /// Several units of each option in one booking, paid in full. `max_each` caps one option
    /// (default `MAX_COUNT`); two or more items take `multi_discount_bps` off.
    Counts {
        units: Vec<UnitOption>,
        #[serde(default)]
        max_each: Option<u8>,
        #[serde(default)]
        multi_discount_bps: i64,
    },
    /// Estimate first, final price agreed in chat, 10% deposit confirms.
    Quote,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct UnitOption {
    pub label_key: String,
    pub minutes: u32,
    pub price: Won,
}

impl Pricing {
    /// The priced options of a unit or counts service, in catalogue order.
    pub fn options(&self) -> Option<&[UnitOption]> {
        match self {
            Self::Unit { units } | Self::Counts { units, .. } => Some(units.as_slice()),
            Self::Fixed { .. } | Self::Quote => None,
        }
    }
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
            (pricing, Some(i)) => pricing
                .options()
                .and_then(|u| u.get(i))
                .map(|u| (u.price, u.minutes))
                .ok_or(DomainError::InvalidUnit),
            _ => Err(DomainError::InvalidUnit),
        }
    }

    /// Counts service: price and minutes for one count per option (catalogue order).
    /// Two or more items take the multi-item discount, rounded like the other discounts.
    pub fn count_price(&self, counts: &[u8]) -> Result<(Won, u32), DomainError> {
        let Pricing::Counts {
            units,
            max_each,
            multi_discount_bps,
        } = &self.pricing
        else {
            return Err(DomainError::InvalidUnit);
        };
        let cap = max_each.unwrap_or(MAX_COUNT);
        if counts.len() != units.len() || counts.iter().any(|n| *n > cap) {
            return Err(DomainError::OutOfRange("counts"));
        }
        let items: u32 = counts.iter().map(|n| u32::from(*n)).sum();
        if items == 0 {
            return Err(DomainError::OutOfRange("counts"));
        }
        let list = units.iter().zip(counts).fold(Won::ZERO, |sum, (u, n)| sum + Won(u.price.0 * i64::from(*n)));
        let minutes = units
            .iter()
            .zip(counts)
            .map(|(u, n)| u.minutes * u32::from(*n))
            .sum::<u32>()
            .max(MIN_COUNT_MINUTES);
        let discount = multi_item_discount(list, *multi_discount_bps)?;
        let total = if items >= 2 { list.saturating_sub(discount) } else { list };
        Ok((total, minutes))
    }

    /// Counts for a booking: its own `counts`, or a legacy `unit_index` read as one item of that option.
    pub fn counts_for(&self, unit_index: Option<usize>, counts: &[u8]) -> Result<Vec<u8>, DomainError> {
        if !counts.is_empty() {
            return Ok(counts.to_vec());
        }
        let options = self.pricing.options().unwrap_or(&[]);
        match unit_index {
            Some(i) if i < options.len() => {
                let mut one_each = vec![0u8; options.len()];
                one_each[i] = 1;
                Ok(one_each)
            }
            _ => Err(DomainError::InvalidUnit),
        }
    }

    /// Spec rule 1: studio cleaning only for small homes.
    pub fn check_address_size(&self, size_pyeong: u16) -> Result<(), DomainError> {
        match self.max_pyeong {
            Some(max) if size_pyeong > max => Err(DomainError::StudioTooLarge { max }),
            _ => Ok(()),
        }
    }
}

/// The multi-item discount on `list`: `bps` of it, rounded to 100 won. Returns the amount taken off.
fn multi_item_discount(list: Won, bps: i64) -> Result<Won, DomainError> {
    if !(0..=FULL_BPS).contains(&bps) {
        return Err(DomainError::OutOfRange("multi_discount_bps"));
    }
    Ok(list.times_bps(bps).round100())
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

/// The launch services with the spec's placeholder prices (VAT included). Owners edit them in the console.
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
            Counts {
                units: vec![unit("mattress", 60, 59_000)],
                max_each: None,
                multi_discount_bps: 1_500,
            },
            false,
            None,
        ),
        service(
            "aircon",
            Counts {
                units: vec![
                    unit("wall", 90, 79_000),
                    unit("stand", 120, 119_000),
                    unit("two_in_one", 180, 179_000),
                    unit("ceiling", 120, 139_000),
                ],
                max_each: None,
                multi_discount_bps: 1_000,
            },
            false,
            None,
        ),
        service(
            "sofa",
            Counts {
                units: vec![
                    unit("seat_1_2", 60, 59_000),
                    unit("seat_3", 90, 79_000),
                    unit("seat_4_plus", 120, 99_000),
                    unit("l_shape", 150, 119_000),
                ],
                max_each: None,
                multi_discount_bps: 1_000,
            },
            false,
            None,
        ),
        service("move_out", Quote, false, None),
        service("move_in", Quote, false, None),
        service("whole_home", Quote, true, None),
        service(
            "window",
            Counts {
                units: vec![unit("window_small", 15, 9_000), unit("window_large", 25, 15_000)],
                max_each: None,
                multi_discount_bps: 0,
            },
            false,
            None,
        ),
        service(
            "disinfection",
            Counts {
                units: vec![
                    unit("pest", 90, 80_000),
                    unit("mite_bedbug", 120, 90_000),
                    unit("sanitize", 90, 100_000),
                    unit("sick_house", 240, 300_000),
                ],
                max_each: Some(1),
                multi_discount_bps: 1_000,
            },
            false,
            None,
        ),
    ]
}

#[cfg(test)]
mod tests {
    use super::*;

    fn by_code(code: &str) -> Service {
        default_catalog().into_iter().find(|s| s.code == code).unwrap()
    }

    #[test]
    fn catalog_has_eleven_services() {
        assert_eq!(default_catalog().len(), 11);
    }

    #[test]
    fn unit_price_lookup() {
        assert_eq!(by_code("bathroom").list_price(Some(1)), Ok((Won(52_000), 120)));
        assert_eq!(by_code("bathroom").list_price(Some(9)), Err(DomainError::InvalidUnit));
        assert_eq!(by_code("bathroom").list_price(None), Err(DomainError::InvalidUnit));
        assert_eq!(by_code("studio").list_price(None), Ok((Won(45_000), 120)));
        assert!(by_code("move_in").list_price(None).is_err());
    }

    #[test]
    fn studio_rule() {
        let studio = by_code("studio");
        assert!(studio.check_address_size(10).is_ok());
        assert_eq!(studio.check_address_size(15), Err(DomainError::StudioTooLarge { max: 10 }));
        assert!(by_code("kitchen").check_address_size(60).is_ok());
    }

    #[test]
    fn counts_json_defaults_optional_fields() {
        let v = serde_json::json!({"type":"counts","units":[{"label_key":"w","minutes":15,"price":9000}]});
        let p: Pricing = serde_json::from_value(v).unwrap();
        assert_eq!(
            p,
            Pricing::Counts {
                units: vec![unit("w", 15, 9_000)],
                max_each: None,
                multi_discount_bps: 0
            }
        );
    }

    #[test]
    fn spec_example_aircon_two_stand_one_wall() {
        // 2 x 119,000 + 1 x 79,000 = 317,000, -10% = 285,300; 2 x 120 + 90 = 330 minutes.
        assert_eq!(by_code("aircon").count_price(&[1, 2, 0, 0]), Ok((Won(285_300), 330)));
    }

    #[test]
    fn spec_example_window_three_small_two_large() {
        // 3 x 9,000 + 2 x 15,000 = 57,000 (no multi discount); 3 x 15 + 2 x 25 = 95 minutes.
        assert_eq!(by_code("window").count_price(&[3, 2]), Ok((Won(57_000), 95)));
    }

    #[test]
    fn spec_example_disinfection_pest_and_sanitize() {
        // 80,000 + 100,000 = 180,000, -10% = 162,000.
        assert_eq!(by_code("disinfection").count_price(&[1, 0, 1, 0]), Ok((Won(162_000), 180)));
    }

    #[test]
    fn max_each_caps_each_option() {
        assert!(by_code("disinfection").count_price(&[2, 0, 0, 0]).is_err());
        assert!(by_code("aircon").count_price(&[20, 0, 0, 0]).is_ok());
        assert!(by_code("aircon").count_price(&[21, 0, 0, 0]).is_err());
    }

    #[test]
    fn counts_need_one_item_and_one_count_per_option() {
        let w = by_code("window");
        assert_eq!(w.count_price(&[0, 0]), Err(DomainError::OutOfRange("counts")));
        assert_eq!(w.count_price(&[1]), Err(DomainError::OutOfRange("counts")));
    }

    #[test]
    fn minimum_sixty_minutes() {
        // One small window is 15 minutes of work; the booking still takes an hour.
        assert_eq!(by_code("window").count_price(&[1, 0]), Ok((Won(9_000), 60)));
    }

    #[test]
    fn legacy_unit_index_reads_as_one_item() {
        let mattress = by_code("mattress");
        assert_eq!(mattress.counts_for(Some(0), &[]), Ok(vec![1]));
        assert_eq!(mattress.counts_for(Some(1), &[]), Err(DomainError::InvalidUnit));
        assert_eq!(mattress.counts_for(None, &[]), Err(DomainError::InvalidUnit));
        assert_eq!(mattress.counts_for(Some(3), &[2]), Ok(vec![2]), "counts win over unit_index");
    }
}
