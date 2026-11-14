//! Console: partner payouts. requested -> sent -> paid, or failed (retryable). Transitions live in
//! [`crate::payout`]; every change runs in one transaction on a locked row, so a payout can be paid
//! at most once and a settlement is marked paid only together with its payout.

use super::audit;
use crate::{
    auth::{Admin, Role, live_staff_role},
    contract::{json_row_cursor, page_limit, paged, ts_id_cursor},
    crypto,
    error::{ApiError, ApiResult},
    integrations::PayoutMode,
    payout::{Action, State},
    providers::{ProviderError, payout as adapter},
    realtime::{Recipient, notify},
    state::AppState,
    util::today_kst,
};
use axum::{
    Json,
    extract::{Path, State as AxState},
    http::header,
    response::{IntoResponse, Response},
};
use chrono::{DateTime, NaiveDate, Utc};
use serde::Deserialize;
use serde_json::{Value, json};
use sqlx::{PgPool, Postgres, Transaction};
use uuid::Uuid;

const REASON_MAX: usize = 200;

/// Settlements due by `date` that no payout covers yet, grouped per verified pro. Runs under an
/// advisory lock, so two clicks can't create two payouts for the same settlements. A pro who already
/// has a requested or sent payout for the date is skipped (the partial unique index), not an error.
const CREATE_SQL: &str = "
WITH due AS (
  SELECT st.id AS settlement_id, st.pro_id, st.net FROM settlements st
  WHERE st.state = 'pending' AND st.payout_date <= $1 AND st.payout_id IS NULL
    AND st.pro_id IN (SELECT pro_id FROM payout_accounts WHERE verified_at IS NOT NULL)
),
sums AS (
  SELECT d.pro_id, pr.tax_type, sum(d.net)::bigint AS amount, count(*)::int AS items
  FROM due d JOIN pros pr ON pr.id = d.pro_id GROUP BY d.pro_id, pr.tax_type
),
ins AS (
  INSERT INTO payouts (pro_id, payout_date, amount, items, provider, state, bank, holder, account_enc, account_last4, tax_type)
  SELECT s.pro_id, $1, s.amount, s.items, $2, 'requested', pa.bank, pa.holder, pa.account_enc, pa.account_last4, s.tax_type
  FROM sums s JOIN payout_accounts pa ON pa.pro_id = s.pro_id
  ON CONFLICT (pro_id, payout_date) WHERE state IN ('requested', 'sent') DO NOTHING
  RETURNING id, pro_id
),
linked AS (
  UPDATE settlements st SET payout_id = ins.id FROM due d JOIN ins ON ins.pro_id = d.pro_id
  WHERE st.id = d.settlement_id AND st.payout_id IS NULL
  RETURNING st.id
)
SELECT id FROM ins";

/// Payout rows for the console. Account numbers are never included here (see `reveal_account`).
const LIST_SQL: &str = "SELECT COALESCE(jsonb_agg(x ORDER BY x.created_at DESC, x.id DESC), '[]') FROM (
  SELECT p.id, p.pro_id, pr.name AS pro_name, pr.team_name, p.payout_date, p.amount, p.items, p.provider, p.state,
         p.bank, p.account_last4, p.attempts, p.failure_reason, p.provider_transfer_id, p.created_at, p.paid_at, p.tax_type
  FROM payouts p JOIN pros pr ON pr.id = p.pro_id
  WHERE ($1::text IS NULL OR p.state = $1) AND ($2::uuid[] IS NULL OR p.id = ANY($2))
    AND ($3::timestamptz IS NULL OR (p.created_at, p.id) < ($3, $4))
  ORDER BY p.created_at DESC, p.id DESC LIMIT $5) x";
/// Rows for a run of payouts picked by id: all of them, however many.
const BY_IDS_LIMIT: i64 = 1000;

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct RunPayouts {
    date: NaiveDate,
}

#[derive(Deserialize)]
pub struct PayoutFilter {
    state: Option<String>,
    limit: Option<i64>,
    cursor: Option<String>,
}

#[derive(Deserialize, Default)]
pub struct ActionBody {
    reason: Option<String>,
}

#[derive(sqlx::FromRow)]
struct Row {
    pro_id: Uuid,
    payout_date: NaiveDate,
    amount: i64,
    tax_type: String,
    provider: String,
    state: String,
    bank: String,
    holder: String,
    account_enc: String,
    idempotency_key: String,
    provider_transfer_id: Option<String>,
    failure_reason: Option<String>,
}

impl Row {
    fn state(&self) -> State {
        State::parse(&self.state).unwrap_or(State::Failed)
    }

    /// A Toss transfer that may already exist at the provider: sent, or requested after an ambiguous send error.
    fn awaiting_provider(&self) -> bool {
        self.state() == State::Sent || (self.state() == State::Requested && self.failure_reason.is_some())
    }
}

fn mode_str(m: PayoutMode) -> &'static str {
    match m {
        PayoutMode::Manual => "manual",
        PayoutMode::Toss => "toss",
    }
}

async fn rows(db: &PgPool, state: Option<&str>, ids: Option<&[Uuid]>, after: (Option<DateTime<Utc>>, Option<Uuid>), limit: i64) -> ApiResult<Value> {
    Ok(sqlx::query_scalar(LIST_SQL)
        .bind(state)
        .bind(ids)
        .bind(after.0)
        .bind(after.1)
        .bind(limit)
        .fetch_one(db)
        .await?)
}

/// Newest first; keyset cursor over (created_at, id).
pub async fn list_payouts(AxState(s): AxState<AppState>, _a: Admin, axum::extract::Query(f): axum::extract::Query<PayoutFilter>) -> ApiResult<Response> {
    let limit = page_limit(f.limit)?;
    let after = ts_id_cursor(f.cursor.as_deref())?;
    let list = rows(&s.db, f.state.as_deref(), None, after, limit).await?;
    let mut items = match list {
        Value::Array(items) => items,
        _ => Vec::new(),
    };
    items.iter_mut().for_each(add_split);
    Ok(paged(items, limit, |r| json_row_cursor(r, "created_at", "id")))
}

/// Adds gross / withholding / net to a payout row. `amount` is the gross settlement total.
fn add_split(p: &mut Value) {
    let split = domain::tax::payout_withholding(p["tax_type"].as_str().unwrap_or("untracked"), domain::Won(p["amount"].as_i64().unwrap_or(0)));
    p["income_tax"] = json!(split.income_tax.0);
    p["local_tax"] = json!(split.local_tax.0);
    p["net"] = json!(split.net.0);
}

#[derive(Deserialize)]
pub struct TaxTypeBody {
    tax_type: String,
}

/// Owner classifies a partner for withholding. Affects payouts created after this, never ones already made.
pub async fn set_tax_type(AxState(s): AxState<AppState>, Admin(a): Admin, Path(pro): Path<Uuid>, Json(b): Json<TaxTypeBody>) -> ApiResult<Json<Value>> {
    if !matches!(b.tax_type.as_str(), "freelancer" | "business") {
        return Err(ApiError::BadRequest("tax_type"));
    }
    let n = sqlx::query("UPDATE pros SET tax_type = $2 WHERE id = $1")
        .bind(pro)
        .bind(&b.tax_type)
        .execute(&s.db)
        .await?;
    if n.rows_affected() == 0 {
        return Err(ApiError::NotFound);
    }
    audit(&s.db, "staff", Some(a.id), "pro.tax_type", &pro.to_string(), json!({ "tax_type": b.tax_type })).await?;
    Ok(Json(json!({ "tax_type": b.tax_type })))
}

/// Creates one requested payout per pro for everything due by the date. Future dates are refused.
pub async fn run_payouts(AxState(s): AxState<AppState>, Admin(a): Admin, Json(r): Json<RunPayouts>) -> ApiResult<Json<Value>> {
    live_admin(&s, a.id).await?;
    if r.date > today_kst() {
        return Err(ApiError::BadRequest("future_date"));
    }
    let mut tx = s.db.begin().await?;
    sqlx::query("SELECT pg_advisory_xact_lock(hashtext('payout_run'))").execute(&mut *tx).await?;
    let ids: Vec<Uuid> = sqlx::query_scalar(CREATE_SQL)
        .bind(r.date)
        .bind(mode_str(s.providers.payout_mode()))
        .fetch_all(&mut *tx)
        .await?;
    tx.commit().await?;
    audit(
        &s.db,
        "staff",
        Some(a.id),
        "payout.request",
        &r.date.to_string(),
        json!({ "payouts": ids.len() }),
    )
    .await?;
    Ok(Json(rows(&s.db, None, Some(&ids), (None, None), BY_IDS_LIMIT).await?))
}

/// Money actions check the role stored now: a demoted or deactivated owner's token lives on for its TTL.
async fn live_admin(s: &AppState, id: Uuid) -> ApiResult<()> {
    if live_staff_role(&s.db, id).await? == Role::StaffAdmin {
        Ok(())
    } else {
        Err(ApiError::Forbidden)
    }
}

/// Bank details for a manual transfer. Owner only; every reveal is audit-logged and never cached.
pub async fn reveal_account(AxState(s): AxState<AppState>, Admin(a): Admin, Path(id): Path<Uuid>) -> ApiResult<Response> {
    live_admin(&s, a.id).await?;
    let (bank, holder, enc, gross, tax_type): (String, String, String, i64, String) =
        sqlx::query_as("SELECT bank, holder, account_enc, amount, tax_type FROM payouts WHERE id = $1")
            .bind(id)
            .fetch_one(&s.db)
            .await?;
    let account = crypto::decrypt(&s.config.data_key, crypto::aad::PAYOUT_ACCOUNT, &enc).ok_or(ApiError::Internal("cannot decrypt payout account".into()))?;
    audit(&s.db, "staff", Some(a.id), "payout.reveal", &id.to_string(), json!({})).await?;
    // `amount` is what to transfer (net of withholding); `gross` and the taxes are shown for the record.
    let split = domain::tax::payout_withholding(&tax_type, domain::Won(gross));
    let body = Json(json!({
        "bank": bank,
        "holder": holder,
        "account": account,
        "amount": split.net.0,
        "gross": gross,
        "income_tax": split.income_tax.0,
        "local_tax": split.local_tax.0,
    }));
    Ok(([(header::CACHE_CONTROL, "no-store")], body).into_response())
}

/// POST /settlements/payouts/{id}/{action}: send | confirm | fail | retry | sync.
pub async fn act(
    AxState(s): AxState<AppState>,
    Admin(a): Admin,
    Path((id, action)): Path<(Uuid, String)>,
    Json(b): Json<ActionBody>,
) -> ApiResult<Json<Value>> {
    live_admin(&s, a.id).await?;
    let outcome = match action.as_str() {
        "send" => send(&s, id).await?,
        "confirm" => step(&s, id, Owner::Confirm).await?,
        "fail" => {
            let reason = require_reason(b.reason)?;
            step(&s, id, Owner::Fail(reason)).await?
        }
        "retry" => step(&s, id, Owner::Retry).await?,
        "sync" => sync(&s, id).await?,
        _ => return Err(ApiError::NotFound),
    };
    audit(
        &s.db,
        "staff",
        Some(a.id),
        &format!("payout.{action}"),
        &id.to_string(),
        json!({ "state": outcome.as_str() }),
    )
    .await?;
    if outcome == State::Paid {
        notify_paid(&s, id).await;
    }
    Ok(Json(json!({ "id": id, "state": outcome.as_str() })))
}

fn require_reason(r: Option<String>) -> ApiResult<String> {
    let r = r.unwrap_or_default().trim().to_string();
    if r.is_empty() || r.chars().count() > REASON_MAX {
        return Err(ApiError::BadRequest("reason_required"));
    }
    Ok(r)
}

/// Owner-driven steps. Each one is valid only from one state and for one provider mode.
enum Owner {
    /// Manual transfer done (requested -> paid).
    Confirm,
    /// Owner gives up on a transfer that was never sent (requested -> failed).
    Fail(String),
    /// Re-queue a failed payout (failed -> requested).
    Retry,
}

#[derive(Deserialize)]
pub struct SellerInput {
    /// `individual` (name only) or `company` (representative and business registration number).
    pub business_type: String,
    pub name: Option<String>,
    pub representative: Option<String>,
    pub registration_no: Option<String>,
    pub email: String,
    pub phone: String,
}

/// Builds the Toss seller draft. The bank account is the pro's verified payout account, not typed again.
/// The seller id is per revision, so a re-registration after an account change gets a new `refSellerId`.
fn seller_draft(pro: Uuid, rev: i32, b: &SellerInput, bank_code: &'static str, account: &str, holder: &str) -> ApiResult<adapter::SellerDraft> {
    let text = |v: &str| v.trim().to_string();
    let email = text(&b.email);
    let phone: String = b.phone.chars().filter(|c| c.is_ascii_digit()).collect();
    if !email.contains('@') || !(10..=11).contains(&phone.len()) {
        return Err(ApiError::BadRequest("invalid_contact"));
    }
    let business = match b.business_type.as_str() {
        "individual" => {
            let name = text(b.name.as_deref().unwrap_or_default());
            if name.is_empty() {
                return Err(ApiError::BadRequest("invalid_name"));
            }
            adapter::Business::Individual { name, email, phone }
        }
        "company" => {
            let representative = text(b.representative.as_deref().unwrap_or_default());
            let registration_no: String = b
                .registration_no
                .as_deref()
                .unwrap_or_default()
                .chars()
                .filter(|c| c.is_ascii_digit())
                .collect();
            if representative.is_empty() || registration_no.len() != 10 {
                return Err(ApiError::BadRequest("invalid_business"));
            }
            let name = b.name.as_deref().map(text).filter(|n| !n.is_empty());
            adapter::Business::Company {
                name,
                representative,
                registration_no,
                email,
                phone,
            }
        }
        _ => return Err(ApiError::BadRequest("invalid_business_type")),
    };
    let ref_id = format!("mk{}r{rev}", &pro.simple().to_string()[..12]);
    if !adapter::REF_SELLER_ID_RANGE.contains(&ref_id.len()) || account.len() > 14 || holder.chars().count() > 50 {
        return Err(ApiError::BadRequest("invalid_account"));
    }
    Ok(adapter::SellerDraft {
        ref_id,
        business,
        bank_code,
        account: account.to_string(),
        holder: holder.to_string(),
    })
}

/// Registers a pro as a Toss seller, or re-registers after the payout account changed. Stores the seller id,
/// its status and the account fingerprint that payouts are checked against.
pub async fn register_seller(AxState(s): AxState<AppState>, Admin(a): Admin, Path(pro): Path<Uuid>, Json(b): Json<SellerInput>) -> ApiResult<Json<Value>> {
    if s.providers.payout_mode() != PayoutMode::Toss {
        return Err(ApiError::Conflict("payout_provider"));
    }
    let (bank, account_enc, holder): (String, String, String) =
        sqlx::query_as("SELECT bank, account_enc, holder FROM payout_accounts WHERE pro_id = $1 AND verified_at IS NOT NULL")
            .bind(pro)
            .fetch_optional(&s.db)
            .await?
            .ok_or(ApiError::Conflict("payout_account_unverified"))?;
    let account =
        crypto::decrypt(&s.config.data_key, crypto::aad::PAYOUT_ACCOUNT, &account_enc).ok_or(ApiError::Internal("cannot decrypt payout account".into()))?;
    let bank_code = adapter::bank_code(&bank).ok_or(ApiError::Conflict("unsupported_bank"))?;
    let rev: i32 = sqlx::query_scalar("UPDATE pros SET toss_seller_rev = toss_seller_rev + 1 WHERE id = $1 RETURNING toss_seller_rev")
        .bind(pro)
        .fetch_optional(&s.db)
        .await?
        .ok_or(ApiError::NotFound)?;
    let draft = seller_draft(pro, rev, &b, bank_code, &account, &holder)?;
    let (seller_id, status) = s.providers.register_seller(&draft).await.map_err(|e| match e {
        ProviderError::Declined(_) => ApiError::Conflict("seller_declined"),
        _ => ApiError::Unavailable("provider_unreachable"),
    })?;
    let fp = adapter::account_fingerprint(bank_code, &account, &holder);
    sqlx::query("UPDATE pros SET toss_seller_id = $2, toss_seller_status = $3, toss_seller_fp = $4 WHERE id = $1")
        .bind(pro)
        .bind(&seller_id)
        .bind(&status)
        .bind(&fp)
        .execute(&s.db)
        .await?;
    audit(
        &s.db,
        a.role.as_str(),
        Some(a.id),
        "payout.seller",
        &pro.to_string(),
        json!({ "status": status, "rev": rev }),
    )
    .await?;
    Ok(Json(json!({ "seller_status": status, "rev": rev })))
}

/// What actually moves: the gross settlement total less the withholding snapshotted on the payout.
fn transfer_amount(row: &Row) -> i64 {
    domain::tax::payout_withholding(&row.tax_type, domain::Won(row.amount)).net.0
}

async fn lock(tx: &mut Transaction<'_, Postgres>, id: Uuid) -> ApiResult<Row> {
    Ok(sqlx::query_as(
        "SELECT pro_id, payout_date, amount, tax_type, provider, state, bank, holder, account_enc, idempotency_key, provider_transfer_id, failure_reason
         FROM payouts WHERE id = $1 FOR UPDATE",
    )
    .bind(id)
    .fetch_one(&mut **tx)
    .await?)
}

/// Money may only move for the amount the settlements still add up to. A booking cancelled or
/// changed after the batch was made must not be paid through it.
async fn check_amount(tx: &mut Transaction<'_, Postgres>, id: Uuid, amount: i64) -> ApiResult<()> {
    let sum: i64 = sqlx::query_scalar("SELECT COALESCE(sum(net), 0)::bigint FROM settlements WHERE payout_id = $1 AND state = 'pending'")
        .bind(id)
        .fetch_one(&mut **tx)
        .await?;
    if sum != amount {
        return Err(ApiError::Conflict("payout_amount_changed"));
    }
    Ok(())
}

/// Writes a transition. The `state` guard in each statement is a second check behind the row lock.
async fn write(tx: &mut Transaction<'_, Postgres>, id: Uuid, to: State, failure: Option<&str>) -> ApiResult<()> {
    let r = match to {
        State::Paid => {
            sqlx::query("UPDATE settlements SET state = 'paid', paid_at = now() WHERE payout_id = $1 AND state = 'pending'")
                .bind(id)
                .execute(&mut **tx)
                .await?;
            sqlx::query("UPDATE payouts SET state = 'paid', paid_at = now(), updated_at = now(), failure_reason = NULL WHERE id = $1 AND state IN ('requested', 'sent')")
                .bind(id)
                .execute(&mut **tx)
                .await?
        }
        State::Failed => {
            sqlx::query("UPDATE payouts SET state = 'failed', failure_reason = $2, updated_at = now() WHERE id = $1 AND state IN ('requested', 'sent')")
                .bind(id)
                .bind(failure)
                .execute(&mut **tx)
                .await?
        }
        State::Requested => {
            sqlx::query("UPDATE payouts SET state = 'requested', failure_reason = NULL, updated_at = now() WHERE id = $1 AND state = 'failed'")
                .bind(id)
                .execute(&mut **tx)
                .await?
        }
        State::Sent => return Err(ApiError::Internal("sent is written by send()".into())),
    };
    if r.rows_affected() != 1 {
        return Err(ApiError::Conflict("payout_state"));
    }
    Ok(())
}

async fn step(s: &AppState, id: Uuid, step: Owner) -> ApiResult<State> {
    let mut tx = s.db.begin().await?;
    let row = lock(&mut tx, id).await?;
    let (action, to, failure) = match &step {
        Owner::Confirm => {
            if row.provider != "manual" {
                return Err(ApiError::Conflict("payout_provider"));
            }
            (Action::Confirm, State::Paid, None)
        }
        Owner::Fail(reason) => {
            if row.state() != State::Requested {
                return Err(ApiError::Conflict("payout_state"));
            }
            (Action::Reject, State::Failed, Some(reason.as_str()))
        }
        Owner::Retry => (Action::Retry, State::Requested, None),
    };
    crate::payout::next(row.state(), action).ok_or(ApiError::Conflict("payout_state"))?;
    if to == State::Paid {
        check_amount(&mut tx, id, row.amount).await?;
    }
    write(&mut tx, id, to, failure).await?;
    tx.commit().await?;
    Ok(to)
}

/// Sends a Toss transfer. The idempotency key is the payout's own key, so a retry after a timeout
/// cannot create a second transfer. A definite decline rotates the key before the payout is retried.
async fn send(s: &AppState, id: Uuid) -> ApiResult<State> {
    let mut tx = s.db.begin().await?;
    let row = lock(&mut tx, id).await?;
    if row.provider != "toss" {
        return Err(ApiError::Conflict("payout_provider"));
    }
    crate::payout::next(row.state(), Action::Accept).ok_or(ApiError::Conflict("payout_state"))?;
    check_amount(&mut tx, id, row.amount).await?;
    let bank_code = adapter::bank_code(&row.bank).ok_or(ApiError::Conflict("unsupported_bank"))?;
    let account =
        crypto::decrypt(&s.config.data_key, crypto::aad::PAYOUT_ACCOUNT, &row.account_enc).ok_or(ApiError::Internal("cannot decrypt payout account".into()))?;
    // Toss pays the seller's registered account. Refuse when that is not the account this payout was approved for.
    let (seller_id, seller_fp): (Option<String>, Option<String>) = sqlx::query_as("SELECT toss_seller_id, toss_seller_fp FROM pros WHERE id = $1")
        .bind(row.pro_id)
        .fetch_one(&mut *tx)
        .await?;
    let seller_id = seller_id.ok_or(ApiError::Conflict("seller_required"))?;
    if seller_fp.as_deref() != Some(adapter::account_fingerprint(bank_code, &account, &row.holder).as_str()) {
        return Err(ApiError::Conflict("seller_account_changed"));
    }
    let transfer = adapter::Transfer {
        amount: transfer_amount(&row),
        bank_code,
        account,
        holder: row.holder.clone(),
        memo: payout_memo(&super::setup::brand_name(&s.db).await, row.payout_date),
    };
    match s.providers.send_transfer(&row.idempotency_key, &id.to_string(), &seller_id, &transfer).await {
        Ok(transfer_id) => {
            let r = sqlx::query(
                "UPDATE payouts SET state = 'sent', provider_transfer_id = $2, attempts = attempts + 1, failure_reason = NULL, updated_at = now()
                 WHERE id = $1 AND state = 'requested'",
            )
            .bind(id)
            .bind(transfer_id)
            .execute(&mut *tx)
            .await?;
            if r.rows_affected() != 1 {
                return Err(ApiError::Conflict("payout_state"));
            }
            tx.commit().await?;
            Ok(State::Sent)
        }
        Err(ProviderError::Declined(reason)) => {
            // Definitely not transferred: a fresh key makes the next retry a new transfer.
            sqlx::query(
                "UPDATE payouts SET state = 'failed', failure_reason = $2, attempts = attempts + 1, idempotency_key = gen_random_uuid()::text, updated_at = now()
                 WHERE id = $1 AND state = 'requested'",
            )
            .bind(id)
            .bind(truncate(&reason))
            .execute(&mut *tx)
            .await?;
            tx.commit().await?;
            Ok(State::Failed)
        }
        Err(e) => {
            // Ambiguous (timeout, 5xx): the transfer may exist. Stay requested with the same key.
            sqlx::query("UPDATE payouts SET failure_reason = $2, attempts = attempts + 1, updated_at = now() WHERE id = $1 AND state = 'requested'")
                .bind(id)
                .bind(truncate(&e.to_string()))
                .execute(&mut *tx)
                .await?;
            tx.commit().await?;
            Err(ApiError::Unavailable("provider_unreachable"))
        }
    }
}

/// Asks the provider about a Toss transfer that may already exist and records paid or failed.
/// Pending leaves the row as it was. Never sends money. Shared by the owner's button and the background pass.
pub(crate) async fn sync(s: &AppState, id: Uuid) -> ApiResult<State> {
    let mut tx = s.db.begin().await?;
    let row = lock(&mut tx, id).await?;
    if row.provider != "toss" {
        return Err(ApiError::Conflict("payout_provider"));
    }
    if !row.awaiting_provider() {
        return Err(ApiError::Conflict("payout_state"));
    }
    // Toss looks payouts up by its own id (returned on create), not by our refPayoutId. A send that
    // ended ambiguously has no id yet, so there is nothing to ask about.
    let Some(provider_id) = row.provider_transfer_id.clone() else {
        return Ok(row.state());
    };
    match s.providers.transfer_status(&provider_id).await? {
        adapter::TransferStatus::Pending => Ok(row.state()),
        adapter::TransferStatus::Paid => {
            check_amount(&mut tx, id, row.amount).await?;
            write(&mut tx, id, State::Paid, None).await?;
            tx.commit().await?;
            Ok(State::Paid)
        }
        adapter::TransferStatus::Failed(reason) => {
            // The provider confirms no money moved: rotate the key so the retry is a new transfer.
            let r = sqlx::query(
                "UPDATE payouts SET state = 'failed', failure_reason = $2, idempotency_key = gen_random_uuid()::text, updated_at = now()
                 WHERE id = $1 AND state IN ('requested', 'sent')",
            )
            .bind(id)
            .bind(truncate(&reason))
            .execute(&mut *tx)
            .await?;
            if r.rows_affected() != 1 {
                return Err(ApiError::Conflict("payout_state"));
            }
            tx.commit().await?;
            Ok(State::Failed)
        }
    }
}

/// True when a booking's pending settlements sit in a Toss batch that may already be at the provider.
/// Cancelling such a booking would pay for a cancelled job, so the cancel is refused up front.
pub(crate) async fn in_transfer(db: &PgPool, booking: Uuid) -> Result<bool, sqlx::Error> {
    sqlx::query_scalar(
        "SELECT EXISTS (SELECT 1 FROM settlements st JOIN payouts p ON p.id = st.payout_id
           WHERE st.booking_id = $1 AND st.state = 'pending' AND NOT (p.state = 'requested' AND p.attempts = 0 AND p.failure_reason IS NULL))",
    )
    .bind(booking)
    .fetch_one(db)
    .await
}

/// Takes a cancelled booking's pending settlements out of their batch. A batch nobody has sent is
/// shrunk to what remains (deleted when nothing does), so its amount still matches its settlements.
/// Refuses if such a batch was meanwhile sent. Call inside the cancel transaction.
pub(crate) async fn detach_booking(tx: &mut Transaction<'_, Postgres>, booking: Uuid) -> ApiResult<()> {
    let batches: Vec<(Uuid, String, i32, Option<String>)> = sqlx::query_as(
        "SELECT p.id, p.state, p.attempts, p.failure_reason FROM payouts p
         WHERE p.id IN (SELECT payout_id FROM settlements WHERE booking_id = $1 AND state = 'pending' AND payout_id IS NOT NULL)
         ORDER BY p.id FOR UPDATE",
    )
    .bind(booking)
    .fetch_all(&mut **tx)
    .await?;
    if batches
        .iter()
        .any(|(_, state, attempts, failure)| state != "requested" || *attempts > 0 || failure.is_some())
    {
        return Err(ApiError::Conflict("settlement_in_transfer"));
    }
    sqlx::query("UPDATE settlements SET payout_id = NULL WHERE booking_id = $1 AND state = 'pending' AND payout_id IS NOT NULL")
        .bind(booking)
        .execute(&mut **tx)
        .await?;
    let ids: Vec<Uuid> = batches.into_iter().map(|b| b.0).collect();
    sqlx::query("DELETE FROM payouts WHERE id = ANY($1) AND NOT EXISTS (SELECT 1 FROM settlements WHERE payout_id = payouts.id)")
        .bind(&ids)
        .execute(&mut **tx)
        .await?;
    sqlx::query(
        "UPDATE payouts p SET amount = t.amount, items = t.items, updated_at = now()
         FROM (SELECT payout_id, sum(net)::bigint AS amount, count(*)::int AS items FROM settlements
               WHERE payout_id = ANY($1) AND state = 'pending' GROUP BY payout_id) t
         WHERE p.id = t.payout_id",
    )
    .bind(&ids)
    .execute(&mut **tx)
    .await?;
    Ok(())
}

fn truncate(s: &str) -> String {
    s.chars().take(REASON_MAX).collect()
}

pub(crate) async fn notify_paid(s: &AppState, id: Uuid) {
    let Ok((pro_id, amount)) = sqlx::query_as::<_, (Uuid, i64)>("SELECT pro_id, amount FROM payouts WHERE id = $1")
        .bind(id)
        .fetch_one(&s.db)
        .await
    else {
        return;
    };
    crate::util::best_effort(
        "notify",
        notify(
            s,
            Recipient::Pro(pro_id),
            "settlement.paid",
            "정산 완료",
            &format!("{amount}원"),
            json!({ "total": amount }),
        ),
    )
    .await;
}

/// Text on the partner's bank statement. Toss keeps the first 7 characters, so the shop name leads.
fn payout_memo(brand: &str, payout_date: NaiveDate) -> String {
    format!("{brand} 정산 {payout_date}")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn memo_leads_with_the_shop_name() {
        let date = NaiveDate::from_ymd_opt(2026, 11, 18).expect("date");
        assert_eq!(payout_memo("다해", date), "다해 정산 2026-11-18");
        assert_eq!(payout_memo("우리집청소", date), "우리집청소 정산 2026-11-18");
    }
}
