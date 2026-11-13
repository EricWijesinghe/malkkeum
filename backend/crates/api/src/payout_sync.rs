//! Background Toss payout sync. Every pass asks the provider about transfers that are still open
//! (sent, or requested after an ambiguous send). It never sends money. Each row goes through the
//! same locked path as the owner's "sync" button. Also counts the payouts the owner must hear about.

use crate::{
    error::ApiResult,
    lifecycle::next_tick,
    metrics::job_pass,
    payout::State,
    routes::{audit, payouts},
    state::AppState,
};
use serde_json::json;
use sqlx::PgPool;
use std::{
    sync::{
        Mutex,
        atomic::{AtomicBool, Ordering},
    },
    time::{Duration, Instant},
};
use tokio::task::JoinHandle;
use uuid::Uuid;

pub const SYNC_EVERY: Duration = Duration::from_secs(600);
/// Open transfers older than this are "stuck", and failed ones younger than it count as fresh failures.
pub const ALERT_AFTER_HOURS: i32 = 24;
const BATCH: i64 = 100;

const DUE_SQL: &str = "SELECT id FROM payouts
  WHERE provider = 'toss' AND (state = 'sent' OR (state = 'requested' AND failure_reason IS NOT NULL))
  ORDER BY updated_at LIMIT $1";

/// (stuck open transfers, Toss transfers failed within the alert window).
const ALERT_SQL: &str = "SELECT
  count(*) FILTER (WHERE (state = 'sent' OR (state = 'requested' AND failure_reason IS NOT NULL))
                     AND updated_at < now() - make_interval(hours => $1)),
  count(*) FILTER (WHERE state = 'failed' AND updated_at > now() - make_interval(hours => $1))
FROM payouts WHERE provider = 'toss'";

/// One sync pass over the open transfers. Returns how many reached paid or failed. A row that errors
/// is logged by the caller's loop and retried on the next pass.
pub async fn sync_pass(s: &AppState) -> ApiResult<usize> {
    let ids: Vec<Uuid> = sqlx::query_scalar(DUE_SQL).bind(BATCH).fetch_all(&s.db).await?;
    let mut settled = 0;
    for id in ids {
        match payouts::sync(s, id).await {
            Ok(state @ (State::Paid | State::Failed)) => {
                settled += 1;
                audit(&s.db, "system", None, "payout.sync", &id.to_string(), json!({ "state": state.as_str() })).await?;
                if state == State::Paid {
                    payouts::notify_paid(s, id).await;
                }
            }
            Ok(_) => {}
            Err(e) => tracing::warn!(error = ?e, payout = %id, "payout sync failed"),
        }
    }
    Ok(settled)
}

/// (stuck open transfers, recent Toss failures) for the owner's alert rules.
pub async fn alert_counts(db: &PgPool) -> Result<(i64, i64), sqlx::Error> {
    sqlx::query_as(ALERT_SQL).bind(ALERT_AFTER_HOURS).fetch_one(db).await
}

/// Webhook kicks start a pass at most this often, however many arrive: `/webhooks/toss` is unauthenticated.
const KICK_MIN_INTERVAL: Duration = Duration::from_secs(30);

static PASS_RUNNING: AtomicBool = AtomicBool::new(false);
static LAST_KICK: Mutex<Option<Instant>> = Mutex::new(None);

/// Clears the running flag when dropped, so a pass that panics cannot leave kicks disabled for good.
struct RunningGuard(&'static AtomicBool);

impl Drop for RunningGuard {
    fn drop(&mut self) {
        self.0.store(false, Ordering::SeqCst);
    }
}

/// True when a kick at `now` is far enough after the last accepted one; records it if so.
fn kick_due(last: &Mutex<Option<Instant>>, now: Instant) -> bool {
    let mut last = last.lock().unwrap_or_else(|p| p.into_inner());
    if last.is_some_and(|t| now.saturating_duration_since(t) < KICK_MIN_INTERVAL) {
        return false;
    }
    *last = Some(now);
    true
}

/// Runs one pass in the background unless one is already running or one started recently
/// (webhook bursts coalesce into one pass).
pub fn kick(state: AppState) {
    if state.config.dev_mode || PASS_RUNNING.compare_exchange(false, true, Ordering::SeqCst, Ordering::SeqCst).is_err() {
        return;
    }
    let guard = RunningGuard(&PASS_RUNNING);
    if !kick_due(&LAST_KICK, Instant::now()) {
        return; // the guard's drop frees the flag
    }
    tokio::spawn(async move {
        let _guard = guard;
        if let Err(e) = sync_pass(&state).await {
            tracing::warn!(error = ?e, "payout sync pass from webhook failed");
        }
    });
}

/// Starts the periodic sync. Dev mode never starts it: the fake provider would report every transfer paid.
pub fn spawn(state: AppState) -> JoinHandle<()> {
    if state.config.dev_mode {
        return tokio::spawn(std::future::ready(()));
    }
    let mut stop = state.hub.drain_signal();
    tokio::spawn(async move {
        let mut tick = tokio::time::interval(SYNC_EVERY);
        while next_tick(&mut tick, &mut stop).await {
            let ok = match sync_pass(&state).await {
                Ok(0) => true,
                Ok(n) => {
                    tracing::info!(settled = n, "payout sync pass");
                    true
                }
                Err(e) => {
                    tracing::warn!(error = ?e, "payout sync pass failed");
                    false
                }
            };
            job_pass("payout_sync", ok);
        }
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn kicks_are_spaced_by_the_minimum_interval() {
        let last = Mutex::new(None);
        let t0 = Instant::now();
        assert!(kick_due(&last, t0));
        assert!(!kick_due(&last, t0 + Duration::from_secs(29)), "too soon");
        assert!(kick_due(&last, t0 + KICK_MIN_INTERVAL), "interval passed");
    }

    #[tokio::test]
    async fn a_panicking_pass_frees_the_running_flag() {
        static FLAG: AtomicBool = AtomicBool::new(true);
        let guard = RunningGuard(&FLAG);
        let joined = tokio::spawn(async move {
            let _guard = guard;
            panic!("pass blew up");
        })
        .await;
        assert!(joined.is_err());
        assert!(!FLAG.load(Ordering::SeqCst), "flag reset by the drop guard");
    }
}
