//! Partner quality recompute. Aggregates each partner's last 90 days (ratings, check-ins, bookings,
//! cases), stores the score, auto-pauses offers below the owner's floor (the owner can lift a pause per
//! partner), and notifies a partner once when they drop into the warning band or pause.

use crate::{
    error::{ApiError, ApiResult},
    lifecycle::next_tick,
    realtime::{Recipient, notify},
    state::AppState,
};
use chrono::{DateTime, Duration as ChronoDuration, NaiveDate, Utc};
use domain::quality::{self, OwnerOverride, QualityInputs, QualityStatus, QualityThresholds};
use serde_json::json;
use sqlx::PgPool;
use std::time::Duration;
use tokio::task::JoinHandle;
use uuid::Uuid;

pub const RECOMPUTE_EVERY: Duration = Duration::from_secs(3600);
const WINDOW_DAYS: i64 = 90;
/// Check-in within this many minutes after the booked start still counts as on time.
const ON_TIME_GRACE_MIN: i32 = 15;

/// One row per partner. Counts only; the domain turns them into a score.
const INPUTS_SQL: &str = "
SELECT p.id,
  (SELECT COALESCE(sum(r.rating), 0)::bigint FROM reviews r WHERE r.pro_id = p.id AND NOT r.hidden AND r.created_at >= $1),
  (SELECT count(*) FROM reviews r WHERE r.pro_id = p.id AND NOT r.hidden AND r.created_at >= $1),
  (SELECT count(*) FROM bookings b WHERE b.pro_id = p.id AND b.visit_date >= $2),
  (SELECT count(*) FROM bookings b WHERE b.pro_id = p.id AND b.visit_date >= $2 AND b.status = 3),
  (SELECT count(*) FROM bookings b WHERE b.pro_id = p.id AND b.visit_date >= $2 AND b.checked_in_at IS NOT NULL),
  (SELECT count(*) FROM bookings b WHERE b.pro_id = p.id AND b.visit_date >= $2 AND b.checked_in_at IS NOT NULL
     AND b.checked_in_at <= ((b.visit_date + b.start_hour * interval '1 hour') AT TIME ZONE 'Asia/Seoul') + make_interval(mins => $3)),
  (SELECT count(*) FROM cases c JOIN bookings b ON b.id = c.booking_id WHERE b.pro_id = p.id AND c.kind = 'no_show' AND c.created_at >= $1),
  (SELECT count(*) FROM cases c JOIN bookings b ON b.id = c.booking_id WHERE b.pro_id = p.id AND c.kind = 'complaint' AND c.created_at >= $1)
FROM pros p";

type InputsRow = (Uuid, i64, i64, i64, i64, i64, i64, i64, i64);

fn to_u32(v: i64) -> ApiResult<u32> {
    u32::try_from(v).map_err(|_| ApiError::Internal(format!("negative quality count {v}")))
}

fn inputs_of(r: InputsRow) -> ApiResult<QualityInputs> {
    let i = QualityInputs {
        rating_sum: to_u32(r.1)?,
        rating_count: to_u32(r.2)?,
        jobs_assigned: to_u32(r.3)?,
        jobs_completed: to_u32(r.4)?,
        checkins: to_u32(r.5)?,
        checkins_on_time: to_u32(r.6)?,
        cancellations_or_no_shows: to_u32(r.7)?,
        complaints: to_u32(r.8)?,
    };
    i.validate()?;
    Ok(i)
}

/// Owner thresholds from the single `quality_settings` row.
pub async fn thresholds(db: &PgPool) -> ApiResult<QualityThresholds> {
    let (warning_below, pause_below): (i16, i16) = sqlx::query_as("SELECT warning_below, pause_below FROM quality_settings WHERE id = 1").fetch_one(db).await?;
    Ok(QualityThresholds { warning_below: warning_below as u8, pause_below: pause_below as u8 })
}

/// Job-offer gate for accepting a job: auto-pause first, then every required published training module.
pub async fn check_offer_gate(db: &PgPool, pro: Uuid) -> ApiResult<()> {
    let status: Option<String> = sqlx::query_scalar("SELECT status FROM partner_quality WHERE pro_id = $1").bind(pro).fetch_optional(db).await?;
    if status.and_then(|s| parse_status(&s)).is_some_and(|s| !quality::can_receive_offers(s)) {
        return Err(ApiError::Conflict("quality_paused"));
    }
    let required_done: Vec<bool> = sqlx::query_scalar(
        "SELECT tp.completed_at IS NOT NULL FROM training_modules m
         LEFT JOIN training_progress tp ON tp.module_id = m.id AND tp.pro_id = $1
         WHERE m.required AND m.published",
    )
    .bind(pro)
    .fetch_all(db)
    .await?;
    domain::training::check_can_receive_jobs(&required_done).map_err(|_| ApiError::Conflict("training_required"))
}

fn parse_status(s: &str) -> Option<QualityStatus> {
    match s {
        "ok" => Some(QualityStatus::Ok),
        "warning" => Some(QualityStatus::Warning),
        "paused" => Some(QualityStatus::Paused),
        "overridden_by_owner" => Some(QualityStatus::OverriddenByOwner),
        _ => None,
    }
}

fn status_str(s: QualityStatus) -> &'static str {
    match s {
        QualityStatus::Ok => "ok",
        QualityStatus::Warning => "warning",
        QualityStatus::Paused => "paused",
        QualityStatus::OverriddenByOwner => "overridden_by_owner",
    }
}

/// Recomputes every partner. A partner that fails is logged and skipped so one bad row never blocks the rest.
pub async fn recompute_pass(s: &AppState, now: DateTime<Utc>) -> ApiResult<usize> {
    let t = thresholds(&s.db).await?;
    let since_ts = now - ChronoDuration::days(WINDOW_DAYS);
    let since_date: NaiveDate = since_ts.date_naive();
    let rows: Vec<InputsRow> = sqlx::query_as(INPUTS_SQL).bind(since_ts).bind(since_date).bind(ON_TIME_GRACE_MIN).fetch_all(&s.db).await?;
    let mut done = 0;
    for row in rows {
        let pro = row.0;
        match recompute_one(s, t, pro, inputs_of(row)).await {
            Ok(()) => done += 1,
            Err(e) => tracing::warn!(error = ?e, pro = %pro, "quality recompute skipped partner"),
        }
    }
    Ok(done)
}

async fn recompute_one(s: &AppState, t: QualityThresholds, pro: Uuid, inputs: ApiResult<QualityInputs>) -> ApiResult<()> {
    let inputs = inputs?;
    let previous: Option<(String, bool)> = sqlx::query_as("SELECT status, lift_pause FROM partner_quality WHERE pro_id = $1").bind(pro).fetch_optional(&s.db).await?;
    let lift = previous.as_ref().is_some_and(|p| p.1);
    let prev_status = previous.as_ref().and_then(|p| parse_status(&p.0));
    let score = quality::score(&inputs);
    let status = quality::status(score, t, OwnerOverride { lift_pause: lift });
    sqlx::query(
        "INSERT INTO partner_quality (pro_id, score, status, lift_pause, inputs, computed_at) VALUES ($1, $2, $3, $4, $5, now())
         ON CONFLICT (pro_id) DO UPDATE SET score = EXCLUDED.score, status = EXCLUDED.status, inputs = EXCLUDED.inputs, computed_at = now()",
    )
    .bind(pro)
    .bind(i16::from(score))
    .bind(status_str(status))
    .bind(lift)
    .bind(sqlx::types::Json(&inputs))
    .execute(&s.db)
    .await?;
    if quality::should_notify_warning(prev_status, status) {
        notify(s, Recipient::Pro(pro), "quality.warning", "품질 점수가 낮아졌어요", "품질 점수를 확인하고 개선해 주세요.", json!({ "score": score })).await?;
    }
    Ok(())
}

/// Starts the periodic recompute. Errors are logged and the loop goes on.
pub fn spawn(state: AppState) -> JoinHandle<()> {
    let mut stop = state.hub.drain_signal();
    tokio::spawn(async move {
        let mut tick = tokio::time::interval(RECOMPUTE_EVERY);
        while next_tick(&mut tick, &mut stop).await {
            crate::jobs::run(&state, "quality", recompute_pass(&state, Utc::now())).await;
        }
    })
}
