//! Pure settle policy for checkouts: given the checkout and what the provider says, what happens next.
//! No I/O here; `checkouts` carries the decision out.

use crate::error::ApiError;

/// What the provider and the checkout say, reduced to the facts the decision needs.
/// `provider_status` is `None` when the provider has no such payment.
#[derive(Debug, Clone, Copy)]
pub struct Recovery<'a> {
    pub status: &'a str,
    pub expired: bool,
    pub provider_status: Option<&'a str>,
    /// Provider amount, currency and status all match the checkout (see `amount_matches`).
    pub amount_ok: bool,
    /// The provider payment is the one already recorded on this checkout.
    pub paid_by_this: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Action {
    /// Leave the checkout as it is.
    Nothing,
    /// Paid in time: book it.
    Fulfil,
    /// Paid after expiry: book it if the slot still exists, otherwise refund and mark 'refunded'.
    FulfilLate,
    /// Paid for a different amount: refund it, mark failed.
    RefundMismatch,
    /// Paid on a checkout that can no longer use it (closed, or already paid by another payment): refund it.
    RefundClosed,
    /// Virtual account issued: wait for the deposit.
    MarkAwaitingDeposit,
    /// Open, past expiry, never paid: close it.
    MarkExpired,
}

fn is_open_deposit(status: &str) -> bool {
    matches!(status, "pending" | "awaiting_deposit")
}

/// Pure settle policy. Money moves only for PAID payments; everything else is a status move or nothing.
pub fn decide(r: &Recovery<'_>) -> Action {
    match r.provider_status {
        Some("PAID") => decide_paid(r),
        Some("VIRTUAL_ACCOUNT_ISSUED") if is_open_deposit(r.status) => Action::MarkAwaitingDeposit,
        Some("VIRTUAL_ACCOUNT_ISSUED") => Action::Nothing,
        _ if r.status == "pending" && r.expired => Action::MarkExpired,
        _ => Action::Nothing,
    }
}

fn decide_paid(r: &Recovery<'_>) -> Action {
    if r.status == "paid" {
        return if r.paid_by_this { Action::Nothing } else { Action::RefundClosed };
    }
    if !r.amount_ok {
        return Action::RefundMismatch;
    }
    match r.status {
        "pending" | "awaiting_deposit" if !r.expired => Action::Fulfil,
        "pending" | "awaiting_deposit" | "expired" => Action::FulfilLate,
        _ => Action::RefundClosed,
    }
}

/// Reason stored with a refund: the stable error code of whatever stopped the booking.
pub fn refund_reason(e: &ApiError) -> String {
    match e {
        ApiError::Conflict(code) | ApiError::BadRequest(code) => (*code).to_string(),
        ApiError::Domain(d) => d.code().to_string(),
        _ => "fulfil_failed".to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn recovery<'a>(status: &'a str, expired: bool, provider: Option<&'a str>, amount_ok: bool, paid_by_this: bool) -> Recovery<'a> {
        Recovery {
            status,
            expired,
            provider_status: provider,
            amount_ok,
            paid_by_this,
        }
    }

    #[test]
    fn paid_in_time_is_fulfilled() {
        for status in ["pending", "awaiting_deposit"] {
            assert_eq!(decide(&recovery(status, false, Some("PAID"), true, false)), Action::Fulfil, "{status}");
        }
    }

    #[test]
    fn paid_after_expiry_is_fulfilled_late_not_refused() {
        assert_eq!(decide(&recovery("pending", true, Some("PAID"), true, false)), Action::FulfilLate);
        assert_eq!(decide(&recovery("awaiting_deposit", true, Some("PAID"), true, false)), Action::FulfilLate);
        assert_eq!(decide(&recovery("expired", true, Some("PAID"), true, false)), Action::FulfilLate);
        assert_eq!(decide(&recovery("expired", false, Some("PAID"), true, false)), Action::FulfilLate);
    }

    #[test]
    fn wrong_amount_is_refunded_before_anything_else() {
        for status in ["pending", "awaiting_deposit", "expired", "failed"] {
            let r = recovery(status, false, Some("PAID"), false, false);
            assert_eq!(decide(&r), Action::RefundMismatch, "{status}");
        }
    }

    #[test]
    fn paid_on_closed_checkout_is_refunded() {
        for status in ["failed", "cancelled", "refunded"] {
            assert_eq!(decide(&recovery(status, false, Some("PAID"), true, false)), Action::RefundClosed, "{status}");
        }
    }

    #[test]
    fn second_payment_on_paid_checkout_is_refunded_same_payment_is_noop() {
        assert_eq!(decide(&recovery("paid", false, Some("PAID"), true, true)), Action::Nothing);
        assert_eq!(decide(&recovery("paid", false, Some("PAID"), true, false)), Action::RefundClosed);
    }

    #[test]
    fn virtual_account_moves_open_checkouts_to_awaiting_deposit() {
        for status in ["pending", "awaiting_deposit"] {
            let r = recovery(status, true, Some("VIRTUAL_ACCOUNT_ISSUED"), false, false);
            assert_eq!(decide(&r), Action::MarkAwaitingDeposit, "{status}");
        }
        assert_eq!(decide(&recovery("expired", false, Some("VIRTUAL_ACCOUNT_ISSUED"), false, false)), Action::Nothing);
        assert_eq!(decide(&recovery("paid", false, Some("VIRTUAL_ACCOUNT_ISSUED"), false, true)), Action::Nothing);
    }

    #[test]
    fn unpaid_expired_pending_is_closed() {
        for provider in [None, Some("READY"), Some("FAILED"), Some("CANCELLED")] {
            assert_eq!(decide(&recovery("pending", true, provider, false, false)), Action::MarkExpired, "{provider:?}");
        }
    }

    #[test]
    fn unpaid_open_checkouts_are_left_alone() {
        for status in ["pending", "awaiting_deposit", "expired", "failed", "cancelled", "refunded", "paid"] {
            for expired in [false, true] {
                for provider in [None, Some("READY"), Some("FAILED"), Some("CANCELLED")] {
                    let action = decide(&recovery(status, expired, provider, false, false));
                    let expected = if status == "pending" && expired { Action::MarkExpired } else { Action::Nothing };
                    assert_eq!(action, expected, "{status} expired={expired} {provider:?}");
                }
            }
        }
    }

    #[test]
    fn money_actions_only_ever_follow_a_paid_provider_status() {
        let statuses = ["pending", "awaiting_deposit", "paid", "failed", "cancelled", "expired", "refunded", "unknown"];
        let providers = [None, Some("PAID"), Some("VIRTUAL_ACCOUNT_ISSUED"), Some("READY"), Some("FAILED"), Some("CANCELLED")];
        for status in statuses {
            for expired in [false, true] {
                for provider in providers {
                    for amount_ok in [false, true] {
                        for paid_by_this in [false, true] {
                            let r = recovery(status, expired, provider, amount_ok, paid_by_this);
                            let action = decide(&r);
                            if provider != Some("PAID") {
                                assert!(
                                    !matches!(action, Action::Fulfil | Action::FulfilLate | Action::RefundMismatch | Action::RefundClosed),
                                    "{r:?} -> {action:?}"
                                );
                            }
                            if action == Action::Fulfil {
                                assert!(amount_ok && !expired && is_open_deposit(status), "{r:?}");
                            }
                            if action == Action::FulfilLate {
                                assert!(amount_ok && (expired || status == "expired") && (is_open_deposit(status) || status == "expired"), "{r:?}");
                            }
                            if action == Action::RefundClosed {
                                assert!(status != "pending" && status != "awaiting_deposit" && status != "expired" || status == "paid", "{r:?}");
                            }
                        }
                    }
                }
            }
        }
    }

    #[test]
    fn refund_reason_keeps_the_stable_code() {
        assert_eq!(refund_reason(&ApiError::Conflict("price_changed")), "price_changed");
        assert_eq!(refund_reason(&ApiError::BadRequest("payment_not_found")), "payment_not_found");
        assert_eq!(refund_reason(&ApiError::Internal("boom".into())), "fulfil_failed");
    }
}
