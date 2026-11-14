//! One-off payments through PortOne: checkout intents, confirm, virtual-account deposits, expiry.
//! Money moves only through `settle`: a PAID payment is checked against the checkout, then
//! fulfilled in one transaction. Any failure after PAID refunds the payment (durably: see
//! `util::refund_durably`). Recovery and the checkout lists live in `checkout_recon`.

use super::checkout_policy::{Action, Binding, Recovery, bind, decide, dev_lookup, refund_reason};
use super::checkout_recon::{admin_list, list};
use super::{
    booking_core::{
        BookingBody, Prepared, SeenQuote, after_booking_created, after_deposit, balance_due, check_seen_quote, deposit_due, insert_paid, lock_slot, prepare,
        price_for, record_payment, take_balance, take_deposit,
    },
    bookings::{BookingRow, load_booking, owned},
    catalog::load_service,
    payments::ensure_enabled,
};
use crate::{
    auth::Customer,
    error::{ApiError, ApiResult},
    providers::{
        PaymentInfo, ProviderError,
        portone::{self, dev_method},
    },
    realtime::{Recipient, notify},
    state::AppState,
    util::{Refund, best_effort, refund_durably, today_kst},
};
use axum::{
    Json, Router,
    extract::{Path, State},
    routing::{get, post},
};
use chrono::{DateTime, Duration, Utc};
use domain::{
    Won,
    catalog::Service,
    schedule::{check_date, check_slot},
};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use sqlx::{PgPool, Postgres, Transaction};
use uuid::Uuid;

const CHECKOUT_TTL_MIN: i64 = 30;
pub(super) const CHECKOUT_COLS: &str = "id, user_id, kind, booking_id, draft, amount, points, status, provider_payment_id, result_booking_id, expires_at";

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/checkouts", crate::idempotency::replayable(get(list).post(create)))
        .route("/checkouts/{id}/confirm", crate::idempotency::replayable(post(confirm)))
}

pub fn admin_routes() -> Router<AppState> {
    Router::new().route("/checkouts", get(admin_list))
}

#[derive(Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
enum CheckoutRequest {
    Booking {
        booking: BookingBody,
        method: String,
    },
    /// `expected_*`: the quote card the customer tapped (see `check_seen_quote`).
    Deposit {
        booking_id: Uuid,
        method: String,
        expected_deposit: Option<i64>,
        expected_final_price: Option<i64>,
        expected_quote_message_id: Option<Uuid>,
    },
    Balance {
        booking_id: Uuid,
        method: String,
    },
}

impl CheckoutRequest {
    fn method(&self) -> &str {
        match self {
            Self::Booking { method, .. } | Self::Deposit { method, .. } | Self::Balance { method, .. } => method,
        }
    }
}

#[derive(Deserialize)]
struct CreateBody {
    #[serde(flatten)]
    req: CheckoutRequest,
    /// Points the customer asks to pay with. Checked here against balance and cap, debited at settlement.
    #[serde(default)]
    points: i64,
}

/// The booking request as the customer saw it, frozen until payment settles.
#[derive(Serialize, Deserialize)]
struct Draft {
    body: BookingBody,
    district_code: String,
    snapshot: Value,
    notes: Value,
    /// Stored so the checkout books exactly the household the customer saw.
    #[serde(default)]
    household: Value,
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
    /// What the PG must charge: `total - points`.
    amount: i64,
    total: i64,
    points: i64,
    order_name: &'static str,
    method: String,
    store_id: Option<String>,
    channel_key: Option<String>,
    /// 현금영수증 request is offered only when the server has it switched on.
    cash_receipts: bool,
}

#[derive(sqlx::FromRow)]
pub struct CheckoutRow {
    pub id: Uuid,
    pub user_id: Uuid,
    pub kind: String,
    pub booking_id: Option<Uuid>,
    pub draft: Option<Value>,
    pub amount: i64,
    pub points: i64,
    pub status: String,
    pub provider_payment_id: Option<String>,
    pub result_booking_id: Option<Uuid>,
    pub expires_at: DateTime<Utc>,
}

impl CheckoutRow {
    /// What the PG charges: the total less the points applied. Always > 0 (checked at create).
    pub fn charge(&self) -> i64 {
        self.amount - self.points
    }
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

/// The quote card stored with a deposit checkout at create (none for checkouts made before v1.4).
fn seen_on(ck: &CheckoutRow) -> ApiResult<SeenQuote> {
    match ck.draft.as_ref().and_then(|d| d.get("seen")) {
        Some(v) => serde_json::from_value(v.clone()).map_err(|e| ApiError::Internal(e.to_string())),
        None => Ok(SeenQuote::default()),
    }
}

/// Checkouts that may still be fulfilled. A late payment on an expired intent is honoured if the slot still exists.
pub fn can_settle(status: &str) -> bool {
    matches!(status, "pending" | "awaiting_deposit" | "expired")
}

async fn create(State(s): State<AppState>, Customer(a): Customer, Json(body): Json<CreateBody>) -> ApiResult<Json<CheckoutIntent>> {
    let CreateBody { req, points } = body;
    ensure_enabled(&s.db, req.method()).await?;
    if matches!(req, CheckoutRequest::Booking { .. }) && super::config::maintenance_on(&s.db, &s.config).await? {
        return Err(ApiError::Unavailable("maintenance"));
    }
    let intent = match &req {
        CheckoutRequest::Booking { booking, .. } => booking_intent(&s, a.id, booking).await?,
        CheckoutRequest::Deposit {
            booking_id,
            expected_deposit,
            expected_final_price,
            expected_quote_message_id,
            ..
        } => {
            let seen = SeenQuote {
                expected_deposit: *expected_deposit,
                expected_final_price: *expected_final_price,
                expected_quote_message_id: *expected_quote_message_id,
            };
            seen.validate()?;
            let b = owned(&s, a.id, *booking_id).await?;
            deposit_due(&b)?;
            // Early answer for the app. The card stored is the server's locked read (equal to the
            // client's when it sent one), so settlement binds create->settle for every client.
            let card = check_seen_quote(&mut *s.db.acquire().await?, b.id, &seen).await?;
            let amount = card.expected_deposit.ok_or(ApiError::Conflict("quote_not_sent"))?;
            Intent {
                kind: "deposit",
                booking_id: Some(b.id),
                draft: Some(json!({ "seen": card })),
                amount,
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
    // Nothing is debited yet; the same rules run again under lock when the checkout settles.
    let points = if points == 0 {
        0
    } else {
        let mut conn = s.db.acquire().await?;
        let split = crate::points::quote(&mut conn, a.id, intent.booking_id, Won(intent.amount), points).await?;
        if split.pg.0 <= 0 {
            // The PG cannot charge zero won.
            return Err(ApiError::BadRequest("points_cover_total"));
        }
        split.points
    };
    let id = Uuid::now_v7();
    sqlx::query("INSERT INTO checkouts (id, user_id, kind, booking_id, draft, method, amount, points, status, expires_at) VALUES ($1,$2,$3,$4,$5,$6,$7,$9,'pending',$8)")
        .bind(id)
        .bind(a.id)
        .bind(intent.kind)
        .bind(intent.booking_id)
        .bind(&intent.draft)
        .bind(req.method())
        .bind(intent.amount)
        .bind(Utc::now() + Duration::minutes(CHECKOUT_TTL_MIN))
        .bind(points)
        .execute(&s.db)
        .await?;
    let method = req.method();
    let integ = s.providers.integ();
    let portone = &integ.portone;
    Ok(Json(CheckoutIntent {
        id,
        amount: intent.amount - points,
        total: intent.amount,
        points,
        order_name: order_name(intent.kind),
        method: method.to_string(),
        store_id: portone.store_id.clone(),
        channel_key: portone.channel_keys.get(method).cloned(),
        cash_receipts: portone.cash_receipts,
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
        household: prep.household,
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
    // A booking checkout with no booking yet would create one here, so it waits for maintenance to end.
    if ck.kind == "booking" && ck.result_booking_id.is_none() && super::config::maintenance_on(&s.db, &s.config).await? {
        return Err(ApiError::Unavailable("maintenance"));
    }
    Ok(Json(settle(&s, &ck, &req.payment_id).await?))
}

/// Verifies a provider payment against a checkout and moves the checkout forward.
/// Shared by the confirm call, the PortOne webhook and the reconciler. The provider is
/// always asked; the webhook body and the client are never trusted for money.
pub async fn settle(s: &AppState, ck: &CheckoutRow, payment_id: &str) -> ApiResult<ConfirmResult> {
    let payment_id = bound_payment(s, ck, payment_id).await?;
    let payment_id = payment_id.as_str();
    if ck.status == "paid" && ck.provider_payment_id.as_deref() == Some(payment_id) {
        return Ok(ConfirmResult::paid(ck.result_booking_id));
    }
    let lookup = dev_lookup(payment_id);
    let info = s.providers.payment(lookup, ck.charge()).await.map_err(|e| match e {
        ProviderError::NotFound => ApiError::BadRequest("payment_not_found"),
        other => other.into(),
    })?;
    // Dev window: the method the customer picked is the one the payment is stored under.
    if let (Some(code), "pending") = (dev_method(lookup), ck.status.as_str()) {
        sqlx::query("UPDATE checkouts SET method = $2 WHERE id = $1 AND status = 'pending'")
            .bind(ck.id)
            .bind(code)
            .execute(&s.db)
            .await?;
    }
    apply(s, ck, payment_id, Some(&info)).await
}

/// The id this checkout's payment is stored under. A payment of another checkout is refused before
/// anything is read, changed or refunded: one PortOne payment backs exactly one checkout.
async fn bound_payment(s: &AppState, ck: &CheckoutRow, payment_id: &str) -> ApiResult<String> {
    let foreign = ApiError::BadRequest("payment_not_for_checkout");
    match bind(ck.id, payment_id) {
        Binding::Bound(id) => Ok(id),
        Binding::Foreign => Err(foreign),
        Binding::AskProvider => match portone::custom_checkout_id(&s.providers, payment_id).await {
            Ok(Some(owner)) if owner == ck.id => Ok(payment_id.to_string()),
            Ok(_) | Err(ProviderError::NotFound) => Err(foreign),
            Err(e) => Err(e.into()),
        },
    }
}

/// Carries out `decide` for one checkout. `info` is `None` when the provider has no such payment.
/// `payment_id` must already be bound to `ck` (see `bound_payment`).
pub(super) async fn apply(s: &AppState, ck: &CheckoutRow, payment_id: &str, info: Option<&PaymentInfo>) -> ApiResult<ConfirmResult> {
    let action = decide(&Recovery {
        status: &ck.status,
        expired: ck.expires_at < Utc::now(),
        provider_status: info.map(|i| i.status.as_str()),
        amount_ok: info.is_some_and(|i| amount_matches(ck.charge(), i)),
        paid_by_this: ck.provider_payment_id.as_deref() == Some(payment_id),
    });
    let provider_status = info.map_or("NOT_FOUND", |i| i.status.as_str());
    match action {
        Action::Nothing => Err(refused(ck, provider_status)),
        Action::Fulfil | Action::FulfilLate => match fulfil(s, ck, payment_id).await {
            Ok(booking_id) => Ok(ConfirmResult::paid(Some(booking_id))),
            Err(e) => unfulfilled(s, ck, payment_id, action, e).await,
        },
        Action::RefundMismatch => {
            // This checkout's payment, for another amount: give it back.
            let refund = give_back(s, ck, payment_id, info).await;
            failed_or_pending(s, ck, "amount_mismatch", refund).await?;
            Err(ApiError::BadRequest("amount_mismatch"))
        }
        Action::RefundClosed => {
            let refund = give_back(s, ck, payment_id, info).await;
            if ck.status != "paid" {
                refund_late(s, ck, Some("closed_checkout"), refund).await?;
            }
            Err(ApiError::Conflict("checkout_closed"))
        }
        Action::MarkAwaitingDeposit => {
            let i = info.ok_or(ApiError::Internal("virtual account without provider payment".into()))?;
            sqlx::query("UPDATE checkouts SET status = 'awaiting_deposit', provider_payment_id = $2, virtual_account = $3 WHERE id = $1 AND status IN ('pending','awaiting_deposit')")
                .bind(ck.id)
                .bind(payment_id)
                .bind(&i.method)
                .execute(&s.db)
                .await?;
            Ok(ConfirmResult {
                status: "awaiting_deposit",
                booking_id: None,
                virtual_account: Some(i.method.clone()),
            })
        }
        Action::MarkExpired => {
            sqlx::query("UPDATE checkouts SET status = 'expired' WHERE id = $1 AND status = 'pending'")
                .bind(ck.id)
                .execute(&s.db)
                .await?;
            Err(ApiError::Conflict("checkout_expired"))
        }
    }
}

/// A PAID payment that could not be fulfilled is given back, unless a racing settle (or a read
/// after commit) fulfilled this very payment.
async fn unfulfilled(s: &AppState, ck: &CheckoutRow, payment_id: &str, action: Action, e: ApiError) -> ApiResult<ConfirmResult> {
    match find_by_id(&s.db, ck.id).await {
        Ok(Some(now)) if now.status == "paid" && now.provider_payment_id.as_deref() == Some(payment_id) => {
            return Ok(ConfirmResult::paid(now.result_booking_id));
        }
        Ok(_) => {}
        // Unknown state: refunding an unfulfilled charge is the safe default.
        Err(re) => tracing::error!(error = %re, checkout = %ck.id, "re-reading checkout before refund failed"),
    }
    let refund = refund_durably(s, "portone", payment_id, ck.charge(), Some(ck.id)).await;
    let reason = refund_reason(&e);
    if ck.kind == "deposit" && deposit_changed(&e) {
        // Re-quoted or changed after the customer paid: the money goes back, say so, and keep the reason.
        refund_late(s, ck, Some(&reason), refund).await?;
        return Err(e);
    }
    if action == Action::FulfilLate {
        // Paid after expiry and the slot or coupon is gone: the money goes back, say so.
        refund_late(s, ck, Some(&reason), refund).await?;
        return Err(ApiError::Conflict(match refund {
            Refund::Done => "checkout_refunded",
            Refund::Pending => "checkout_refund_pending",
        }));
    }
    failed_or_pending(s, ck, &reason, refund).await?;
    Err(e)
}

/// Refunds this checkout's PAID payment in full, as the provider reports it.
async fn give_back(s: &AppState, ck: &CheckoutRow, payment_id: &str, info: Option<&PaymentInfo>) -> Refund {
    match info {
        Some(i) => refund_durably(s, "portone", payment_id, i.total, Some(ck.id)).await,
        // Nothing was paid, so nothing is owed.
        None => Refund::Done,
    }
}

/// 'failed' once the money is back; 'refund_pending' (with notice) while it is not.
async fn failed_or_pending(s: &AppState, ck: &CheckoutRow, reason: &str, refund: Refund) -> ApiResult<()> {
    match refund {
        Refund::Done => mark_failed(&s.db, ck.id).await,
        Refund::Pending => refund_late(s, ck, Some(reason), refund).await,
    }
}

/// The booking moved between the customer's tap and settlement (re-quote, changed under lock, or
/// another checkout confirmed it first): the charge was refunded and the customer must hear of it.
fn deposit_changed(e: &ApiError) -> bool {
    matches!(
        e,
        ApiError::PriceChanged(_) | ApiError::Conflict("price_changed" | "booking_changed" | "already_confirmed")
    )
}

/// The refusal for a checkout that stays as it is: closed checkouts say so, open ones report the provider state.
fn refused(ck: &CheckoutRow, provider_status: &str) -> ApiError {
    if matches!(ck.status.as_str(), "failed" | "cancelled" | "refund_pending" | "refunded") {
        ApiError::Conflict("checkout_closed")
    } else {
        ApiError::PaymentFailed(provider_status.to_string())
    }
}

/// Marks a checkout whose payment is given back: 'refunded' once the provider confirmed it,
/// 'refund_pending' until then (the reconciler retries it). The customer hears of each state once,
/// and is never told "refunded" before the money went back. `reason` None keeps the stored one.
pub(super) async fn refund_late(s: &AppState, ck: &CheckoutRow, reason: Option<&str>, refund: Refund) -> ApiResult<()> {
    let (status, kind, title, body) = match refund {
        Refund::Done => (
            "refunded",
            "payment.refunded",
            "결제가 자동으로 취소됐어요",
            "예약 조건이 바뀌어 결제 금액을 환불했어요",
        ),
        Refund::Pending => (
            "refund_pending",
            "payment.refund_pending",
            "결제 취소를 진행하고 있어요",
            "예약 조건이 바뀌어 결제 금액을 환불하고 있어요. 환불이 끝나면 알려드릴게요",
        ),
    };
    let moved = sqlx::query(
        "UPDATE checkouts SET status = $3, refund_reason = COALESCE($2, refund_reason) WHERE id = $1 AND status <> $3
           AND status IN ('pending','awaiting_deposit','expired','failed','cancelled','refund_pending')",
    )
    .bind(ck.id)
    .bind(reason)
    .bind(status)
    .execute(&s.db)
    .await?;
    if moved.rows_affected() == 0 {
        // Already in this state (retry or webhook replay): the customer was told the first time.
        return Ok(());
    }
    best_effort(
        "notify",
        notify(s, Recipient::User(ck.user_id), kind, title, body, json!({ "checkout_id": ck.id })),
    )
    .await;
    Ok(())
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
                household: draft.household,
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
    // Read outside the transaction, but its error waits for the paid check below: a racing settle
    // makes `plan` fail (already_confirmed / balance_not_due) for a payment that is already fulfilled.
    let plan = plan(s, ck).await;
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
    let (booking_id, db_kind, number) = match plan? {
        Plan::Booking { prep, body } => {
            let (id, number) = book(&mut tx, &s.config.data_key, ck.user_id, &prep, &body, ck.amount).await?;
            (id, "full", Some(number))
        }
        Plan::Deposit { booking, amount } => {
            take_deposit(&mut tx, booking.id, amount, &seen_on(ck)?).await?;
            (booking.id, "deposit", None)
        }
        Plan::Balance { booking, amount } => {
            take_balance(&mut tx, &booking, amount).await?;
            (booking.id, "balance", None)
        }
    };
    if ck.points > 0 {
        // Same transaction as the booking and the payment: balance and cap are re-checked under the
        // user lock, and a failure rolls everything back (the PG charge is then refunded by `apply`).
        crate::points::spend(&mut tx, ck.user_id, booking_id, Won(ck.amount), ck.points).await?;
    }
    record_payment(&mut tx, booking_id, ck.charge(), db_kind, "portone", payment_id, &format!("checkout:{}", ck.id)).await?;
    sqlx::query("UPDATE checkouts SET status = 'paid', provider_payment_id = $2, result_booking_id = $3 WHERE id = $1")
        .bind(ck.id)
        .bind(payment_id)
        .bind(booking_id)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    best_effort(
        "payment receipt",
        notify(
            s,
            Recipient::User(ck.user_id),
            "payment.receipt",
            "결제가 완료됐어요",
            "결제 내역은 예약 상세에서 확인할 수 있어요",
            json!({ "checkout_id": ck.id, "booking_id": booking_id }),
        ),
    )
    .await;
    super::cash_receipts::on_settled(s, ck.id, payment_id).await;
    super::tax_invoices::on_settled(s, ck.id, payment_id).await;
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
async fn book(tx: &mut Transaction<'_, Postgres>, key: &[u8; 32], user: Uuid, prep: &Prepared, body: &BookingBody, amount: i64) -> ApiResult<(Uuid, String)> {
    check_date(today_kst(), body.visit_date)?;
    check_slot(prep.service.is_quote(), body.start_hour)?;
    lock_slot(tx, body.visit_date, body.start_hour).await?;
    let price = price_for(tx, user, prep, body, true).await?;
    if price.total.0 != amount {
        return Err(ApiError::Conflict("price_changed"));
    }
    let id = Uuid::now_v7();
    let number = insert_paid(tx, key, id, user, prep, body, &price).await?;
    Ok((id, number))
}

pub(super) async fn load_owned(db: &PgPool, user: Uuid, id: Uuid) -> ApiResult<CheckoutRow> {
    sqlx::query_as(&format!("SELECT {CHECKOUT_COLS} FROM checkouts WHERE id = $1 AND user_id = $2"))
        .bind(id)
        .bind(user)
        .fetch_optional(db)
        .await?
        .ok_or(ApiError::NotFound)
}

pub async fn find_by_id(db: &PgPool, id: Uuid) -> ApiResult<Option<CheckoutRow>> {
    Ok(sqlx::query_as(&format!("SELECT {CHECKOUT_COLS} FROM checkouts WHERE id = $1"))
        .bind(id)
        .fetch_optional(db)
        .await?)
}

/// The checkout a provider payment belongs to. The app pays with `checkout.id` as the PortOne
/// paymentId, so that is tried first; the payment id stored at settlement covers the rest.
pub async fn find_by_payment(db: &PgPool, payment_id: &str) -> ApiResult<Option<CheckoutRow>> {
    if let Ok(id) = Uuid::parse_str(payment_id)
        && let Some(ck) = find_by_id(db, id).await?
    {
        return Ok(Some(ck));
    }
    Ok(sqlx::query_as(&format!(
        "SELECT {CHECKOUT_COLS} FROM checkouts WHERE provider_payment_id = $1 ORDER BY created_at DESC LIMIT 1"
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

    #[test]
    fn a_booking_changed_under_lock_is_a_refund_with_notice() {
        assert!(deposit_changed(&ApiError::Conflict("booking_changed")));
        assert!(deposit_changed(&ApiError::Conflict("price_changed")));
        assert!(deposit_changed(&ApiError::PriceChanged(json!({}))));
        assert!(deposit_changed(&ApiError::Conflict("already_confirmed")));
        assert!(!deposit_changed(&ApiError::Conflict("already_paid")));
        assert_eq!(refund_reason(&ApiError::Conflict("booking_changed")), "booking_changed");
    }
}
