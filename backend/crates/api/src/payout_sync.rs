//! Background Toss payout sync. Every pass asks the provider about transfers that are still open
//! (sent, or requested after an ambiguous send). It never sends money. Each row goes through the
//! same locked path as the owner's "sync" button. Also counts the payouts the owner must hear about.

use crate::{
    error::ApiResult,
    payout::State,
    routes::{audit, payouts},
    state::AppState,
};
use serde_json::json;
use sqlx::PgPool;
use std::time::Duration;
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

/// Starts the periodic sync. Dev mode never starts it: the fake provider would report every transfer paid.
pub fn spawn(state: AppState) {
    if state.config.dev_mode {
        return;
    }
    tokio::spawn(async move {
        let mut tick = tokio::time::interval(SYNC_EVERY);
        loop {
            tick.tick().await;
            match sync_pass(&state).await {
                Ok(0) => {}
                Ok(n) => tracing::info!(settled = n, "payout sync pass"),
                Err(e) => tracing::warn!(error = ?e, "payout sync pass failed"),
            }
        }
    });
}
