//! Retention purge (PIPA 제21조 파기). Runs hourly. What is purged, and why, is documented in
//! `docs/privacy-retention.md`. Each run is idempotent; a failed step is logged and the next run retries it.

use crate::{config::Config, state::AppState};
use sqlx::PgPool;
use std::{path::Path, time::Duration};
use tokio::task::JoinHandle;

const EVERY: Duration = Duration::from_secs(60 * 60);
/// Tables that can hold a reference to an upload URL. A file named in any of them is not orphaned.
const UPLOAD_REFERENCE_TABLES: [&str; 5] = ["bookings", "chat_messages", "pros", "users", "cases"];

#[derive(Debug, Default, PartialEq, Eq)]
pub struct Report {
    pub otp_codes: u64,
    pub refresh_tokens: u64,
    pub ai_messages: u64,
    pub uploads: u64,
    pub entry_codes: u64,
    pub analytics_events: u64,
}

pub fn spawn(state: AppState) -> JoinHandle<()> {
    let mut stop = state.hub.drain_signal();
    tokio::spawn(async move {
        let mut tick = tokio::time::interval(EVERY);
        while crate::lifecycle::next_tick(&mut tick, &mut stop).await {
            let cfg = &state.config;
            match purge(&state.db, cfg).await {
                Ok(r) => tracing::info!(?r, "retention purge done"),
                Err(e) => tracing::warn!(error = %e, "retention purge failed"),
            }
        }
    })
}

/// One pass over every purge rule. Stops at the first database error so the run is retried whole.
pub async fn purge(db: &PgPool, cfg: &Config) -> Result<Report, Box<dyn std::error::Error + Send + Sync>> {
    let otp_codes = sqlx::query("DELETE FROM otp_codes WHERE created_at < now() - interval '1 day'").execute(db).await?.rows_affected();
    let refresh_tokens = sqlx::query("DELETE FROM refresh_tokens WHERE expires_at < now() OR revoked_at < now() - interval '1 day'")
        .execute(db)
        .await?
        .rows_affected();
    crate::ops::prune(db).await?;
    crate::client_errors::prune(db).await?;
    let ai_messages = sqlx::query(
        "DELETE FROM chat_messages WHERE created_at < now() - make_interval(days => $1) AND thread_id IN (SELECT DISTINCT thread_id FROM ai_usage WHERE thread_id IS NOT NULL)",
    )
    .bind(cfg.ai_chat_retention_days as i32)
    .execute(db)
    .await?
    .rows_affected();
    let entry_codes = crate::safety::purge_codes(db).await?;
    let uploads = purge_orphan_uploads(db, &cfg.upload_dir, cfg.upload_orphan_days).await?;
    let analytics_events = sqlx::query("DELETE FROM analytics_events WHERE created_at < now() - make_interval(days => $1)")
        .bind(crate::analytics::RETENTION_DAYS as i32)
        .execute(db)
        .await?
        .rows_affected();
    Ok(Report { otp_codes, refresh_tokens, ai_messages, uploads, entry_codes, analytics_events })
}

/// Deletes uploads older than `days` that no record refers to. The file goes first, then its row, so a
/// failed file removal leaves the row for the next run.
async fn purge_orphan_uploads(db: &PgPool, dir: &Path, days: u32) -> Result<u64, Box<dyn std::error::Error + Send + Sync>> {
    let refs = UPLOAD_REFERENCE_TABLES
        .iter()
        .map(|t| format!("NOT EXISTS (SELECT 1 FROM {t} r WHERE to_jsonb(r)::text LIKE '%' || u.file || '%')"))
        .collect::<Vec<_>>()
        .join(" AND ");
    let sql = format!("SELECT u.id, u.file FROM uploads u WHERE u.created_at < now() - make_interval(days => $1) AND {refs}");
    let orphans: Vec<(uuid::Uuid, String)> = sqlx::query_as(&sql).bind(days as i32).fetch_all(db).await?;
    let mut removed = 0;
    for (id, file) in orphans {
        match tokio::fs::remove_file(dir.join(&file)).await {
            Ok(()) => {}
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => {}
            Err(e) => return Err(e.into()),
        }
        sqlx::query("DELETE FROM uploads WHERE id = $1").bind(id).execute(db).await?;
        removed += 1;
    }
    Ok(removed)
}
