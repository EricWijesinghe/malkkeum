use thiserror::Error;

/// Every rule violation has a stable machine code so apps can localize the message.
#[derive(Debug, Clone, PartialEq, Eq, Error)]
pub enum DomainError {
    #[error("studio cleaning requires an address of at most {max} pyeong")]
    StudioTooLarge { max: u16 },
    #[error("visit date must be between tomorrow and {max_days} days ahead")]
    DateOutOfRange { max_days: i64 },
    #[error("time slot is not offered for this service")]
    InvalidSlot,
    #[error("time slot is full")]
    SlotFull,
    #[error("unit option index is invalid")]
    InvalidUnit,
    #[error("coupon is expired")]
    CouponExpired,
    #[error("coupon was already used")]
    CouponUsed,
    #[error("coupon does not apply to this service")]
    CouponWrongService,
    #[error("status transition is not allowed")]
    InvalidTransition,
    #[error("booking can no longer be cancelled for free")]
    CancellationWindowClosed,
    #[error("tip is not allowed for this booking")]
    TipNotAllowed,
    #[error("the slot offer has expired")]
    OfferExpired,
    #[error("training modules are not complete")]
    TrainingIncomplete,
    #[error("value out of range: {0}")]
    OutOfRange(&'static str),
}

impl DomainError {
    /// Stable code for API responses and i18n keys.
    pub fn code(&self) -> &'static str {
        match self {
            Self::StudioTooLarge { .. } => "studio_too_large",
            Self::DateOutOfRange { .. } => "date_out_of_range",
            Self::InvalidSlot => "invalid_slot",
            Self::SlotFull => "slot_full",
            Self::InvalidUnit => "invalid_unit",
            Self::CouponExpired => "coupon_expired",
            Self::CouponUsed => "coupon_used",
            Self::CouponWrongService => "coupon_wrong_service",
            Self::InvalidTransition => "invalid_transition",
            Self::CancellationWindowClosed => "cancellation_window_closed",
            Self::TipNotAllowed => "tip_not_allowed",
            Self::OfferExpired => "offer_expired",
            Self::TrainingIncomplete => "training_incomplete",
            Self::OutOfRange(_) => "out_of_range",
        }
    }
}
