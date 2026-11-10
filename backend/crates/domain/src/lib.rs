//! Business rules shared by the API server and (through FFI later) the apps.
//! Everything here is pure and deterministic: callers pass "today" and data in.

pub mod booking;
pub mod catalog;
pub mod coupon;
pub mod error;
pub mod money;
pub mod partner;
pub mod pricing;
pub mod quote;
pub mod schedule;

pub use error::DomainError;
pub use money::Won;
