//! Cases: claims, incidents and disputes. Customers and partners file on their own bookings; staff
//! triage, assign, note and settle. Refunds and settlement holds are admin-only. Every move is audited.

use super::{
    audit,
    bookings::{load_booking, owned, refund_all},
    uploads,
};
use crate::{
    auth::{Customer, Pro, Role, Staff},
    error::{ApiError, ApiResult},
    noshow,
    realtime::Recipient,
    safety,
    state::AppState,
    util::own_uploads,
};
use axum::{
    Json, Router,
    extract::{Path, Query, State},
    routing::{get, post},
};
use chrono::{DateTime, Utc};
use domain::booking::BookingStatus;
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

/// First response target. Overdue means open or investigating past this.
const SLA_HOURS: i32 = 24;
const MAX_TEXT: usize = 2000;
const MAX_PHOTOS: usize = 5;
/// Largest apology coupon a reassign can issue (KRW).
const MAX_APOLOGY_COUPON: i64 = 100_000;

pub fn customer_routes() -> Router<AppState> {
    Router::new().route("/bookings/{id}/cases", post(customer_open))
}

pub fn partner_routes() -> Router<AppState> {
    Router::new().route("/jobs/{id}/cases", post(partner_open))
}

pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/cases", get(list))
        .route("/cases/{id}", get(detail).put(update))
        .route("/cases/{id}/reassign", post(reassign))
}

/// Fields a new case needs. `booking` is None only for cases not tied to a job.
pub struct NewCase<'a> {
    pub booking: Option<Uuid>,
    pub kind: &'a str,
    pub source: &'a str,
    pub reporter: &'a str,
    pub reporter_id: Option<Uuid>,
    pub summary: &'a str,
    pub photos: Value,
}

pub async fn insert(db: &PgPool, c: NewCase<'_>) -> ApiResult<Uuid> {
    Ok(sqlx::query_scalar(
        "INSERT INTO cases (booking_id, kind, source, reporter_role, reporter_id, summary, photos, sla_due_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, now() + make_interval(hours => $8)) RETURNING id",
    )
    .bind(c.booking)
    .bind(c.kind)
    .bind(c.source)
    .bind(c.reporter)
    .bind(c.reporter_id)
    .bind(c.summary)
    .bind(c.photos)
    .bind(SLA_HOURS)
    .fetch_one(db)
    .await?)
}

/// An AI handoff on a job opens one complaint case, unless one is already open for that job.
pub async fn open_from_ai(db: &PgPool, booking: Option<Uuid>, customer: Option<Uuid>, thread: Uuid) -> ApiResult<()> {
    let (Some(booking), Some(customer)) = (booking, customer) else {
        return Ok(());
    };
    sqlx::query(
        "INSERT INTO cases (booking_id, kind, source, reporter_role, reporter_id, summary, sla_due_at)
         SELECT $1, 'complaint', 'ai', 'customer', $2, $3, now() + make_interval(hours => $4)
         WHERE NOT EXISTS (SELECT 1 FROM cases WHERE booking_id = $1 AND source = 'ai' AND status IN ('open', 'investigating'))",
    )
    .bind(booking)
    .bind(customer)
    .bind(format!("AI 상담 이관 (thread {thread})"))
    .bind(SLA_HOURS)
    .execute(db)
    .await?;
    Ok(())
}

#[derive(Deserialize)]
struct NewCaseBody {
    kind: String,
    summary: String,
    #[serde(default)]
    photos: Vec<String>,
}

/// Shared checks for a filing: known kind for this reporter, bounded text, bounded photos.
fn validate(body: &NewCaseBody, reporter: &str) -> ApiResult<()> {
    let len = body.summary.trim().chars().count();
    if !safety::may_file(reporter, &body.kind) || len == 0 || len > MAX_TEXT || body.photos.len() > MAX_PHOTOS {
        return Err(ApiError::BadRequest("invalid_case"));
    }
    Ok(())
}

fn job_is_open_to_claims(status: BookingStatus) -> bool {
    matches!(status, BookingStatus::TeamAssigned | BookingStatus::Completed)
}

async fn customer_open(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>, Json(b): Json<NewCaseBody>) -> ApiResult<Json<Value>> {
    validate(&b, "customer")?;
    let booking = owned(&s, a.id, id).await?;
    if !job_is_open_to_claims(booking.status()?) {
        return Err(ApiError::Conflict("booking_closed"));
    }
    let photos = own_upload_list(&s, Some(a.id), &b.photos, false).await?;
    let case = insert(
        &s.db,
        NewCase { booking: Some(id), kind: &b.kind, source: "manual", reporter: "customer", reporter_id: Some(a.id), summary: b.summary.trim(), photos },
    )
    .await?;
    audit(&s.db, "customer", Some(a.id), "case.open", &case.to_string(), json!({ "booking_id": id, "kind": b.kind })).await?;
    s.hub.send(Recipient::Staff, "case.opened", json!({ "case_id": case }));
    Ok(Json(json!({ "id": case })))
}

async fn partner_open(State(s): State<AppState>, Pro(a): Pro, Path(id): Path<Uuid>, Json(b): Json<NewCaseBody>) -> ApiResult<Json<Value>> {
    validate(&b, "partner")?;
    let booking = load_booking(&s.db, id).await?;
    if booking.pro_id != Some(a.id) {
        return Err(ApiError::NotFound);
    }
    if !job_is_open_to_claims(booking.status()?) {
        return Err(ApiError::Conflict("booking_closed"));
    }
    let photos = own_upload_list(&s, Some(a.id), &b.photos, true).await?;
    let case = insert(
        &s.db,
        NewCase { booking: Some(id), kind: &b.kind, source: "manual", reporter: "partner", reporter_id: Some(a.id), summary: b.summary.trim(), photos },
    )
    .await?;
    audit(&s.db, "pro", Some(a.id), "case.open", &case.to_string(), json!({ "booking_id": id, "kind": b.kind })).await?;
    s.hub.send(Recipient::Staff, "case.opened", json!({ "case_id": case }));
    Ok(Json(json!({ "id": case })))
}

/// Photos must be this reporter's own uploads (a partner also gets their team's).
async fn own_upload_list(s: &AppState, owner: Option<Uuid>, urls: &[String], team: bool) -> ApiResult<Value> {
    if urls.is_empty() {
        return Ok(json!([]));
    }
    let stored = own_uploads(s.config.public_base_url.as_str(), urls).ok_or(ApiError::BadRequest("invalid_photo"))?;
    let ours = match (team, owner) {
        (true, Some(pro)) => uploads::owned_by_team(&s.db, pro, &stored).await?,
        _ => uploads::owned(&s.db, owner, &stored).await?,
    };
    if !ours {
        return Err(ApiError::BadRequest("invalid_photo"));
    }
    Ok(json!(stored))
}

#[derive(Serialize, sqlx::FromRow)]
pub struct CaseRow {
    id: Uuid,
    booking_id: Option<Uuid>,
    booking_number: Option<String>,
    kind: String,
    source: String,
    reporter_role: String,
    reporter_id: Option<Uuid>,
    status: String,
    assignee_id: Option<Uuid>,
    summary: String,
    photos: Value,
    outcome: Option<Value>,
    sla_due_at: DateTime<Utc>,
    created_at: DateTime<Utc>,
    resolved_at: Option<DateTime<Utc>>,
    overdue: bool,
}

const CASE_COLS: &str = "c.id, c.booking_id, b.number AS booking_number, c.kind, c.source, c.reporter_role, c.reporter_id, c.status,
    c.assignee_id, c.summary, c.photos, c.outcome, c.sla_due_at, c.created_at, c.resolved_at,
    (c.status IN ('open', 'investigating') AND c.sla_due_at < now()) AS overdue";

#[derive(Deserialize)]
struct ListQuery {
    status: Option<String>,
}

/// Queue order: open work first, then the earliest SLA deadline.
async fn list(State(s): State<AppState>, _st: Staff, Query(q): Query<ListQuery>) -> ApiResult<Json<Vec<CaseRow>>> {
    let rows = sqlx::query_as(&format!(
        "SELECT {CASE_COLS} FROM cases c LEFT JOIN bookings b ON b.id = c.booking_id
         WHERE ($1::text IS NULL OR c.status = $1)
         ORDER BY (c.status IN ('open', 'investigating')) DESC, c.sla_due_at LIMIT 200"
    ))
    .bind(q.status)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}

async fn load_case(db: &PgPool, id: Uuid) -> ApiResult<CaseRow> {
    sqlx::query_as(&format!("SELECT {CASE_COLS} FROM cases c LEFT JOIN bookings b ON b.id = c.booking_id WHERE c.id = $1"))
        .bind(id)
        .fetch_optional(db)
        .await?
        .ok_or(ApiError::NotFound)
}

/// Case, internal notes and the job (with check-in/out times, which only staff see).
async fn case_view(s: &AppState, id: Uuid) -> ApiResult<Value> {
    let case = load_case(&s.db, id).await?;
    let notes: Value = sqlx::query_scalar(
        "SELECT COALESCE(jsonb_agg(jsonb_build_object('id', n.id, 'author', st.name, 'body', n.body, 'created_at', n.created_at) ORDER BY n.created_at), '[]')
         FROM case_notes n LEFT JOIN staff st ON st.id = n.author_id WHERE n.case_id = $1",
    )
    .bind(id)
    .fetch_one(&s.db)
    .await?;
    let booking = match case.booking_id {
        Some(b) => Some(load_booking(&s.db, b).await?),
        None => None,
    };
    Ok(json!({ "case": case, "notes": notes, "booking": booking }))
}

async fn detail(State(s): State<AppState>, _st: Staff, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    Ok(Json(case_view(&s, id).await?))
}

#[derive(Deserialize)]
struct CaseUpdate {
    status: Option<String>,
    assignee_id: Option<Uuid>,
    note: Option<String>,
    /// Admin only. Refunds up to this amount across the job's payments, once per case.
    refund_amount: Option<i64>,
    /// Admin only. true holds a pending settlement; false releases a held one.
    hold_settlement: Option<bool>,
}

/// Status, assignee, note, refund and hold in one request. Money moves first (as in cancellation),
/// then the case row is written under a status guard so a concurrent move fails instead of racing.
async fn update(State(s): State<AppState>, Staff(st): Staff, Path(id): Path<Uuid>, Json(u): Json<CaseUpdate>) -> ApiResult<Json<Value>> {
    let case = load_case(&s.db, id).await?;
    let money = u.refund_amount.is_some() || u.hold_settlement.is_some();
    if money && st.role != Role::StaffAdmin {
        return Err(ApiError::Forbidden);
    }
    if let Some(to) = &u.status {
        if to != &case.status && !safety::can_move(&case.status, to) {
            return Err(ApiError::Conflict("case_move_invalid"));
        }
    }
    if u.note.as_deref().is_some_and(|n| n.trim().len() > MAX_TEXT) {
        return Err(ApiError::BadRequest("invalid_note"));
    }
    let mut outcome = case.outcome.clone().unwrap_or_else(|| json!({}));
    if let Some(amount) = u.refund_amount {
        let booking = case.booking_id.ok_or(ApiError::BadRequest("case_has_no_booking"))?;
        if amount <= 0 {
            return Err(ApiError::BadRequest("invalid_refund"));
        }
        // Claim first: the row is written as pending before any money moves, and only a case with no
        // refund field can be claimed. A retry or a second click sees pending/done and stops here.
        let key = Uuid::now_v7();
        let claimed = sqlx::query("UPDATE cases SET outcome = jsonb_set(COALESCE(outcome, '{}'), '{refund}', $2), updated_at = now() WHERE id = $1 AND outcome->'refund' IS NULL")
            .bind(id)
            .bind(json!({ "status": "pending", "key": key, "requested": amount }))
            .execute(&s.db)
            .await?
            .rows_affected();
        if claimed == 0 {
            return Err(ApiError::Conflict("refund_already_claimed"));
        }
        // Gateway cancels have no idempotency id here, so on an error the claim stays pending and a
        // person reconciles it with the gateway. Never retried automatically.
        let refunded = match refund_all(&s, booking, Some(amount)).await {
            Ok(total) => total,
            Err(e) => {
                audit(&s.db, "staff", Some(st.id), "case.refund_failed", &id.to_string(), json!({ "key": key, "requested": amount })).await?;
                return Err(e);
            }
        };
        outcome["refund"] = json!({ "status": "done", "key": key, "requested": amount, "refunded": refunded });
        audit(&s.db, "staff", Some(st.id), "case.refund", &id.to_string(), json!({ "requested": amount, "refunded": refunded })).await?;
    }
    if let Some(hold) = u.hold_settlement {
        let booking = case.booking_id.ok_or(ApiError::BadRequest("case_has_no_booking"))?;
        let (from, to) = if hold { ("pending", "held") } else { ("held", "pending") };
        let moved = sqlx::query("UPDATE settlements SET state = $3 WHERE booking_id = $1 AND state = $2 AND payout_id IS NULL")
            .bind(booking)
            .bind(from)
            .bind(to)
            .execute(&s.db)
            .await?
            .rows_affected();
        if moved == 0 {
            return Err(ApiError::Conflict("settlement_state"));
        }
        outcome["hold"] = json!(hold);
        audit(&s.db, "staff", Some(st.id), "settlement.hold", &booking.to_string(), json!({ "hold": hold, "case_id": id })).await?;
    }
    let moved = sqlx::query(
        "UPDATE cases SET status = COALESCE($3, status), assignee_id = COALESCE($4, assignee_id), outcome = $5, updated_at = now(),
           resolved_at = CASE WHEN $3 IN ('resolved', 'rejected') THEN now() ELSE resolved_at END
         WHERE id = $1 AND status = $2",
    )
    .bind(id)
    .bind(&case.status)
    .bind(u.status.as_deref())
    .bind(u.assignee_id)
    .bind(&outcome)
    .execute(&s.db)
    .await?
    .rows_affected();
    if moved == 0 {
        return Err(ApiError::Conflict("case_changed"));
    }
    if let Some(note) = u.note.as_deref().map(str::trim).filter(|n| !n.is_empty()) {
        sqlx::query("INSERT INTO case_notes (case_id, author_id, body) VALUES ($1, $2, $3)").bind(id).bind(st.id).bind(note).execute(&s.db).await?;
    }
    audit(&s.db, "staff", Some(st.id), "case.update", &id.to_string(), json!({ "status": u.status, "assignee_id": u.assignee_id })).await?;
    Ok(Json(case_view(&s, id).await?))
}

#[derive(Deserialize, Default)]
struct ReassignBody {
    /// Admin only. Apology coupon for the customer; omitted or 0 for none.
    coupon_amount: Option<i64>,
}

/// Moves the job to another partner and tells everyone. The case moves open -> investigating.
async fn reassign(State(s): State<AppState>, Staff(st): Staff, Path(id): Path<Uuid>, Json(b): Json<ReassignBody>) -> ApiResult<Json<Value>> {
    let case = load_case(&s.db, id).await?;
    let booking = case.booking_id.ok_or(ApiError::BadRequest("case_has_no_booking"))?;
    let coupon = b.coupon_amount.unwrap_or(0);
    if coupon != 0 && st.role != Role::StaffAdmin {
        return Err(ApiError::Forbidden);
    }
    if !(0..=MAX_APOLOGY_COUPON).contains(&coupon) {
        return Err(ApiError::BadRequest("invalid_coupon"));
    }
    let next = noshow::reassign(&s, booking, coupon).await?;
    let to = if case.status == "open" { "investigating" } else { case.status.as_str() };
    sqlx::query(
        "UPDATE cases SET status = $2, outcome = COALESCE(outcome, '{}') || jsonb_build_object('reassigned_to', $3::text, 'apology_coupon', $4::bigint), updated_at = now()
         WHERE id = $1",
    )
    .bind(id)
    .bind(to)
    .bind(next.to_string())
    .bind(coupon)
    .execute(&s.db)
    .await?;
    audit(&s.db, "staff", Some(st.id), "booking.reassign", &booking.to_string(), json!({ "case_id": id, "to_pro": next, "coupon": coupon })).await?;
    Ok(Json(case_view(&s, id).await?))
}
