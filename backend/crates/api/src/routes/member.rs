//! Team member (partner app login): assigned jobs only, with full address, and completion.
//! Members never see payouts; settlement is written to the owner (`pro_id`) like owner completions.

use super::{
    booking_core::{CompletionBody, complete_job},
    bookings::{BOOKING_COLS, BookingRow, load_booking},
    site,
};
use crate::{
    auth::{Member, mask_name},
    error::{ApiError, ApiResult},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Path, Query, State},
    routing::{get, post},
};
use chrono::NaiveDate;
use serde::Deserialize;
use serde_json::{Value, json};
use uuid::Uuid;

const MAX_RANGE_DAYS: i64 = 62;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/me", get(me))
        .route("/jobs", get(jobs))
        .route("/jobs/{id}", get(job))
        .route("/jobs/{id}/complete", post(complete))
        .route("/jobs/{id}/check-in", post(check_in))
        .route("/jobs/{id}/check-out", post(check_out))
}

/// The member's arrival on their own assigned job; the rules are `site::check_in_job`, shared with the owner's.
async fn check_in(State(s): State<AppState>, Member(a): Member, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    let (b, _) = assigned(&s, a.id, id).await?;
    site::check_in_job(&s, &b).await
}

/// The member's departure from their own assigned job; the rules are `site::check_out_job`.
async fn check_out(State(s): State<AppState>, Member(a): Member, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    let (b, _) = assigned(&s, a.id, id).await?;
    site::check_out_job(&s, &b).await
}

async fn me(State(s): State<AppState>, Member(a): Member) -> ApiResult<Json<Value>> {
    let v: Value = sqlx::query_scalar(
        "SELECT jsonb_build_object('id', m.id, 'name', m.name, 'team_id', p.id, 'team_name', p.team_name)
         FROM team_members m JOIN pros p ON p.id = m.pro_id WHERE m.id = $1 AND m.invite_status <> 'removed'",
    )
    .bind(a.id)
    .fetch_one(&s.db)
    .await?;
    Ok(Json(v))
}

#[derive(Deserialize)]
struct Range {
    from: NaiveDate,
    to: NaiveDate,
}

/// Jobs assigned to this member in the date range. Same row shape as the owner's schedule.
async fn jobs(State(s): State<AppState>, Member(a): Member, Query(r): Query<Range>) -> ApiResult<Json<Vec<BookingRow>>> {
    if (r.to - r.from).num_days() > MAX_RANGE_DAYS {
        return Err(ApiError::BadRequest("range_too_large"));
    }
    let rows = sqlx::query_as(&format!(
        "SELECT {BOOKING_COLS} FROM bookings b WHERE b.assignee_id = $1 AND b.visit_date BETWEEN $2 AND $3 ORDER BY b.visit_date, b.start_hour"
    ))
    .bind(a.id)
    .bind(r.from)
    .bind(r.to)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}

/// The member's own job with its team memo, or 404: other jobs are invisible, not forbidden.
async fn assigned(s: &AppState, member: Uuid, booking: Uuid) -> ApiResult<(BookingRow, Option<String>)> {
    let b = load_booking(&s.db, booking).await?;
    let (assignee, memo): (Option<Uuid>, Option<String>) = sqlx::query_as("SELECT assignee_id, team_memo FROM bookings WHERE id = $1")
        .bind(booking)
        .fetch_one(&s.db)
        .await?;
    if assignee == Some(member) { Ok((b, memo)) } else { Err(ApiError::NotFound) }
}

/// Committed view: address, notes and masked customer name. No payout fields.
async fn job(State(s): State<AppState>, Member(a): Member, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    let (b, memo) = assigned(&s, a.id, id).await?;
    let raw_name: String = sqlx::query_scalar("SELECT name FROM users WHERE id = $1")
        .bind(b.user_id)
        .fetch_one(&s.db)
        .await?;
    Ok(Json(json!({
        "booking": b,
        "customer_name": mask_name(&raw_name),
        "team_memo": memo,
    })))
}

/// The member's completion. The rules and writes are `booking_core::complete_job`, shared with the
/// owner's; the settlement goes to the owner and the response carries no payout.
async fn complete(State(s): State<AppState>, Member(a): Member, Path(id): Path<Uuid>, Json(c): Json<CompletionBody>) -> ApiResult<Json<Value>> {
    let (b, _) = assigned(&s, a.id, id).await?;
    let Some(pro) = b.pro_id else {
        return Err(ApiError::NotFound);
    };
    complete_job(&s, &b, pro, Some(a.id), &c).await?;
    Ok(Json(json!({ "ok": true })))
}
