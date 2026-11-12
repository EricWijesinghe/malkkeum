//! Waitlist for a full slot. A customer joins with their booking request when the slot is full. When
//! a seat frees up, the first waiting customer gets a 15-minute offer that holds the seat (see
//! `util::lock_and_count_slot`). Accepting the offer creates the booking through the normal create path.

use super::{
    bookings::{self, CreateBooking},
    booking_core::{BookingBody, lock_slot, prepare},
};
use crate::{
    auth::Customer,
    error::{ApiError, ApiResult},
    lifecycle::next_tick,
    realtime::{Recipient, notify},
    state::AppState,
    util::{best_effort, lock_and_count_slot},
};
use axum::{
    Json, Router,
    extract::{Path, State},
    routing::{get, post},
};
use chrono::{DateTime, NaiveDate, Utc};
use domain::{
    DomainError,
    schedule::check_capacity,
    waitlist::{self, SlotRange, WaitEntry},
};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use std::time::Duration;
use tokio::task::JoinHandle;
use uuid::Uuid;

const OFFER_PASS_EVERY: Duration = Duration::from_secs(60);

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/waitlist", get(mine).post(join))
        .route("/waitlist/{id}", axum::routing::delete(leave))
        .route("/waitlist/{id}/accept", post(accept))
}

const WAIT_COLS: &str = "id, service_code, visit_date, start_hour, status, offer_expires_at";

#[derive(Serialize, sqlx::FromRow)]
pub struct WaitRow {
    id: Uuid,
    service_code: String,
    visit_date: NaiveDate,
    start_hour: i16,
    status: String,
    offer_expires_at: Option<DateTime<Utc>>,
}

/// Joins the queue for a slot that is full right now. Refused when the slot still has room.
async fn join(State(s): State<AppState>, Customer(a): Customer, Json(b): Json<BookingBody>) -> ApiResult<Json<WaitRow>> {
    prepare(&s.db, a.id, &b).await?;
    let mut tx = s.db.begin().await?;
    match lock_slot(&mut tx, b.visit_date, b.start_hour).await {
        Err(ApiError::Domain(DomainError::SlotFull)) => {}
        Ok(()) => return Err(ApiError::Conflict("slot_available")),
        Err(e) => return Err(e),
    }
    let dup: bool = sqlx::query_scalar(
        "SELECT EXISTS (SELECT 1 FROM waitlist_entries WHERE user_id = $1 AND visit_date = $2 AND start_hour = $3 AND status IN ('waiting','offered'))",
    )
    .bind(a.id)
    .bind(b.visit_date)
    .bind(i16::from(b.start_hour))
    .fetch_one(&mut *tx)
    .await?;
    if dup {
        return Err(ApiError::Conflict("already_waiting"));
    }
    let body = serde_json::to_value(&b).map_err(|e| ApiError::Internal(e.to_string()))?;
    let row: WaitRow = sqlx::query_as(&format!(
        "INSERT INTO waitlist_entries (id, user_id, service_code, visit_date, start_hour, end_hour, body)
         VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING {WAIT_COLS}"
    ))
    .bind(Uuid::now_v7())
    .bind(a.id)
    .bind(&b.service_code)
    .bind(b.visit_date)
    .bind(i16::from(b.start_hour))
    .bind(i16::from(b.start_hour) + 1)
    .bind(body)
    .fetch_one(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(Json(row))
}

async fn mine(State(s): State<AppState>, Customer(a): Customer) -> ApiResult<Json<Vec<WaitRow>>> {
    let rows: Vec<WaitRow> = sqlx::query_as(&format!(
        "SELECT {WAIT_COLS} FROM waitlist_entries WHERE user_id = $1 AND status IN ('waiting','offered') ORDER BY joined_at"
    ))
    .bind(a.id)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}

/// Leaving a slot you were offered frees the seat, so the next waiter is offered it.
async fn leave(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    let row: Option<(NaiveDate, i16)> = sqlx::query_as(
        "UPDATE waitlist_entries SET status = 'cancelled' WHERE id = $1 AND user_id = $2 AND status IN ('waiting','offered')
         RETURNING visit_date, start_hour",
    )
    .bind(id)
    .bind(a.id)
    .fetch_optional(&s.db)
    .await?;
    let (date, hour) = row.ok_or(ApiError::NotFound)?;
    best_effort("waitlist offer on leave", offer_for_slot(&s, date, hour as u8)).await;
    Ok(Json(json!({ "ok": true })))
}

#[derive(Deserialize)]
struct AcceptBody {
    payment_method_id: Option<Uuid>,
}

/// Turns a live offer into a booking. The entry is marked accepted first so its own hold stops
/// counting against the slot; a failed create puts the offer back if it is still open.
async fn accept(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>, body: Option<Json<AcceptBody>>) -> ApiResult<Json<Value>> {
    let (body_json, expires, status, date, hour): (Value, Option<DateTime<Utc>>, String, NaiveDate, i16) =
        sqlx::query_as("SELECT body, offer_expires_at, status, visit_date, start_hour FROM waitlist_entries WHERE id = $1 AND user_id = $2")
            .bind(id)
            .bind(a.id)
            .fetch_optional(&s.db)
            .await?
            .ok_or(ApiError::NotFound)?;
    if status != "offered" {
        return Err(ApiError::Conflict("offer_not_open"));
    }
    let expires = expires.ok_or(ApiError::Conflict("offer_not_open"))?;
    waitlist::check_offer_open(expires, Utc::now())?;
    let claimed = sqlx::query("UPDATE waitlist_entries SET status = 'accepted' WHERE id = $1 AND status = 'offered' AND offer_expires_at > now()")
        .bind(id)
        .execute(&s.db)
        .await?;
    if claimed.rows_affected() == 0 {
        return Err(ApiError::Conflict("offer_expired"));
    }
    let booking_body: BookingBody = serde_json::from_value(body_json).map_err(|e| ApiError::Internal(e.to_string()))?;
    let req = CreateBooking {
        body: booking_body,
        payment_method_id: body.and_then(|Json(b)| b.payment_method_id),
    };
    match bookings::create_core(&s, a.id, &req).await {
        Ok(booking) => Ok(Json(json!({ "booking_id": booking }))),
        Err(e) => {
            // The seat is free again: reopen this offer while it is live, else close it and pass the seat on.
            let reopened = sqlx::query("UPDATE waitlist_entries SET status = 'offered' WHERE id = $1 AND status = 'accepted' AND offer_expires_at > now()")
                .bind(id)
                .execute(&s.db)
                .await?
                .rows_affected();
            if reopened == 0 {
                sqlx::query("UPDATE waitlist_entries SET status = 'cancelled' WHERE id = $1 AND status = 'accepted'").bind(id).execute(&s.db).await?;
                best_effort("waitlist re-offer", offer_for_slot(&s, date, hour as u8)).await;
            }
            Err(e)
        }
    }
}

/// Offers a freed seat in `hour` (KST, one-hour window) on `date` to the first waiting entry, if the
/// slot has room once live holds are counted. One offer per call.
pub async fn offer_for_slot(s: &AppState, date: NaiveDate, hour: u8) -> ApiResult<()> {
    let mut tx = s.db.begin().await?;
    let (used, cap) = lock_and_count_slot(&mut tx, date, hour, None).await?;
    if check_capacity(used, cap).is_err() {
        return Ok(());
    }
    let queue: Vec<(Uuid, Uuid, DateTime<Utc>)> = sqlx::query_as(
        "SELECT id, user_id, joined_at FROM waitlist_entries
         WHERE status = 'waiting' AND visit_date = $1 AND start_hour <= $2 AND end_hour > $2
         ORDER BY joined_at, id",
    )
    .bind(date)
    .bind(i16::from(hour))
    .fetch_all(&mut *tx)
    .await?;
    // customer_id carries the queue position here, not a customer; pick_next_offer only needs order.
    let entries: Vec<WaitEntry> = queue
        .iter()
        .enumerate()
        .map(|(i, q)| WaitEntry {
            customer_id: i as i64,
            range: SlotRange { date, start_hour: u32::from(hour), end_hour: u32::from(hour) + 1 },
            joined_at: q.2,
            has_live_offer: false,
        })
        .collect();
    let freed = SlotRange { date, start_hour: u32::from(hour), end_hour: u32::from(hour) + 1 };
    let Some(idx) = waitlist::pick_next_offer(&entries, &freed) else {
        return Ok(());
    };
    let (entry, user, _) = queue[idx];
    let now = Utc::now();
    let expires = waitlist::offer_expires_at(now);
    sqlx::query("UPDATE waitlist_entries SET status = 'offered', offered_at = $2, offer_expires_at = $3 WHERE id = $1")
        .bind(entry)
        .bind(now)
        .bind(expires)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    notify(
        s,
        Recipient::User(user),
        "waitlist.offer",
        "빈 자리가 생겼어요",
        "15분 안에 예약을 확정해 주세요.",
        json!({ "waitlist_id": entry, "expires_at": expires }),
    )
    .await
}

/// Expires lapsed offers and re-offers their seats to the next waiter.
pub async fn expire_pass(s: &AppState) -> ApiResult<usize> {
    let lapsed: Vec<(NaiveDate, i16)> = sqlx::query_as(
        "UPDATE waitlist_entries SET status = 'expired' WHERE status = 'offered' AND offer_expires_at <= now()
         RETURNING visit_date, start_hour",
    )
    .fetch_all(&s.db)
    .await?;
    for (date, hour) in &lapsed {
        best_effort("waitlist re-offer after expiry", offer_for_slot(s, *date, *hour as u8)).await;
    }
    Ok(lapsed.len())
}

/// Starts the periodic expiry pass. Errors are logged and the loop goes on.
pub fn spawn(state: AppState) -> JoinHandle<()> {
    let mut stop = state.hub.drain_signal();
    tokio::spawn(async move {
        let mut tick = tokio::time::interval(OFFER_PASS_EVERY);
        while next_tick(&mut tick, &mut stop).await {
            if let Err(e) = expire_pass(&state).await {
                tracing::warn!(error = %e, "waitlist expiry pass failed");
            }
        }
    })
}
