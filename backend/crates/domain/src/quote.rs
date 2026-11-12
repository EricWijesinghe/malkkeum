//! Move-in / move-out estimate. The formula's numbers are configuration
//! (editable in admin); the shape of the calculation is fixed here.

use crate::{DomainError, Won};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Layout {
    Studio,
    OneAndHalf,
    TwoRooms,
    ThreeRooms,
    FourPlus,
}

/// Cleaning type within move-in / move-out. Each carries a surcharge.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum CleaningType {
    // move-out
    Standard,
    SameDayMove,
    SomeLuggageLeft,
    // move-in
    NormalMoveIn,
    AfterInterior,
    LivedInDeepClean,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum LuggageState {
    Empty,
    PartlyUnpacked,
    FullyLivedIn,
    Unknown,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum BuildingType {
    Apartment,
    Villa,
    Officetel,
    House,
    Other,
}

/// Customer's answers from the quote steps. Stored as JSON on the booking.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct QuoteAnswers {
    pub cleaning_type: CleaningType,
    pub luggage: LuggageState,
    pub building: BuildingType,
    pub layout: Layout,
    pub duplex: bool,
    pub bathrooms: u8,
    pub balconies: u8,
    pub elevator: bool,
    pub floor_3_or_higher: bool,
}

/// All amounts and rates (basis points, 10_000 = 100%) used by the estimate.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct QuoteFormula {
    pub base_studio: Won,
    pub base_one_and_half: Won,
    pub base_two_rooms: Won,
    pub base_three_rooms: Won,
    pub base_four_plus: Won,
    pub per_extra_bathroom: Won,
    pub per_balcony: Won,
    pub duplex: Won,
    pub no_elevator_high_floor: Won,
    pub type_bps: TypeSurcharges,
    pub luggage_bps: LuggageSurcharges,
    pub vat_bps: i64,
    pub deposit_bps: i64,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TypeSurcharges {
    pub after_interior: i64,
    pub lived_in_deep_clean: i64,
    pub same_day_move: i64,
    pub some_luggage_left: i64,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LuggageSurcharges {
    pub partly_unpacked: i64,
    pub fully_lived_in: i64,
    pub unknown: i64,
}

impl Default for QuoteFormula {
    /// Prototype values; the business confirms final numbers (decision #9).
    fn default() -> Self {
        Self {
            base_studio: Won(180_000),
            base_one_and_half: Won(230_000),
            base_two_rooms: Won(300_000),
            base_three_rooms: Won(380_000),
            base_four_plus: Won(460_000),
            per_extra_bathroom: Won(30_000),
            per_balcony: Won(15_000),
            duplex: Won(60_000),
            no_elevator_high_floor: Won(40_000),
            type_bps: TypeSurcharges {
                after_interior: 2_000,
                lived_in_deep_clean: 1_000,
                same_day_move: 1_000,
                some_luggage_left: 500,
            },
            luggage_bps: LuggageSurcharges {
                partly_unpacked: 500,
                fully_lived_in: 1_500,
                unknown: 1_000,
            },
            vat_bps: 1_000,
            deposit_bps: 1_000,
        }
    }
}

const MAX_ROOMS_COUNT: u8 = 5;
const FULL_BPS: i64 = 10_000;

/// Itemised estimate so the app and admin can show the breakdown.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Estimate {
    pub base: Won,
    pub extras: Won,
    pub surcharge_bps: i64,
    /// Peak (weekend/holiday/evening) rate and its won amount on `base + extras`, shown as its own line.
    pub peak_bps: i64,
    pub peak: Won,
    pub before_vat: Won,
    pub total: Won,
}

impl QuoteFormula {
    fn base(&self, layout: Layout) -> Won {
        match layout {
            Layout::Studio => self.base_studio,
            Layout::OneAndHalf => self.base_one_and_half,
            Layout::TwoRooms => self.base_two_rooms,
            Layout::ThreeRooms => self.base_three_rooms,
            Layout::FourPlus => self.base_four_plus,
        }
    }

    fn type_surcharge(&self, t: CleaningType) -> i64 {
        let s = &self.type_bps;
        match t {
            CleaningType::Standard | CleaningType::NormalMoveIn => 0,
            CleaningType::AfterInterior => s.after_interior,
            CleaningType::LivedInDeepClean => s.lived_in_deep_clean,
            CleaningType::SameDayMove => s.same_day_move,
            CleaningType::SomeLuggageLeft => s.some_luggage_left,
        }
    }

    fn luggage_surcharge(&self, l: LuggageState) -> i64 {
        let s = &self.luggage_bps;
        match l {
            LuggageState::Empty => 0,
            LuggageState::PartlyUnpacked => s.partly_unpacked,
            LuggageState::FullyLivedIn => s.fully_lived_in,
            LuggageState::Unknown => s.unknown,
        }
    }

    pub fn estimate(&self, a: &QuoteAnswers) -> Result<Estimate, DomainError> {
        self.estimate_with_peak(a, 0)
    }

    /// `peak_bps` comes from `peak::peak_surcharge(..).bps` for the requested start time.
    /// shortcut: peak amount is rounded separately, so the displayed lines can differ from `total` by up to 100 won.
    pub fn estimate_with_peak(&self, a: &QuoteAnswers, peak_bps: i64) -> Result<Estimate, DomainError> {
        if !(0..=FULL_BPS).contains(&peak_bps) {
            return Err(DomainError::OutOfRange("peak_bps"));
        }
        if a.bathrooms > MAX_ROOMS_COUNT {
            return Err(DomainError::OutOfRange("bathrooms"));
        }
        if a.balconies > MAX_ROOMS_COUNT {
            return Err(DomainError::OutOfRange("balconies"));
        }
        let base = self.base(a.layout);
        let extra_baths = i64::from(a.bathrooms.saturating_sub(1));
        let mut extras = Won(self.per_extra_bathroom.0 * extra_baths) + Won(self.per_balcony.0 * i64::from(a.balconies));
        if a.duplex {
            extras = extras + self.duplex;
        }
        if !a.elevator && a.floor_3_or_higher {
            extras = extras + self.no_elevator_high_floor;
        }
        let surcharge_bps = self.type_surcharge(a.cleaning_type) + self.luggage_surcharge(a.luggage);
        let subtotal = base + extras;
        let peak = subtotal.times_bps(peak_bps).round100();
        let before_vat = subtotal.times_bps(FULL_BPS + surcharge_bps + peak_bps);
        let total = before_vat.times_bps(FULL_BPS + self.vat_bps).round100();
        Ok(Estimate {
            base,
            extras,
            surcharge_bps,
            peak_bps,
            peak,
            before_vat,
            total,
        })
    }

    /// Spec rule 4: 10% of the final agreed price, rounded to 100 won.
    pub fn deposit(&self, final_price: Won) -> Won {
        final_price.times_bps(self.deposit_bps).round100()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn answers() -> QuoteAnswers {
        QuoteAnswers {
            cleaning_type: CleaningType::AfterInterior,
            luggage: LuggageState::Empty,
            building: BuildingType::Apartment,
            layout: Layout::ThreeRooms,
            duplex: false,
            bathrooms: 2,
            balconies: 2,
            elevator: true,
            floor_3_or_higher: true,
        }
    }

    #[test]
    fn peak_surcharge_is_its_own_line_before_vat() {
        // subtotal 440,000; AfterInterior +20% and peak +20% stack: x1.4 = 616,000; VAT x1.1 = 677,600.
        // Peak line = 440,000 x 20% = 88,000.
        let e = QuoteFormula::default().estimate_with_peak(&answers(), 2_000).unwrap();
        assert_eq!((e.peak_bps, e.peak), (2_000, Won(88_000)));
        assert_eq!(e.before_vat, Won(616_000));
        assert_eq!(e.total, Won(677_600));
    }

    #[test]
    fn zero_peak_matches_plain_estimate() {
        let f = QuoteFormula::default();
        assert_eq!(f.estimate_with_peak(&answers(), 0).unwrap(), f.estimate(&answers()).unwrap());
    }

    #[test]
    fn peak_bps_out_of_range_is_rejected() {
        assert!(QuoteFormula::default().estimate_with_peak(&answers(), 10_001).is_err());
        assert!(QuoteFormula::default().estimate_with_peak(&answers(), -1).is_err());
    }

    #[test]
    fn matches_worked_example() {
        // 380,000 + 30,000 + 30,000 = 440,000; x1.2 = 528,000; x1.1 = 580,800
        let e = QuoteFormula::default().estimate(&answers()).unwrap();
        assert_eq!(e.base, Won(380_000));
        assert_eq!(e.extras, Won(60_000));
        assert_eq!(e.before_vat, Won(528_000));
        assert_eq!(e.total, Won(580_800));
    }

    #[test]
    fn stairs_duplex_and_luggage_add_up() {
        let a = QuoteAnswers {
            cleaning_type: CleaningType::Standard,
            luggage: LuggageState::FullyLivedIn,
            layout: Layout::Studio,
            duplex: true,
            bathrooms: 1,
            balconies: 0,
            elevator: false,
            ..answers()
        };
        // (180,000 + 60,000 + 40,000) x 1.15 = 322,000; x1.1 = 354,200
        assert_eq!(QuoteFormula::default().estimate(&a).unwrap().total, Won(354_200));
    }

    #[test]
    fn zero_bathrooms_has_no_negative_extra() {
        let a = QuoteAnswers {
            bathrooms: 0,
            balconies: 0,
            cleaning_type: CleaningType::NormalMoveIn,
            ..answers()
        };
        assert_eq!(QuoteFormula::default().estimate(&a).unwrap().extras, Won(0));
    }

    #[test]
    fn rejects_out_of_range_counts() {
        let a = QuoteAnswers { bathrooms: 6, ..answers() };
        assert_eq!(QuoteFormula::default().estimate(&a), Err(DomainError::OutOfRange("bathrooms")));
    }

    #[test]
    fn deposit_is_ten_percent() {
        assert_eq!(QuoteFormula::default().deposit(Won(560_000)), Won(56_000));
        assert_eq!(QuoteFormula::default().deposit(Won(580_800)), Won(58_100));
    }
}
