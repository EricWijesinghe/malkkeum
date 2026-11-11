//! Booking rules shared by pay-now (bookings.rs) and checkout intents (checkouts.rs):
//! request validation, server-side pricing, the paid-booking insert, and the deposit
//! and balance steps. Nothing here decides money; callers own the transaction.

use super::{bookings::BookingRow, catalog::load_service, chat, growth};
use crate::{
    crypto,
    error::{ApiError, ApiResult},
    realtime::{Recipient, notify},
    safety::take_entry,
    state::AppState,
    util::{KST_TODAY, best_effort, lock_and_count_slot, sanitize_notes, today_kst},
};
use chrono::{DateTime, NaiveDate, Utc};
use domain::{
    Won,
    booking::BookingStatus,
    catalog::Service,
    coupon::Coupon,
    growth::{apply_welcome, welcome_applies},
    partner::payout_date,
    pricing::{PriceBreakdown, price_booking},
    quote::QuoteAnswers,
    schedule::{check_capacity, check_date, check_slot},
};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use sqlx::{PgConnection, PgPool};
use uuid::Uuid;

/// A booking request without any payment details.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BookingBody {
    pub service_code: String,
    pub unit_index: Option<usize>,
    pub address_id: Uuid,
    pub visit_date: NaiveDate,
    pub start_hour: u8,
    pub coupon_id: Option<Uuid>,
    pub answers: Option<QuoteAnswers>,
    #[serde(default)]
    pub visit_notes: Value,
    /// Per-booking household override; absent means "copy the address profile".
    #[serde(default)]
    pub household: Option<Value>,
}

/// Request facts that do not depend on payment: catalogue entry, address snapshot, notes.
pub struct Prepared {
    pub service: Service,
    pub district_code: String,
    pub snapshot: Value,
    pub notes: Value,
    pub household: Value,
}

#[derive(sqlx::FromRow)]
struct AddressSnap {
    kind: String,
    label: String,
    road_address: String,
    detail: String,
    district_code: String,
    size_pyeong: i16,
    household: Value,
}

/// Validates the household payload and returns its stored (trimmed) form.
pub fn checked_household(v: &Value) -> ApiResult<Value> {
    let h: domain::household::Household = serde_json::from_value(v.clone()).map_err(|_| ApiError::BadRequest("invalid_household"))?;
    let h = h.validated().map_err(ApiError::BadRequest)?;
    serde_json::to_value(h).map_err(|e| ApiError::Internal(e.to_string()))
}

/// Validates the request against the catalogue, the customer's address and the calendar.
pub async fn prepare(db: &PgPool, user: Uuid, b: &BookingBody) -> ApiResult<Prepared> {
    let service = load_service(db, &b.service_code).await?;
    let addr: AddressSnap = sqlx::query_as(
        "SELECT kind, label, road_address, detail, district_code, size_pyeong, household FROM addresses WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL",
    )
    .bind(b.address_id)
    .bind(user)
    .fetch_optional(db)
    .await?
    .ok_or(ApiError::BadRequest("address_required"))?;
    service.check_address_size(addr.size_pyeong as u16)?;
    check_date(today_kst(), b.visit_date)?;
    check_slot(service.is_quote(), b.start_hour)?;
    let snapshot = json!({ "kind": addr.kind, "label": addr.label, "road_address": addr.road_address, "detail": addr.detail, "size_pyeong": addr.size_pyeong });
    let notes = if b.visit_notes.is_null() {
        json!({})
    } else {
        sanitize_notes(&b.visit_notes).ok_or(ApiError::BadRequest("invalid_notes"))?
    };
    let household = match &b.household {
        Some(h) => checked_household(h)?,
        None => addr.household,
    };
    Ok(Prepared {
        service,
        district_code: addr.district_code,
        snapshot,
        notes,
        household,
    })
}

/// Loads a coupon owned by the customer; `lock` holds the row until the transaction ends.
pub async fn load_coupon(conn: &mut PgConnection, user: Uuid, id: Uuid, lock: bool) -> ApiResult<Coupon> {
    type Row = (i64, Option<String>, DateTime<Utc>, DateTime<Utc>, Option<Uuid>);
    let lock_sql = if lock { " FOR UPDATE" } else { "" };
    let row: Option<Row> = sqlx::query_as(&format!(
        "SELECT amount, service_code, issued_at, expires_at, used_booking_id FROM coupons WHERE id = $1 AND user_id = $2{lock_sql}"
    ))
    .bind(id)
    .bind(user)
    .fetch_optional(&mut *conn)
    .await?;
    let (amount, service_code, issued_at, expires_at, used) = row.ok_or(ApiError::NotFound)?;
    Ok(Coupon {
        amount: Won(amount),
        service_code,
        issued_at,
        expires_at,
        used: used.is_some(),
    })
}

/// Server-side price for the chosen unit, optional coupon, and the first-booking welcome offer.
pub async fn price_for(conn: &mut PgConnection, user: Uuid, prep: &Prepared, b: &BookingBody, lock: bool) -> ApiResult<PriceBreakdown> {
    let coupon = match b.coupon_id {
        Some(id) => Some(load_coupon(conn, user, id, lock).await?),
        None => None,
    };
    let price = price_booking(&prep.service, b.unit_index, coupon.as_ref(), Utc::now())?;
    let offer = growth::load_welcome(conn).await?;
    if !offer.enabled || coupon.is_some() {
        return Ok(price);
    }
    // Per-customer lock held to commit: two first bookings at once can't both get the welcome price.
    sqlx::query("SELECT pg_advisory_xact_lock(hashtext($1))")
        .bind(format!("welcome-user:{user}"))
        .execute(&mut *conn)
        .await?;
    let prior: i64 = sqlx::query_scalar("SELECT count(*) FROM bookings WHERE user_id = $1")
        .bind(user)
        .fetch_one(&mut *conn)
        .await?;
    if !welcome_applies(&offer, prior, false) {
        return Ok(price);
    }
    Ok(apply_welcome(price, &offer))
}

/// Takes the per-slot lock for the rest of the transaction and fails when the slot is full.
pub async fn lock_slot(conn: &mut PgConnection, date: NaiveDate, hour: u8) -> ApiResult<()> {
    let (used, cap) = lock_and_count_slot(conn, date, hour, None).await?;
    Ok(check_capacity(used, cap)?)
}

pub async fn next_number(conn: &mut PgConnection) -> ApiResult<String> {
    let number: String = sqlx::query_scalar(&format!(
        "SELECT 'BK' || to_char({KST_TODAY}, 'YYMM') || '-' || lpad(nextval('booking_number_seq')::text, 5, '0')"
    ))
    .fetch_one(&mut *conn)
    .await?;
    Ok(number)
}

/// Inserts a confirmed booking whose full price is paid, and marks its coupon used.
/// Returns the booking number.
/// The entry code is encrypted with `key` and never stored in `visit_notes`.
pub async fn insert_paid(conn: &mut PgConnection, key: &[u8; 32], id: Uuid, user: Uuid, prep: &Prepared, b: &BookingBody, price: &PriceBreakdown) -> ApiResult<String> {
    let number = next_number(&mut *conn).await?;
    let mut notes = prep.notes.clone();
    let access_code = take_entry(&mut notes).map(|code| crypto::encrypt(key, &code));
    sqlx::query(
        "INSERT INTO bookings (id, number, user_id, service_code, unit_index, address, district_code, visit_date, start_hour, minutes, status, list_price, discount, paid_amount, coupon_id, visit_notes, access_code_enc, household)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,1,$11,$12,$13,$14,$15,$16,$17)",
    )
    .bind(id)
    .bind(&number)
    .bind(user)
    .bind(&prep.service.code)
    .bind(b.unit_index.map(|u| u as i16))
    .bind(&prep.snapshot)
    .bind(&prep.district_code)
    .bind(b.visit_date)
    .bind(i16::from(b.start_hour))
    .bind(price.minutes as i32)
    .bind(price.list_price.0)
    .bind(price.discount.0)
    .bind(price.total.0)
    .bind(b.coupon_id)
    .bind(&notes)
    .bind(access_code)
    .bind(&prep.household)
    .execute(&mut *conn)
    .await?;
    if let Some(cid) = b.coupon_id {
        sqlx::query("UPDATE coupons SET used_booking_id = $2 WHERE id = $1")
            .bind(cid)
            .bind(id)
            .execute(&mut *conn)
            .await?;
    }
    Ok(number)
}

/// Records a successful charge or payment. `idem` must be unique per payment.
pub async fn record_payment(conn: &mut PgConnection, booking: Uuid, amount: i64, kind: &str, provider: &str, tx_id: &str, idem: &str) -> ApiResult<()> {
    sqlx::query("INSERT INTO payments (booking_id, amount, kind, status, provider, provider_tx_id, idempotency_key) VALUES ($1,$2,$3,'paid',$4,$5,$6)")
        .bind(booking)
        .bind(amount)
        .bind(kind)
        .bind(provider)
        .bind(tx_id)
        .bind(idem)
        .execute(conn)
        .await?;
    Ok(())
}

/// Deposit due on a quoted booking (10%), while the quote is still awaiting payment.
pub fn deposit_due(b: &BookingRow) -> ApiResult<i64> {
    let (Some(_), Some(deposit)) = (b.final_price, b.deposit) else {
        return Err(ApiError::Conflict("quote_not_sent"));
    };
    if b.status()? != BookingStatus::Consultation {
        return Err(ApiError::Conflict("already_confirmed"));
    }
    Ok(deposit)
}

/// Confirms a quoted booking on deposit: attaches the chosen pro and rejects the other quotes.
pub async fn take_deposit(conn: &mut PgConnection, id: Uuid, deposit: i64) -> ApiResult<()> {
    // Read the chosen quote under lock so a concurrent staff change can't attach the wrong pro.
    let selected: Option<(Uuid, Uuid)> = sqlx::query_as("SELECT id, pro_id FROM quotes WHERE booking_id = $1 AND state = 'selected' FOR UPDATE")
        .bind(id)
        .fetch_optional(&mut *conn)
        .await?;
    let new_status = if selected.is_some() { 2 } else { 1 };
    let moved = sqlx::query("UPDATE bookings SET status = $2, paid_amount = paid_amount + $3, pro_id = $4, accepted_at = CASE WHEN $4 IS NULL THEN NULL ELSE now() END, updated_at = now() WHERE id = $1 AND status = 0")
        .bind(id)
        .bind(new_status)
        .bind(deposit)
        .bind(selected.map(|q| q.1))
        .execute(&mut *conn)
        .await?;
    if moved.rows_affected() == 0 {
        return Err(ApiError::Conflict("booking_changed"));
    }
    sqlx::query("UPDATE quotes SET state = 'rejected', updated_at = now(), seen_by_pro = FALSE WHERE booking_id = $1 AND state = 'waiting'")
        .bind(id)
        .execute(&mut *conn)
        .await?;
    Ok(())
}

/// Balance due on a completed quote booking, if it is still unpaid.
pub fn balance_due(b: &BookingRow) -> ApiResult<i64> {
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
    Ok(balance)
}

/// Marks the balance paid and releases the pro's settlement.
pub async fn take_balance(conn: &mut PgConnection, b: &BookingRow, balance: i64) -> ApiResult<()> {
    let moved = sqlx::query("UPDATE bookings SET balance_paid = TRUE, paid_amount = paid_amount + $2, updated_at = now() WHERE id = $1 AND NOT balance_paid")
        .bind(b.id)
        .bind(balance)
        .execute(&mut *conn)
        .await?;
    if moved.rows_affected() == 0 {
        return Err(ApiError::Conflict("balance_not_due"));
    }
    growth::reward_on_paid_completion(&mut *conn, b.id).await?;
    let completed = b.completed_at.map(|c| (c + chrono::Duration::hours(9)).date_naive()).unwrap_or_else(today_kst);
    sqlx::query("UPDATE settlements SET state = 'pending', payout_date = $2 WHERE booking_id = $1 AND state = 'waiting_balance'")
        .bind(b.id)
        .bind(payout_date(today_kst().max(completed)))
        .execute(&mut *conn)
        .await?;
    Ok(())
}

/// Chat line and notifications after a deposit commits. `b` must be reloaded after the commit.
pub async fn after_deposit(s: &AppState, b: &BookingRow, deposit: i64) {
    if let Some(t) = b.thread_id {
        best_effort("chat", chat::post_system(s, t, "deposit_paid", json!({ "amount": deposit }))).await;
    }
    if let Some(pro) = b.pro_id {
        best_effort(
            "notify",
            notify(
                s,
                Recipient::Pro(pro),
                "quote.selected",
                "견적이 선택됐어요",
                &b.number,
                json!({ "booking_id": b.id }),
            ),
        )
        .await;
    }
    best_effort(
        "notify",
        notify(
            s,
            Recipient::Staff,
            "booking.deposit_paid",
            "예약금 결제",
            &b.number,
            json!({ "booking_id": b.id }),
        ),
    )
    .await;
}

pub async fn after_booking_created(s: &AppState, id: Uuid, number: &str) {
    best_effort(
        "notify",
        notify(s, Recipient::Staff, "booking.created", "새 예약", number, json!({ "booking_id": id })),
    )
    .await;
}
