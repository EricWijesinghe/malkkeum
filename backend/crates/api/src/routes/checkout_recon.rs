//! Checkout recovery and listing: the reconciler pass (unfinished checkouts and queued refunds)
//! and the customer and console checkout lists. Settlement itself lives in `checkouts`.

use super::checkouts::{CHECKOUT_COLS, CheckoutRow, apply, find_by_id, refund_late};
use crate::{
    auth::{Customer, Staff},
    contract::{cursor_part, decode_cursor, encode_cursor, page_limit, paged, ts_key},
    error::{ApiError, ApiResult},
    providers::ProviderError,
    state::AppState,
    util::{QueuedRefund, REFUND_COLS, REFUND_LEASE_MINS, Refund, retry_refund},
};
use axum::{
    extract::{Query, State},
    response::Response,
};
use chrono::{DateTime, Duration, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;

/// Checkouts re-checked with the provider once per cooldown, and only after this much time.
const RECON_BATCH: i64 = 20;
const RECON_COOLDOWN_SECS: i64 = 300;
const RECON_MIN_AGE_SECS: i64 = 120;
const RECON_MAX_AGE_HOURS: i64 = 24;
const REFUND_BATCH: i64 = 20;

/// One reconciler pass: retry due refunds, sweep pending checkouts older than a day to 'expired',
/// then claim a batch of recent unfinished checkouts and settle each against the provider.
/// Returns how many refunds and checkouts were checked.
pub(crate) async fn reconcile_pass(s: &AppState) -> ApiResult<usize> {
    let refunds = drain_refunds(s).await?;
    let now = Utc::now();
    sqlx::query(
        "UPDATE checkouts SET status = 'expired' WHERE id IN (
            SELECT id FROM checkouts WHERE status = 'pending' AND created_at < $1
            LIMIT 200 FOR UPDATE SKIP LOCKED)",
    )
    .bind(now - Duration::hours(RECON_MAX_AGE_HOURS))
    .execute(&s.db)
    .await?;
    // Claim: the stamp is the lease. SKIP LOCKED keeps two replicas off the same rows.
    let claimed: Vec<CheckoutRow> = sqlx::query_as(&format!(
        "UPDATE checkouts SET reconciled_at = now() WHERE id IN (
            SELECT id FROM checkouts
            WHERE status IN ('pending','awaiting_deposit','expired') AND created_at < $1 AND created_at > $2
              AND (reconciled_at IS NULL OR reconciled_at < $3)
            ORDER BY reconciled_at NULLS FIRST, created_at
            LIMIT $4 FOR UPDATE SKIP LOCKED)
         RETURNING {CHECKOUT_COLS}"
    ))
    .bind(now - Duration::seconds(RECON_MIN_AGE_SECS))
    .bind(now - Duration::hours(RECON_MAX_AGE_HOURS))
    .bind(now - Duration::seconds(RECON_COOLDOWN_SECS))
    .bind(RECON_BATCH)
    .fetch_all(&s.db)
    .await?;
    for ck in &claimed {
        reconcile_one(s, ck).await;
    }
    Ok(refunds + claimed.len())
}

async fn reconcile_one(s: &AppState, ck: &CheckoutRow) {
    // Payment id = checkout id, as the app pays with it.
    let payment_id = ck.id.to_string();
    let info = match s.providers.payment(&payment_id, ck.charge()).await {
        Ok(info) => Some(info),
        Err(ProviderError::NotFound) => None,
        Err(e) => {
            tracing::warn!(error = %e, checkout = %ck.id, "reconcile: provider lookup failed");
            return;
        }
    };
    if let Err(e) = apply(s, ck, &payment_id, info.as_ref()).await {
        tracing::debug!(error = %e, checkout = %ck.id, "reconcile: checkout left as it is");
    }
}

/// Retries due compensating refunds (lease + SKIP LOCKED, like the checkout claim). A refund that
/// lands moves its checkout from 'refund_pending' to 'refunded' and tells the customer, once.
/// Returns how many were tried.
pub async fn drain_refunds(s: &AppState) -> ApiResult<usize> {
    let due: Vec<QueuedRefund> = sqlx::query_as(&format!(
        "UPDATE refund_queue SET next_at = now() + make_interval(mins => $2) WHERE id IN (
            SELECT id FROM refund_queue WHERE done_at IS NULL AND next_at <= now()
            ORDER BY next_at LIMIT $1 FOR UPDATE SKIP LOCKED)
         RETURNING {REFUND_COLS}"
    ))
    .bind(REFUND_BATCH)
    .bind(REFUND_LEASE_MINS)
    .fetch_all(&s.db)
    .await?;
    for r in &due {
        if retry_refund(s, r).await == Refund::Done
            && let Some(id) = r.checkout_id
            && let Err(e) = refunded_later(s, id).await
        {
            tracing::error!(error = %e, checkout = %id, "refund landed but the checkout still says refund_pending");
        }
    }
    Ok(due.len())
}

async fn refunded_later(s: &AppState, id: Uuid) -> ApiResult<()> {
    match find_by_id(&s.db, id).await? {
        Some(ck) => refund_late(s, &ck, None, Refund::Done).await,
        None => Ok(()),
    }
}

#[derive(Deserialize)]
pub(super) struct ListQuery {
    status: Option<String>,
    limit: Option<i64>,
    cursor: Option<String>,
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

/// Newest first; keyset cursor over (created_at, id). `status` must be a known checkout status.
pub(super) async fn list(State(s): State<AppState>, Customer(a): Customer, Query(q): Query<ListQuery>) -> ApiResult<Response> {
    let limit = page_limit(q.limit)?;
    let status = checked_status(q.status.as_deref())?;
    let (ts, id) = keyset(q.cursor.as_deref())?;
    sqlx::query("UPDATE checkouts SET status = 'expired' WHERE user_id = $1 AND status = 'pending' AND expires_at < now()")
        .bind(a.id)
        .execute(&s.db)
        .await?;
    let rows: Vec<CheckoutView> = sqlx::query_as(
        "SELECT id, kind, booking_id, method, amount, status, virtual_account, result_booking_id, expires_at, created_at
         FROM checkouts WHERE user_id = $1 AND ($2::text IS NULL OR status = $2)
           AND ($3::timestamptz IS NULL OR (created_at, id) < ($3, $4)) ORDER BY created_at DESC, id DESC LIMIT $5",
    )
    .bind(a.id)
    .bind(status)
    .bind(ts)
    .bind(id)
    .bind(limit)
    .fetch_all(&s.db)
    .await?;
    Ok(paged(rows, limit, |r| encode_cursor(&[&ts_key(r.created_at), &r.id.to_string()])))
}

/// Every status a checkout can hold; list filters outside this set are a client error.
const STATUSES: [&str; 8] = [
    "pending",
    "awaiting_deposit",
    "paid",
    "refund_pending",
    "refunded",
    "expired",
    "failed",
    "cancelled",
];

fn checked_status(status: Option<&str>) -> ApiResult<Option<String>> {
    match status {
        Some(s) if !STATUSES.contains(&s) => Err(ApiError::BadRequest("invalid_status")),
        other => Ok(other.map(str::to_owned)),
    }
}

fn keyset(cursor: Option<&str>) -> ApiResult<(Option<DateTime<Utc>>, Option<Uuid>)> {
    Ok(match decode_cursor(cursor, 2)? {
        Some(p) => (Some(cursor_part(&p[0])?), Some(cursor_part(&p[1])?)),
        None => (None, None),
    })
}

#[derive(Serialize, sqlx::FromRow)]
struct AdminCheckoutView {
    id: Uuid,
    kind: String,
    method: String,
    amount: i64,
    status: String,
    created_at: DateTime<Utc>,
    booking_id: Option<Uuid>,
    result_booking_id: Option<Uuid>,
    user_id: Uuid,
}

/// Console view of checkouts, newest first. Staff only.
pub(super) async fn admin_list(State(s): State<AppState>, _staff: Staff, Query(q): Query<ListQuery>) -> ApiResult<Response> {
    let limit = page_limit(q.limit)?;
    let status = checked_status(q.status.as_deref())?;
    let (ts, id) = keyset(q.cursor.as_deref())?;
    let rows: Vec<AdminCheckoutView> = sqlx::query_as(
        "SELECT id, kind, method, amount, status, created_at, booking_id, result_booking_id, user_id
         FROM checkouts WHERE ($1::text IS NULL OR status = $1)
           AND ($2::timestamptz IS NULL OR (created_at, id) < ($2, $3)) ORDER BY created_at DESC, id DESC LIMIT $4",
    )
    .bind(status)
    .bind(ts)
    .bind(id)
    .bind(limit)
    .fetch_all(&s.db)
    .await?;
    Ok(paged(rows, limit, |r| encode_cursor(&[&ts_key(r.created_at), &r.id.to_string()])))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn refund_pending_is_a_listable_status() {
        assert_eq!(checked_status(Some("refund_pending")).expect("known"), Some("refund_pending".into()));
        assert!(checked_status(Some("nope")).is_err());
    }
}
