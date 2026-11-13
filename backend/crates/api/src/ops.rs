//! Operations signals: last success and failure per external integration, a failure log for the
//! alert windows, an hourly 5xx counter, disk and database figures, and the status summary the
//! console's status page shows. Only short error codes are stored, never provider messages.

use crate::{error::ApiResult, integrations::Section, state::AppState};
use axum::{
    extract::{Request, State},
    middleware::Next,
    response::Response,
};
use chrono::{DateTime, Duration, Utc};
use serde::Serialize;
use serde_json::{Value, json};
use sqlx::PgPool;
use std::{path::PathBuf, sync::OnceLock, time::Instant};

pub const BACKUP_STATUS_KEY: &str = "backup_status";
/// The nightly backup runs at 03:30; a missing run for a day and a half is a red flag.
pub const BACKUP_STALE_HOURS: f64 = 36.0;
pub const BACKUP_LATE_HOURS: f64 = 26.0;
pub const DISK_LOW_PCT: f64 = 10.0;
pub const DISK_WARN_PCT: f64 = 20.0;
const ERRORS_WARN: i64 = 20;
const ERRORS_BAD: i64 = 100;
const SIGNATURE_BAD: i64 = 3;
/// Integration codes whose health is shown on the status page (same codes as the setup wizard).
pub const INTEGRATIONS: [Section; 8] = [
    Section::Portone,
    Section::Solapi,
    Section::Push,
    Section::Kakao,
    Section::Naver,
    Section::Google,
    Section::Apple,
    Section::Backup,
];

static STARTED: OnceLock<Instant> = OnceLock::new();

/// Called once at start-up so uptime counts from the process start.
pub fn mark_started() {
    STARTED.get_or_init(Instant::now);
}

/// How bad one check is. Ordered, so the overall level is the maximum.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum Level {
    Green,
    Yellow,
    Red,
}

/// Free space of the filesystem that holds the uploads.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Disk {
    pub total: u64,
    pub free: u64,
}

impl Disk {
    pub fn free_pct(&self) -> f64 {
        if self.total == 0 { 0.0 } else { self.free as f64 * 100.0 / self.total as f64 }
    }
}

/// Stores one provider outcome. `Err` carries a short code such as `unreachable`.
pub async fn write_outcome(db: &PgPool, integration: &str, outcome: Result<(), &str>) -> Result<(), sqlx::Error> {
    match outcome {
        Ok(()) => sqlx::query(
            "INSERT INTO ops_health (integration, last_ok_at) VALUES ($1, now())
             ON CONFLICT (integration) DO UPDATE SET last_ok_at = now()",
        )
        .bind(integration)
        .execute(db)
        .await
        .map(|_| ()),
        Err(code) => {
            sqlx::query(
                "INSERT INTO ops_health (integration, last_fail_at, last_error) VALUES ($1, now(), $2)
                 ON CONFLICT (integration) DO UPDATE SET last_fail_at = now(), last_error = EXCLUDED.last_error",
            )
            .bind(integration)
            .bind(code)
            .execute(db)
            .await?;
            record_failure(db, integration, code).await
        }
    }
}

/// Appends to the failure log that the alert rules count over time windows.
pub async fn record_failure(db: &PgPool, integration: &str, code: &str) -> Result<(), sqlx::Error> {
    sqlx::query("INSERT INTO ops_failures (integration, code) VALUES ($1, $2)")
        .bind(integration)
        .bind(code)
        .execute(db)
        .await
        .map(|_| ())
}

/// One auth-abuse event (`code` says which: lockout, refresh reuse, MFA failure). Feeds the `auth_suspicious` alert.
/// Best effort: a failed log write must not change the auth answer the caller is about to give.
pub async fn auth_abuse(db: &PgPool, code: &str) {
    if let Err(e) = record_failure(db, "auth_abuse", code).await {
        tracing::warn!(error = %e, code, "ops auth_abuse record failed");
    }
}

/// Records one outcome and waits for it. Awaited (not spawned) so the row exists before the caller
/// answers: status and alert rules never race a request or a shutdown. A write failure only logs.
pub async fn record(db: &PgPool, integration: &'static str, outcome: Result<(), &'static str>) {
    if let Err(e) = write_outcome(db, integration, outcome).await {
        tracing::warn!(error = %e, integration, "ops record failed");
    }
}

/// Counts every 5xx answer in the current hour (one row per hour). Awaited, like `record`.
pub async fn count_5xx(State(s): State<AppState>, req: Request, next: Next) -> Response {
    let resp = next.run(req).await;
    if resp.status().is_server_error() {
        let res = sqlx::query(
            "INSERT INTO ops_http_errors (hour, count) VALUES (date_trunc('hour', now()), 1)
             ON CONFLICT (hour) DO UPDATE SET count = ops_http_errors.count + 1",
        )
        .execute(&s.db)
        .await;
        if let Err(e) = res {
            tracing::warn!(error = %e, "5xx counter failed");
        }
    }
    resp
}

/// Seconds since start-up, for the metrics page.
pub fn uptime_secs() -> u64 {
    STARTED.get_or_init(Instant::now).elapsed().as_secs()
}

/// Parses `df -Pk` output (POSIX format, 1K blocks). None when the line is not there.
pub fn parse_df(text: &str) -> Option<Disk> {
    let cols: Vec<&str> = text.lines().nth(1)?.split_whitespace().collect();
    let total = cols.get(1)?.parse::<u64>().ok()? * 1024;
    let free = cols.get(3)?.parse::<u64>().ok()? * 1024;
    Some(Disk { total, free })
}

/// Free space on the filesystem holding `path`. None where `df` is missing (for example dev on Windows).
pub async fn disk_usage(path: PathBuf) -> Option<Disk> {
    tokio::task::spawn_blocking(move || {
        let out = std::process::Command::new("df").arg("-Pk").arg(&path).output().ok()?;
        parse_df(&String::from_utf8_lossy(&out.stdout))
    })
    .await
    .ok()
    .flatten()
}

pub fn disk_level(pct: f64) -> Level {
    if pct < DISK_LOW_PCT {
        Level::Red
    } else if pct < DISK_WARN_PCT {
        Level::Yellow
    } else {
        Level::Green
    }
}

pub fn backup_level(age_hours: Option<f64>) -> Level {
    match age_hours {
        None => Level::Red,
        Some(h) if h > BACKUP_STALE_HOURS => Level::Red,
        Some(h) if h > BACKUP_LATE_HOURS => Level::Yellow,
        Some(_) => Level::Green,
    }
}

pub fn errors_level(count_24h: i64) -> Level {
    if count_24h >= ERRORS_BAD {
        Level::Red
    } else if count_24h >= ERRORS_WARN {
        Level::Yellow
    } else {
        Level::Green
    }
}

/// Webhook signature failures in 24h: a few is a misconfigured secret or a probe; many is an attack or a broken key.
pub fn signature_level(count_24h: i64) -> Level {
    if count_24h >= SIGNATURE_BAD {
        Level::Red
    } else if count_24h > 0 {
        Level::Yellow
    } else {
        Level::Green
    }
}

/// One integration: not set up is a yellow reminder; a failure in the last day with no success after it is red.
pub fn integration_level(configured: bool, last_ok: Option<DateTime<Utc>>, last_fail: Option<DateTime<Utc>>, now: DateTime<Utc>) -> Level {
    if !configured {
        return Level::Yellow;
    }
    match last_fail {
        Some(f) if now - f < Duration::hours(24) => {
            if last_ok.is_none_or(|ok| ok < f) { Level::Red } else { Level::Yellow }
        }
        _ => Level::Green,
    }
}

#[derive(Serialize)]
struct Check {
    key: &'static str,
    level: Level,
    value: Value,
}

fn check(key: &'static str, level: Level, value: impl Serialize) -> Check {
    Check { key, level, value: json!(value) }
}

#[derive(sqlx::FromRow)]
struct HealthRow {
    integration: String,
    last_ok_at: Option<DateTime<Utc>>,
    last_fail_at: Option<DateTime<Utc>>,
    last_error: Option<String>,
}

async fn count_failures(db: &PgPool, integration: &str, hours: i64) -> Result<i64, sqlx::Error> {
    sqlx::query_scalar("SELECT count(*) FROM ops_failures WHERE integration = $1 AND at > now() - make_interval(hours => $2::int)")
        .bind(integration)
        .bind(hours as i32)
        .fetch_one(db)
        .await
}

/// Age of the last backup in hours, from the status the backup command writes. None when never run.
pub fn backup_age_hours(status: Option<&Value>, now: DateTime<Utc>) -> Option<f64> {
    let at: DateTime<Utc> = status?.get("at")?.as_str()?.parse().ok()?;
    Some((now - at).num_minutes() as f64 / 60.0)
}

/// Everything the status page shows, in one call. Database errors are reported in the payload, not as a failure.
pub async fn status(s: &AppState) -> ApiResult<Value> {
    let now = Utc::now();
    let started = Instant::now();
    let ping = sqlx::query_scalar::<_, i32>("SELECT 1").fetch_one(&s.db).await.is_ok();
    let latency_ms = started.elapsed().as_millis() as u64;
    let db_size: i64 = sqlx::query_scalar("SELECT pg_database_size(current_database())").fetch_one(&s.db).await.unwrap_or(0);
    let sessions: i64 = sqlx::query_scalar("SELECT count(*) FROM pg_stat_activity WHERE datname = current_database()")
        .fetch_one(&s.db)
        .await
        .unwrap_or(0);
    let errors: i64 = sqlx::query_scalar("SELECT COALESCE(sum(count), 0)::bigint FROM ops_http_errors WHERE hour > now() - interval '24 hours'")
        .fetch_one(&s.db)
        .await?;
    let backup: Option<Value> = sqlx::query_scalar("SELECT value FROM settings WHERE key = $1")
        .bind(BACKUP_STATUS_KEY)
        .fetch_optional(&s.db)
        .await?;
    let health: Vec<HealthRow> = sqlx::query_as("SELECT integration, last_ok_at, last_fail_at, last_error FROM ops_health").fetch_all(&s.db).await?;
    let signatures = count_failures(&s.db, "portone_webhook", 24).await?;
    let stuck = count_failures(&s.db, "payment_stuck", 24).await?;
    let disk = disk_usage(s.config.upload_dir.clone()).await;

    let integ = s.providers.integ();
    let integrations: Vec<Value> = INTEGRATIONS
        .iter()
        .map(|sec| {
            let row = health.iter().find(|h| h.integration == sec.code());
            let configured = integ.has(*sec);
            let (ok, fail) = (row.and_then(|r| r.last_ok_at), row.and_then(|r| r.last_fail_at));
            let level = integration_level(configured, ok, fail, now);
            json!({ "code": sec.code(), "configured": configured, "level": level, "last_ok_at": ok, "last_fail_at": fail, "last_error": row.and_then(|r| r.last_error.clone()) })
        })
        .collect();
    let backup_age = backup_age_hours(backup.as_ref(), now);
    let checks = vec![
        check("db", if ping { Level::Green } else { Level::Red }, latency_ms),
        check("disk", disk.map_or(Level::Green, |d| disk_level(d.free_pct())), disk.map(|d| d.free_pct().round())),
        check("backup", backup_level(backup_age), backup_age.map(|h| h.round())),
        check("errors", errors_level(errors), errors),
        check("payments", if stuck > 0 { Level::Red } else { Level::Green }, stuck),
        check("webhook", signature_level(signatures), signatures),
    ];
    // Background jobs of this process. Listed beside the checks (the console has no card for them
    // yet); a stalled job still turns the page red, and the `job_stalled` owner alert says why.
    let jobs = crate::jobs::health(now.timestamp() as f64);
    let jobs_level = if jobs.iter().any(|j| j["stalled"] == true) {
        Level::Red
    } else {
        Level::Green
    };
    let level = checks
        .iter()
        .map(|c| c.level)
        .chain(integrations.iter().filter_map(|i| i["level"].as_str().map(level_of)))
        .chain([jobs_level])
        .max()
        .unwrap_or(Level::Green);
    Ok(json!({
        "level": level,
        "version": env!("CARGO_PKG_VERSION"),
        "uptime_secs": uptime_secs(),
        "dev_mode": s.config.dev_mode,
        "db": { "ok": ping, "latency_ms": latency_ms, "size_bytes": db_size, "sessions": sessions, "pool_open": s.db.size(), "pool_idle": s.db.num_idle() },
        "disk": disk.map(|d| json!({ "total_bytes": d.total, "free_bytes": d.free, "free_pct": d.free_pct() })),
        "backup": backup.map(|b| json!({ "status": b, "age_hours": backup_age })),
        "checks": checks,
        "integrations": integrations,
        "jobs": jobs,
    }))
}

fn level_of(s: &str) -> Level {
    match s {
        "red" => Level::Red,
        "yellow" => Level::Yellow,
        _ => Level::Green,
    }
}

/// Reads the last backup status the backup command stored (for the alert rules).
pub async fn backup_status(db: &PgPool) -> Result<Option<Value>, sqlx::Error> {
    sqlx::query_scalar("SELECT value FROM settings WHERE key = $1").bind(BACKUP_STATUS_KEY).fetch_optional(db).await
}

/// Keeps the failure log small: the longest alert window is a day.
pub async fn prune(db: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::query("DELETE FROM ops_failures WHERE at < now() - interval '3 days'").execute(db).await?;
    sqlx::query("DELETE FROM ops_http_errors WHERE hour < now() - interval '3 days'").execute(db).await?;
    crate::realtime::prune_stored(db).await
    
}

/// Used by the alert rules: failures of one integration in the last `minutes`.
pub async fn failures_within(db: &PgPool, integrations: &[&str], minutes: i64) -> Result<i64, sqlx::Error> {
    sqlx::query_scalar("SELECT count(*) FROM ops_failures WHERE integration = ANY($1) AND at > now() - make_interval(mins => $2::int)")
        .bind(integrations)
        .bind(minutes as i32)
        .fetch_one(db)
        .await
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    fn at(h: u32) -> DateTime<Utc> {
        Utc.with_ymd_and_hms(2026, 11, 11, h, 0, 0).unwrap()
    }

    #[test]
    fn df_parsing_reads_kilobyte_columns() {
        let text = "Filesystem     1024-blocks      Used Available Capacity Mounted on\n/dev/sda1        1000    600     400      60% /data\n";
        assert_eq!(parse_df(text), Some(Disk { total: 1000 * 1024, free: 400 * 1024 }));
        assert_eq!(parse_df("garbage"), None);
        assert!((Disk { total: 1000, free: 95 }.free_pct() - 9.5).abs() < 1e-9);
    }

    #[test]
    fn disk_below_ten_percent_is_red() {
        assert_eq!(disk_level(9.9), Level::Red);
        assert_eq!(disk_level(15.0), Level::Yellow);
        assert_eq!(disk_level(42.0), Level::Green);
    }

    #[test]
    fn backup_thresholds_follow_the_nightly_schedule() {
        assert_eq!(backup_level(None), Level::Red);
        assert_eq!(backup_level(Some(12.0)), Level::Green);
        assert_eq!(backup_level(Some(30.0)), Level::Yellow);
        assert_eq!(backup_level(Some(37.0)), Level::Red);
    }

    #[test]
    fn integration_turns_red_only_when_failing_after_last_success() {
        let now = at(12);
        assert_eq!(integration_level(false, None, None, now), Level::Yellow);
        assert_eq!(integration_level(true, None, None, now), Level::Green);
        assert_eq!(integration_level(true, Some(at(11)), Some(at(10)), now), Level::Yellow, "recovered");
        assert_eq!(integration_level(true, Some(at(9)), Some(at(11)), now), Level::Red, "failing now");
        let old = Utc.with_ymd_and_hms(2026, 11, 9, 0, 0, 0).unwrap();
        assert_eq!(integration_level(true, None, Some(old), now), Level::Green, "failure older than a day");
    }

    #[test]
    fn counts_map_to_levels_and_overall_is_the_worst() {
        assert_eq!(errors_level(19), Level::Green);
        assert_eq!(errors_level(20), Level::Yellow);
        assert_eq!(errors_level(100), Level::Red);
        assert_eq!(signature_level(1), Level::Yellow);
        assert_eq!(signature_level(3), Level::Red);
        assert!(Level::Red > Level::Yellow && Level::Yellow > Level::Green);
    }

    #[test]
    fn backup_age_reads_the_stored_timestamp() {
        let status = json!({ "at": "2026-11-10T18:30:00Z" });
        assert_eq!(backup_age_hours(Some(&status), at(12)), Some(17.5));
        assert_eq!(backup_age_hours(None, at(12)), None);
    }
}
