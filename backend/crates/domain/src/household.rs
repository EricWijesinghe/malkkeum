//! Household profile saved per address and copied into each booking. Free text is for staff and
//! partners to read; no field here is used for pricing.

use serde::{Deserialize, Serialize};

pub const MAX_PETS: usize = 5;
pub const MAX_PET_COUNT: u8 = 20;
pub const MAX_TEXT_CHARS: usize = 300;
pub const PET_KINDS: [&str; 5] = ["dog", "cat", "bird", "fish", "other"];

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Pet {
    pub kind: String,
    pub count: u8,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct Household {
    #[serde(default)]
    pub pets: Vec<Pet>,
    #[serde(default)]
    pub allergies: String,
    #[serde(default)]
    pub preferred_products: String,
    #[serde(default)]
    pub parking: String,
    /// Floor of the unit; negative for basements.
    #[serde(default)]
    pub floor: Option<i16>,
    #[serde(default)]
    pub elevator: Option<bool>,
    #[serde(default)]
    pub notes: String,
}

impl Household {
    /// Returns the trimmed profile, or the stable error code of the first rule it breaks.
    pub fn validated(mut self) -> Result<Self, &'static str> {
        if self.pets.len() > MAX_PETS {
            return Err("invalid_household");
        }
        for p in &self.pets {
            if !PET_KINDS.contains(&p.kind.as_str()) || p.count == 0 || p.count > MAX_PET_COUNT {
                return Err("invalid_household");
            }
        }
        if self.floor.is_some_and(|f| !(-5..=150).contains(&f)) {
            return Err("invalid_household");
        }
        for text in [&mut self.allergies, &mut self.preferred_products, &mut self.parking, &mut self.notes] {
            if text.chars().count() > MAX_TEXT_CHARS {
                return Err("invalid_household");
            }
            *text = text.trim().to_string();
        }
        Ok(self)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn trims_text_and_accepts_a_full_profile() {
        let h = Household {
            pets: vec![Pet { kind: "dog".into(), count: 2 }],
            allergies: "  고양이 털  ".into(),
            floor: Some(-1),
            elevator: Some(true),
            ..Default::default()
        }
        .validated()
        .unwrap();
        assert_eq!(h.allergies, "고양이 털");
    }

    #[test]
    fn rejects_bad_pets_floor_and_length() {
        let bad_kind = Household { pets: vec![Pet { kind: "lizard".into(), count: 1 }], ..Default::default() };
        assert_eq!(bad_kind.validated(), Err("invalid_household"));
        let zero = Household { pets: vec![Pet { kind: "cat".into(), count: 0 }], ..Default::default() };
        assert_eq!(zero.validated(), Err("invalid_household"));
        let many = Household { pets: vec![Pet { kind: "cat".into(), count: 1 }; MAX_PETS + 1], ..Default::default() };
        assert_eq!(many.validated(), Err("invalid_household"));
        let floor = Household { floor: Some(999), ..Default::default() };
        assert_eq!(floor.validated(), Err("invalid_household"));
        let long = Household { notes: "가".repeat(MAX_TEXT_CHARS + 1), ..Default::default() };
        assert_eq!(long.validated(), Err("invalid_household"));
    }
}
