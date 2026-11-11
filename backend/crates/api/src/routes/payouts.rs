//! Console: partner payouts. requested -> sent -> paid, or failed (retryable). Transitions live in
//! [`crate::payout`]; every change runs in one transaction on a locked row, so a payout can be paid
//! at most once and a settlement is marked paid only together with its payout.

use super::audit;
use crate::{
    auth::Admin,
    crypto,
    error::{ApiError, ApiResult},
    integrations::PayoutMode,
    payout::{Action, State},
    providers::{ProviderError, payout as adapter},
    realtime::{Recipient, notify},
    state::AppState,
};
use axum::{
    Json,
    extract::{Path, State as AxState},
};
use chrono::NaiveDate;
use serde::Deserialize;
use serde_json::{Value, json};
use sqlx::{PgPool, Postgres, Transaction};
use uuid::Uuid;

const REASON_MAX: usize = 200;

/// Settlements due by `date` that no payout covers yet, grouped per verified pro. Runs under an
/// advisory lock, so two clicks can't create two payouts for the same settlements.
const CREATE_SQL: &str = "
WITH due AS (
  SELECT st.id AS settlement_id, st.pro_id, st.net FROM settlements st
  WHERE st.state = 'pending' AND st.payout_date <= $1 AND st.payout_id IS NULL
    AND st.pro_id IN (SELECT pro_id FROM payout_accounts WHERE verified_at IS NOT NULL)
),
sums AS (SELECT pro_id, sum(net)::bigint AS amount, count(*)::int AS items FROM due GROUP BY pro_id),
ins AS (
  INSERT INTO payouts (pro_id, payout_date, amount, items, provider, state, bank, holder, account_enc, account_last4)
  SELECT s.pro_id, $1, s.amount, s.items, $2, 'requested', pa.bank, pa.holder, pa.account_enc, pa.account_last4
  FROM sums s JOIN payout_accounts pa ON pa.pro_id = s.pro_id
  RETURNING id, pro_id
),
linked AS (
  UPDATE settlements st SET payout_id = ins.id FROM due d JOIN ins ON ins.pro_id = d.pro_id
  WHERE st.id = d.settlement_id AND st.payout_id IS NULL
  RETURNING st.id
)
SELECT id FROM ins";

/// Payout rows for the console. Account numbers are never included here (see `reveal_account`).
const LIST_SQL: &str = "SELECT COALESCE(jsonb_agg(x), '[]') FROM (
  SELECT p.id, p.pro_id, pr.name AS pro_name, pr.team_name, p.payout_date, p.amount, p.items, p.provider, p.state,
         p.bank, p.account_last4, p.attempts, p.failure_reason, p.provider_transfer_id, p.created_at, p.paid_at
  FROM payouts p JOIN pros pr ON pr.id = p.pro_id
  WHERE ($1::text IS NULL OR p.state = $1) AND ($2::uuid[] IS NULL OR p.id = ANY($2))
  ORDER BY p.created_at DESC LIMIT 200) x";

#[derive(Deserialize)]
pub struct RunPayouts {
    date: NaiveDate,
}

#[derive(Deserialize)]
pub struct PayoutFilter {
    state: Option<String>,
}

#[derive(Deserialize, Default)]
pub struct ActionBody {
    reason: Option<String>,
}

#[derive(sqlx::FromRow)]
struct Row {
    payout_date: NaiveDate,
    amount: i64,
    provider: String,
    state: String,
    bank: String,
    holder: String,
    account_enc: String,
    idempotency_key: String,
}

impl Row {
    fn state(&self) -> State {
        State::parse(&self.state).unwrap_or(State::Failed)
    }
}

fn mode_str(m: PayoutMode) -> &'static str {
    match m {
        PayoutMode::Manual => "manual",
        PayoutMode::Toss => "toss",
    }
}

async fn rows(db: &PgPool, state: Option<&str>, ids: Option<&[Uuid]>) -> ApiResult<Value> {
    Ok(sqlx::query_scalar(LIST_SQL).bind(state).bind(ids).fetch_one(db).await?)
}

pub async fn list_payouts(AxState(s): AxState<AppState>, _a: Admin, axum::extract::Query(f): axum::extract::Query<PayoutFilter>) -> ApiResult<Json<Value>> {
    Ok(Json(rows(&s.db, f.state.as_deref(), None).await?))
}

/// Creates one requested payout per pro for everything due by the date.
pub async fn run_payouts(AxState(s): AxState<AppState>, Admin(a): Admin, Json(r): Json<RunPayouts>) -> ApiResult<Json<Value>> {
    let mut tx = s.db.begin().await?;
    sqlx::query("SELECT pg_advisory_xact_lock(hashtext('payout_run'))").execute(&mut *tx).await?;
    let ids: Vec<Uuid> = sqlx::query_scalar(CREATE_SQL)
        .bind(r.date)
        .bind(mode_str(s.providers.payout_mode()))
        .fetch_all(&mut *tx)
        .await?;
    tx.commit().await?;
    audit(&s.db, "staff", Some(a.id), "payout.request", &r.date.to_string(), json!({ "payouts": ids.len() })).await?;
    Ok(Json(rows(&s.db, None, Some(&ids)).await?))
}

/// Bank details for a manual transfer. Owner only; every reveal is audit-logged.
pub async fn reveal_account(AxState(s): AxState<AppState>, Admin(a): Admin, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    let (bank, holder, enc, amount): (String, String, String, i64) =
        sqlx::query_as("SELECT bank, holder, account_enc, amount FROM payouts WHERE id = $1").bind(id).fetch_one(&s.db).await?;
    let account = crypto::decrypt(&s.config.data_key, &enc).ok_or(ApiError::Internal("cannot decrypt payout account".into()))?;
    audit(&s.db, "staff", Some(a.id), "payout.reveal", &id.to_string(), json!({})).await?;
    Ok(Json(json!({ "bank": bank, "holder": holder, "account": account, "amount": amount })))
}

/// POST /settlements/payouts/{id}/{action}: send | confirm | fail | retry | sync.
pub async fn act(AxState(s): AxState<AppState>, Admin(a): Admin, Path((id, action)): Path<(Uuid, String)>, Json(b): Json<ActionBody>) -> ApiResult<Json<Value>> {
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
    audit(&s.db, "staff", Some(a.id), &format!("payout.{action}"), &id.to_string(), json!({ "state": outcome.as_str() })).await?;
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

async fn lock(tx: &mut Transaction<'_, Postgres>, id: Uuid) -> ApiResult<Row> {
    Ok(sqlx::query_as(
        "SELECT payout_date, amount, provider, state, bank, holder, account_enc, idempotency_key
         FROM payouts WHERE id = $1 FOR UPDATE",
    )
    .bind(id)
    .fetch_one(&mut **tx)
    .await?)
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
        State::Failed => sqlx::query("UPDATE payouts SET state = 'failed', failure_reason = $2, updated_at = now() WHERE id = $1 AND state IN ('requested', 'sent')")
            .bind(id)
            .bind(failure)
            .execute(&mut **tx)
            .await?,
        State::Requested => sqlx::query("UPDATE payouts SET state = 'requested', failure_reason = NULL, updated_at = now() WHERE id = $1 AND state = 'failed'")
            .bind(id)
            .execute(&mut **tx)
            .await?,
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
    let bank_code = adapter::bank_code(&row.bank).ok_or(ApiError::Conflict("unsupported_bank"))?;
    let account = crypto::decrypt(&s.config.data_key, &row.account_enc).ok_or(ApiError::Internal("cannot decrypt payout account".into()))?;
    let transfer = adapter::Transfer {
        amount: row.amount,
        bank_code,
        account,
        holder: row.holder.clone(),
        memo: format!("말끔 정산 {}", row.payout_date),
    };
    match s.providers.send_transfer(&row.idempotency_key, &id.to_string(), &transfer).await {
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

/// Asks the provider about a sent transfer and records paid or failed. Pending leaves it sent.
async fn sync(s: &AppState, id: Uuid) -> ApiResult<State> {
    let mut tx = s.db.begin().await?;
    let row = lock(&mut tx, id).await?;
    if row.provider != "toss" {
        return Err(ApiError::Conflict("payout_provider"));
    }
    if row.state() != State::Sent {
        return Err(ApiError::Conflict("payout_state"));
    }
    let status = s.providers.transfer_status(&id.to_string()).await?;
    let to = match status {
        adapter::TransferStatus::Pending => return Ok(State::Sent),
        adapter::TransferStatus::Paid => State::Paid,
        adapter::TransferStatus::Failed(reason) => {
            write(&mut tx, id, State::Failed, Some(&truncate(&reason))).await?;
            tx.commit().await?;
            return Ok(State::Failed);
        }
    };
    write(&mut tx, id, to, None).await?;
    tx.commit().await?;
    Ok(to)
}

fn truncate(s: &str) -> String {
    s.chars().take(REASON_MAX).collect()
}

async fn notify_paid(s: &AppState, id: Uuid) {
    let Ok((pro_id, amount)) = sqlx::query_as::<_, (Uuid, i64)>("SELECT pro_id, amount FROM payouts WHERE id = $1").bind(id).fetch_one(&s.db).await else {
        return;
    };
    crate::util::best_effort(
        "notify",
        notify(s, Recipient::Pro(pro_id), "settlement.paid", "정산 완료", &format!("{amount}원"), json!({ "total": amount })),
    )
    .await;
}
