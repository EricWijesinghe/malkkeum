//! Customer booking engine: create (+pay), list, detail, cancel, deposit, balance, notes, reschedule, review.

use super::{
    audit,
    catalog::{load_formula, load_service},
    chat,
};
use crate::{
    auth::Customer,
    error::{ApiError, ApiResult},
    realtime::{Recipient, notify},
    state::AppState,
    util::{KST_TODAY, best_effort, lock_and_count_slot, refund_or_alert, sanitize_notes, today_kst},
};
use axum::{
    Json, Router,
    extract::{Path, State},
    routing::{get, post, put},
};
use chrono::{DateTime, NaiveDate, Utc};
use domain::{
    Won,
    booking::{BookingStatus, customer_cancel},
    coupon::Coupon,
    partner::payout_date,
    pricing::price_booking,
    quote::QuoteAnswers,
    schedule::{check_capacity, check_date, check_slot},
};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use sqlx::PgConnection;
use uuid::Uuid;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/bookings", get(list).post(create))
        .route("/bookings/{id}", get(detail))
        .route("/bookings/{id}/cancel", post(cancel))
        .route("/bookings/{id}/deposit", post(pay_deposit))
        .route("/bookings/{id}/balance", post(pay_balance))
        .route("/bookings/{id}/notes", put(update_notes))
        .route("/bookings/{id}/reschedule", post(reschedule))
        .route("/bookings/{id}/review", post(review))
}

pub const BOOKING_COLS: &str =
    "b.id, b.number, b.user_id, b.service_code, b.unit_index, b.address, b.district_code, b.visit_date, b.start_hour, b.minutes, b.status,
    b.answers, b.estimate, b.final_price, b.deposit, b.list_price, b.discount, b.paid_amount, b.balance_paid, b.coupon_id, b.team_name, b.pro_id,
    b.visit_notes, b.reschedule, b.cancelled_at, b.completed_at, b.created_at,
    (SELECT t.id FROM chat_threads t WHERE t.booking_id = b.id AND t.audience = 'customer') AS thread_id,
    (SELECT jsonb_build_object('before', c.before_photos, 'after', c.after_photos) FROM completion_reports c WHERE c.booking_id = b.id) AS photos,
    EXISTS (SELECT 1 FROM reviews r WHERE r.booking_id = b.id) AS reviewed";

#[derive(Serialize, sqlx::FromRow, Clone)]
pub struct BookingRow {
    pub id: Uuid,
    pub number: String,
    pub user_id: Uuid,
    pub service_code: String,
    pub unit_index: Option<i16>,
    pub address: Value,
    pub district_code: String,
    pub visit_date: NaiveDate,
    pub start_hour: i16,
    pub minutes: Option<i32>,
    pub status: i16,
    pub answers: Option<Value>,
    pub estimate: Option<i64>,
    pub final_price: Option<i64>,
    pub deposit: Option<i64>,
    pub list_price: Option<i64>,
    pub discount: i64,
    pub paid_amount: i64,
    pub balance_paid: bool,
    pub coupon_id: Option<Uuid>,
    pub team_name: Option<String>,
    pub pro_id: Option<Uuid>,
    pub visit_notes: Value,
    pub reschedule: Option<Value>,
    pub cancelled_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub thread_id: Option<Uuid>,
    pub photos: Option<Value>,
    pub reviewed: bool,
}

impl BookingRow {
    pub fn status(&self) -> ApiResult<BookingStatus> {
        BookingStatus::from_i16(self.status).ok_or(ApiError::Internal("bad status".into()))
    }
}

pub async fn load_booking(db: &sqlx::PgPool, id: Uuid) -> ApiResult<BookingRow> {
    sqlx::query_as(&format!("SELECT {BOOKING_COLS} FROM bookings b WHERE b.id = $1"))
        .bind(id)
        .fetch_optional(db)
        .await?
        .ok_or(ApiError::NotFound)
}

async fn owned(s: &AppState, user: Uuid, id: Uuid) -> ApiResult<BookingRow> {
    let b = load_booking(&s.db, id).await?;
    if b.user_id == user { Ok(b) } else { Err(ApiError::NotFound) }
}

type CouponRow = (i64, Option<String>, DateTime<Utc>, DateTime<Utc>, Option<Uuid>);

#[derive(Deserialize)]
struct CreateBooking {
    service_code: String,
    unit_index: Option<usize>,
    address_id: Uuid,
    visit_date: NaiveDate,
    start_hour: u8,
    coupon_id: Option<Uuid>,
    payment_method_id: Option<Uuid>,
    answers: Option<QuoteAnswers>,
    #[serde(default)]
    visit_notes: Value,
}

#[derive(sqlx::FromRow)]
struct AddressSnap {
    kind: String,
    label: String,
    road_address: String,
    detail: String,
    district_code: String,
    size_pyeong: i16,
}

/// Charges a saved method and records the payment. Used inside a transaction.
pub async fn charge(s: &AppState, conn: &mut PgConnection, user: Uuid, method: Uuid, booking: Uuid, amount: Won, kind: &str) -> ApiResult<String> {
    let key: String = sqlx::query_scalar("SELECT billing_key FROM payment_methods WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL")
        .bind(method)
        .bind(user)
        .fetch_optional(&mut *conn)
        .await?
        .ok_or(ApiError::BadRequest("payment_method_required"))?;
    let idem = format!("{booking}:{kind}");
    let tx_id = s
        .providers
        .charge(&key, amount.0, &idem)
        .await
        .map_err(|e| ApiError::PaymentFailed(e.to_string()))?;
    let recorded =
        sqlx::query("INSERT INTO payments (booking_id, amount, kind, status, provider, provider_tx_id, idempotency_key) VALUES ($1,$2,$3,'paid','pg',$4,$5)")
            .bind(booking)
            .bind(amount.0)
            .bind(kind)
            .bind(&tx_id)
            .bind(idem)
            .execute(conn)
            .await;
    if let Err(e) = recorded {
        refund_or_alert(s, &tx_id, amount.0).await;
        return Err(e.into());
    }
    Ok(tx_id)
}

async fn create(State(s): State<AppState>, Customer(a): Customer, Json(req): Json<CreateBooking>) -> ApiResult<Json<BookingRow>> {
    let service = load_service(&s.db, &req.service_code).await?;
    let addr: AddressSnap = sqlx::query_as(
        "SELECT kind, label, road_address, detail, district_code, size_pyeong FROM addresses WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL",
    )
    .bind(req.address_id)
    .bind(a.id)
    .fetch_optional(&s.db)
    .await?
    .ok_or(ApiError::BadRequest("address_required"))?;
    service.check_address_size(addr.size_pyeong as u16)?;
    check_date(today_kst(), req.visit_date)?;
    check_slot(service.is_quote(), req.start_hour)?;
    let snapshot = json!({ "kind": addr.kind, "label": addr.label, "road_address": addr.road_address, "detail": addr.detail, "size_pyeong": addr.size_pyeong });

    let notes = if req.visit_notes.is_null() {
        json!({})
    } else {
        sanitize_notes(&req.visit_notes).ok_or(ApiError::BadRequest("invalid_notes"))?
    };
    // Anything needing its own pool connection is read before the slot lock is taken.
    let formula = if service.is_quote() { Some(load_formula(&s.db).await?) } else { None };

    let mut tx = s.db.begin().await?;
    // Serialize bookings per slot so capacity can't be oversold.
    let (used, cap) = lock_and_count_slot(&mut tx, req.visit_date, req.start_hour, None).await?;
    check_capacity(used, cap)?;

    let id = Uuid::now_v7();
    let number: String = sqlx::query_scalar(&format!(
        "SELECT 'BK' || to_char({KST_TODAY}, 'YYMM') || '-' || lpad(nextval('booking_number_seq')::text, 5, '0')"
    ))
    .fetch_one(&mut *tx)
    .await?;

    if let Some(formula) = formula {
        let answers = req.answers.ok_or(ApiError::BadRequest("answers_required"))?;
        let est = formula.estimate(&answers)?;
        sqlx::query(
            "INSERT INTO bookings (id, number, user_id, service_code, address, district_code, visit_date, start_hour, status, answers, estimate, visit_notes)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,0,$9,$10,$11)",
        )
        .bind(id)
        .bind(&number)
        .bind(a.id)
        .bind(&service.code)
        .bind(&snapshot)
        .bind(&addr.district_code)
        .bind(req.visit_date)
        .bind(i16::from(req.start_hour))
        .bind(sqlx::types::Json(&answers))
        .bind(est.total.0)
        .bind(&notes)
        .execute(&mut *tx)
        .await?;
        let thread = chat::booking_thread(&mut tx, "customer", a.id, id, &service.code).await?;
        let sys = chat::insert_message(&mut tx, thread, "system", None, "system", json!({ "code": "consultation_received" })).await?;
        let card = chat::insert_message(
            &mut tx,
            thread,
            "system",
            None,
            "card",
            json!({
                "booking_id": id, "service_code": service.code, "visit_date": req.visit_date, "start_hour": req.start_hour,
                "answers": answers, "estimate": est.total.0
            }),
        )
        .await?;
        tx.commit().await?;
        best_effort("broadcast", chat::broadcast_message(&s, &sys)).await;
        best_effort("broadcast", chat::broadcast_message(&s, &card)).await;
        best_effort(
            "notify",
            notify(
                &s,
                Recipient::Staff,
                "booking.quote_requested",
                "견적 요청",
                &number,
                json!({ "booking_id": id }),
            ),
        )
        .await;
    } else {
        let coupon = match req.coupon_id {
            Some(cid) => {
                let row: Option<CouponRow> = sqlx::query_as(
                    "SELECT amount, service_code, issued_at, expires_at, used_booking_id FROM coupons WHERE id = $1 AND user_id = $2 FOR UPDATE",
                )
                .bind(cid)
                .bind(a.id)
                .fetch_optional(&mut *tx)
                .await?;
                let (amount, svc, issued_at, expires_at, used) = row.ok_or(ApiError::NotFound)?;
                Some(Coupon {
                    amount: Won(amount),
                    service_code: svc,
                    issued_at,
                    expires_at,
                    used: used.is_some(),
                })
            }
            None => None,
        };
        let price = price_booking(&service, req.unit_index, coupon.as_ref(), Utc::now())?;
        let method = req.payment_method_id.ok_or(ApiError::BadRequest("payment_method_required"))?;
        sqlx::query(
            "INSERT INTO bookings (id, number, user_id, service_code, unit_index, address, district_code, visit_date, start_hour, minutes, status, list_price, discount, paid_amount, coupon_id, visit_notes)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,1,$11,$12,$13,$14,$15)",
        )
        .bind(id).bind(&number).bind(a.id).bind(&service.code).bind(req.unit_index.map(|u| u as i16)).bind(&snapshot).bind(&addr.district_code)
        .bind(req.visit_date).bind(i16::from(req.start_hour)).bind(price.minutes as i32).bind(price.list_price.0).bind(price.discount.0).bind(price.total.0)
        .bind(req.coupon_id).bind(&notes)
        .execute(&mut *tx)
        .await?;
        if let Some(cid) = req.coupon_id {
            sqlx::query("UPDATE coupons SET used_booking_id = $2 WHERE id = $1")
                .bind(cid)
                .bind(id)
                .execute(&mut *tx)
                .await?;
        }
        let tx_id = if price.total.0 > 0 {
            Some(charge(&s, &mut tx, a.id, method, id, price.total, "full").await?)
        } else {
            None
        };
        if let Err(e) = tx.commit().await {
            // Charged but not saved: give the money back before reporting the failure.
            if let Some(t) = tx_id {
                refund_or_alert(&s, &t, price.total.0).await;
            }
            return Err(e.into());
        }
        best_effort(
            "notify",
            notify(&s, Recipient::Staff, "booking.created", "새 예약", &number, json!({ "booking_id": id })),
        )
        .await;
    }
    Ok(Json(load_booking(&s.db, id).await?))
}

async fn list(State(s): State<AppState>, Customer(a): Customer) -> ApiResult<Json<Vec<BookingRow>>> {
    let rows = sqlx::query_as(&format!(
        "SELECT {BOOKING_COLS} FROM bookings b WHERE b.user_id = $1 ORDER BY b.visit_date DESC, b.start_hour"
    ))
    .bind(a.id)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}

async fn detail(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>) -> ApiResult<Json<BookingRow>> {
    Ok(Json(owned(&s, a.id, id).await?))
}

/// Refunds every paid payment on a booking (full or a capped amount) and records it.
pub async fn refund_all(s: &AppState, booking: Uuid, max_amount: Option<i64>) -> ApiResult<i64> {
    let pays: Vec<(Uuid, i64, i64, Option<String>)> = sqlx::query_as("SELECT id, amount, refunded_amount, provider_tx_id FROM payments WHERE booking_id = $1 AND status IN ('paid','partially_refunded') ORDER BY created_at DESC")
        .bind(booking)
        .fetch_all(&s.db)
        .await?;
    let mut left = max_amount.unwrap_or(i64::MAX);
    let mut total = 0;
    for (pid, amount, refunded, tx) in pays {
        let amt = (amount - refunded).min(left);
        if amt <= 0 {
            continue;
        }
        let tx = tx.ok_or_else(|| ApiError::Internal(format!("payment {pid} has no provider transaction id")))?;
        s.providers.refund(&tx, amt).await.map_err(|e| ApiError::PaymentFailed(e.to_string()))?;
        let status = if refunded + amt == amount { "refunded" } else { "partially_refunded" };
        sqlx::query("UPDATE payments SET refunded_amount = refunded_amount + $2, status = $3 WHERE id = $1")
            .bind(pid)
            .bind(amt)
            .bind(status)
            .execute(&s.db)
            .await?;
        left -= amt;
        total += amt;
    }
    Ok(total)
}

/// Shared by customer and staff cancellation.
/// Money first: refunds are recorded per payment, so if the gateway fails the booking
/// stays active and the same call can be retried without refunding twice.
pub async fn apply_cancel(s: &AppState, b: &BookingRow, refund_cap: Option<i64>, actor: &str) -> ApiResult<()> {
    let refunded = refund_all(s, b.id, refund_cap).await?;
    let mut tx = s.db.begin().await?;
    let updated = sqlx::query("UPDATE bookings SET status = -1, cancelled_at = now(), updated_at = now() WHERE id = $1 AND status = $2")
        .bind(b.id)
        .bind(b.status)
        .execute(&mut *tx)
        .await?;
    if updated.rows_affected() == 0 {
        return Err(ApiError::Conflict("booking_changed"));
    }
    if b.coupon_id.is_some() && refund_cap.is_none() {
        // Full refund: the coupon goes back to the customer.
        sqlx::query("UPDATE coupons SET used_booking_id = NULL WHERE id = $1")
            .bind(b.coupon_id)
            .execute(&mut *tx)
            .await?;
    }
    sqlx::query("UPDATE quotes SET state = 'closed', updated_at = now() WHERE booking_id = $1 AND state = 'waiting'")
        .bind(b.id)
        .execute(&mut *tx)
        .await?;
    // A cancelled job must never reach the payout batch; staff decide on any compensation.
    sqlx::query("UPDATE settlements SET state = 'held' WHERE booking_id = $1 AND state IN ('pending','waiting_balance')")
        .bind(b.id)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    if let Some(t) = b.thread_id {
        best_effort(
            "chat",
            chat::post_system(s, t, "booking_cancelled", json!({ "by": actor, "refunded": refunded })),
        )
        .await;
    }
    if let Some(pro) = b.pro_id {
        best_effort(
            "notify",
            notify(s, Recipient::Pro(pro), "job.cancelled", "예약 취소", &b.number, json!({ "booking_id": b.id })),
        )
        .await;
    }
    let data = json!({ "booking_id": b.id, "refunded": refunded });
    best_effort(
        "notify",
        notify(s, Recipient::User(b.user_id), "booking.cancelled", "예약이 취소됐어요", &b.number, data),
    )
    .await;
    s.hub.send(Recipient::Staff, "booking.updated", json!({ "booking_id": b.id }));
    Ok(())
}

async fn cancel(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>) -> ApiResult<Json<BookingRow>> {
    let b = owned(&s, a.id, id).await?;
    customer_cancel(b.status()?, today_kst(), b.visit_date)?;
    apply_cancel(&s, &b, None, "customer").await?;
    audit(&s.db, "customer", Some(a.id), "booking.cancel", &id.to_string(), json!({})).await?;
    Ok(Json(load_booking(&s.db, id).await?))
}

#[derive(Deserialize)]
struct PayRequest {
    payment_method_id: Uuid,
}

/// Quote booking: pay 10% deposit after the staff quote -> confirmed (or team assigned).
async fn pay_deposit(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>, Json(p): Json<PayRequest>) -> ApiResult<Json<BookingRow>> {
    let b = owned(&s, a.id, id).await?;
    let (Some(_), Some(deposit)) = (b.final_price, b.deposit) else {
        return Err(ApiError::Conflict("quote_not_sent"));
    };
    if b.status()? != BookingStatus::Consultation {
        return Err(ApiError::Conflict("already_confirmed"));
    }
    let mut tx = s.db.begin().await?;
    // Read the chosen quote under lock so a concurrent staff change can't attach the wrong pro.
    let selected: Option<(Uuid, Uuid)> = sqlx::query_as("SELECT id, pro_id FROM quotes WHERE booking_id = $1 AND state = 'selected' FOR UPDATE")
        .bind(id)
        .fetch_optional(&mut *tx)
        .await?;
    let new_status = if selected.is_some() { 2 } else { 1 };
    let moved = sqlx::query("UPDATE bookings SET status = $2, paid_amount = paid_amount + $3, pro_id = $4, accepted_at = CASE WHEN $4 IS NULL THEN NULL ELSE now() END, updated_at = now() WHERE id = $1 AND status = 0")
        .bind(id).bind(new_status).bind(deposit).bind(selected.map(|q| q.1))
        .execute(&mut *tx).await?;
    if moved.rows_affected() == 0 {
        return Err(ApiError::Conflict("booking_changed"));
    }
    sqlx::query("UPDATE quotes SET state = 'rejected', updated_at = now(), seen_by_pro = FALSE WHERE booking_id = $1 AND state = 'waiting'")
        .bind(id)
        .execute(&mut *tx)
        .await?;
    // Charge last: after this only the commit can fail, and that path refunds.
    let tx_id = charge(&s, &mut tx, a.id, p.payment_method_id, id, Won(deposit), "deposit").await?;
    if let Err(e) = tx.commit().await {
        refund_or_alert(&s, &tx_id, deposit).await;
        return Err(e.into());
    }
    if let Some(t) = b.thread_id {
        best_effort("chat", chat::post_system(&s, t, "deposit_paid", json!({ "amount": deposit }))).await;
    }
    if let Some((_, pro)) = selected {
        best_effort(
            "notify",
            notify(
                &s,
                Recipient::Pro(pro),
                "quote.selected",
                "견적이 선택됐어요",
                &b.number,
                json!({ "booking_id": id }),
            ),
        )
        .await;
    }
    best_effort(
        "notify",
        notify(
            &s,
            Recipient::Staff,
            "booking.deposit_paid",
            "예약금 결제",
            &b.number,
            json!({ "booking_id": id }),
        ),
    )
    .await;
    Ok(Json(load_booking(&s.db, id).await?))
}

/// Quote booking balance after completion; releases the pro's settlement.
async fn pay_balance(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>, Json(p): Json<PayRequest>) -> ApiResult<Json<BookingRow>> {
    let b = owned(&s, a.id, id).await?;
    let (Some(final_price), Some(deposit)) = (b.final_price, b.deposit) else {
        return Err(ApiError::Conflict("not_quote_booking"));
    };
    if b.status()? != BookingStatus::Completed || b.balance_paid {
        return Err(ApiError::Conflict("balance_not_due"));
    }
    let balance = final_price - deposit;
    if balance <= 0 {
        return Err(ApiError::Conflict("balance_not_due"));
    }
    let mut tx = s.db.begin().await?;
    let moved = sqlx::query("UPDATE bookings SET balance_paid = TRUE, paid_amount = paid_amount + $2, updated_at = now() WHERE id = $1 AND NOT balance_paid")
        .bind(id)
        .bind(balance)
        .execute(&mut *tx)
        .await?;
    if moved.rows_affected() == 0 {
        return Err(ApiError::Conflict("balance_not_due"));
    }
    let completed = b.completed_at.map(|c| (c + chrono::Duration::hours(9)).date_naive()).unwrap_or_else(today_kst);
    sqlx::query("UPDATE settlements SET state = 'pending', payout_date = $2 WHERE booking_id = $1 AND state = 'waiting_balance'")
        .bind(id)
        .bind(payout_date(today_kst().max(completed)))
        .execute(&mut *tx)
        .await?;
    let tx_id = charge(&s, &mut tx, a.id, p.payment_method_id, id, Won(balance), "balance").await?;
    if let Err(e) = tx.commit().await {
        refund_or_alert(&s, &tx_id, balance).await;
        return Err(e.into());
    }
    Ok(Json(load_booking(&s.db, id).await?))
}

#[derive(Deserialize)]
struct Notes {
    entry: Option<String>,
    parking: Option<String>,
    other: Option<String>,
}

const MAX_NOTE: usize = 300;

async fn update_notes(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>, Json(n): Json<Notes>) -> ApiResult<Json<BookingRow>> {
    let b = owned(&s, a.id, id).await?;
    if [&n.entry, &n.parking, &n.other]
        .iter()
        .any(|v| v.as_ref().is_some_and(|t| t.chars().count() > MAX_NOTE))
    {
        return Err(ApiError::BadRequest("note_too_long"));
    }
    let r = sqlx::query("UPDATE bookings SET visit_notes = $2, updated_at = now() WHERE id = $1 AND status BETWEEN 0 AND 2")
        .bind(id)
        .bind(json!({ "entry": n.entry, "parking": n.parking, "other": n.other }))
        .execute(&s.db)
        .await?;
    if r.rows_affected() == 0 {
        return Err(ApiError::Conflict("booking_closed"));
    }
    if let Some(pro) = b.pro_id {
        s.hub.send(Recipient::Pro(pro), "job.updated", json!({ "booking_id": id }));
    }
    Ok(Json(load_booking(&s.db, id).await?))
}

#[derive(Deserialize)]
struct Reschedule {
    visit_date: NaiveDate,
    start_hour: u8,
}

/// Free while outside the 2-day window; an assigned pro must confirm the new slot.
async fn reschedule(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>, Json(r): Json<Reschedule>) -> ApiResult<Json<BookingRow>> {
    let b = owned(&s, a.id, id).await?;
    let status = b.status()?;
    if status.is_terminal() || !domain::booking::is_free_cancellation(status, today_kst(), b.visit_date) {
        return Err(ApiError::Conflict("reschedule_closed"));
    }
    check_date(today_kst(), r.visit_date)?;
    check_slot(b.answers.is_some(), r.start_hour)?;
    // Keep the pro's original slot if an earlier change is still unconfirmed.
    let pending = b.pro_id.map(|_| {
        b.reschedule
            .clone()
            .unwrap_or_else(|| json!({ "from_date": b.visit_date, "from_hour": b.start_hour, "requested_at": Utc::now() }))
    });
    let mut tx = s.db.begin().await?;
    let (used, cap) = lock_and_count_slot(&mut tx, r.visit_date, r.start_hour, Some(id)).await?;
    check_capacity(used, cap)?;
    let moved = sqlx::query("UPDATE bookings SET visit_date = $2, start_hour = $3, reschedule = $4, updated_at = now() WHERE id = $1 AND status = $5")
        .bind(id)
        .bind(r.visit_date)
        .bind(i16::from(r.start_hour))
        .bind(pending)
        .bind(b.status)
        .execute(&mut *tx)
        .await?;
    if moved.rows_affected() == 0 {
        return Err(ApiError::Conflict("booking_changed"));
    }
    tx.commit().await?;
    if let Some(pro) = b.pro_id {
        best_effort(
            "notify",
            notify(
                &s,
                Recipient::Pro(pro),
                "job.reschedule_requested",
                "일정 변경 요청",
                &b.number,
                json!({ "booking_id": id }),
            ),
        )
        .await;
    }
    if let Some(t) = b.thread_id {
        best_effort(
            "chat",
            chat::post_system(&s, t, "rescheduled", json!({ "visit_date": r.visit_date, "start_hour": r.start_hour })),
        )
        .await;
    }
    Ok(Json(load_booking(&s.db, id).await?))
}

#[derive(Deserialize)]
struct ReviewInput {
    rating: i16,
    body: String,
}

async fn review(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>, Json(r): Json<ReviewInput>) -> ApiResult<Json<Value>> {
    let b = owned(&s, a.id, id).await?;
    if b.status()? != BookingStatus::Completed {
        return Err(ApiError::Conflict("not_completed"));
    }
    if !(1..=5).contains(&r.rating) || r.body.chars().count() > 1000 {
        return Err(ApiError::BadRequest("invalid_review"));
    }
    let inserted = sqlx::query("INSERT INTO reviews (booking_id, user_id, pro_id, rating, body) VALUES ($1,$2,$3,$4,$5) ON CONFLICT (booking_id) DO NOTHING")
        .bind(id)
        .bind(a.id)
        .bind(b.pro_id)
        .bind(r.rating)
        .bind(r.body.trim())
        .execute(&s.db)
        .await?;
    if inserted.rows_affected() == 0 {
        return Err(ApiError::Conflict("already_reviewed"));
    }
    Ok(Json(json!({ "ok": true })))
}
