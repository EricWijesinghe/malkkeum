//! Partner payout state machine. Money only moves along the edges in [`next`]; every other
//! (state, action) pair is refused, and paid is terminal.

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum State {
    Requested,
    Sent,
    Paid,
    Failed,
}

impl State {
    pub fn parse(s: &str) -> Option<Self> {
        Some(match s {
            "requested" => Self::Requested,
            "sent" => Self::Sent,
            "paid" => Self::Paid,
            "failed" => Self::Failed,
            _ => return None,
        })
    }

    pub fn as_str(self) -> &'static str {
        match self {
            Self::Requested => "requested",
            Self::Sent => "sent",
            Self::Paid => "paid",
            Self::Failed => "failed",
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Action {
    /// Provider accepted the transfer (requested -> sent).
    Accept,
    /// Money is confirmed moved: owner confirmed a manual transfer, or the provider reports done.
    Confirm,
    /// Not paid: provider declined, the owner marked it failed, or the provider reports failure.
    Reject,
    /// Owner re-queues a failed payout.
    Retry,
}

/// The next state for `action`, or `None` when the transition is not allowed.
pub fn next(from: State, action: Action) -> Option<State> {
    use Action::*;
    use State::*;
    match (from, action) {
        (Requested, Accept) => Some(Sent),
        (Requested | Sent, Confirm) => Some(Paid),
        (Requested | Sent, Reject) => Some(Failed),
        (Failed, Retry) => Some(Requested),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use Action::*;
    use State::*;

    #[test]
    fn happy_paths() {
        assert_eq!(next(Requested, Accept), Some(Sent));
        assert_eq!(next(Sent, Confirm), Some(Paid));
        assert_eq!(next(Requested, Confirm), Some(Paid)); // manual transfer
    }

    #[test]
    fn failed_is_retryable_and_only_retry_leaves_it() {
        assert_eq!(next(Requested, Reject), Some(Failed));
        assert_eq!(next(Sent, Reject), Some(Failed));
        assert_eq!(next(Failed, Retry), Some(Requested));
        for a in [Accept, Confirm, Reject] {
            assert_eq!(next(Failed, a), None, "{a:?} must not leave failed");
        }
    }

    #[test]
    fn paid_is_terminal() {
        for a in [Accept, Confirm, Reject, Retry] {
            assert_eq!(next(Paid, a), None, "{a:?} must not change a paid payout");
        }
    }

    #[test]
    fn sent_cannot_be_sent_twice_or_retried() {
        assert_eq!(next(Sent, Accept), None);
        assert_eq!(next(Sent, Retry), None);
        assert_eq!(next(Requested, Retry), None);
    }

    #[test]
    fn state_strings_round_trip() {
        for s in [Requested, Sent, Paid, Failed] {
            assert_eq!(State::parse(s.as_str()), Some(s));
        }
        assert_eq!(State::parse("pending"), None);
    }
}
