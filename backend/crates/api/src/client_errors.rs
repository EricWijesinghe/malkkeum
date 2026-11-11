//! Client error reports from web, Windows and console apps: `POST /v1/client-errors` stores a capped,
//! PII-scrubbed row; the console lists the latest ones. Mobile crashes go to Crashlytics instead.
use crate::{
    auth::Admin,
    error::{ApiError, ApiResult},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Query, State},
    http::StatusCode,
    routing::{get, post},
};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sqlx::PgPool;
use std::sync::Mutex;
use std::time::{Duration, Instant};

const APPS: [&str; 3] = ["web", "windows", "console"];
const MAX_MESSAGE_CHARS: usize = 1000;
const MAX_STACK_CHARS: usize = 4000;
const MAX_VERSION_CHARS: usize = 40;
/// Global, not per IP: a flood of reports must not fill the table. Ordinary traffic is far below this.
const MAX_PER_MINUTE: u32 = 60;
const RETENTION_DAYS: i32 = 14;
const LIST_DEFAULT: i64 = 50;
const LIST_MAX: i64 = 200;

static WINDOW: Mutex<(Option<Instant>, u32)> = Mutex::new((None, 0));

pub fn routes() -> Router<AppState> {
    Router::new().route("/client-errors", post(report))
}

pub fn admin_routes() -> Router<AppState> {
    Router::new().route("/client-errors", get(list))
}

#[derive(Deserialize)]
pub struct Report {
    app: String,
    version: String,
    message: String,
    #[serde(default)]
    stack: String,
}

#[derive(Serialize, sqlx::FromRow)]
pub struct Row {
    id: i64,
    at: chrono::DateTime<chrono::Utc>,
    app: String,
    version: String,
    message: String,
    stack: String,
}

/// Blanks out e-mail addresses and phone-like digit runs (9+ digits, dashes allowed). Lines and
/// spacing are kept. Addresses (street names) cannot be detected reliably: the apps must not send them.
pub fn scrub(text: &str) -> String {
    text.split('\n')
        .map(|line| line.split(' ').map(scrub_token).collect::<Vec<_>>().join(" "))
        .collect::<Vec<_>>()
        .join("\n")
}

fn scrub_token(tok: &str) -> String {
    let digits = tok.chars().filter(char::is_ascii_digit).count();
    let email = tok.split_once('@').is_some_and(|(local, domain)| !local.is_empty() && domain.contains('.'));
    if email || digits >= 9 { "[redacted]".to_string() } else { tok.to_string() }
}

fn cap(s: &str, max: usize) -> String {
    s.chars().take(max).collect()
}

/// Validates and normalises one report. Errors are the only thing the client learns.
pub fn clean(r: Report) -> Result<(String, String, String, String), ApiError> {
    if !APPS.contains(&r.app.as_str()) {
        return Err(ApiError::BadRequest("invalid_app"));
    }
    let version = r.version.trim();
    if version.is_empty() || version.chars().count() > MAX_VERSION_CHARS {
        return Err(ApiError::BadRequest("invalid_version"));
    }
    let message = scrub(&cap(r.message.trim(), MAX_MESSAGE_CHARS));
    if message.is_empty() {
        return Err(ApiError::BadRequest("invalid_input"));
    }
    let stack = scrub(&cap(&r.stack, MAX_STACK_CHARS));
    Ok((r.app, cap(version, MAX_VERSION_CHARS), message, stack))
}

/// Fixed one-minute window. Returns false once the global budget for this minute is spent.
fn admit(now: Instant) -> bool {
    let Ok(mut w) = WINDOW.lock() else { return false };
    match w.0 {
        Some(start) if now.duration_since(start) < Duration::from_secs(60) => {}
        _ => *w = (Some(now), 0),
    }
    if w.1 >= MAX_PER_MINUTE {
        return false;
    }
    w.1 += 1;
    true
}

async fn report(State(s): State<AppState>, Json(r): Json<Report>) -> ApiResult<StatusCode> {
    let (app, version, message, stack) = clean(r)?;
    if !admit(Instant::now()) {
        return Err(ApiError::RateLimited);
    }
    sqlx::query("INSERT INTO client_errors (app, version, message, stack) VALUES ($1, $2, $3, $4)")
        .bind(app)
        .bind(version)
        .bind(message)
        .bind(stack)
        .execute(&s.db)
        .await?;
    Ok(StatusCode::NO_CONTENT)
}

#[derive(Deserialize)]
struct ListQuery {
    limit: Option<i64>,
}

async fn list(State(s): State<AppState>, Admin(_): Admin, Query(q): Query<ListQuery>) -> ApiResult<Json<Value>> {
    let limit = q.limit.unwrap_or(LIST_DEFAULT).clamp(1, LIST_MAX);
    let rows: Vec<Row> = sqlx::query_as("SELECT id, at, app, version, message, stack FROM client_errors ORDER BY at DESC LIMIT $1")
        .bind(limit)
        .fetch_all(&s.db)
        .await?;
    Ok(Json(serde_json::json!({ "items": rows })))
}

/// Called from the retention purge.
pub async fn prune(db: &PgPool) -> Result<u64, sqlx::Error> {
    let done = sqlx::query("DELETE FROM client_errors WHERE at < now() - make_interval(days => $1)")
        .bind(RETENTION_DAYS)
        .execute(db)
        .await?;
    Ok(done.rows_affected())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn report(app: &str, message: &str) -> Report {
        Report { app: app.into(), version: "1.0.0".into(), message: message.into(), stack: String::new() }
    }

    #[test]
    fn unknown_app_is_rejected() {
        assert!(matches!(clean(report("customer", "boom")), Err(ApiError::BadRequest("invalid_app"))));
    }

    #[test]
    fn empty_message_is_rejected() {
        assert!(clean(report("web", "   ")).is_err());
    }

    #[test]
    fn scrub_removes_phone_and_email_but_keeps_layout() {
        let out = scrub("call 010-1234-5678 or a@b.co now\n  at foo.js:12");
        assert_eq!(out, "call [redacted] or [redacted] now\n  at foo.js:12");
    }

    #[test]
    fn message_and_stack_are_capped() {
        let big = "x".repeat(MAX_MESSAGE_CHARS + 50);
        let (_, _, msg, _) = clean(Report { app: "web".into(), version: "1".into(), message: big, stack: "s".repeat(MAX_STACK_CHARS + 9) }).unwrap();
        assert_eq!(msg.chars().count(), MAX_MESSAGE_CHARS);
    }

    #[test]
    fn global_budget_is_enforced_per_window() {
        let now = Instant::now();
        *WINDOW.lock().unwrap() = (Some(now), MAX_PER_MINUTE);
        assert!(!admit(now));
        assert!(admit(now + Duration::from_secs(61)));
    }
}
