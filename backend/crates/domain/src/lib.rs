//! Business rules shared by the API server and (through FFI later) the apps.
//! Everything here is pure and deterministic: callers pass "today" and data in.

pub mod booking;
pub mod cash_receipt;
pub mod cancel_policy;
pub mod catalog;
pub mod coupon;
pub mod error;
pub mod finance;
pub mod growth;
pub mod household;
pub mod money;
pub mod partner;
pub mod pricing;
pub mod quote;
pub mod schedule;
pub mod tax;

pub use error::DomainError;
pub use money::Won;
