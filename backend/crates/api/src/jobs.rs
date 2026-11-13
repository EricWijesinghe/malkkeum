//! Shared runner for the periodic jobs. One replica runs a pass at a time, and every pass reports to
//! the job metrics that `/metrics`, the status page and the `job_stalled` owner alert read.

use crate::{metrics, ops, state::AppState};
use serde_json::{Value, json};
use sqlx::{Connection, PgConnection, PgPool};
use std::{fmt::Display, future::Future};

const MINUTE: u64 = 60;
const HOUR: u64 = 60 * MINUTE;

/// Every periodic job, and how old (seconds) its last successful pass may get before the job counts
/// as stalled: several of its own intervals, so one slow or failed pass does not alert.
pub const ALL: [(&str, u64); 12] = [
    ("settings_refresh", 10 * MINUTE),
    ("reconciler", 30 * MINUTE),
    ("ops_alerts", 30 * MINUTE),
    ("payout_sync", HOUR),
    ("retention", 4 * HOUR),
    ("noshow", 30 * MINUTE),
    ("points", 4 * HOUR),
    ("marketing", 30 * MINUTE),
    ("quality", 4 * HOUR),
    ("waitlist", 10 * MINUTE),
    ("subscription_engine", 30 * MINUTE),
    ("notify_outbox", 10 * MINUTE),
];

/// Takes the job's lock on a connection of its own, outside the pool. A session advisory lock lives
/// exactly as long as its connection: closing it after the pass releases the lock, and so does a
/// crash or a deploy in the middle of a pass, so there is no lease that can go stale.
/// None when another replica holds the lock.
async fn lead(db: &PgPool, job: &str) -> sqlx::Result<Option<PgConnection>> {
    let mut conn = db.acquire().await?.detach();
    let won: bool = sqlx::query_scalar("SELECT pg_try_advisory_lock(hashtext($1))")
        .bind(format!("job:{job}"))
        .fetch_one(&mut conn)
        .await?;
    if won {
        return Ok(Some(conn));
    }
    conn.close().await?;
    Ok(None)
}

/// Runs one pass of `job` unless another replica is running it, and reports the outcome to the job
/// metrics. Returns the pass result. None when the pass was skipped or failed (logged here).
pub async fn run<T, E: Display>(s: &AppState, job: &'static str, pass: impl Future<Output = Result<T, E>>) -> Option<T> {
    let lock = match lead(&s.db, job).await {
        Ok(Some(conn)) => conn,
        Ok(None) => {
            // Another replica has this pass. This loop is alive and has nothing to do.
            metrics::job_pass(job, true);
            return None;
        }
        Err(e) => {
            tracing::warn!(error = %e, job, "job lock unavailable; pass skipped");
            metrics::job_pass(job, false);
            return None;
        }
    };
    let out = pass.await;
    if let Err(e) = lock.close().await {
        tracing::debug!(error = %e, job, "job lock connection did not close cleanly");
    }
    match out {
        Ok(v) => {
            metrics::job_pass(job, true);
            Some(v)
        }
        Err(e) => {
            tracing::warn!(error = %e, job, "background pass failed");
            metrics::job_pass(job, false);
            None
        }
    }
}

/// A job that has not succeeded since the process started is measured from the start, so a fresh
/// process does not alert before its jobs had time to run.
fn is_stalled(since_ok_secs: f64, uptime_secs: f64, max_age_secs: u64) -> bool {
    since_ok_secs.min(uptime_secs) > max_age_secs as f64
}

/// Names of the jobs whose last success in this process is older than their limit.
pub fn stalled(now_unix: f64) -> Vec<&'static str> {
    let (jobs, uptime) = (metrics::jobs(), ops::uptime_secs() as f64);
    ALL.iter()
        .filter(|(job, max_age)| is_stalled(now_unix - jobs.get(job).map_or(0.0, |j| j.last_ok_unix), uptime, *max_age))
        .map(|(job, _)| *job)
        .collect()
}

/// Each job's last pass in this process, for the status page.
pub fn health(now_unix: f64) -> Vec<Value> {
    let (jobs, stalled) = (metrics::jobs(), stalled(now_unix));
    ALL.iter()
        .map(|(job, _)| {
            let j = jobs.get(job).copied().unwrap_or_default();
            json!({ "job": job, "last_run_unix": j.last_run_unix, "last_ok_unix": j.last_ok_unix, "errors": j.errors, "stalled": stalled.contains(job) })
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_job_stalls_only_after_its_limit_and_never_right_after_start() {
        assert!(!is_stalled(1_700_000_000.0, 120.0, 600), "never ran, but the process just started");
        assert!(is_stalled(1_700_000_000.0, 601.0, 600), "never ran in a process that is up past the limit");
        assert!(!is_stalled(599.0, 86_400.0, 600), "succeeded inside the limit");
        assert!(is_stalled(601.0, 86_400.0, 600), "last success is too old");
    }

    #[test]
    fn every_job_is_listed_before_its_first_pass() {
        let names: Vec<String> = health(0.0).iter().filter_map(|j| j["job"].as_str().map(str::to_string)).collect();
        assert_eq!(names.len(), ALL.len());
        assert!(names.iter().any(|n| n == "subscription_engine") && names.iter().any(|n| n == "notify_outbox"));
    }
}
