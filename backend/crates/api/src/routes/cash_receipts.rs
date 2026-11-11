//! 현금영수증 (cash receipts). The customer asks at checkout (`PUT /checkouts/{id}/cash-receipt`), the receipt is
//! issued when the payment settles, cancelled on a full refund, and the owner can list and reissue failures.
//! Off unless `PORTONE_CASH_RECEIPTS=1`. Failures never fail the payment: they are recorded for the console.
//! Provider shapes: providers/portone_cash_receipt.rs (SANDBOX-VERIFY before enabling).

use super::{
    audit,
    checkouts::load_owned,
    finance::{PeriodQuery, resolve},
};
use crate::{
    auth::{Admin, Customer},
    config::PortOne,
    crypto,
    error::{ApiError, ApiResult},
    providers::portone_cash_receipt::{self as pcr, Issued},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Path, Query, State},
    routing::{get, post, put},
};
use chrono::{DateTime, NaiveDate, Utc};
use domain::cash_receipt::{self as rules, cash_eligible};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use sqlx::{FromRow, PgPool};
use uuid::Uuid;

/// Portone settings when cash receipts are switched on and keyed; otherwise a 503 the console can explain.
fn live(s: &AppState) -> ApiResult<PortOne> {
    let p = s.providers.integ().portone.clone();
    if !p.cash_receipts {
        return Err(ApiError::Unavailable("cash_receipts_disabled"));
    }
    if p.api_secret.is_none() {
        return Err(ApiError::Unavailable("provider_not_configured"));
    }
    Ok(p)
}

#[derive(Deserialize)]
struct RequestBody {
    /// PERSONAL (소득공제용, phone number) or CORPORATE (지출증빙용, business registration number).
    purpose: String,
    identity: String,
}

#[derive(Serialize, FromRow)]
pub struct ReceiptView {
    id: Uuid,
    checkout_id: Uuid,
    payment_id: Option<Uuid>,
    purpose: String,
    identity_last4: String,
    state: String,
    issue_number: Option<String>,
    receipt_url: Option<String>,
    failure_reason: Option<String>,
    created_at: DateTime<Utc>,
    issued_at: Option<DateTime<Utc>>,
}

const VIEW_COLUMNS: &str = "id, checkout_id, payment_id, purpose, identity_last4, state, issue_number, receipt_url, failure_reason, created_at, issued_at";

async fn view(db: &PgPool, id: Uuid) -> ApiResult<ReceiptView> {
    sqlx::query_as(&format!("SELECT {VIEW_COLUMNS} FROM cash_receipts WHERE id = $1"))
        .bind(id)
        .fetch_optional(db)
        .await?
        .ok_or(ApiError::NotFound)
}

/// `PUT /checkouts/{id}/cash-receipt`: replaces any earlier pending request for the checkout. Only while unpaid.
async fn request(State(s): State<AppState>, Customer(a): Customer, Path(checkout): Path<Uuid>, Json(b): Json<RequestBody>) -> ApiResult<Json<ReceiptView>> {
    live(&s)?;
    let ck = load_owned(&s.db, a.id, checkout).await?;
    if ck.status != "pending" && ck.status != "awaiting_deposit" {
        return Err(ApiError::Conflict("checkout_not_open"));
    }
    let method: String = sqlx::query_scalar("SELECT method FROM checkouts WHERE id = $1").bind(checkout).fetch_one(&s.db).await?;
    if !cash_eligible(&method) {
        return Err(ApiError::BadRequest("cash_receipt_method"));
    }
    let (purpose, identity_type, identity) = match b.purpose.as_str() {
        "PERSONAL" => ("PERSONAL", "PHONE", rules::normalize_phone(&b.identity)?),
        "CORPORATE" => ("CORPORATE", "BUSINESS", rules::normalize_business_number(&b.identity)?),
        _ => return Err(ApiError::BadRequest("cash_receipt_purpose")),
    };
    let enc = crypto::encrypt(&s.config.data_key, &identity);
    let last4 = &identity[identity.len() - 4..];
    let mut tx = s.db.begin().await?;
    sqlx::query("DELETE FROM cash_receipts WHERE checkout_id = $1 AND state = 'pending'").bind(checkout).execute(&mut *tx).await?;
    let id: Uuid = sqlx::query_scalar(
        "INSERT INTO cash_receipts (checkout_id, purpose, identity_type, identity_enc, identity_last4, state)
         VALUES ($1, $2, $3, $4, $5, 'pending') RETURNING id",
    )
    .bind(checkout)
    .bind(purpose)
    .bind(identity_type)
    .bind(enc)
    .bind(last4)
    .fetch_one(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(Json(view(&s.db, id).await?))
}

#[derive(FromRow)]
struct Job {
    purpose: String,
    identity_enc: String,
    provider_tx_id: Option<String>,
    amount: i64,
    method: String,
}

const JOB_SQL: &str = "SELECT cr.purpose, cr.identity_enc, p.provider_tx_id, p.amount, ck.method
    FROM cash_receipts cr
    JOIN payments p ON p.id = cr.payment_id
    JOIN checkouts ck ON ck.id = cr.checkout_id
    WHERE cr.id = $1";

/// One issue attempt. The result is recorded on the row: `issued` with the number, or `failed` with the reason.
async fn issue_job(s: &AppState, id: Uuid) -> ApiResult<()> {
    let p = live(s)?;
    let job: Job = sqlx::query_as(JOB_SQL).bind(id).fetch_one(&s.db).await?;
    match attempt(s, &p, &job).await {
        Ok(Issued { issue_number, url }) => {
            sqlx::query(
                "UPDATE cash_receipts SET state = 'issued', issue_number = $2, receipt_url = $3, failure_reason = NULL,
                 attempts = attempts + 1, issued_at = now(), updated_at = now() WHERE id = $1",
            )
            .bind(id)
            .bind(issue_number)
            .bind(url)
            .execute(&s.db)
            .await?;
        }
        Err(reason) => {
            tracing::warn!(receipt = %id, %reason, "cash receipt issue failed");
            sqlx::query("UPDATE cash_receipts SET state = 'failed', failure_reason = $2, attempts = attempts + 1, updated_at = now() WHERE id = $1")
                .bind(id)
                .bind(reason)
                .execute(&s.db)
                .await?;
        }
    }
    Ok(())
}

async fn attempt(s: &AppState, p: &PortOne, job: &Job) -> Result<Issued, String> {
    let channel = p.channel_keys.get(&job.method).ok_or("no PortOne channel key for this payment method")?;
    let payment_id = job.provider_tx_id.as_deref().ok_or("payment has no provider transaction id")?;
    let identity = crypto::decrypt(&s.config.data_key, &job.identity_enc).ok_or("cannot decrypt receipt identity")?;
    let body = pcr::issue_body(p.store_id.clone(), payment_id, channel, job.purpose == "CORPORATE", &identity, job.amount);
    let secret = p.api_secret.as_deref().unwrap_or_default();
    pcr::issue(s.providers.http(), pcr::api_base(), secret, &body).await.map_err(|e| e.to_string())
}

/// Called after a checkout settles. Links the pending request to the payment and issues. Never fails the payment.
pub async fn on_settled(s: &AppState, checkout: Uuid, provider_tx_id: &str) {
    if live(s).is_err() {
        return;
    }
    let linked: Result<Option<(Uuid,)>, sqlx::Error> = sqlx::query_as(
        "UPDATE cash_receipts SET payment_id = (SELECT id FROM payments WHERE provider = 'portone' AND provider_tx_id = $2 LIMIT 1),
         updated_at = now() WHERE checkout_id = $1 AND state = 'pending' RETURNING id",
    )
    .bind(checkout)
    .bind(provider_tx_id)
    .fetch_optional(&s.db)
    .await;
    match linked {
        Ok(Some((id,))) => {
            if let Err(e) = issue_job(s, id).await {
                tracing::error!(error = %e, receipt = %id, "cash receipt job failed");
            }
        }
        Ok(None) => {}
        Err(e) => tracing::error!(error = %e, checkout = %checkout, "cash receipt link failed"),
    }
}

/// Called after a full refund. Cancels the issued receipt. A failed cancel is recorded, not raised:
/// the refund already happened and the owner resolves it from the console.
pub async fn on_full_refund(s: &AppState, payment: Uuid, provider_tx_id: &str) {
    let Ok(p) = live(s) else { return };
    let issued: Option<(Uuid,)> = match sqlx::query_as("SELECT id FROM cash_receipts WHERE payment_id = $1 AND state = 'issued'").bind(payment).fetch_optional(&s.db).await {
        Ok(v) => v,
        Err(e) => {
            tracing::error!(error = %e, payment = %payment, "cash receipt lookup failed");
            return;
        }
    };
    let Some((id,)) = issued else { return };
    let secret = p.api_secret.as_deref().unwrap_or_default();
    match pcr::cancel(s.providers.http(), pcr::api_base(), secret, provider_tx_id).await {
        Ok(()) => {
            let _ = sqlx::query("UPDATE cash_receipts SET state = 'cancelled', cancelled_at = now(), updated_at = now() WHERE id = $1")
                .bind(id)
                .execute(&s.db)
                .await;
        }
        Err(e) => {
            tracing::warn!(receipt = %id, error = %e, "cash receipt cancel failed");
            let _ = sqlx::query("UPDATE cash_receipts SET failure_reason = $2, updated_at = now() WHERE id = $1")
                .bind(id)
                .bind(e.to_string())
                .execute(&s.db)
                .await;
        }
    }
}

/// Owner list of receipts created in the period (identity shown as last four digits only).
async fn list(State(s): State<AppState>, Admin(_): Admin, Query(q): Query<PeriodQuery>) -> ApiResult<Json<Vec<ReceiptView>>> {
    let (from, to) = resolve(&q)?;
    let rows: Vec<ReceiptView> = sqlx::query_as(&format!(
        "SELECT {VIEW_COLUMNS} FROM cash_receipts WHERE (created_at AT TIME ZONE 'Asia/Seoul')::date BETWEEN $1 AND $2
         ORDER BY created_at DESC LIMIT 500"
    ))
    .bind(from)
    .bind(to)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}

/// `POST /finance/cash-receipts/{id}/reissue`: only for a failed issue.
async fn reissue(State(s): State<AppState>, Admin(a): Admin, Path(id): Path<Uuid>) -> ApiResult<Json<ReceiptView>> {
    live(&s)?;
    let state: String = sqlx::query_scalar("SELECT state FROM cash_receipts WHERE id = $1")
        .bind(id)
        .fetch_optional(&s.db)
        .await?
        .ok_or(ApiError::NotFound)?;
    if state != "failed" {
        return Err(ApiError::Conflict("not_reissuable"));
    }
    issue_job(&s, id).await?;
    audit(&s.db, "staff", Some(a.id), "cash_receipt.reissue", "cash_receipt", json!({ "id": id })).await?;
    Ok(Json(view(&s.db, id).await?))
}

/// Whether the app should offer receipt options. Carries no customer data, so it needs no login.
async fn options(State(s): State<AppState>) -> Json<Value> {
    Json(json!({ "cash_receipts": s.providers.integ().portone.cash_receipts }))
}

/// Customer routes, merged at the top level like the checkout routes.
pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/checkouts/{id}/cash-receipt", put(request))
        .route("/receipt-options", get(options))
}

/// Owner routes, merged under `/admin`.
pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/finance/cash-receipts", get(list))
        .route("/finance/cash-receipts/{id}/reissue", post(reissue))
}
