//! Team member (partner app login): assigned jobs only, with full address, and completion.
//! Members never see payouts; settlement is written to the owner (`pro_id`) like owner completions.

use super::{
    bookings::{BOOKING_COLS, BookingRow, load_booking},
    chat, growth, partner_jobs, uploads,
};
use crate::{
    auth::{Member, mask_name},
    error::{ApiError, ApiResult},
    realtime::{Recipient, notify},
    state::AppState,
    util::{best_effort, own_uploads, today_kst},
};
use axum::{
    Json, Router,
    extract::{Path, Query, State},
    routing::{get, post},
};
use chrono::NaiveDate;
use domain::{
    Won,
    partner::{payout, payout_date},
};
use serde::Deserialize;
use serde_json::{Value, json};
use uuid::Uuid;

const MAX_RANGE_DAYS: i64 = 62;
const CHECKLIST_ITEMS: usize = 4;
const MAX_PHOTOS: usize = 20;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/me", get(me))
        .route("/jobs", get(jobs))
        .route("/jobs/{id}", get(job))
        .route("/jobs/{id}/complete", post(complete))
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

#[derive(Deserialize)]
struct Completion {
    before_photos: Vec<String>,
    after_photos: Vec<String>,
    checklist: Vec<bool>,
}

/// Same rules and writes as the owner's completion (`partner_jobs::complete`), with no payout in the response.
/// Kept as a copy: the owner handler carries the team-phone gate, and the shared body is not factored out yet.
async fn complete(State(s): State<AppState>, Member(a): Member, Path(id): Path<Uuid>, Json(c): Json<Completion>) -> ApiResult<Json<Value>> {
    let base = &s.config.public_base_url;
    let (Some(before), Some(after)) = (own_uploads(base, &c.before_photos), own_uploads(base, &c.after_photos)) else {
        return Err(ApiError::BadRequest("completion_incomplete"));
    };
    let photos_ok = (1..=MAX_PHOTOS).contains(&before.len()) && (1..=MAX_PHOTOS).contains(&after.len());
    if !photos_ok || c.checklist.len() != CHECKLIST_ITEMS || !c.checklist.iter().all(|x| *x) {
        return Err(ApiError::BadRequest("completion_incomplete"));
    }
    if !uploads::owned(&s.db, Some(a.id), &before).await? || !uploads::owned(&s.db, Some(a.id), &after).await? {
        return Err(ApiError::BadRequest("completion_incomplete"));
    }
    let (b, _) = assigned(&s, a.id, id).await?;
    let Some(pro) = b.pro_id else {
        return Err(ApiError::NotFound);
    };
    if partner_jobs::settled_once(&s.db, id, pro).await?.is_some() {
        return Ok(Json(json!({ "ok": true })));
    }
    let today = today_kst();
    // A job can't be completed (and paid) before it has happened.
    if b.visit_date > today {
        return Err(ApiError::Conflict("job_not_started"));
    }
    let gross = b.final_price.or(b.list_price).ok_or(ApiError::Conflict("job_unpriced"))?;
    let fee_bps: i32 = sqlx::query_scalar("SELECT fee_bps FROM pros WHERE id = $1").bind(pro).fetch_one(&s.db).await?;
    let p = payout(Won(gross), i64::from(fee_bps));
    let is_quote = b.answers.is_some();
    let mut tx = s.db.begin().await?;
    let moved = sqlx::query("UPDATE bookings SET status = 3, completed_at = now(), updated_at = now() WHERE id = $1 AND pro_id = $2 AND status = 2")
        .bind(id)
        .bind(pro)
        .execute(&mut *tx)
        .await?;
    if moved.rows_affected() == 0 {
        return Err(ApiError::Conflict("job_not_active"));
    }
    sqlx::query("INSERT INTO completion_reports (booking_id, before_photos, after_photos, checklist, submitted_by) VALUES ($1,$2,$3,$4,$5)")
        .bind(id)
        .bind(&before)
        .bind(&after)
        .bind(json!(c.checklist))
        .bind(a.id)
        .execute(&mut *tx)
        .await?;
    sqlx::query("INSERT INTO settlements (pro_id, booking_id, gross, fee, net, payout_date, state) VALUES ($1,$2,$3,$4,$5,$6,$7)")
        .bind(pro)
        .bind(id)
        .bind(p.gross.0)
        .bind(p.fee.0)
        .bind(p.net.0)
        .bind(if is_quote { None } else { Some(payout_date(today)) })
        .bind(if is_quote { "waiting_balance" } else { "pending" })
        .execute(&mut *tx)
        .await?;
    growth::reward_on_paid_completion(&mut tx, id).await?;
    crate::points::on_completed(&mut tx, id).await?;
    tx.commit().await?;
    if let Some(t) = b.thread_id {
        best_effort("chat", chat::post_system(&s, t, "job_completed", json!({}))).await;
    }
    notify(
        &s,
        Recipient::User(b.user_id),
        "booking.completed",
        "청소가 끝났어요",
        "전후 사진을 확인하고 후기를 남겨 주세요",
        json!({ "booking_id": id, "status": 3 }),
    )
    .await?;
    Ok(Json(json!({ "ok": true })))
}
