use serde::{Deserialize, Serialize};
use std::ops::{Add, Sub};

/// Korean won, VAT included. Integer only: money never touches floating point.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Default, Serialize, Deserialize)]
#[serde(transparent)]
pub struct Won(pub i64);

const ROUNDING_UNIT: i64 = 100;
const BASIS_POINTS: i64 = 10_000;

impl Won {
    pub const ZERO: Won = Won(0);

    /// Round half-up to the nearest 100 won (spec rule 8).
    pub fn round100(self) -> Won {
        let half = ROUNDING_UNIT / 2;
        Won((self.0 + half).div_euclid(ROUNDING_UNIT) * ROUNDING_UNIT)
    }

    /// Multiply by a rate in basis points (10_000 = 100%), rounding half-up to 1 won.
    pub fn times_bps(self, bps: i64) -> Won {
        Won((self.0 * bps + BASIS_POINTS / 2).div_euclid(BASIS_POINTS))
    }

    pub fn min(self, other: Won) -> Won {
        Won(self.0.min(other.0))
    }

    pub fn saturating_sub(self, other: Won) -> Won {
        Won((self.0 - other.0).max(0))
    }
}

impl Add for Won {
    type Output = Won;
    fn add(self, rhs: Won) -> Won {
        Won(self.0 + rhs.0)
    }
}

impl Sub for Won {
    type Output = Won;
    fn sub(self, rhs: Won) -> Won {
        Won(self.0 - rhs.0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rounds_half_up_to_100() {
        assert_eq!(Won(580_849).round100(), Won(580_800));
        assert_eq!(Won(580_850).round100(), Won(580_900));
        assert_eq!(Won(0).round100(), Won(0));
    }

    #[test]
    fn basis_points() {
        assert_eq!(Won(560_000).times_bps(1_000), Won(56_000));
        assert_eq!(Won(52_000).times_bps(2_000), Won(10_400));
    }
}
