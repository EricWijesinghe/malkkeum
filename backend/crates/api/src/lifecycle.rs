//! Process lifecycle: liveness and readiness probes, the shutdown signal, and stopping background jobs.
//!
//! Shutdown order on SIGTERM (or Ctrl+C): the hub starts draining, so WebSockets close with 1012
//! (service restart) and clients reconnect elsewhere; the listener stops taking new connections and
//! in-flight requests finish (each is bounded by the request timeout); then the background jobs stop
//! after their current pass, joined under a deadline.

use crate::{routes::APP_VERSION, state::AppState};
use axum::{
    Json,
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
};
use futures_util::future::join_all;
use serde_json::{Value, json};
use sqlx::{PgPool, migrate::Migrator};
use std::time::Duration;
use tokio::{sync::watch, task::JoinHandle, time::Interval};

/// The migrations this binary ships; readiness compares them with `_sqlx_migrations`.
static MIGRATOR: Migrator = sqlx::migrate!("../../migrations");
const JOB_STOP_TIMEOUT: Duration = Duration::from_secs(10);
const PROBE_TIMEOUT: Duration = Duration::from_secs(2);

/// Resolves once the hub started draining. Jobs select on it beside their timers.
pub async fn drained(stop: &mut watch::Receiver<bool>) {
    let _ = stop.wait_for(|d| *d).await;
}

/// Waits for the next tick. False once draining started, so the job returns instead of starting a pass.
pub async fn next_tick(tick: &mut Interval, stop: &mut watch::Receiver<bool>) -> bool {
    tokio::select! {
        _ = tick.tick() => true,
        () = drained(stop) => false,
    }
}

/// Ctrl+C, or SIGTERM on Unix (what Docker and systemd send when stopping a container or unit).
pub async fn os_signal() {
    #[cfg(unix)]
    {
        use tokio::signal::unix::{SignalKind, signal};
        match signal(SignalKind::terminate()) {
            Ok(mut term) => {
                tokio::select! {
                    () = wait_ctrl_c() => {}
                    _ = term.recv() => {}
                }
            }
            Err(e) => {
                tracing::warn!(error = %e, "SIGTERM handler unavailable; only Ctrl+C stops the server");
                wait_ctrl_c().await;
            }
        }
    }
    #[cfg(not(unix))]
    wait_ctrl_c().await;
    tracing::info!("shutdown signal received; draining");
}

async fn wait_ctrl_c() {
    if let Err(e) = tokio::signal::ctrl_c().await {
        tracing::warn!(error = %e, "Ctrl+C handler failed; treating it as a shutdown request");
    }
}

/// Waits for the jobs to finish their current pass, up to a deadline. Panicked jobs are logged.
pub async fn join_jobs(jobs: Vec<JoinHandle<()>>) {
    match tokio::time::timeout(JOB_STOP_TIMEOUT, join_all(jobs)).await {
        Ok(results) => {
            for r in results.into_iter().filter_map(Result::err) {
                tracing::error!(error = %r, "background job panicked");
            }
        }
        Err(_) => tracing::warn!("background jobs still running at the stop deadline; exiting"),
    }
}

/// Liveness: the process answers. Never touches the database, so a DB outage does not restart the container.
pub async fn live() -> Json<Value> {
    Json(json!({ "ok": true, "version": APP_VERSION }))
}

/// Readiness: the database answers and every shipped migration is applied. Failing it takes the node
/// out of rotation; it does not restart it.
pub async fn ready(State(s): State<AppState>) -> Response {
    let db_ok = tokio::time::timeout(PROBE_TIMEOUT, sqlx::query_scalar::<_, i32>("SELECT 1").fetch_one(&s.db))
        .await
        .is_ok_and(|r| r.is_ok());
    let migrated = db_ok && migrations_applied(&s.db).await;
    let ready = db_ok && migrated;
    let status = if ready { StatusCode::OK } else { StatusCode::SERVICE_UNAVAILABLE };
    (status, Json(json!({ "ready": ready, "db": db_ok, "migrations": migrated }))).into_response()
}

/// True when the database has applied every migration this binary knows about.
pub async fn migrations_applied(db: &PgPool) -> bool {
    let Some(latest) = MIGRATOR.migrations.iter().map(|m| m.version).max() else {
        return true;
    };
    // A missing bookkeeping table (never migrated) is a failed probe, not a crash.
    let applied: Result<Option<i64>, sqlx::Error> = sqlx::query_scalar("SELECT MAX(version) FROM _sqlx_migrations WHERE success")
        .fetch_one(db)
        .await;
    matches!(applied, Ok(Some(v)) if v >= latest)
}

#[cfg(test)]
mod tests {
    use super::MIGRATOR;

    #[test]
    fn migrator_embeds_the_shipped_migrations() {
        assert!(MIGRATOR.migrations.len() >= 15, "migrations directory is embedded");
    }
}
