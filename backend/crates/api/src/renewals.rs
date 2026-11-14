//! Renewal calendar (갱신 일정). An item is due on a date. The owner gets one SMS 30 days and one SMS 7 days
//! before it. The yearly keys test is derived from `key_bundle_checks.verified_at`, not stored as a row.

use crate::{
    error::ApiResult,
    lifecycle::next_tick,
    metrics::job_pass,
    ops_alerts,
    routes::setup,
    sms_outbox::{self, Message},
    state::AppState,
};
use chrono::{DateTime, Datelike, Duration, NaiveDate, Utc};
use serde_json::Value;
use sqlx::PgPool;
use std::time::Duration as StdDuration;
use tokio::task::JoinHandle;

pub const KINDS: [&str; 7] = ["domain", "domain_alias", "hosting", "apple", "solapi", "storage", "other"];
/// Ascending: the first one a date has reached is the nearest, so a late-created item gets only that text.
pub const THRESHOLDS: [i64; 2] = [7, 30];
pub const KEYS_TEST_ID: &str = "keys_test";
const KEYS_TEST_NAME: &str = "비밀 키 사본 시험 업로드 (연 1회)";
const KEYS_TEST_DAYS: i64 = 365;
const NAME_MAX_CHARS: usize = 80;
const YEAR_RANGE: std::ops::RangeInclusive<i32> = 2000..=2100;
const KST_OFFSET_SECS: i64 = 9 * 3600;
const PASS_EVERY: StdDuration = StdDuration::from_secs(3600);

/// One item on the calendar. `id` is a renewal row id, or `KEYS_TEST_ID` for the derived keys test.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Due {
    pub id: String,
    pub kind: String,
    pub name: String,
    pub due_on: NaiveDate,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Input {
    pub kind: String,
    pub name: String,
    pub due_on: NaiveDate,
}

/// Validates a create or update body. Errors are fixed codes the console turns into Korean text.
pub fn parse_input(v: &Value) -> Result<Input, &'static str> {
    let kind = v["kind"].as_str().filter(|k| KINDS.contains(k)).ok_or("invalid_kind")?;
    let name = v["name"]
        .as_str()
        .map(str::trim)
        .filter(|n| !n.is_empty() && n.chars().count() <= NAME_MAX_CHARS)
        .ok_or("invalid_name")?;
    let due_on = v["due_on"]
        .as_str()
        .and_then(|d| NaiveDate::parse_from_str(d, "%Y-%m-%d").ok())
        .filter(|d| YEAR_RANGE.contains(&d.year()))
        .ok_or("invalid_due_on")?;
    Ok(Input {
        kind: kind.to_owned(),
        name: name.to_owned(),
        due_on,
    })
}

/// Calendar date in KST, the date the owner reads.
pub fn kst_today(now: DateTime<Utc>) -> NaiveDate {
    (now + Duration::seconds(KST_OFFSET_SECS)).date_naive()
}

/// Whole days from `today` to `due`. Negative once the date has passed.
pub fn days_left(due: NaiveDate, today: NaiveDate) -> i64 {
    (due - today).num_days()
}

/// The threshold to send now, if any: the first one the date has reached that is not yet recorded as sent.
pub fn threshold_due(left: i64, sent: &[i64]) -> Option<i64> {
    THRESHOLDS.iter().copied().find(|t| left <= *t && !sent.contains(t))
}

/// The keys test is due one year after the last successful upload test, counted in KST days.
pub fn keys_test_due(verified_at: DateTime<Utc>) -> NaiveDate {
    kst_today(verified_at) + Duration::days(KEYS_TEST_DAYS)
}

/// Every item that is on the calendar now: the renewal rows and, once a test has passed, the keys test.
pub async fn due_items(db: &PgPool) -> ApiResult<Vec<Due>> {
    let rows: Vec<(String, String, String, NaiveDate)> = sqlx::query_as("SELECT id::text, kind, name, due_on FROM renewals ORDER BY due_on, created_at")
        .fetch_all(db)
        .await?;
    let mut items: Vec<Due> = rows.into_iter().map(|(id, kind, name, due_on)| Due { id, kind, name, due_on }).collect();
    let verified: Option<DateTime<Utc>> = sqlx::query_scalar("SELECT verified_at FROM key_bundle_checks WHERE id = 1")
        .fetch_optional(db)
        .await?;
    if let Some(at) = verified {
        items.push(Due {
            id: KEYS_TEST_ID.to_owned(),
            kind: KEYS_TEST_ID.to_owned(),
            name: KEYS_TEST_NAME.to_owned(),
            due_on: keys_test_due(at),
        });
    }
    Ok(items)
}

/// The owner's alert number: the one set for ops alerts, else the business support phone.
async fn owner_phone(db: &PgPool) -> ApiResult<Option<String>> {
    match ops_alerts::load_prefs(db).await?.alert_phone {
        Some(p) => Ok(Some(p)),
        None => Ok(ops_alerts::business_phone(db).await?),
    }
}

async fn sent_thresholds(db: &PgPool, item: &Due) -> ApiResult<Vec<i64>> {
    let rows: Vec<i64> = sqlx::query_scalar("SELECT days::BIGINT FROM renewal_reminders WHERE item = $1 AND due_on = $2")
        .bind(&item.id)
        .bind(item.due_on)
        .fetch_all(db)
        .await?;
    Ok(rows)
}

fn when_text(left: i64) -> String {
    match left {
        i64::MIN..=-1 => "기한이 지났어요".to_owned(),
        0 => "오늘이 기한이에요".to_owned(),
        n => format!("{n}일 남았어요"),
    }
}

/// Sends the reminder for one item if a threshold is due, then records every threshold it covers.
/// Returns whether a text was queued.
async fn remind(s: &AppState, phone: &str, item: &Due, today: NaiveDate) -> ApiResult<bool> {
    let left = days_left(item.due_on, today);
    let sent = sent_thresholds(&s.db, item).await?;
    let Some(threshold) = threshold_due(left, &sent) else {
        return Ok(false);
    };
    let brand = setup::brand_name(&s.db).await;
    let text = format!("[{brand}] 갱신 알림: {} ({}, {})", item.name, item.due_on, when_text(left));
    sms_outbox::send(s, None, phone, "renewal.due", Message::Sms(&text)).await?;
    for days in THRESHOLDS.iter().copied().filter(|d| *d >= threshold) {
        sqlx::query("INSERT INTO renewal_reminders (item, due_on, days) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING")
            .bind(&item.id)
            .bind(item.due_on)
            .bind(days as i16)
            .execute(&s.db)
            .await?;
    }
    Ok(true)
}

/// One pass over the calendar. Without an owner phone nothing is sent and nothing is recorded, so the
/// reminder goes out once a phone is set. A failing item is logged and the rest still run.
pub async fn run_once(s: &AppState) -> ApiResult<usize> {
    let Some(phone) = owner_phone(&s.db).await? else {
        return Ok(0);
    };
    let today = kst_today(Utc::now());
    let mut queued = 0;
    for item in due_items(&s.db).await? {
        match remind(s, &phone, &item, today).await {
            Ok(true) => queued += 1,
            Ok(false) => {}
            Err(e) => tracing::warn!(error = %e, item = %item.id, "renewal reminder failed"),
        }
    }
    Ok(queued)
}

/// Starts the hourly pass. Errors are logged and the loop goes on.
pub fn spawn(state: AppState) -> JoinHandle<()> {
    let mut stop = state.hub.drain_signal();
    tokio::spawn(async move {
        let mut tick = tokio::time::interval(PASS_EVERY);
        while next_tick(&mut tick, &mut stop).await {
            let ok = match run_once(&state).await {
                Ok(_) => true,
                Err(e) => {
                    tracing::warn!(error = %e, "renewal pass failed");
                    false
                }
            };
            job_pass("renewals", ok);
        }
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;
    use serde_json::json;

    fn day(y: i32, m: u32, d: u32) -> NaiveDate {
        NaiveDate::from_ymd_opt(y, m, d).expect("valid date")
    }

    #[test]
    fn valid_input_is_trimmed_and_kind_checked() {
        let ok = parse_input(&json!({ "kind": "domain", "name": "  malkkeum.kr ", "due_on": "2027-03-01" })).expect("valid");
        assert_eq!(
            ok,
            Input {
                kind: "domain".into(),
                name: "malkkeum.kr".into(),
                due_on: day(2027, 3, 1)
            }
        );
        assert_eq!(
            parse_input(&json!({ "kind": "nope", "name": "x", "due_on": "2027-03-01" })),
            Err("invalid_kind")
        );
    }

    #[test]
    fn name_and_date_bounds_are_enforced() {
        let blank = json!({ "kind": "other", "name": "   ", "due_on": "2027-03-01" });
        assert_eq!(parse_input(&blank), Err("invalid_name"));
        let long = json!({ "kind": "other", "name": "가".repeat(81), "due_on": "2027-03-01" });
        assert_eq!(parse_input(&long), Err("invalid_name"));
        let bad_date = json!({ "kind": "other", "name": "x", "due_on": "2027-02-30" });
        assert_eq!(parse_input(&bad_date), Err("invalid_due_on"));
        let too_early = json!({ "kind": "other", "name": "x", "due_on": "1999-12-31" });
        assert_eq!(parse_input(&too_early), Err("invalid_due_on"));
    }

    #[test]
    fn threshold_is_the_nearest_unsent_one() {
        assert_eq!(threshold_due(45, &[]), None);
        assert_eq!(threshold_due(30, &[]), Some(30));
        assert_eq!(threshold_due(20, &[30]), None);
        assert_eq!(threshold_due(7, &[30]), Some(7));
        assert_eq!(threshold_due(5, &[]), Some(7));
        assert_eq!(threshold_due(-3, &[7, 30]), None);
    }

    #[test]
    fn keys_test_is_one_kst_year_after_the_upload() {
        // 2026-11-14 16:00 UTC is 2026-11-15 01:00 KST, so the year counts from the 15th.
        let at = Utc.with_ymd_and_hms(2026, 11, 14, 16, 0, 0).single().expect("instant");
        assert_eq!(keys_test_due(at), day(2027, 11, 15));
        assert_eq!(days_left(keys_test_due(at), kst_today(at)), 365);
    }
}
