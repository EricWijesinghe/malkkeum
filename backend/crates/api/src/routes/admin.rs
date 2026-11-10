//! Console: bookings, status changes, quote desk, inboxes, dashboard.

use super::{
    audit,
    bookings::{BOOKING_COLS, BookingRow, apply_cancel, load_booking},
    catalog::load_formula,
    chat::{self, MessageRow, THREAD_COLS, ThreadRow},
};
use crate::{
    auth::Staff,
    error::{ApiError, ApiResult},
    realtime::{Recipient, notify},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Path, Query, State},
    routing::{get, post},
};
use chrono::NaiveDate;
use domain::{Won, booking::BookingStatus};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use uuid::Uuid;

const LIST_LIMIT: i64 = 200;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/dashboard", get(dashboard))
        .route("/bookings", get(list_bookings))
        .route("/bookings/{id}", get(booking_detail))
        .route("/bookings/{id}/status", post(change_status))
        .route("/bookings/{id}/cancel", post(cancel))
        .route("/bookings/{id}/quotes", get(quotes_for))
        .route("/bookings/{id}/send-quote", post(send_quote))
        .route("/threads", get(inbox))
        .route("/threads/{id}/messages", get(chat::messages).post(chat::send))
        .route("/threads/{id}/read", post(chat::mark_read))
}

#[derive(Serialize)]
struct Dashboard {
    today_jobs: i64,
    open_quotes: i64,
    unassigned: i64,
    unread_threads: i64,
    revenue_30d: i64,
    bookings_30d: i64,
    by_service: Value,
}

async fn dashboard(State(s): State<AppState>, _st: Staff) -> ApiResult<Json<Dashboard>> {
    let row: (i64, i64, i64, i64, i64, i64) = sqlx::query_as(
        "SELECT
           (SELECT count(*) FROM bookings WHERE visit_date = (now() AT TIME ZONE 'Asia/Seoul')::date AND status BETWEEN 1 AND 3),
           (SELECT count(*) FROM bookings WHERE status = 0),
           (SELECT count(*) FROM bookings WHERE status = 1 AND pro_id IS NULL AND team_name IS NULL),
           (SELECT count(*) FROM chat_threads WHERE unread_staff > 0),
           (SELECT COALESCE(sum(amount - refunded_amount), 0)::bigint FROM payments WHERE status IN ('paid','partially_refunded') AND created_at > now() - interval '30 days'),
           (SELECT count(*) FROM bookings WHERE created_at > now() - interval '30 days')",
    )
    .fetch_one(&s.db)
    .await?;
    let by_service: Value = sqlx::query_scalar(
        "SELECT COALESCE(jsonb_object_agg(service_code, n), '{}'::jsonb) FROM (SELECT service_code, count(*) n FROM bookings WHERE created_at > now() - interval '30 days' GROUP BY 1) x",
    )
    .fetch_one(&s.db)
    .await?;
    Ok(Json(Dashboard { today_jobs: row.0, open_quotes: row.1, unassigned: row.2, unread_threads: row.3, revenue_30d: row.4, bookings_30d: row.5, by_service }))
}

#[derive(Deserialize)]
struct BookingFilter {
    status: Option<i16>,
    service: Option<String>,
    from: Option<NaiveDate>,
    to: Option<NaiveDate>,
    q: Option<String>,
}

async fn list_bookings(State(s): State<AppState>, _st: Staff, Query(f): Query<BookingFilter>) -> ApiResult<Json<Vec<BookingRow>>> {
    let q = f.q.map(|q| format!("%{}%", q.replace(['%', '_'], "")));
    let rows = sqlx::query_as(&format!(
        "SELECT {BOOKING_COLS} FROM bookings b LEFT JOIN users u ON u.id = b.user_id
         WHERE ($1::smallint IS NULL OR b.status = $1) AND ($2::text IS NULL OR b.service_code = $2)
           AND ($3::date IS NULL OR b.visit_date >= $3) AND ($4::date IS NULL OR b.visit_date <= $4)
           AND ($5::text IS NULL OR b.number ILIKE $5 OR u.phone LIKE $5 OR u.name ILIKE $5 OR b.address->>'road_address' ILIKE $5)
         ORDER BY b.visit_date, b.start_hour LIMIT $6"
    ))
    .bind(f.status)
    .bind(f.service)
    .bind(f.from)
    .bind(f.to)
    .bind(q)
    .bind(LIST_LIMIT)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}

#[derive(Serialize)]
struct BookingDetail {
    booking: BookingRow,
    customer: Value,
    payments: Value,
    estimate_breakdown: Option<Value>,
}

async fn booking_detail(State(s): State<AppState>, _st: Staff, Path(id): Path<Uuid>) -> ApiResult<Json<BookingDetail>> {
    let booking = load_booking(&s.db, id).await?;
    let customer: Value = sqlx::query_scalar("SELECT jsonb_build_object('id', id, 'name', name, 'phone', phone, 'email', email) FROM users WHERE id = $1").bind(booking.user_id).fetch_one(&s.db).await?;
    let payments: Value = sqlx::query_scalar(
        "SELECT COALESCE(jsonb_agg(jsonb_build_object('id', id, 'amount', amount, 'kind', kind, 'status', status, 'refunded', refunded_amount, 'at', created_at) ORDER BY created_at), '[]'::jsonb) FROM payments WHERE booking_id = $1",
    )
    .bind(id)
    .fetch_one(&s.db)
    .await?;
    let answers = booking.answers.clone().and_then(|a| serde_json::from_value::<domain::quote::QuoteAnswers>(a).ok());
    let estimate_breakdown = match answers {
        Some(a) => Some(serde_json::to_value(load_formula(&s.db).await?.estimate(&a)?).unwrap_or(Value::Null)),
        None => None,
    };
    Ok(Json(BookingDetail { booking, customer, payments, estimate_breakdown }))
}

#[derive(Deserialize)]
struct StatusChange {
    status: i16,
    team_name: Option<String>,
}

async fn change_status(State(s): State<AppState>, Staff(st): Staff, Path(id): Path<Uuid>, Json(c): Json<StatusChange>) -> ApiResult<Json<BookingRow>> {
    let b = load_booking(&s.db, id).await?;
    let to = BookingStatus::from_i16(c.status).ok_or(ApiError::BadRequest("invalid_status"))?;
    if to == BookingStatus::Cancelled {
        return Err(ApiError::BadRequest("use_cancel"));
    }
    b.status()?.transition(to)?;
    if to == BookingStatus::TeamAssigned && b.pro_id.is_none() && c.team_name.as_deref().is_none_or(|t| t.trim().is_empty()) {
        return Err(ApiError::BadRequest("team_required"));
    }
    let moved = sqlx::query(
        "UPDATE bookings SET status = $3, team_name = COALESCE($4, team_name), completed_at = CASE WHEN $3 = 3 THEN now() ELSE completed_at END, updated_at = now() WHERE id = $1 AND status = $2",
    )
    .bind(id)
    .bind(b.status)
    .bind(c.status)
    .bind(c.team_name.map(|t| t.trim().to_string()))
    .execute(&s.db)
    .await?;
    if moved.rows_affected() == 0 {
        return Err(ApiError::Conflict("booking_changed"));
    }
    audit(&s.db, "staff", Some(st.id), "booking.status", &id.to_string(), json!({ "from": b.status, "to": c.status })).await?;
    if let Some(t) = b.thread_id {
        chat::post_system(&s, t, "status_changed", json!({ "status": c.status })).await?;
    }
    notify(&s, Recipient::User(b.user_id), "booking.status", "예약 상태가 바뀌었어요", &b.number, json!({ "booking_id": id, "status": c.status })).await?;
    Ok(Json(load_booking(&s.db, id).await?))
}

#[derive(Deserialize)]
struct CancelRequest {
    /// None = full refund; otherwise refund at most this amount (late-cancel fee).
    refund_amount: Option<i64>,
}

async fn cancel(State(s): State<AppState>, Staff(st): Staff, Path(id): Path<Uuid>, Json(c): Json<CancelRequest>) -> ApiResult<Json<BookingRow>> {
    let b = load_booking(&s.db, id).await?;
    b.status()?.transition(BookingStatus::Cancelled)?;
    if c.refund_amount.is_some_and(|a| a < 0) {
        return Err(ApiError::BadRequest("invalid_amount"));
    }
    apply_cancel(&s, &b, c.refund_amount, "staff").await?;
    audit(&s.db, "staff", Some(st.id), "booking.cancel", &id.to_string(), json!({ "refund_amount": c.refund_amount })).await?;
    Ok(Json(load_booking(&s.db, id).await?))
}

#[derive(Serialize, sqlx::FromRow)]
struct QuoteRow {
    id: Uuid,
    pro_id: Uuid,
    pro_name: String,
    team_name: String,
    rating: Option<f64>,
    amount: i64,
    note: String,
    state: String,
}

async fn quotes_for(State(s): State<AppState>, _st: Staff, Path(id): Path<Uuid>) -> ApiResult<Json<Vec<QuoteRow>>> {
    let rows = sqlx::query_as(
        "SELECT q.id, q.pro_id, p.name AS pro_name, p.team_name, (SELECT avg(rating)::float8 FROM reviews r WHERE r.pro_id = p.id AND NOT r.hidden) AS rating, q.amount, q.note, q.state
         FROM quotes q JOIN pros p ON p.id = q.pro_id WHERE q.booking_id = $1 AND q.state <> 'withdrawn' ORDER BY q.amount",
    )
    .bind(id)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}

#[derive(Deserialize)]
struct SendQuote {
    final_price: i64,
    /// Pro quote this price comes from; that pro is attached when the deposit is paid.
    quote_id: Option<Uuid>,
    note: Option<String>,
}

const MAX_QUOTE_PRICE: i64 = 50_000_000;

async fn send_quote(State(s): State<AppState>, Staff(st): Staff, Path(id): Path<Uuid>, Json(q): Json<SendQuote>) -> ApiResult<Json<MessageRow>> {
    let b = load_booking(&s.db, id).await?;
    if b.status()? != BookingStatus::Consultation || b.answers.is_none() {
        return Err(ApiError::Conflict("not_open_quote"));
    }
    if !(1..=MAX_QUOTE_PRICE).contains(&q.final_price) {
        return Err(ApiError::BadRequest("invalid_amount"));
    }
    let price = Won(q.final_price).round100();
    let deposit = load_formula(&s.db).await?.deposit(price);
    let mut tx = s.db.begin().await?;
    sqlx::query("UPDATE bookings SET final_price = $2, deposit = $3, updated_at = now() WHERE id = $1").bind(id).bind(price.0).bind(deposit.0).execute(&mut *tx).await?;
    sqlx::query("UPDATE quotes SET state = 'waiting', updated_at = now() WHERE booking_id = $1 AND state = 'selected'").bind(id).execute(&mut *tx).await?;
    if let Some(qid) = q.quote_id {
        let r = sqlx::query("UPDATE quotes SET state = 'selected', updated_at = now() WHERE id = $1 AND booking_id = $2 AND state = 'waiting'").bind(qid).bind(id).execute(&mut *tx).await?;
        if r.rows_affected() == 0 {
            return Err(ApiError::Conflict("quote_unavailable"));
        }
    }
    let thread = chat::booking_thread(&mut tx, "customer", b.user_id, id, &b.service_code).await?;
    let msg = chat::insert_message(&mut tx, thread, "staff", Some(st.id), "quote", json!({
        "booking_id": id, "final_price": price.0, "deposit": deposit.0, "balance": price.0 - deposit.0, "note": q.note
    })).await?;
    tx.commit().await?;
    chat::broadcast_message(&s, &msg).await?;
    audit(&s.db, "staff", Some(st.id), "quote.send", &id.to_string(), json!({ "final_price": price.0, "quote_id": q.quote_id })).await?;
    Ok(Json(msg))
}

#[derive(Deserialize)]
struct InboxQuery {
    audience: Option<String>,
}

async fn inbox(State(s): State<AppState>, _st: Staff, Query(q): Query<InboxQuery>) -> ApiResult<Json<Vec<ThreadRow>>> {
    let aud = q.audience.unwrap_or_else(|| "customer".into());
    if aud != "customer" && aud != "partner" {
        return Err(ApiError::BadRequest("invalid_audience"));
    }
    let rows = sqlx::query_as(&format!("SELECT {THREAD_COLS} FROM chat_threads t WHERE t.audience = $1 ORDER BY (t.unread_staff > 0) DESC, t.last_message_at DESC LIMIT $2"))
        .bind(aud)
        .bind(LIST_LIMIT)
        .fetch_all(&s.db)
        .await?;
    Ok(Json(rows))
}
