//! Owner alerts. A pass every few minutes checks a handful of rules over the ops failure log, the
//! backup status and free disk. A firing rule goes to the console inbox, to the owner's phone (SMS)
//! and to staff push devices, then sits out a cooldown so one incident sends one message per cooldown.
//! Quiet hours (KST) hold everything until they end; the condition is still there then.

use crate::{
    error::{ApiError, ApiResult},
    lifecycle::next_tick,
    metrics::job_pass,
    ops::{self, Level},
    realtime::{Recipient, notify},
    state::AppState,
};
use chrono::{DateTime, Duration, FixedOffset, Timelike, Utc};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use sqlx::PgPool;
use tokio::task::JoinHandle;
use std::{collections::{BTreeMap, HashMap}, time::Duration as StdDuration};

pub const RULES: [&str; 8] = ["sms_failing", "push_failing", "payment_failing", "payment_stuck", "social_failing", "auth_suspicious", "backup_stale", "disk_low"];
pub const COOLDOWN_HOURS: i64 = 6;
const PREFS_KEY: &str = "ops_alerts";
const BUSINESS_KEY: &str = "business";
const PASS_EVERY: StdDuration = StdDuration::from_secs(300);
const SMS_WINDOW_MIN: i64 = 15;
const SMS_FAILURES: i64 = 3;
const PUSH_WINDOW_MIN: i64 = 30;
const PUSH_FAILURES: i64 = 5;
const PAYMENT_WINDOW_MIN: i64 = 15;
const PAYMENT_FAILURES: i64 = 3;
const STUCK_WINDOW_MIN: i64 = 60;
const DEAD_LETTER_WINDOW_MIN: i64 = 60;
const SOCIAL_WINDOW_MIN: i64 = 30;
const SOCIAL_FAILURES: i64 = 5;
const SOCIAL_PROVIDERS: [&str; 4] = ["kakao", "naver", "google", "apple"];
/// Lockouts, refresh-token reuse and MFA lockouts across the window before the owner hears about it.
const AUTH_WINDOW_MIN: i64 = 60;
const AUTH_EVENTS: i64 = 5;
const KST_OFFSET_SECS: i32 = 9 * 3600;

/// What the owner chose on the console's alert card.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(default)]
pub struct Prefs {
    /// Rule key -> on/off. A missing rule is on.
    pub rules: BTreeMap<String, bool>,
    pub quiet_start: u32,
    pub quiet_end: u32,
    /// Digits only. Empty means use the business support phone.
    pub alert_phone: Option<String>,
}

impl Default for Prefs {
    fn default() -> Self {
        Self { rules: BTreeMap::new(), quiet_start: 22, quiet_end: 7, alert_phone: None }
    }
}

impl Prefs {
    pub fn enabled(&self, rule: &str) -> bool {
        self.rules.get(rule).copied().unwrap_or(true)
    }
}

/// Validates the console's input. Unknown rule keys are dropped; hours must be 0..=23.
pub fn parse_input(v: &Value) -> Result<Prefs, &'static str> {
    let mut prefs = Prefs::default();
    for rule in RULES {
        if let Some(on) = v["rules"].get(rule).and_then(Value::as_bool) {
            prefs.rules.insert(rule.to_string(), on);
        }
    }
    prefs.quiet_start = hour(&v["quiet_start"]).ok_or("invalid_quiet_hours")?;
    prefs.quiet_end = hour(&v["quiet_end"]).ok_or("invalid_quiet_hours")?;
    prefs.alert_phone = match v["alert_phone"].as_str().map(str::trim).filter(|s| !s.is_empty()) {
        None => None,
        Some(raw) => {
            let digits: String = raw.chars().filter(char::is_ascii_digit).collect();
            let allowed = raw.chars().all(|c| c.is_ascii_digit() || c == '-' || c == ' ');
            // Korean mobiles only (010, 011, 016-019): never premium-rate 060 or landlines.
            let mobile = digits.starts_with("01") && matches!(digits.as_bytes().get(2), Some(b'0' | b'1' | b'6'..=b'9'));
            if !allowed || !mobile || !(10..=11).contains(&digits.len()) {
                return Err("invalid_phone");
            }
            Some(digits)
        }
    };
    Ok(prefs)
}

fn hour(v: &Value) -> Option<u32> {
    v.as_u64().filter(|h| *h <= 23).map(|h| h as u32)
}

/// True when `hour` is inside [start, end). A window such as 22..7 wraps midnight; equal bounds mean none.
pub fn in_quiet_hours(hour: u32, start: u32, end: u32) -> bool {
    match start.cmp(&end) {
        std::cmp::Ordering::Equal => false,
        std::cmp::Ordering::Less => (start..end).contains(&hour),
        std::cmp::Ordering::Greater => hour >= start || hour < end,
    }
}

/// A rule may fire again only after the cooldown since its last message.
pub fn due(now: DateTime<Utc>, last_sent: Option<DateTime<Utc>>) -> bool {
    last_sent.is_none_or(|t| now - t >= Duration::hours(COOLDOWN_HOURS))
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Finding {
    pub rule: &'static str,
    pub title: &'static str,
    pub body: &'static str,
}

/// The rules that should fire now, before cooldown. Pure over the inputs, so the dedup logic is testable.
pub fn select<'a>(findings: &'a [Finding], prefs: &Prefs, last: &HashMap<String, DateTime<Utc>>, now: DateTime<Utc>, quiet: bool) -> Vec<&'a Finding> {
    if quiet {
        return Vec::new();
    }
    findings
        .iter()
        .filter(|f| prefs.enabled(f.rule) && due(now, last.get(f.rule).copied()))
        .collect()
}

async fn count(db: &PgPool, integrations: &[&str], minutes: i64) -> Result<i64, sqlx::Error> {
    ops::failures_within(db, integrations, minutes).await
}

/// Evaluates every rule against current data.
pub async fn evaluate(s: &AppState) -> ApiResult<Vec<Finding>> {
    let db = &s.db;
    let mut out = Vec::new();
    if count(db, &["solapi"], SMS_WINDOW_MIN).await? >= SMS_FAILURES {
        out.push(Finding {
            rule: "sms_failing",
            title: "문자 발송이 계속 실패해요",
            body: "설정 > 문자(Solapi)에서 키와 발신번호를 확인하고 연결 테스트를 해 주세요.",
        });
    }
    if count(db, &["push"], PUSH_WINDOW_MIN).await? >= PUSH_FAILURES {
        out.push(Finding {
            rule: "push_failing",
            title: "앱 알림(푸시)이 계속 실패해요",
            body: "설정 > 앱 알림(Firebase) 키 파일을 확인하고 연결 테스트를 해 주세요.",
        });
    }
    if count(db, &["portone", "portone_webhook"], PAYMENT_WINDOW_MIN).await? >= PAYMENT_FAILURES {
        out.push(Finding {
            rule: "payment_failing",
            title: "결제 연동에 문제가 생겼어요",
            body: "설정 > 결제(PortOne)의 키와 웹훅 시크릿을 확인하세요. 고객 결제가 실패할 수 있어요.",
        });
    }
    if count(db, &["payment_stuck"], STUCK_WINDOW_MIN).await? >= 1 {
        out.push(Finding {
            rule: "payment_stuck",
            title: "결제는 됐지만 자동 처리가 안 됐어요",
            body: "PortOne 관리자 화면에서 해당 결제를 찾아 예약 생성 또는 환불 여부를 직접 확인하세요.",
        });
    }
    if count(db, &["sms_dead_letter"], DEAD_LETTER_WINDOW_MIN).await? >= 1 {
        out.push(Finding {
            rule: "sms_dead_letter",
            title: "문자 발송이 끝내 실패했어요",
            body: "고객에게 가지 못한 문자가 있어요. 설정 > 문자(Solapi)에서 키와 발신번호를 확인하고 연결 테스트를 해 주세요.",
        });
    }
    if count(db, &SOCIAL_PROVIDERS, SOCIAL_WINDOW_MIN).await? >= SOCIAL_FAILURES {
        out.push(Finding {
            rule: "social_failing",
            title: "소셜 로그인이 계속 실패해요",
            body: "설정에서 카카오·네이버·구글·애플 로그인 키(클라이언트 ID)를 확인하세요.",
        });
    }
    if count(db, &["auth_abuse"], AUTH_WINDOW_MIN).await? >= AUTH_EVENTS {
        out.push(Finding {
            rule: "auth_suspicious",
            title: "로그인 시도가 비정상적으로 많아요",
            body: "직원 로그인 또는 인증 번호에 반복 실패가 있어 잠금이 걸렸어요. 감사 로그에서 대상 계정과 시간을 확인하고, 본인이 아니면 비밀번호를 바꾸세요.",
        });
    }
    out.extend(payout_findings(db).await?);
    out.extend(job_finding());
    let backup = ops::backup_status(db).await?;
    let age = ops::backup_age_hours(backup.as_ref(), Utc::now());
    if ops::backup_level(age) == Level::Red {
        out.push(Finding {
            rule: "backup_stale",
            title: "자동 백업이 36시간 넘게 없어요",
            body: "서버에서 malkkeum backup 을 실행하고, backups 폴더의 backup.log 를 확인하세요.",
        });
    }
    let disk = ops::disk_usage(s.config.upload_dir.clone()).await;
    if disk.is_some_and(|d| ops::disk_level(d.free_pct()) == Level::Red) {
        out.push(Finding {
            rule: "disk_low",
            title: "서버 디스크 여유 공간이 10% 아래예요",
            body: "오래된 백업 파일을 정리하거나 서버 디스크를 늘려 주세요.",
        });
    }
    Ok(out)
}

/// Payout alerts. Not owner-toggleable: a stuck or failed transfer is money the owner must look at.
async fn payout_findings(db: &PgPool) -> Result<Vec<Finding>, sqlx::Error> {
    let (stuck, failed) = crate::payout_sync::alert_counts(db).await?;
    let mut out = Vec::new();
    if stuck > 0 {
        out.push(Finding {
            rule: "payout_stuck",
            title: "정산 송금이 24시간 넘게 끝나지 않았어요",
            body: "정산 > 송금 목록에서 해당 건을 찾아 상태 동기화를 눌러 주세요. 계속 대기 중이면 PG 관리자 화면을 확인하세요.",
        });
    }
    if failed > 0 {
        out.push(Finding {
            rule: "payout_failed",
            title: "정산 송금이 실패했어요",
            body: "정산 > 송금 목록에서 실패 사유와 기사님 계좌를 확인한 뒤 재시도하세요.",
        });
    }
    Ok(out)
}

/// Background job alert. Not owner-toggleable: a stalled job means bookings, charges or notifications stop silently.
fn job_finding() -> Option<Finding> {
    let stalled = crate::jobs::stalled(Utc::now().timestamp() as f64);
    if stalled.is_empty() {
        return None;
    }
    tracing::error!(jobs = ?stalled, "background jobs stalled");
    Some(Finding {
        rule: "job_stalled",
        title: "자동 작업이 멈췄어요",
        body: "정기 결제, 알림, 노쇼 확인 같은 자동 작업이 한동안 성공하지 못했어요. 서버 로그를 확인한 뒤 서버를 다시 시작해 주세요.",
    })
}

pub async fn load_prefs(db: &PgPool) -> Result<Prefs, sqlx::Error> {
    let raw: Option<Value> = sqlx::query_scalar("SELECT value FROM settings WHERE key = $1").bind(PREFS_KEY).fetch_optional(db).await?;
    Ok(raw.and_then(|v| serde_json::from_value(v).ok()).unwrap_or_default())
}

pub async fn save_prefs(db: &PgPool, prefs: &Prefs) -> Result<(), sqlx::Error> {
    sqlx::query(
        "INSERT INTO settings (key, value) VALUES ($1, $2)
         ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()",
    )
    .bind(PREFS_KEY)
    .bind(serde_json::to_value(prefs).unwrap_or(Value::Null))
    .execute(db)
    .await
    .map(|_| ())
}

/// Business support phone, the default alert number.
pub async fn business_phone(db: &PgPool) -> Result<Option<String>, sqlx::Error> {
    let raw: Option<Value> = sqlx::query_scalar("SELECT value FROM settings WHERE key = $1").bind(BUSINESS_KEY).fetch_optional(db).await?;
    Ok(raw.and_then(|v| v["support_phone"].as_str().map(|p| p.chars().filter(char::is_ascii_digit).collect())).filter(|p: &String| !p.is_empty()))
}

async fn last_sent(db: &PgPool) -> Result<HashMap<String, DateTime<Utc>>, sqlx::Error> {
    let rows: Vec<(String, DateTime<Utc>)> = sqlx::query_as("SELECT alert_key, last_sent_at FROM ops_alerts").fetch_all(db).await?;
    Ok(rows.into_iter().collect())
}

async fn mark_sent(db: &PgPool, rule: &str, now: DateTime<Utc>) -> Result<(), sqlx::Error> {
    sqlx::query(
        "INSERT INTO ops_alerts (alert_key, last_sent_at) VALUES ($1, $2)
         ON CONFLICT (alert_key) DO UPDATE SET last_sent_at = EXCLUDED.last_sent_at",
    )
    .bind(rule)
    .bind(now)
    .execute(db)
    .await
    .map(|_| ())
}

/// Inbox entry, SMS to the owner and push to staff devices. Each channel logs its own failure and the others still go.
async fn deliver(s: &AppState, phone: Option<&str>, f: &Finding) {
    if let Err(e) = notify(s, Recipient::Staff, "ops_alert", f.title, f.body, json!({ "rule": f.rule })).await {
        tracing::warn!(error = %e, rule = f.rule, "ops alert inbox failed");
    }
    let brand = crate::routes::setup::brand_name(&s.db).await;
    if let Some(phone) = phone {
        let text = format!("[{brand}] {}\n{}", f.title, f.body);
        if let Err(e) = s.providers.send_sms(phone, &text).await {
            tracing::warn!(error = %e, rule = f.rule, "ops alert sms failed");
        }
    }
    let tokens: Result<Vec<String>, sqlx::Error> = sqlx::query_scalar("SELECT token FROM push_tokens WHERE owner_role = 'staff'").fetch_all(&s.db).await;
    match tokens {
        Ok(t) if !t.is_empty() => {
            if let Err(e) = s.providers.push(&t, &format!("{brand} 운영 알림"), f.title, &json!({ "kind": "ops_alert", "rule": f.rule })).await {
                tracing::warn!(error = %e, rule = f.rule, "ops alert push failed");
            }
        }
        Ok(_) => {}
        Err(e) => tracing::warn!(error = %e, "ops alert push tokens unreadable"),
    }
}

/// One pass: evaluate, select, deliver, stamp. Returns how many rules fired.
pub async fn run_once(s: &AppState) -> ApiResult<usize> {
    let now = Utc::now();
    let prefs = load_prefs(&s.db).await?;
    let kst = FixedOffset::east_opt(KST_OFFSET_SECS).ok_or(ApiError::Internal("kst offset".into()))?;
    let quiet = in_quiet_hours(now.with_timezone(&kst).hour(), prefs.quiet_start, prefs.quiet_end);
    if quiet {
        return Ok(0);
    }
    ops::prune(&s.db).await?;
    let findings = evaluate(s).await?;
    let last = last_sent(&s.db).await?;
    let chosen = select(&findings, &prefs, &last, now, false);
    if chosen.is_empty() {
        return Ok(0);
    }
    let phone = match prefs.alert_phone.clone() {
        Some(p) => Some(p),
        None => business_phone(&s.db).await?,
    };
    for f in &chosen {
        deliver(s, phone.as_deref(), f).await;
        mark_sent(&s.db, f.rule, now).await?;
    }
    Ok(chosen.len())
}

/// Starts the periodic pass. Errors are logged and the loop goes on.
pub fn spawn(state: AppState) -> JoinHandle<()> {
    let mut stop = state.hub.drain_signal();
    tokio::spawn(async move {
        let mut tick = tokio::time::interval(PASS_EVERY);
        while next_tick(&mut tick, &mut stop).await {
            let ok = match run_once(&state).await {
                Ok(0) => true,
                Ok(fired) => {
                    tracing::warn!(fired, "owner alerts sent");
                    true
                }
                Err(e) => {
                    tracing::warn!(error = %e, "ops alert pass failed");
                    false
                }
            };
            job_pass("ops_alerts", ok);
        }
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;
    use serde_json::json;

    fn at(h: u32, m: u32) -> DateTime<Utc> {
        Utc.with_ymd_and_hms(2026, 11, 11, h, m, 0).unwrap()
    }

    fn finding(rule: &'static str) -> Finding {
        Finding { rule, title: "t", body: "b" }
    }

    #[test]
    fn cooldown_allows_one_message_per_window() {
        assert!(due(at(12, 0), None));
        assert!(!due(at(12, 0), Some(at(9, 0))), "three hours later: still cooling down");
        assert!(due(at(12, 0), Some(at(5, 59))), "six hours is enough");
    }

    #[test]
    fn repeated_passes_do_not_spam() {
        let prefs = Prefs::default();
        let findings = vec![finding("sms_failing")];
        let mut last = HashMap::new();
        let first = select(&findings, &prefs, &last, at(12, 0), false);
        assert_eq!(first.len(), 1);
        last.insert("sms_failing".to_string(), at(12, 0));
        assert!(select(&findings, &prefs, &last, at(12, 5), false).is_empty(), "five minutes later");
        assert!(select(&findings, &prefs, &last, at(13, 0), false).is_empty(), "an hour later");
        assert_eq!(select(&findings, &prefs, &last, at(18, 1), false).len(), 1, "after cooldown, if still failing");
    }

    #[test]
    fn quiet_hours_hold_everything_and_wrap_midnight() {
        assert!(in_quiet_hours(23, 22, 7));
        assert!(in_quiet_hours(3, 22, 7));
        assert!(!in_quiet_hours(7, 22, 7));
        assert!(!in_quiet_hours(12, 22, 7));
        assert!(in_quiet_hours(13, 12, 14));
        assert!(!in_quiet_hours(5, 4, 4), "equal bounds mean no quiet window");
        let prefs = Prefs::default();
        assert!(select(&[finding("disk_low")], &prefs, &HashMap::new(), at(12, 0), true).is_empty());
    }

    #[test]
    fn disabled_rules_stay_silent() {
        let mut prefs = Prefs::default();
        prefs.rules.insert("push_failing".into(), false);
        let findings = vec![finding("push_failing"), finding("disk_low")];
        let chosen = select(&findings, &prefs, &HashMap::new(), at(12, 0), false);
        assert_eq!(chosen.iter().map(|f| f.rule).collect::<Vec<_>>(), vec!["disk_low"]);
    }

    #[test]
    fn input_is_validated_and_unknown_rules_are_dropped() {
        let ok = parse_input(&json!({
            "rules": { "sms_failing": false, "made_up": false },
            "quiet_start": 23, "quiet_end": 6, "alert_phone": "010-1234-5678"
        }))
        .expect("valid");
        assert_eq!(ok.rules.len(), 1);
        assert!(!ok.enabled("sms_failing"));
        assert!(ok.enabled("backup_stale"));
        assert_eq!(ok.alert_phone.as_deref(), Some("01012345678"));
        assert_eq!(parse_input(&json!({"quiet_start": 24, "quiet_end": 6})), Err("invalid_quiet_hours"));
        assert_eq!(parse_input(&json!({"quiet_start": 22, "quiet_end": 7, "alert_phone": "12"})), Err("invalid_phone"));
        let none = parse_input(&json!({"quiet_start": 22, "quiet_end": 7, "alert_phone": " "})).expect("blank phone ok");
        assert_eq!(none.alert_phone, None);
    }
}
