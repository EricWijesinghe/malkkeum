//! Move-in / move-out estimate. The formula's numbers are configuration
//! (editable in admin); the shape of the calculation is fixed here.

use crate::{
    DomainError, Won,
    catalog::{Pricing, Service},
};
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
    /// Moving boxes in, none opened yet.
    NotUnpacked,
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
    Commercial,
    Other,
}

/// One aircon unit type added to a move-in / move-out booking. `unit` is the aircon
/// service's `label_key` (wall, stand, two_in_one, ceiling); its price comes from the catalog.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AcAddon {
    pub unit: String,
    pub count: u8,
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
    /// Older bookings have no add-ons; absent and empty are the same.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub ac_addons: Vec<AcAddon>,
    /// The home type picked on the home-type chooser. Absent on bookings made before it existed.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub home_type: Option<HomeType>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum HomeType {
    OneTwoRoom,
    Apartment,
    VillaHouse,
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
    /// Discount on aircon add-ons booked with a move clean. Saved formulas without it get the default.
    #[serde(default = "default_ac_addon_discount_bps")]
    pub ac_addon_discount_bps: i64,
}

/// 10% off; the owner edits it in the console catalog.
pub const DEFAULT_AC_ADDON_DISCOUNT_BPS: i64 = 1_000;

/// shortcut: prototype value between empty and partly unpacked, owner to confirm in the console formula.
const DEFAULT_NOT_UNPACKED_BPS: i64 = 300;

fn default_not_unpacked_bps() -> i64 {
    DEFAULT_NOT_UNPACKED_BPS
}

fn default_ac_addon_discount_bps() -> i64 {
    DEFAULT_AC_ADDON_DISCOUNT_BPS
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
    /// Added after the other states; saved formulas without it get the default.
    #[serde(default = "default_not_unpacked_bps")]
    pub not_unpacked: i64,
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
                not_unpacked: DEFAULT_NOT_UNPACKED_BPS,
                partly_unpacked: 500,
                fully_lived_in: 1_500,
                unknown: 1_000,
            },
            vat_bps: 1_000,
            deposit_bps: 1_000,
            ac_addon_discount_bps: DEFAULT_AC_ADDON_DISCOUNT_BPS,
        }
    }
}

const MAX_ROOMS_COUNT: u8 = 5;
const FULL_BPS: i64 = 10_000;
/// Per unit type; more than this is a separate aircon booking.
pub const MAX_AC_ADDON_UNITS: u8 = 5;

/// Discounted sum of aircon add-on lines `(catalog unit price, count)`, rounded to 100 won.
/// Catalog prices already include VAT, so this is added after the move estimate's VAT.
pub fn addon_total(lines: &[(Won, u8)], discount_bps: i64) -> Result<Won, DomainError> {
    if !(0..=FULL_BPS).contains(&discount_bps) {
        return Err(DomainError::OutOfRange("ac_addon_discount_bps"));
    }
    let list = lines.iter().fold(Won(0), |sum, (price, count)| sum + Won(price.0 * i64::from(*count)));
    Ok(list.times_bps(FULL_BPS - discount_bps).round100())
}

/// Prices each add-on from the aircon service's unit options. Unknown, repeated or
/// out-of-range units are rejected so the client cannot pick its own price.
pub fn resolve_ac_addons(aircon: &Service, addons: &[AcAddon]) -> Result<Vec<(Won, u8)>, DomainError> {
    let Pricing::Unit { units } = &aircon.pricing else {
        return Err(DomainError::InvalidUnit);
    };
    let mut seen: Vec<&str> = Vec::with_capacity(addons.len());
    addons
        .iter()
        .map(|a| {
            if a.count == 0 || a.count > MAX_AC_ADDON_UNITS {
                return Err(DomainError::OutOfRange("ac_addons"));
            }
            if seen.contains(&a.unit.as_str()) {
                return Err(DomainError::InvalidUnit);
            }
            seen.push(&a.unit);
            let unit = units.iter().find(|u| u.label_key == a.unit).ok_or(DomainError::InvalidUnit)?;
            Ok((unit.price, a.count))
        })
        .collect()
}

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
    /// Aircon add-ons after their discount (VAT already included). Zero without add-ons.
    #[serde(default)]
    pub addons: Won,
    #[serde(default)]
    pub addon_discount_bps: i64,
    pub total: Won,
    /// What the deposit would be if the total were confirmed as-is (the app's "예약금" preview).
    #[serde(default)]
    pub deposit: Won,
    #[serde(default)]
    pub deposit_bps: i64,
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
            LuggageState::NotUnpacked => s.not_unpacked,
            LuggageState::PartlyUnpacked => s.partly_unpacked,
            LuggageState::FullyLivedIn => s.fully_lived_in,
            LuggageState::Unknown => s.unknown,
        }
    }

    pub fn estimate(&self, a: &QuoteAnswers) -> Result<Estimate, DomainError> {
        self.estimate_with_peak(a, 0)
    }

    /// Answers with aircon add-ons need their catalog prices: use [`Self::estimate_with_addons`].
    pub fn estimate_with_peak(&self, a: &QuoteAnswers, peak_bps: i64) -> Result<Estimate, DomainError> {
        self.estimate_with_addons(a, peak_bps, &[])
    }

    /// `peak_bps` comes from `peak::peak_surcharge(..).bps` for the requested start time.
    /// `addon_lines` is `resolve_ac_addons(aircon, &a.ac_addons)`, one line per add-on, so a
    /// caller that forgot to price them gets an error instead of a silently lower total.
    /// shortcut: peak amount is rounded separately, so the displayed lines can differ from `total` by up to 100 won.
    pub fn estimate_with_addons(&self, a: &QuoteAnswers, peak_bps: i64, addon_lines: &[(Won, u8)]) -> Result<Estimate, DomainError> {
        if addon_lines.len() != a.ac_addons.len() {
            return Err(DomainError::InvalidUnit);
        }
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
        let addons = addon_total(addon_lines, self.ac_addon_discount_bps)?;
        let total = before_vat.times_bps(FULL_BPS + self.vat_bps).round100() + addons;
        Ok(Estimate {
            base,
            extras,
            surcharge_bps,
            peak_bps,
            peak,
            before_vat,
            addons,
            addon_discount_bps: if addon_lines.is_empty() { 0 } else { self.ac_addon_discount_bps },
            total,
            deposit: self.deposit(total),
            deposit_bps: self.deposit_bps,
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
            ac_addons: vec![],
            home_type: None,
        }
    }

    fn aircon() -> Service {
        crate::catalog::default_catalog().into_iter().find(|s| s.code == "aircon").unwrap()
    }

    fn addon(unit: &str, count: u8) -> AcAddon {
        AcAddon { unit: unit.into(), count }
    }

    #[test]
    fn commercial_building_parses() {
        let b: BuildingType = serde_json::from_str("\"commercial\"").unwrap();
        assert_eq!(b, BuildingType::Commercial);
    }

    #[test]
    fn old_answers_and_formula_json_still_deserialise() {
        let mut v = serde_json::to_value(answers()).unwrap();
        assert!(v.get("ac_addons").is_none(), "empty add-ons are not written");
        v.as_object_mut().unwrap().remove("ac_addons");
        let a: QuoteAnswers = serde_json::from_value(v).unwrap();
        assert!(a.ac_addons.is_empty());
        let mut f = serde_json::to_value(QuoteFormula::default()).unwrap();
        f.as_object_mut().unwrap().remove("ac_addon_discount_bps");
        let f: QuoteFormula = serde_json::from_value(f).unwrap();
        assert_eq!(f.ac_addon_discount_bps, 1_000);
        let e: Estimate = serde_json::from_str(r#"{"base":1,"extras":0,"surcharge_bps":0,"peak_bps":0,"peak":0,"before_vat":1,"total":1}"#).unwrap();
        assert_eq!(e.addons, Won(0));
    }

    #[test]
    fn not_unpacked_luggage_parses_and_has_its_own_surcharge() {
        let l: LuggageState = serde_json::from_str(r#""not_unpacked""#).unwrap();
        let a = QuoteAnswers { luggage: l, ..answers() };
        // 440,000 x (1 + 20% + 3%) = 541,200; x1.1 = 595,320 -> 595,300
        let e = QuoteFormula::default().estimate(&a).unwrap();
        assert_eq!((e.surcharge_bps, e.total), (2_300, Won(595_300)));
        let mut f = serde_json::to_value(QuoteFormula::default()).unwrap();
        f["luggage_bps"].as_object_mut().unwrap().remove("not_unpacked");
        let f: QuoteFormula = serde_json::from_value(f).unwrap();
        assert_eq!(f.luggage_bps.not_unpacked, 300);
    }

    #[test]
    fn estimate_previews_the_deposit_of_its_total() {
        // Brief example: 346,500 estimate -> 34,700 deposit (10%, rounded to 100).
        let e = QuoteFormula::default().estimate(&answers()).unwrap();
        assert_eq!((e.deposit, e.deposit_bps), (QuoteFormula::default().deposit(e.total), 1_000));
        assert_eq!(QuoteFormula::default().deposit(Won(346_500)), Won(34_700));
    }

    #[test]
    fn no_addons_leaves_total_unchanged() {
        let e = QuoteFormula::default().estimate_with_addons(&answers(), 0, &[]).unwrap();
        assert_eq!((e.addons, e.addon_discount_bps, e.total), (Won(0), 0, Won(580_800)));
    }

    #[test]
    fn home_type_round_trips_and_is_optional_for_old_answers() {
        let a = QuoteAnswers {
            home_type: Some(HomeType::VillaHouse),
            ..answers()
        };
        let json = serde_json::to_value(&a).unwrap();
        assert_eq!(json["home_type"], "villa_house");
        let back: QuoteAnswers = serde_json::from_value(json).unwrap();
        assert_eq!(back.home_type, Some(HomeType::VillaHouse));
        let old: QuoteAnswers = serde_json::from_value(serde_json::json!({
            "cleaning_type": "standard", "luggage": "empty", "building": "apartment",
            "layout": "three_rooms", "duplex": false, "bathrooms": 1, "balconies": 0,
            "elevator": true, "floor_3_or_higher": false
        }))
        .unwrap();
        assert_eq!(old.home_type, None);
    }

    #[test]
    fn addons_get_the_discount_after_vat() {
        let a = QuoteAnswers {
            ac_addons: vec![addon("wall", 2), addon("two_in_one", 1)],
            ..answers()
        };
        let lines = resolve_ac_addons(&aircon(), &a.ac_addons).unwrap();
        assert_eq!(lines, vec![(Won(79_000), 2), (Won(179_000), 1)]);
        // (158,000 + 179,000) x 0.9 = 303,300; added to the 580,800 move total.
        let e = QuoteFormula::default().estimate_with_addons(&a, 0, &lines).unwrap();
        assert_eq!((e.addons, e.addon_discount_bps), (Won(303_300), 1_000));
        assert_eq!(e.total, Won(884_100));
    }

    #[test]
    fn unpriced_addons_are_an_error_not_a_free_unit() {
        let a = QuoteAnswers {
            ac_addons: vec![addon("wall", 1)],
            ..answers()
        };
        assert_eq!(QuoteFormula::default().estimate(&a), Err(DomainError::InvalidUnit));
    }

    #[test]
    fn bad_addons_are_rejected() {
        let s = aircon();
        assert_eq!(resolve_ac_addons(&s, &[addon("window", 1)]), Err(DomainError::InvalidUnit));
        assert_eq!(resolve_ac_addons(&s, &[addon("wall", 1), addon("wall", 1)]), Err(DomainError::InvalidUnit));
        assert_eq!(resolve_ac_addons(&s, &[addon("wall", 0)]), Err(DomainError::OutOfRange("ac_addons")));
        assert_eq!(resolve_ac_addons(&s, &[addon("wall", 6)]), Err(DomainError::OutOfRange("ac_addons")));
        let studio = crate::catalog::default_catalog().into_iter().find(|s| s.code == "studio").unwrap();
        assert_eq!(resolve_ac_addons(&studio, &[addon("wall", 1)]), Err(DomainError::InvalidUnit));
    }

    #[test]
    fn addon_discount_stays_within_list_price_for_every_bps() {
        let lines = [(Won(79_000), 5), (Won(139_000), 3)];
        let list = 79_000 * 5 + 139_000 * 3;
        for bps in (0..=10_000).step_by(37).chain([10_000]) {
            let t = addon_total(&lines, bps).unwrap().0;
            assert!((0..=list).contains(&t), "bps {bps} gave {t}");
        }
        assert_eq!(addon_total(&lines, 0).unwrap(), Won(list));
        assert_eq!(addon_total(&lines, 10_000).unwrap(), Won(0));
        assert!(addon_total(&lines, 10_001).is_err());
        assert!(addon_total(&lines, -1).is_err());
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
