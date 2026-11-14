//! Small helpers shared by route modules.

use crate::{error::ApiResult, providers::ProviderError, state::AppState};
use chrono::{NaiveDate, Utc};
use serde_json::Value;
use sqlx::PgConnection;
use std::{collections::BTreeMap, future::Future, sync::Mutex};
use uuid::Uuid;

/// Business dates are Korean dates, whatever timezone the server or DB runs in.
pub fn today_kst() -> NaiveDate {
    (Utc::now() + chrono::Duration::hours(9)).date_naive()
}

/// SQL equivalent of [`today_kst`]; never use bare `current_date` (it follows the DB timezone).
pub const KST_TODAY: &str = "(now() AT TIME ZONE 'Asia/Seoul')::date";

/// Notifications and chat fan-out run after the money is committed: a push or
/// socket hiccup must not turn a successful booking into an error (and a retry).
pub async fn best_effort(what: &'static str, f: impl Future<Output = ApiResult<()>>) {
    if let Err(e) = f.await {
        tracing::warn!(error = %e, what, "post-commit side effect failed");
    }
}

/// Where a compensating refund stands. `Pending`: the provider has not confirmed it; it waits in
/// `refund_queue` and `checkout_recon::drain_refunds` retries it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Refund {
    Done,
    Pending,
}

/// Failed tries after which a stuck refund alerts the owner (ops rule `payment_stuck`), on every further failure.
pub const REFUND_ALERT_AFTER: i32 = 3;
/// A claimed refund is left alone this long, so a slow provider call is never sent twice.
pub const REFUND_LEASE_MINS: i32 = 5;
const REFUND_BACKOFF_MAX_MINS: i32 = 360;

/// Minutes to the next try after `attempts` tries: 2, 4, 8, ... capped at six hours.
pub fn refund_backoff_mins(attempts: i32) -> i32 {
    (1i32 << attempts.clamp(1, 9)).min(REFUND_BACKOFF_MAX_MINS)
}

/// One `refund_queue` row.
#[derive(sqlx::FromRow)]
pub struct QueuedRefund {
    pub id: Uuid,
    pub provider: String,
    pub tx_id: String,
    pub amount: i64,
    pub attempts: i32,
    pub checkout_id: Option<Uuid>,
}

pub const REFUND_COLS: &str = "id, provider, tx_id, amount, attempts, checkout_id";

/// Compensating refund when a charge succeeded but saving it did not.
pub async fn refund_or_alert(s: &AppState, provider: &str, tx_id: &str, amount: i64) -> Refund {
    refund_durably(s, provider, tx_id, amount, None).await
}

/// Compensating refund, recorded in `refund_queue` before the provider is called: a failure is retried
/// with backoff, and one (provider, tx, amount) is refunded at most once however often a settle replays.
pub async fn refund_durably(s: &AppState, provider: &str, tx_id: &str, amount: i64, checkout: Option<Uuid>) -> Refund {
    let queued = sqlx::query_as::<_, QueuedRefund>(&format!(
        "INSERT INTO refund_queue (provider, tx_id, amount, checkout_id, next_at) VALUES ($1, $2, $3, $4, now() + make_interval(mins => $5))
         ON CONFLICT (provider, tx_id, amount) DO NOTHING RETURNING {REFUND_COLS}"
    ))
    .bind(provider)
    .bind(tx_id)
    .bind(amount)
    .bind(checkout)
    .bind(REFUND_LEASE_MINS)
    .fetch_optional(&s.db)
    .await;
    match queued {
        Ok(Some(row)) => retry_refund(s, &row).await,
        // Already asked for: never call the provider twice; report where the first one stands.
        Ok(None) => match sqlx::query_scalar("SELECT done_at IS NOT NULL FROM refund_queue WHERE provider = $1 AND tx_id = $2 AND amount = $3")
            .bind(provider)
            .bind(tx_id)
            .bind(amount)
            .fetch_one(&s.db)
            .await
        {
            Ok(true) => Refund::Done,
            Ok(false) => Refund::Pending,
            Err(e) => {
                tracing::error!(error = %e, provider, tx_id, "refund queue read failed");
                Refund::Pending
            }
        },
        Err(e) => {
            // No retry record possible: refund now, and a failure must reach a human.
            tracing::error!(error = %e, provider, tx_id, amount, "refund queue unavailable");
            let row = QueuedRefund {
                id: Uuid::nil(),
                provider: provider.into(),
                tx_id: tx_id.into(),
                amount,
                attempts: 0,
                checkout_id: checkout,
            };
            match attempt_refund(s, &row).await {
                Ok(()) => Refund::Done,
                Err(e) => {
                    tracing::error!(error = %e, provider, tx_id, amount, "COMPENSATING REFUND FAILED - reconcile manually");
                    crate::ops::record(&s.db, "payment_stuck", Err("refund_failed")).await;
                    Refund::Pending
                }
            }
        }
    }
}

/// One try at a queued refund, saved on its row. A DB error leaves the row leased for a later pass.
pub async fn retry_refund(s: &AppState, r: &QueuedRefund) -> Refund {
    let result = attempt_refund(s, r).await;
    let attempts = r.attempts + 1;
    let state = if result.is_ok() { Refund::Done } else { Refund::Pending };
    let error = result.err().map(|e| e.to_string());
    let saved = sqlx::query(
        "UPDATE refund_queue SET attempts = $2, done_at = CASE WHEN $3 THEN now() END, last_error = $4,
            next_at = now() + make_interval(mins => $5) WHERE id = $1",
    )
    .bind(r.id)
    .bind(attempts)
    .bind(state == Refund::Done)
    .bind(&error)
    .bind(refund_backoff_mins(attempts))
    .execute(&s.db)
    .await;
    if let Err(e) = saved {
        tracing::error!(error = %e, refund = %r.id, "refund outcome not saved");
    }
    if let Some(error) = error {
        let (provider, tx_id, amount) = (r.provider.as_str(), r.tx_id.as_str(), r.amount);
        if attempts >= REFUND_ALERT_AFTER {
            tracing::error!(
                error,
                provider,
                tx_id,
                amount,
                attempts,
                "COMPENSATING REFUND STILL FAILING - check the PG console"
            );
            crate::ops::record(&s.db, "payment_stuck", Err("refund_failed")).await;
        } else {
            tracing::warn!(error, provider, tx_id, amount, attempts, "compensating refund failed; queued for retry");
        }
    }
    state
}

async fn attempt_refund(s: &AppState, r: &QueuedRefund) -> Result<(), ProviderError> {
    if s.config.dev_mode && dev_refund_fails(&r.tx_id) {
        return Err(ProviderError::Upstream("dev refund failure".into()));
    }
    // After an ambiguous failure PortOne may have cancelled it already. Queued refunds are full refunds.
    if r.attempts > 0 && r.provider == "portone" {
        match s.providers.payment(&r.tx_id, r.amount).await {
            Ok(info) if info.status == "CANCELLED" => return Ok(()),
            Ok(_) | Err(ProviderError::NotFound) => {}
            Err(e) => return Err(e),
        }
    }
    s.providers.refund(&r.provider, &r.tx_id, r.amount).await
}

static DEV_REFUND_FAILURES: Mutex<BTreeMap<String, u32>> = Mutex::new(BTreeMap::new());

/// Dev fakes only: the next `times` refunds of `tx_id` fail like a provider outage. For tests.
#[doc(hidden)]
pub fn fail_dev_refunds(tx_id: &str, times: u32) {
    if let Ok(mut failing) = DEV_REFUND_FAILURES.lock() {
        failing.insert(tx_id.to_string(), times);
    }
}

fn dev_refund_fails(tx_id: &str) -> bool {
    let Ok(mut failing) = DEV_REFUND_FAILURES.lock() else { return false };
    match failing.get_mut(tx_id) {
        Some(left) if *left > 0 => {
            *left -= 1;
            true
        }
        _ => false,
    }
}

/// Serialises bookings per (date, hour) for the rest of the transaction, then counts
/// live bookings in that slot, optionally ignoring one booking (for reschedules).
pub async fn lock_and_count_slot(conn: &mut PgConnection, date: NaiveDate, hour: u8, except: Option<Uuid>) -> ApiResult<(u32, Option<u32>)> {
    sqlx::query("SELECT pg_advisory_xact_lock(hashtext($1))")
        .bind(format!("slot:{date}:{hour}"))
        .execute(&mut *conn)
        .await?;
    let used: i64 =
        sqlx::query_scalar("SELECT count(*) FROM bookings WHERE visit_date = $1 AND start_hour = $2 AND status >= 0 AND ($3::uuid IS NULL OR id <> $3)")
            .bind(date)
            .bind(i16::from(hour))
            .bind(except)
            .fetch_one(&mut *conn)
            .await?;
    // A live waitlist offer holds a seat for 15 minutes.
    let holds: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM waitlist_entries WHERE status = 'offered' AND offer_expires_at > now()
           AND visit_date = $1 AND start_hour <= $2 AND end_hour > $2",
    )
    .bind(date)
    .bind(i16::from(hour))
    .fetch_one(&mut *conn)
    .await?;
    let used = used + holds;
    let cap: Option<i32> = sqlx::query_scalar("SELECT capacity FROM slot_capacity WHERE start_hour = $1")
        .bind(i16::from(hour))
        .fetch_optional(&mut *conn)
        .await?
        .flatten();
    Ok((u32::try_from(used).unwrap_or(u32::MAX), cap.map(|c| u32::try_from(c).unwrap_or(0))))
}

const MAX_NOTE_CHARS: usize = 300;
const NOTE_KEYS: [&str; 3] = ["entry", "parking", "other"];

/// Keeps only the known note fields, as bounded strings (prevents arbitrary JSON blobs).
pub fn sanitize_notes(v: &Value) -> Option<Value> {
    let mut out = serde_json::Map::new();
    for key in NOTE_KEYS {
        match v.get(key) {
            None | Some(Value::Null) => {}
            Some(Value::String(s)) if s.chars().count() <= MAX_NOTE_CHARS => {
                out.insert(key.into(), Value::String(s.trim().to_string()));
            }
            Some(_) => return None,
        }
    }
    Some(Value::Object(out))
}

pub const IMAGE_EXTS: [&str; 4] = ["jpg", "png", "webp", "heic"];

/// Stored form of one of our upload URLs (`/files/<32 hex>.<ext>`), or None for anything else.
/// Accepts the relative or base-prefixed form, with `/v1` and a signed query string; no traversal, no foreign hosts.
pub fn own_upload(base: &str, url: &str) -> Option<String> {
    let path = url.strip_prefix(base).unwrap_or(url);
    let path = path.strip_prefix("/v1").unwrap_or(path);
    let name = path.strip_prefix("/files/")?.split('?').next()?;
    let (stem, ext) = name.split_once('.')?;
    let ok = stem.len() == 32 && stem.chars().all(|c| c.is_ascii_hexdigit()) && IMAGE_EXTS.contains(&ext);
    ok.then(|| format!("/files/{name}"))
}

/// Stored paths for a list of upload URLs; None if any entry is not one of ours.
pub fn own_uploads(base: &str, urls: &[String]) -> Option<Vec<String>> {
    urls.iter().map(|u| own_upload(base, u)).collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn refund_retries_back_off_to_six_hours() {
        assert_eq!([0, 1, 2, 3].map(refund_backoff_mins), [2, 2, 4, 8]);
        assert_eq!(refund_backoff_mins(9), 360);
        assert_eq!(refund_backoff_mins(i32::MAX), 360);
    }

    #[test]
    fn dev_refund_failures_count_down_per_payment() {
        fail_dev_refunds("tx-a", 1);
        assert!(!dev_refund_fails("tx-b"));
        assert!(dev_refund_fails("tx-a"));
        assert!(!dev_refund_fails("tx-a"));
    }

    #[test]
    fn notes_are_bounded() {
        assert_eq!(sanitize_notes(&json!({"entry": "1234#", "junk": 1})), Some(json!({"entry": "1234#"})));
        assert_eq!(sanitize_notes(&json!({"entry": "x".repeat(301)})), None);
        assert_eq!(sanitize_notes(&json!({"parking": 5})), None);
    }

    #[test]
    fn upload_urls() {
        let b = "https://api.x";
        let stem = "0123456789abcdef0123456789abcdef";
        assert_eq!(
            own_upload(b, &format!("https://api.x/files/{stem}.jpg")).as_deref(),
            Some(&*format!("/files/{stem}.jpg"))
        );
        assert_eq!(
            own_upload(b, &format!("https://api.x/v1/files/{stem}.png?exp=5&sig=ab")).as_deref(),
            Some(&*format!("/files/{stem}.png"))
        );
        assert_eq!(own_upload(b, &format!("/files/{stem}.webp")).as_deref(), Some(&*format!("/files/{stem}.webp")));
        assert!(own_upload(b, "https://api.x/files/../etc/passwd").is_none());
        assert!(own_upload(b, &format!("https://evil.x/files/{stem}.jpg")).is_none());
        assert!(own_upload(b, &format!("https://api.x.evil/files/{stem}.jpg")).is_none());
        assert!(own_upload(b, &format!("https://api.x/files/{stem}.svg")).is_none());
    }
}
