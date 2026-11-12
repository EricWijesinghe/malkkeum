//! Business rules shared by the API server and (through FFI later) the apps.
//! Everything here is pure and deterministic: callers pass "today" and data in.

pub mod booking;
pub mod cash_receipt;
pub mod cancel_policy;
pub mod catalog;
pub mod coupon;
pub mod error;
pub mod finance;
pub mod feed;
pub mod growth;
pub mod household;
pub mod money;
pub mod partner;
pub mod points;
pub mod peak;
pub mod pricing;
pub mod quality;
pub mod quote;
pub mod schedule;
pub mod subscription;
pub mod tax;
pub mod tip;
pub mod training;
pub mod waitlist;

pub use error::DomainError;
pub use money::Won;
