//! Customer booking engine: create (+pay), list, detail, cancel, deposit, balance, notes, reschedule, review.

use super::{
    audit,
    booking_core::{
        BookingBody, Prepared, after_booking_created, after_deposit, balance_due, checked_household, deposit_due, insert_paid, lock_slot, next_number, prepare,
        price_for, record_payment, take_balance, take_deposit,
    },
    catalog::{load_formula, load_peak_config},
    chat, growth, payouts,
};
use crate::{
    auth::Customer,
    contract::{PageQuery, cursor_part, decode_cursor, encode_cursor, page_limit, paged},
    crypto,
    error::{ApiError, ApiResult},
    ratelimit::within_quota,
    realtime::{Recipient, notify},
    safety,
    state::AppState,
    util::{best_effort, lock_and_count_slot, refund_or_alert, today_kst},
};
use axum::{
    Json, Router,
    extract::{Path, Query, State},
    response::Response,
    routing::{get, post, put},
};
use chrono::{DateTime, NaiveDate, Utc};
use domain::{
    DomainError, Won,
    booking::{BookingStatus, cancel_quote},
    cancel_policy::{CancelPolicy, Outcome},
    schedule::{check_capacity, check_date, check_slot},
};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use sqlx::{PgConnection, PgPool};
use uuid::Uuid;

const CANCEL_POLICY_KEY: &str = "cancel_policy";

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/bookings", crate::idempotency::replayable(get(list).post(create)))
        .route("/bookings/{id}", get(detail))
        .route("/bookings/{id}/cancel", crate::idempotency::replayable(post(cancel)))
        .route("/bookings/{id}/cancel-preview", get(cancel_preview))
        .route("/bookings/{id}/household", put(update_household))
        .route("/bookings/{id}/deposit", crate::idempotency::replayable(post(pay_deposit)))
        .route("/bookings/{id}/balance", crate::idempotency::replayable(post(pay_balance)))
        .route("/bookings/{id}/notes", put(update_notes))
        .route("/bookings/{id}/reschedule", post(reschedule))
        .route("/bookings/{id}/review", crate::idempotency::replayable(post(review)))
}

pub const BOOKING_COLS: &str =
    "b.id, b.number, b.user_id, b.service_code, b.unit_index, b.address, b.district_code, b.visit_date, b.start_hour, b.minutes, b.status,
    b.answers, b.estimate, b.final_price, b.deposit, b.list_price, b.discount, b.paid_amount, b.balance_paid, b.coupon_id, b.team_name, b.pro_id,
    b.visit_notes, b.household, b.reschedule, b.cancelled_at, b.completed_at, b.created_at, b.checked_in_at, b.checked_out_at,
    (b.access_code_enc IS NOT NULL) AS entry_code_set,
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
    pub household: Value,
    pub reschedule: Option<Value>,
    pub cancelled_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub checked_in_at: Option<DateTime<Utc>>,
    pub checked_out_at: Option<DateTime<Utc>>,
    /// Whether a door code is on file. The code itself is only revealed to the assigned partner.
    pub entry_code_set: bool,
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

/// The customer's own booking; anyone else gets 404, not 403.
pub async fn owned(s: &AppState, user: Uuid, id: Uuid) -> ApiResult<BookingRow> {
    let b = load_booking(&s.db, id).await?;
    if b.user_id == user { Ok(b) } else { Err(ApiError::NotFound) }
}

#[derive(Deserialize)]
pub(crate) struct CreateBooking {
    #[serde(flatten)]
    pub(crate) body: BookingBody,
    pub(crate) payment_method_id: Option<Uuid>,
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
    if let Err(e) = record_payment(conn, booking, amount.0, kind, "pg", &tx_id, &idem).await {
        refund_or_alert(s, "pg", &tx_id, amount.0).await;
        return Err(e);
    }
    Ok(tx_id)
}

async fn create(State(s): State<AppState>, Customer(a): Customer, Json(req): Json<CreateBooking>) -> ApiResult<Json<BookingRow>> {
    let id = create_core(&s, a.id, &req).await?;
    Ok(Json(load_booking(&s.db, id).await?))
}

/// Shared by the direct create and a waitlist offer accept. Returns the new booking id.
pub(crate) async fn create_core(s: &AppState, user: Uuid, req: &CreateBooking) -> ApiResult<Uuid> {
    let prep = prepare(&s.db, user, &req.body).await?;
    if prep.service.is_quote() {
        create_quote(s, user, &req.body, &prep).await
    } else {
        create_paid(s, user, req, &prep).await
    }
}

/// Quote services: a consultation request with the estimate. No payment yet.
async fn create_quote(s: &AppState, user: Uuid, b: &BookingBody, prep: &Prepared) -> ApiResult<Uuid> {
    // Anything needing its own pool connection is read before the slot lock is taken.
    let formula = load_formula(&s.db).await?;
    let mut tx = s.db.begin().await?;
    // Per-customer lock first: two concurrent requests cannot both pass the open-request count.
    sqlx::query("SELECT pg_advisory_xact_lock(hashtext($1))")
        .bind(format!("quote-user:{user}"))
        .execute(&mut *tx)
        .await?;
    let open: i64 = sqlx::query_scalar("SELECT count(*) FROM bookings WHERE user_id = $1 AND status = 0 AND answers IS NOT NULL")
        .bind(user)
        .fetch_one(&mut *tx)
        .await?;
    if !within_quota(open, s.config.max_open_quote_requests) {
        return Err(ApiError::Conflict("too_many_open_requests"));
    }
    // Serialize bookings per slot so capacity can't be oversold.
    lock_slot(&mut tx, b.visit_date, b.start_hour).await?;
    let id = Uuid::now_v7();
    let number = next_number(&mut tx).await?;
    let answers = b.answers.clone().ok_or(ApiError::BadRequest("answers_required"))?;
    let start = domain::peak::kst_to_utc(b.visit_date, u32::from(b.start_hour)).ok_or(ApiError::BadRequest("invalid_slot"))?;
    let peak = domain::peak::peak_surcharge(&load_peak_config(&s.db).await?, start);
    let est = formula.estimate_with_peak(&answers, peak.bps)?;
    sqlx::query(
        "INSERT INTO bookings (id, number, user_id, service_code, address, district_code, visit_date, start_hour, status, answers, estimate, visit_notes, household, peak_surcharge)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,0,$9,$10,$11,$12,$13)",
    )
    .bind(id)
    .bind(&number)
    .bind(user)
    .bind(&prep.service.code)
    .bind(&prep.snapshot)
    .bind(&prep.district_code)
    .bind(b.visit_date)
    .bind(i16::from(b.start_hour))
    .bind(sqlx::types::Json(&answers))
    .bind(est.total.0)
    .bind(&prep.notes)
    .bind(&prep.household)
    .bind(est.peak.0)
    .execute(&mut *tx)
    .await?;
    let thread = chat::booking_thread(&mut tx, "customer", user, id, &prep.service.code).await?;
    let sys = chat::insert_message(&mut tx, thread, "system", None, "system", json!({ "code": "consultation_received" })).await?;
    let card = chat::insert_message(
        &mut tx,
        thread,
        "system",
        None,
        "card",
        json!({
            "booking_id": id, "service_code": prep.service.code, "visit_date": b.visit_date, "start_hour": b.start_hour,
            "answers": answers, "estimate": est.total.0
        }),
    )
    .await?;
    tx.commit().await?;
    best_effort("broadcast", chat::broadcast_message(s, &sys)).await;
    best_effort("broadcast", chat::broadcast_message(s, &card)).await;
    best_effort(
        "notify",
        notify(
            s,
            Recipient::Staff,
            "booking.quote_requested",
            "견적 요청",
            &number,
            json!({ "booking_id": id }),
        ),
    )
    .await;
    Ok(id)
}

/// Fixed and unit services: priced on the server and paid in full now.
async fn create_paid(s: &AppState, user: Uuid, req: &CreateBooking, prep: &Prepared) -> ApiResult<Uuid> {
    let method = req.payment_method_id.ok_or(ApiError::BadRequest("payment_method_required"))?;
    let mut tx = s.db.begin().await?;
    lock_slot(&mut tx, req.body.visit_date, req.body.start_hour).await?;
    let price = price_for(&mut tx, user, prep, &req.body, true).await?;
    let id = Uuid::now_v7();
    let number = insert_paid(&mut tx, &s.config.data_key, id, user, prep, &req.body, &price).await?;
    let tx_id = if price.total.0 > 0 {
        Some(charge(s, &mut tx, user, method, id, price.total, "full").await?)
    } else {
        None
    };
    if let Err(e) = tx.commit().await {
        // Charged but not saved: give the money back before reporting the failure.
        if let Some(t) = tx_id {
            refund_or_alert(s, "pg", &t, price.total.0).await;
        }
        return Err(e.into());
    }
    after_booking_created(s, id, &number).await;
    Ok(id)
}

/// Newest visit date first; keyset cursor over (visit_date, start_hour, id).
async fn list(State(s): State<AppState>, Customer(a): Customer, Query(q): Query<PageQuery>) -> ApiResult<Response> {
    let limit = page_limit(q.limit)?;
    let (date, hour, id) = match decode_cursor(q.cursor.as_deref(), 3)? {
        Some(p) => (Some(cursor_part::<NaiveDate>(&p[0])?), Some(cursor_part::<i16>(&p[1])?), Some(cursor_part::<Uuid>(&p[2])?)),
        None => (None, None, None),
    };
    let rows: Vec<BookingRow> = sqlx::query_as(&format!(
        "SELECT {BOOKING_COLS} FROM bookings b WHERE b.user_id = $1
           AND ($2::date IS NULL OR b.visit_date < $2 OR (b.visit_date = $2 AND (b.start_hour > $3 OR (b.start_hour = $3 AND b.id > $4))))
         ORDER BY b.visit_date DESC, b.start_hour, b.id LIMIT $5"
    ))
    .bind(a.id)
    .bind(date)
    .bind(hour)
    .bind(id)
    .bind(limit)
    .fetch_all(&s.db)
    .await?;
    Ok(paged(rows, limit, |r| encode_cursor(&[&r.visit_date.to_string(), &r.start_hour.to_string(), &r.id.to_string()])))
}

async fn detail(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    let b = owned(&s, a.id, id).await?;
    let mut view = serde_json::to_value(&b).unwrap_or(Value::Null);
    view["emergency"] = safety::emergency_contacts(&s.db).await?;
    Ok(Json(view))
}

/// Refunds every paid payment on a booking (full or a capped amount) and records it.
pub async fn refund_all(s: &AppState, booking: Uuid, max_amount: Option<i64>) -> ApiResult<i64> {
    let pays: Vec<(Uuid, i64, i64, Option<String>, String)> = sqlx::query_as(
        "SELECT id, amount, refunded_amount, provider_tx_id, provider FROM payments WHERE booking_id = $1 AND status IN ('paid','partially_refunded') ORDER BY created_at DESC",
    )
    .bind(booking)
    .fetch_all(&s.db)
    .await?;
    let mut left = max_amount.unwrap_or(i64::MAX);
    let mut total = 0;
    for (pid, amount, refunded, tx, provider) in pays {
        let amt = (amount - refunded).min(left);
        if amt <= 0 {
            continue;
        }
        let tx = tx.ok_or_else(|| ApiError::Internal(format!("payment {pid} has no provider transaction id")))?;
        s.providers
            .refund(&provider, &tx, amt)
            .await
            .map_err(|e| ApiError::PaymentFailed(e.to_string()))?;
        let status = if refunded + amt == amount { "refunded" } else { "partially_refunded" };
        sqlx::query("UPDATE payments SET refunded_amount = refunded_amount + $2, status = $3 WHERE id = $1")
            .bind(pid)
            .bind(amt)
            .bind(status)
            .execute(&s.db)
            .await?;
        if status == "refunded" {
            super::cash_receipts::on_full_refund(s, pid, &tx).await;
        }
        left -= amt;
        total += amt;
    }
    Ok(total)
}

/// Shared by customer and staff cancellation.
/// Money first: refunds are recorded per payment, so if the gateway fails the booking
/// stays active and the same call can be retried without refunding twice.
pub async fn apply_cancel(s: &AppState, b: &BookingRow, refund_cap: Option<i64>, actor: &str) -> ApiResult<()> {
    // Refused before any money moves: a settlement already at the provider cannot be pulled back.
    if payouts::in_transfer(&s.db, b.id).await? {
        return Err(ApiError::Conflict("settlement_in_transfer"));
    }
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
    payouts::detach_booking(&mut tx, b.id).await?;
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

/// The owner's cancel policy and whether it is still the built-in default (not yet saved by the owner).
pub async fn load_cancel_policy(db: &PgPool) -> ApiResult<(CancelPolicy, bool)> {
    let v: Option<Value> = sqlx::query_scalar("SELECT value FROM settings WHERE key = $1")
        .bind(CANCEL_POLICY_KEY)
        .fetch_optional(db)
        .await?;
    match v {
        None => Ok((CancelPolicy::default(), true)),
        Some(v) => Ok((
            serde_json::from_value(v).map_err(|_| ApiError::Internal("bad setting cancel_policy".into()))?,
            false,
        )),
    }
}

/// Whole KST calendar days from today to the visit; the policy's unit.
fn days_before(b: &BookingRow) -> i64 {
    (b.visit_date - today_kst()).num_days()
}

pub fn public_routes() -> Router<AppState> {
    Router::new().route("/policy/cancellation", get(public_cancel_policy))
}

async fn public_cancel_policy(State(s): State<AppState>) -> ApiResult<Json<Value>> {
    let (policy, is_default) = load_cancel_policy(&s.db).await?;
    Ok(Json(json!({ "policy": policy, "is_default": is_default })))
}

#[derive(Serialize)]
struct CancelPreview {
    can_cancel: bool,
    days_before: i64,
    /// None when the outcome is free or closed.
    percent: Option<u8>,
    paid: i64,
    fee: i64,
    refund: i64,
    reschedule_allowed: bool,
}

/// What cancelling or rescheduling would cost right now. The apps show this before the customer confirms.
async fn cancel_preview(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>) -> ApiResult<Json<CancelPreview>> {
    let b = owned(&s, a.id, id).await?;
    let status = b.status()?;
    let (policy, _) = load_cancel_policy(&s.db).await?;
    let days = days_before(&b);
    let open = !status.is_terminal();
    let quote = cancel_quote(&policy, status, days, b.paid_amount);
    Ok(Json(CancelPreview {
        can_cancel: open && quote.is_some(),
        days_before: days,
        percent: match quote.map(|q| q.outcome) {
            Some(Outcome::Fee { percent }) => Some(percent),
            _ => None,
        },
        paid: b.paid_amount,
        fee: quote.map_or(0, |q| q.fee),
        refund: quote.map_or(0, |q| q.refund),
        reschedule_allowed: open && (status == BookingStatus::Consultation || policy.reschedule_allowed(days)),
    }))
}

#[derive(Deserialize, Default)]
struct CancelBody {
    /// The fee the customer saw in the preview. Required whenever the fee is above 0.
    accepted_fee: Option<i64>,
}

async fn cancel(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>, body: Option<Json<CancelBody>>) -> ApiResult<Json<BookingRow>> {
    let b = owned(&s, a.id, id).await?;
    let status = b.status()?;
    let (policy, _) = load_cancel_policy(&s.db).await?;
    let quote = cancel_quote(&policy, status, days_before(&b), b.paid_amount).ok_or(DomainError::CancellationWindowClosed)?;
    status.transition(BookingStatus::Cancelled)?;
    let accepted = body.and_then(|Json(c)| c.accepted_fee);
    if quote.fee > 0 && accepted != Some(quote.fee) {
        return Err(ApiError::Conflict("fee_changed"));
    }
    // A fee keeps the coupon used and refunds only what remains; no fee is a full refund.
    let cap = (quote.fee > 0).then_some(quote.refund);
    apply_cancel(&s, &b, cap, "customer").await?;
    audit(
        &s.db,
        "customer",
        Some(a.id),
        "booking.cancel",
        &id.to_string(),
        json!({ "fee": quote.fee, "refund": quote.refund }),
    )
    .await?;
    crate::util::best_effort("waitlist offer on cancel", super::waitlist::offer_for_slot(&s, b.visit_date, b.start_hour as u8)).await;
    Ok(Json(load_booking(&s.db, id).await?))
}

/// Household is editable until the pro has finished the job, like visit notes.
async fn update_household(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>, Json(h): Json<Value>) -> ApiResult<Json<BookingRow>> {
    let b = owned(&s, a.id, id).await?;
    let household = checked_household(&h)?;
    let r = sqlx::query("UPDATE bookings SET household = $2, updated_at = now() WHERE id = $1 AND status BETWEEN 0 AND 2")
        .bind(id)
        .bind(household)
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
struct PayRequest {
    payment_method_id: Uuid,
}

/// Quote booking: pay 10% deposit after the staff quote -> confirmed (or team assigned).
async fn pay_deposit(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>, Json(p): Json<PayRequest>) -> ApiResult<Json<BookingRow>> {
    let b = owned(&s, a.id, id).await?;
    let deposit = deposit_due(&b)?;
    let mut tx = s.db.begin().await?;
    take_deposit(&mut tx, id, deposit).await?;
    // Charge last: after this only the commit can fail, and that path refunds.
    let tx_id = charge(&s, &mut tx, a.id, p.payment_method_id, id, Won(deposit), "deposit").await?;
    if let Err(e) = tx.commit().await {
        refund_or_alert(&s, "pg", &tx_id, deposit).await;
        return Err(e.into());
    }
    // Reload: the pro attached by the deposit is needed for the notifications.
    let after = load_booking(&s.db, id).await?;
    after_deposit(&s, &after, deposit).await;
    Ok(Json(after))
}

/// Quote booking balance after completion; releases the pro's settlement.
async fn pay_balance(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>, Json(p): Json<PayRequest>) -> ApiResult<Json<BookingRow>> {
    let b = owned(&s, a.id, id).await?;
    let balance = balance_due(&b)?;
    let mut tx = s.db.begin().await?;
    take_balance(&mut tx, &b, balance).await?;
    let tx_id = charge(&s, &mut tx, a.id, p.payment_method_id, id, Won(balance), "balance").await?;
    if let Err(e) = tx.commit().await {
        refund_or_alert(&s, "pg", &tx_id, balance).await;
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
    // The door code is stored encrypted and never in visit_notes; a blank entry clears it.
    let mut notes = json!({ "entry": n.entry, "parking": n.parking, "other": n.other });
    let access_code = safety::take_entry(&mut notes).map(|code| crypto::encrypt(&s.config.data_key, &code));
    let r = sqlx::query("UPDATE bookings SET visit_notes = $2, access_code_enc = $3, updated_at = now() WHERE id = $1 AND status BETWEEN 0 AND 2")
        .bind(id)
        .bind(notes)
        .bind(access_code)
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
    let (policy, _) = load_cancel_policy(&s.db).await?;
    let self_serve = status == BookingStatus::Consultation || policy.reschedule_allowed(days_before(&b));
    if status.is_terminal() || !self_serve {
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
    // The booking's own current slot does not count against the new one.
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
    #[serde(default)]
    photos: Vec<String>,
}

async fn review(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>, Json(r): Json<ReviewInput>) -> ApiResult<Json<Value>> {
    let b = owned(&s, a.id, id).await?;
    if b.status()? != BookingStatus::Completed {
        return Err(ApiError::Conflict("not_completed"));
    }
    let blocked: bool = sqlx::query_scalar("SELECT review_blocked FROM users WHERE id = $1")
        .bind(a.id)
        .fetch_one(&s.db)
        .await?;
    if blocked {
        return Err(ApiError::Conflict("review_blocked"));
    }
    if !(1..=5).contains(&r.rating) || r.body.chars().count() > 1000 {
        return Err(ApiError::BadRequest("invalid_review"));
    }
    let photos = growth::check_photos(&s.db, &s.config.public_base_url, a.id, &r.photos).await?;
    let inserted =
        sqlx::query("INSERT INTO reviews (booking_id, user_id, pro_id, rating, body, photos) VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (booking_id) DO NOTHING")
            .bind(id)
            .bind(a.id)
            .bind(b.pro_id)
            .bind(r.rating)
            .bind(r.body.trim())
            .bind(sqlx::types::Json(&photos))
            .execute(&s.db)
            .await?;
    if inserted.rows_affected() == 0 {
        return Err(ApiError::Conflict("already_reviewed"));
    }
    Ok(Json(json!({ "ok": true })))
}
