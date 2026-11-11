//! First-party product analytics. The apps send events only after the user opts in (consent is checked in
//! the app, not here). Events are anonymous: a random per-install id and an allowlisted name, screen and
//! platform. No user id, no free text, no contact data. Rows older than 90 days are purged (retention.rs).
//! The funnel and cohort views are computed from the business tables, so they do not depend on the app.
//! No third-party SDK is involved.

use crate::{
    auth::Staff,
    error::{ApiError, ApiResult},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Query, State},
    routing::{get, post},
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

pub const MAX_BATCH: usize = 50;
/// Event names the apps may send. Anything else is rejected, so no new data shape gets in unreviewed.
pub const EVENT_NAMES: [&str; 8] = ["app_open", "signup_start", "signup_done", "quote_view", "booking_start", "booking_done", "payment_done", "review_done"];
const PLATFORMS: [&str; 3] = ["android", "ios", "web"];
pub const RETENTION_DAYS: i64 = 90;

#[derive(Deserialize)]
pub struct Batch {
    anon_id: Uuid,
    events: Vec<Event>,
}

#[derive(Deserialize)]
pub struct Event {
    name: String,
    screen: Option<String>,
    platform: Option<String>,
}

/// Checks the batch against the allowlists. Returns an error code the client can log.
pub fn validate(b: &Batch) -> ApiResult<()> {
    if b.events.is_empty() || b.events.len() > MAX_BATCH {
        return Err(ApiError::BadRequest("batch_size"));
    }
    for e in &b.events {
        if !EVENT_NAMES.contains(&e.name.as_str()) {
            return Err(ApiError::BadRequest("event_name"));
        }
        if let Some(screen) = &e.screen {
            let ok = (1..=40).contains(&screen.len()) && screen.chars().all(|c| c.is_ascii_lowercase() || c == '_');
            if !ok {
                return Err(ApiError::BadRequest("screen"));
            }
        }
        if e.platform.as_deref().is_some_and(|p| !PLATFORMS.contains(&p)) {
            return Err(ApiError::BadRequest("platform"));
        }
    }
    Ok(())
}

pub fn public_routes() -> Router<AppState> {
    Router::new().route("/events", post(ingest))
}

pub fn admin_routes() -> Router<AppState> {
    Router::new().route("/analytics/funnel", get(funnel)).route("/analytics/cohorts", get(cohorts))
}

async fn ingest(State(s): State<AppState>, Json(b): Json<Batch>) -> ApiResult<Json<serde_json::Value>> {
    validate(&b)?;
    let names: Vec<String> = b.events.iter().map(|e| e.name.clone()).collect();
    let screens: Vec<Option<String>> = b.events.iter().map(|e| e.screen.clone()).collect();
    let platforms: Vec<Option<String>> = b.events.iter().map(|e| e.platform.clone()).collect();
    let n = sqlx::query(
        "INSERT INTO analytics_events (anon_id, name, screen, platform)
         SELECT $1, * FROM UNNEST($2::text[], $3::text[], $4::text[])",
    )
    .bind(b.anon_id)
    .bind(names)
    .bind(screens)
    .bind(platforms)
    .execute(&s.db)
    .await?
    .rows_affected();
    Ok(Json(serde_json::json!({ "accepted": n })))
}

#[derive(Deserialize)]
pub struct WindowQuery {
    #[serde(default = "default_days")]
    days: i32,
    #[serde(default = "default_weeks")]
    weeks: i32,
}

fn default_days() -> i32 {
    30
}

fn default_weeks() -> i32 {
    8
}

#[derive(Serialize, sqlx::FromRow)]
pub struct Funnel {
    /// Distinct installs that sent `app_open` in the window (consented installs only).
    installs: i64,
    signed_up: i64,
    quoted: i64,
    booked: i64,
    paid: i64,
    repeat_buyers: i64,
}

/// Funnel for customers who signed up in the window: each stage counts those who reached it at any point.
async fn funnel(State(s): State<AppState>, _st: Staff, Query(q): Query<WindowQuery>) -> ApiResult<Json<Funnel>> {
    let days = clamp(q.days, 1, 365);
    let row: Funnel = sqlx::query_as(
        "WITH cohort AS (
           SELECT id FROM users WHERE deleted_at IS NULL AND created_at >= now() - make_interval(days => $1)
         )
         SELECT
           (SELECT count(DISTINCT anon_id) FROM analytics_events WHERE name = 'app_open' AND created_at >= now() - make_interval(days => $1)) AS installs,
           (SELECT count(*) FROM cohort) AS signed_up,
           (SELECT count(*) FROM cohort c WHERE EXISTS (SELECT 1 FROM bookings b WHERE b.user_id = c.id)) AS quoted,
           (SELECT count(*) FROM cohort c WHERE EXISTS (SELECT 1 FROM bookings b WHERE b.user_id = c.id AND b.status BETWEEN 1 AND 3)) AS booked,
           (SELECT count(*) FROM cohort c WHERE EXISTS (SELECT 1 FROM checkouts k WHERE k.user_id = c.id AND k.status = 'paid')) AS paid,
           (SELECT count(*) FROM cohort c WHERE (SELECT count(*) FROM bookings b WHERE b.user_id = c.id AND b.status = 3) >= 2) AS repeat_buyers",
    )
    .bind(days)
    .fetch_one(&s.db)
    .await?;
    Ok(Json(row))
}

#[derive(Serialize, sqlx::FromRow)]
pub struct CohortRow {
    week: chrono::DateTime<chrono::Utc>,
    size: i64,
    /// Customers in the cohort with a booking in week 1, 2, 3 and 4 after their signup week.
    w1: i64,
    w2: i64,
    w3: i64,
    w4: i64,
}

/// Weekly signup cohorts. Raw counts; the console divides by `size`.
async fn cohorts(State(s): State<AppState>, _st: Staff, Query(q): Query<WindowQuery>) -> ApiResult<Json<Vec<CohortRow>>> {
    let weeks = clamp(q.weeks, 1, 52);
    let rows: Vec<CohortRow> = sqlx::query_as(
        "WITH c AS (
           SELECT id, date_trunc('week', created_at) AS cw FROM users
           WHERE deleted_at IS NULL AND created_at >= date_trunc('week', now()) - make_interval(weeks => $1)
         )
         SELECT cw AS week, count(*) AS size,
           count(*) FILTER (WHERE EXISTS (SELECT 1 FROM bookings b WHERE b.user_id = c.id AND b.status BETWEEN 1 AND 3
             AND b.created_at >= c.cw + make_interval(weeks => 1) AND b.created_at < c.cw + make_interval(weeks => 2))) AS w1,
           count(*) FILTER (WHERE EXISTS (SELECT 1 FROM bookings b WHERE b.user_id = c.id AND b.status BETWEEN 1 AND 3
             AND b.created_at >= c.cw + make_interval(weeks => 2) AND b.created_at < c.cw + make_interval(weeks => 3))) AS w2,
           count(*) FILTER (WHERE EXISTS (SELECT 1 FROM bookings b WHERE b.user_id = c.id AND b.status BETWEEN 1 AND 3
             AND b.created_at >= c.cw + make_interval(weeks => 3) AND b.created_at < c.cw + make_interval(weeks => 4))) AS w3,
           count(*) FILTER (WHERE EXISTS (SELECT 1 FROM bookings b WHERE b.user_id = c.id AND b.status BETWEEN 1 AND 3
             AND b.created_at >= c.cw + make_interval(weeks => 4) AND b.created_at < c.cw + make_interval(weeks => 5))) AS w4
         FROM c GROUP BY cw ORDER BY cw",
    )
    .bind(weeks)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}

fn clamp(v: i32, lo: i32, hi: i32) -> i32 {
    v.clamp(lo, hi)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn batch(json: &str) -> Batch {
        serde_json::from_str(json).expect("json")
    }

    #[test]
    fn accepts_allowlisted_events() {
        let b = batch(r#"{"anon_id":"0195e0a2-0000-7000-8000-000000000001","events":[{"name":"app_open","platform":"android"},{"name":"quote_view","screen":"quote_detail"}]}"#);
        assert!(validate(&b).is_ok());
    }

    #[test]
    fn rejects_unknown_names_free_text_screens_and_oversize_batches() {
        let unknown = batch(r#"{"anon_id":"0195e0a2-0000-7000-8000-000000000001","events":[{"name":"email_typed"}]}"#);
        assert!(validate(&unknown).is_err());
        let free_text = batch(r#"{"anon_id":"0195e0a2-0000-7000-8000-000000000001","events":[{"name":"app_open","screen":"Hi John 010-1234"}]}"#);
        assert!(validate(&free_text).is_err());
        let many = format!(
            r#"{{"anon_id":"0195e0a2-0000-7000-8000-000000000001","events":[{}]}}"#,
            vec![r#"{"name":"app_open"}"#; MAX_BATCH + 1].join(",")
        );
        assert!(validate(&batch(&many)).is_err());
        let empty = batch(r#"{"anon_id":"0195e0a2-0000-7000-8000-000000000001","events":[]}"#);
        assert!(validate(&empty).is_err());
    }

    #[test]
    fn rejects_unknown_platforms() {
        let b = batch(r#"{"anon_id":"0195e0a2-0000-7000-8000-000000000001","events":[{"name":"app_open","platform":"windows-phone"}]}"#);
        assert!(validate(&b).is_err());
    }
}
