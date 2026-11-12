//! Background recovery for checkouts whose confirm or webhook never arrived (money taken,
//! booking missing). Runs on every replica: each pass claims checkouts with
//! `FOR UPDATE SKIP LOCKED` and stamps them with a cooldown, and settlement itself is
//! idempotent (`fulfil` re-locks the checkout row).

use crate::{lifecycle::next_tick, metrics::job_pass, routes::checkouts, state::AppState};
use std::time::Duration;
use tokio::task::JoinHandle;

/// Dev mode always runs it (the fake gateway answers); production needs PortOne configured.
/// Only against a real PortOne account: in dev mode the fake gateway reports every
/// checkout as paid, so reconciling would turn abandoned checkouts into bookings.
pub fn enabled(_dev_mode: bool, portone_configured: bool) -> bool {
    portone_configured
}

/// Starts the periodic pass. Each tick re-checks the live keys, so PortOne entered later in the
/// setup wizard switches recovery on without a restart. Errors are logged and the loop goes on.
pub fn spawn(state: AppState) -> JoinHandle<()> {
    let every = Duration::from_secs(state.config.reconcile_interval_secs);
    let mut stop = state.hub.drain_signal();
    tokio::spawn(async move {
        let mut tick = tokio::time::interval(every);
        while next_tick(&mut tick, &mut stop).await {
            if !enabled(state.config.dev_mode, state.providers.integ().portone.api_secret.is_some()) {
                job_pass("reconciler", true);
                continue;
            }
            let ok = match checkouts::reconcile_pass(&state).await {
                Ok(0) => true,
                Ok(checked) => {
                    tracing::info!(checked, "checkout reconcile pass");
                    true
                }
                Err(e) => {
                    tracing::warn!(error = %e, "checkout reconcile pass failed");
                    false
                }
            };
            job_pass("reconciler", ok);
        }
    })
}

#[cfg(test)]
mod tests {
    use super::enabled;

    #[test]
    fn runs_only_with_a_real_portone_account() {
        assert!(!enabled(true, false), "dev fakes must never auto-settle abandoned checkouts");
        assert!(enabled(false, true));
        assert!(enabled(true, true));
        assert!(!enabled(false, false));
    }
}
