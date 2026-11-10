//! Small helpers shared by route modules.

use crate::{error::ApiResult, state::AppState};
use chrono::{NaiveDate, Utc};
use serde_json::Value;
use sqlx::PgConnection;
use std::future::Future;
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

/// Compensating refund when a charge succeeded but saving it did not.
pub async fn refund_or_alert(s: &AppState, provider: &str, tx_id: &str, amount: i64) {
    if let Err(e) = s.providers.refund(provider, tx_id, amount).await {
        // Money is out of sync with the DB: this must reach a human.
        tracing::error!(error = %e, provider, tx_id, amount, "COMPENSATING REFUND FAILED - reconcile manually");
        crate::ops::record(&s.db, "payment_stuck", Err("refund_failed"));
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

/// Our own upload URLs only: `<base>/files/<32 hex>.<ext>` — no traversal, no foreign hosts.
pub fn is_own_upload(base: &str, url: &str) -> bool {
    let Some(name) = url.strip_prefix(&format!("{base}/files/")) else {
        return false;
    };
    let Some((stem, ext)) = name.split_once('.') else { return false };
    stem.len() == 32 && stem.chars().all(|c| c.is_ascii_hexdigit()) && matches!(ext, "jpg" | "png" | "webp" | "heic")
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn notes_are_bounded() {
        assert_eq!(sanitize_notes(&json!({"entry": "1234#", "junk": 1})), Some(json!({"entry": "1234#"})));
        assert_eq!(sanitize_notes(&json!({"entry": "x".repeat(301)})), None);
        assert_eq!(sanitize_notes(&json!({"parking": 5})), None);
    }

    #[test]
    fn upload_urls() {
        let b = "https://api.x";
        assert!(is_own_upload(b, "https://api.x/files/0123456789abcdef0123456789abcdef.jpg"));
        assert!(!is_own_upload(b, "https://api.x/files/../etc/passwd"));
        assert!(!is_own_upload(b, "https://evil.x/files/0123456789abcdef0123456789abcdef.jpg"));
        assert!(!is_own_upload(b, "https://api.x/files/0123456789abcdef0123456789abcdef.svg"));
    }
}
