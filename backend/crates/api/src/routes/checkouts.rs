//! One-off payments through PortOne: checkout intents, confirm, virtual-account deposits, expiry.
//! Money moves only through `settle`: a PAID payment is checked against the checkout, then
//! fulfilled in one transaction. Any failure after PAID refunds the payment.

use super::{
    booking_core::{
        BookingBody, Prepared, after_booking_created, after_deposit, balance_due, deposit_due, insert_paid, lock_slot, prepare, price_for, record_payment,
        take_balance, take_deposit,
    },
    bookings::{BookingRow, load_booking, owned},
    catalog::load_service,
    payments::ensure_enabled,
};
use crate::{
    auth::Customer,
    error::{ApiError, ApiResult},
    providers::{PaymentInfo, ProviderError},
    state::AppState,
    util::{refund_or_alert, today_kst},
};
use axum::{
    Json, Router,
    extract::{Path, Query, State},
    routing::{get, post},
};
use chrono::{DateTime, Duration, Utc};
use domain::{
    catalog::Service,
    schedule::{check_date, check_slot},
};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sqlx::{PgPool, Postgres, Transaction};
use uuid::Uuid;

const CHECKOUT_TTL_MIN: i64 = 30;
const LIST_LIMIT: i64 = 50;
const CHECKOUT_COLS: &str = "id, user_id, kind, booking_id, draft, amount, status, provider_payment_id, result_booking_id, expires_at";

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/checkouts", get(list).post(create))
        .route("/checkouts/{id}/confirm", post(confirm))
}

#[derive(Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
enum CheckoutRequest {
    Booking { booking: BookingBody, method: String },
    Deposit { booking_id: Uuid, method: String },
    Balance { booking_id: Uuid, method: String },
}

impl CheckoutRequest {
    fn method(&self) -> &str {
        match self {
            Self::Booking { method, .. } | Self::Deposit { method, .. } | Self::Balance { method, .. } => method,
        }
    }
}

/// The booking request as the customer saw it, frozen until payment settles.
#[derive(Serialize, Deserialize)]
struct Draft {
    body: BookingBody,
    district_code: String,
    snapshot: Value,
    notes: Value,
}

struct Intent {
    kind: &'static str,
    booking_id: Option<Uuid>,
    draft: Option<Value>,
    amount: i64,
}

#[derive(Serialize)]
struct CheckoutIntent {
    id: Uuid,
    amount: i64,
    order_name: &'static str,
    method: String,
    store_id: Option<String>,
    channel_key: Option<String>,
}

#[derive(sqlx::FromRow)]
pub struct CheckoutRow {
    pub id: Uuid,
    pub user_id: Uuid,
    pub kind: String,
    pub booking_id: Option<Uuid>,
    pub draft: Option<Value>,
    pub amount: i64,
    pub status: String,
    pub provider_payment_id: Option<String>,
    pub result_booking_id: Option<Uuid>,
    pub expires_at: DateTime<Utc>,
}

#[derive(Serialize)]
pub struct ConfirmResult {
    status: &'static str,
    booking_id: Option<Uuid>,
    virtual_account: Option<Value>,
}

impl ConfirmResult {
    fn paid(booking_id: Option<Uuid>) -> Self {
        Self {
            status: "paid",
            booking_id,
            virtual_account: None,
        }
    }
}

fn order_name(kind: &str) -> &'static str {
    match kind {
        "booking" => "청소 예약",
        "deposit" => "예약금",
        _ => "잔금",
    }
}

/// Pure gate: PAID, in KRW, for exactly the checkout amount.
pub fn amount_matches(expected: i64, info: &PaymentInfo) -> bool {
    info.status == "PAID" && info.currency == "KRW" && info.total == expected
}

/// Checkouts that may still be fulfilled. A late payment on an expired intent is honoured if the slot still exists.
pub fn can_settle(status: &str) -> bool {
    matches!(status, "pending" | "awaiting_deposit" | "expired")
}

async fn create(State(s): State<AppState>, Customer(a): Customer, Json(req): Json<CheckoutRequest>) -> ApiResult<Json<CheckoutIntent>> {
    ensure_enabled(&s.db, req.method()).await?;
    let intent = match &req {
        CheckoutRequest::Booking { booking, .. } => booking_intent(&s, a.id, booking).await?,
        CheckoutRequest::Deposit { booking_id, .. } => {
            let b = owned(&s, a.id, *booking_id).await?;
            Intent {
                kind: "deposit",
                booking_id: Some(b.id),
                draft: None,
                amount: deposit_due(&b)?,
            }
        }
        CheckoutRequest::Balance { booking_id, .. } => {
            let b = owned(&s, a.id, *booking_id).await?;
            Intent {
                kind: "balance",
                booking_id: Some(b.id),
                draft: None,
                amount: balance_due(&b)?,
            }
        }
    };
    let id = Uuid::now_v7();
    sqlx::query("INSERT INTO checkouts (id, user_id, kind, booking_id, draft, method, amount, status, expires_at) VALUES ($1,$2,$3,$4,$5,$6,$7,'pending',$8)")
        .bind(id)
        .bind(a.id)
        .bind(intent.kind)
        .bind(intent.booking_id)
        .bind(&intent.draft)
        .bind(req.method())
        .bind(intent.amount)
        .bind(Utc::now() + Duration::minutes(CHECKOUT_TTL_MIN))
        .execute(&s.db)
        .await?;
    let method = req.method();
    let portone = &s.config.portone;
    Ok(Json(CheckoutIntent {
        id,
        amount: intent.amount,
        order_name: order_name(intent.kind),
        method: method.to_string(),
        store_id: portone.store_id.clone(),
        channel_key: portone.channel_keys.get(method).cloned(),
    }))
}

/// Validates a new booking exactly like pay-now, then freezes it as a draft.
async fn booking_intent(s: &AppState, user: Uuid, body: &BookingBody) -> ApiResult<Intent> {
    let prep = prepare(&s.db, user, body).await?;
    if prep.service.is_quote() {
        return Err(ApiError::BadRequest("quote_not_payable"));
    }
    let mut tx = s.db.begin().await?;
    lock_slot(&mut tx, body.visit_date, body.start_hour).await?;
    let price = price_for(&mut tx, user, &prep, body, false).await?;
    // Read-only so far: commit just releases the slot lock.
    tx.commit().await?;
    if price.total.0 <= 0 {
        return Err(ApiError::BadRequest("amount_required"));
    }
    let draft = Draft {
        body: body.clone(),
        district_code: prep.district_code,
        snapshot: prep.snapshot,
        notes: prep.notes,
    };
    Ok(Intent {
        kind: "booking",
        booking_id: None,
        draft: Some(serde_json::to_value(draft).map_err(|e| ApiError::Internal(e.to_string()))?),
        amount: price.total.0,
    })
}

#[derive(Deserialize)]
struct ConfirmRequest {
    payment_id: String,
}

async fn confirm(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>, Json(req): Json<ConfirmRequest>) -> ApiResult<Json<ConfirmResult>> {
    let ck = load_owned(&s.db, a.id, id).await?;
    Ok(Json(settle(&s, &ck, &req.payment_id).await?))
}

/// Verifies a provider payment against a checkout and moves the checkout forward.
/// Shared by the confirm call and the PortOne webhook.
pub async fn settle(s: &AppState, ck: &CheckoutRow, payment_id: &str) -> ApiResult<ConfirmResult> {
    if ck.status == "paid" && ck.provider_payment_id.as_deref() == Some(payment_id) {
        return Ok(ConfirmResult::paid(ck.result_booking_id));
    }
    if matches!(ck.status.as_str(), "failed" | "cancelled") {
        return Err(ApiError::Conflict("checkout_closed"));
    }
    let info = s.providers.payment(payment_id, ck.amount).await.map_err(|e| match e {
        ProviderError::NotFound => ApiError::BadRequest("payment_not_found"),
        other => other.into(),
    })?;
    if info.status == "PAID" {
        if !amount_matches(ck.amount, &info) {
            // Money came in for something other than this checkout: give it back.
            refund_or_alert(s, "portone", payment_id, info.total).await;
            mark_failed(&s.db, ck.id).await?;
            return Err(ApiError::BadRequest("amount_mismatch"));
        }
        return match fulfil(s, ck, payment_id).await {
            Ok(booking_id) => Ok(ConfirmResult::paid(Some(booking_id))),
            Err(e) => {
                refund_or_alert(s, "portone", payment_id, ck.amount).await;
                mark_failed(&s.db, ck.id).await?;
                Err(e)
            }
        };
    }
    if info.status == "VIRTUAL_ACCOUNT_ISSUED" && matches!(ck.status.as_str(), "pending" | "awaiting_deposit") {
        sqlx::query("UPDATE checkouts SET status = 'awaiting_deposit', provider_payment_id = $2, virtual_account = $3 WHERE id = $1 AND status IN ('pending','awaiting_deposit')")
            .bind(ck.id)
            .bind(payment_id)
            .bind(&info.method)
            .execute(&s.db)
            .await?;
        return Ok(ConfirmResult {
            status: "awaiting_deposit",
            booking_id: None,
            virtual_account: Some(info.method),
        });
    }
    if ck.status == "pending" && ck.expires_at < Utc::now() {
        sqlx::query("UPDATE checkouts SET status = 'expired' WHERE id = $1 AND status = 'pending'")
            .bind(ck.id)
            .execute(&s.db)
            .await?;
        return Err(ApiError::Conflict("checkout_expired"));
    }
    Err(ApiError::PaymentFailed(info.status))
}

/// What a settled checkout changes. Loaded before the transaction; re-checked inside it.
enum Plan {
    Booking { prep: Prepared, body: BookingBody },
    Deposit { booking: BookingRow, amount: i64 },
    Balance { booking: BookingRow, amount: i64 },
}

async fn plan(s: &AppState, ck: &CheckoutRow) -> ApiResult<Plan> {
    match ck.kind.as_str() {
        "booking" => {
            let raw = ck.draft.clone().ok_or(ApiError::Internal("booking checkout without draft".into()))?;
            let draft: Draft = serde_json::from_value(raw).map_err(|e| ApiError::Internal(e.to_string()))?;
            let service: Service = load_service(&s.db, &draft.body.service_code).await?;
            let prep = Prepared {
                service,
                district_code: draft.district_code,
                snapshot: draft.snapshot,
                notes: draft.notes,
            };
            Ok(Plan::Booking { prep, body: draft.body })
        }
        "deposit" => {
            let booking = checkout_booking(s, ck).await?;
            let amount = deposit_due(&booking)?;
            if amount != ck.amount {
                return Err(ApiError::Conflict("price_changed"));
            }
            Ok(Plan::Deposit { booking, amount })
        }
        "balance" => {
            let booking = checkout_booking(s, ck).await?;
            let amount = balance_due(&booking)?;
            if amount != ck.amount {
                return Err(ApiError::Conflict("price_changed"));
            }
            Ok(Plan::Balance { booking, amount })
        }
        _ => Err(ApiError::Internal("unknown checkout kind".into())),
    }
}

async fn checkout_booking(s: &AppState, ck: &CheckoutRow) -> ApiResult<BookingRow> {
    let id = ck.booking_id.ok_or(ApiError::Internal("checkout without booking".into()))?;
    load_booking(&s.db, id).await
}

/// Books or applies the payment and marks the checkout paid, in one transaction.
/// Idempotent: a checkout already paid by this payment returns its booking.
async fn fulfil(s: &AppState, ck: &CheckoutRow, payment_id: &str) -> ApiResult<Uuid> {
    let plan = plan(s, ck).await?;
    let mut tx = s.db.begin().await?;
    let (status, paid_by, result): (String, Option<String>, Option<Uuid>) =
        sqlx::query_as("SELECT status, provider_payment_id, result_booking_id FROM checkouts WHERE id = $1 FOR UPDATE")
            .bind(ck.id)
            .fetch_one(&mut *tx)
            .await?;
    if status == "paid" {
        // A parallel confirm or webhook got here first: the same payment gets the same result.
        return match result {
            Some(b) if paid_by.as_deref() == Some(payment_id) => Ok(b),
            _ => Err(ApiError::Conflict("already_paid")),
        };
    }
    if !can_settle(&status) {
        return Err(ApiError::Conflict("checkout_closed"));
    }
    let (booking_id, db_kind, number) = match plan {
        Plan::Booking { prep, body } => {
            let (id, number) = book(&mut tx, ck.user_id, &prep, &body, ck.amount).await?;
            (id, "full", Some(number))
        }
        Plan::Deposit { booking, amount } => {
            take_deposit(&mut tx, booking.id, amount).await?;
            (booking.id, "deposit", None)
        }
        Plan::Balance { booking, amount } => {
            take_balance(&mut tx, &booking, amount).await?;
            (booking.id, "balance", None)
        }
    };
    record_payment(&mut tx, booking_id, ck.amount, db_kind, "portone", payment_id, &format!("checkout:{}", ck.id)).await?;
    sqlx::query("UPDATE checkouts SET status = 'paid', provider_payment_id = $2, result_booking_id = $3 WHERE id = $1")
        .bind(ck.id)
        .bind(payment_id)
        .bind(booking_id)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    match number {
        Some(n) => after_booking_created(s, booking_id, &n).await,
        None if db_kind == "deposit" => {
            let after = load_booking(&s.db, booking_id).await?;
            after_deposit(s, &after, ck.amount).await;
        }
        None => {}
    }
    Ok(booking_id)
}

/// Re-runs the slot, date and coupon rules inside the transaction and inserts the booking.
async fn book(tx: &mut Transaction<'_, Postgres>, user: Uuid, prep: &Prepared, body: &BookingBody, amount: i64) -> ApiResult<(Uuid, String)> {
    check_date(today_kst(), body.visit_date)?;
    check_slot(prep.service.is_quote(), body.start_hour)?;
    lock_slot(tx, body.visit_date, body.start_hour).await?;
    let price = price_for(tx, user, prep, body, true).await?;
    if price.total.0 != amount {
        return Err(ApiError::Conflict("price_changed"));
    }
    let id = Uuid::now_v7();
    let number = insert_paid(tx, id, user, prep, body, &price).await?;
    Ok((id, number))
}

async fn load_owned(db: &PgPool, user: Uuid, id: Uuid) -> ApiResult<CheckoutRow> {
    sqlx::query_as(&format!("SELECT {CHECKOUT_COLS} FROM checkouts WHERE id = $1 AND user_id = $2"))
        .bind(id)
        .bind(user)
        .fetch_optional(db)
        .await?
        .ok_or(ApiError::NotFound)
}

/// The awaiting virtual-account checkout that a webhook payment belongs to, if any.
pub async fn find_awaiting(db: &PgPool, payment_id: &str) -> ApiResult<Option<CheckoutRow>> {
    Ok(sqlx::query_as(&format!(
        "SELECT {CHECKOUT_COLS} FROM checkouts WHERE provider_payment_id = $1 AND status = 'awaiting_deposit'"
    ))
    .bind(payment_id)
    .fetch_optional(db)
    .await?)
}

async fn mark_failed(db: &PgPool, id: Uuid) -> ApiResult<()> {
    sqlx::query("UPDATE checkouts SET status = 'failed' WHERE id = $1 AND status IN ('pending','awaiting_deposit','expired')")
        .bind(id)
        .execute(db)
        .await?;
    Ok(())
}

#[derive(Deserialize)]
struct ListQuery {
    status: Option<String>,
}

#[derive(Serialize, sqlx::FromRow)]
struct CheckoutView {
    id: Uuid,
    kind: String,
    booking_id: Option<Uuid>,
    method: String,
    amount: i64,
    status: String,
    virtual_account: Option<Value>,
    result_booking_id: Option<Uuid>,
    expires_at: DateTime<Utc>,
    created_at: DateTime<Utc>,
}

async fn list(State(s): State<AppState>, Customer(a): Customer, Query(q): Query<ListQuery>) -> ApiResult<Json<Vec<CheckoutView>>> {
    sqlx::query("UPDATE checkouts SET status = 'expired' WHERE user_id = $1 AND status = 'pending' AND expires_at < now()")
        .bind(a.id)
        .execute(&s.db)
        .await?;
    let rows = sqlx::query_as(
        "SELECT id, kind, booking_id, method, amount, status, virtual_account, result_booking_id, expires_at, created_at
         FROM checkouts WHERE user_id = $1 AND ($2::text IS NULL OR status = $2) ORDER BY created_at DESC LIMIT $3",
    )
    .bind(a.id)
    .bind(q.status)
    .bind(LIST_LIMIT)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn paid(total: i64, currency: &str) -> PaymentInfo {
        PaymentInfo {
            status: "PAID".into(),
            total,
            currency: currency.into(),
            method: Value::Null,
        }
    }

    #[test]
    fn exact_krw_payment_settles() {
        assert!(amount_matches(52_000, &paid(52_000, "KRW")));
    }

    #[test]
    fn wrong_amount_or_currency_never_settles() {
        assert!(!amount_matches(52_000, &paid(47_000, "KRW")));
        assert!(!amount_matches(52_000, &paid(52_000, "USD")));
        assert!(!amount_matches(52_000, &paid(-1, "KRW")));
    }

    #[test]
    fn only_paid_status_settles() {
        for status in ["READY", "VIRTUAL_ACCOUNT_ISSUED", "FAILED", "CANCELLED"] {
            let info = PaymentInfo {
                status: status.into(),
                ..paid(52_000, "KRW")
            };
            assert!(!amount_matches(52_000, &info), "{status} must not settle");
        }
    }

    #[test]
    fn closed_checkouts_cannot_be_fulfilled() {
        for status in ["pending", "awaiting_deposit", "expired"] {
            assert!(can_settle(status), "{status} should settle");
        }
        for status in ["paid", "failed", "cancelled"] {
            assert!(!can_settle(status), "{status} must not settle");
        }
    }
}
