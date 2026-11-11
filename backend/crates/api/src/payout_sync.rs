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
    sync::atomic::{AtomicBool, Ordering},
    time::Duration,
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

static PASS_RUNNING: AtomicBool = AtomicBool::new(false);

/// Runs one pass in the background unless one is already running (webhook bursts coalesce into one pass).
pub fn kick(state: AppState) {
    if state.config.dev_mode || PASS_RUNNING.compare_exchange(false, true, Ordering::SeqCst, Ordering::SeqCst).is_err() {
        return;
    }
    tokio::spawn(async move {
        if let Err(e) = sync_pass(&state).await {
            tracing::warn!(error = ?e, "payout sync pass from webhook failed");
        }
        PASS_RUNNING.store(false, Ordering::SeqCst);
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
