//! Marketing under 정보통신망법 (광고성 정보): campaigns from the console and lifecycle nudges.
//! Every advertising send passes one gate, in this order: marketing consent (privacy.rs), quiet
//! hours (21:00-08:00 KST, 제50조), and the weekly frequency cap. SMS ads carry the `(광고)` prefix
//! and a 무료수신거부 line. The day-before reminder is transactional, so it skips this gate.
//! Channel note: AlimTalk 친구톡 ended on 2025-12-31 (Solapi notice), so campaigns use push and SMS only.

use crate::{
    auth::Admin,
    error::{ApiError, ApiResult},
    lifecycle,
    privacy::{self, CONSENT_VERSION},
    providers::sms::TPL_REMINDER,
    realtime::{Recipient, notify},
    routes::audit,
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Path, State},
    routing::{get, post},
};
use chrono::{DateTime, Duration, NaiveTime, Timelike, Utc};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use sqlx::{PgPool, Postgres, QueryBuilder};
use std::time::Duration as StdDuration;
use tokio::task::JoinHandle;
use uuid::Uuid;

/// 정보통신망법 제50조: advertising is blocked 21:00-08:00 KST.
pub const QUIET_START_HOUR: u32 = 21;
pub const QUIET_END_HOUR: u32 = 8;
/// Advertising messages per customer per rolling 7 days, across campaigns and nudges.
pub const FREQ_CAP_PER_WEEK: i64 = 2;
pub const CHANNELS: [&str; 2] = ["push", "sms"];
/// Days after a completed visit before the re-booking nudge.
pub const NUDGE_REBOOK_DAYS: i32 = 30;
const PASS_EVERY: StdDuration = StdDuration::from_secs(300);
const KST_OFFSET_HOURS: i64 = 9;
const NUDGE_BATCH: i64 = 500;
/// Test texts per admin per hour; each one costs a real SMS.
const TEST_SEND_PER_HOUR: i64 = 5;
const CAMPAIGN_COLS: &str = "id, name, channel, title, body, audience, optout_number, status, scheduled_at, sent_at, created_at";

fn kst(t: DateTime<Utc>) -> chrono::NaiveDateTime {
    t.naive_utc() + Duration::hours(KST_OFFSET_HOURS)
}

/// True inside the 21:00-08:00 KST window, when advertising is not allowed.
pub fn quiet_hours(t: DateTime<Utc>) -> bool {
    let h = kst(t).hour();
    h >= QUIET_START_HOUR || h < QUIET_END_HOUR
}

/// `t` itself outside quiet hours, otherwise the next 08:00 KST.
pub fn next_send_time(t: DateTime<Utc>) -> DateTime<Utc> {
    if !quiet_hours(t) {
        return t;
    }
    let local = kst(t);
    let day = if local.hour() >= QUIET_START_HOUR { local.date().succ_opt().expect("date in range") } else { local.date() };
    let morning = day.and_time(NaiveTime::from_hms_opt(QUIET_END_HOUR, 0, 0).expect("valid time"));
    morning.and_utc() - Duration::hours(KST_OFFSET_HOURS)
}

#[derive(Debug, PartialEq, Eq)]
pub enum Gate {
    Send,
    NoConsent,
    Defer(DateTime<Utc>),
    Capped,
}

/// Whether one advertising message may go to one customer now. Order: consent, quiet hours, cap.
pub fn gate(consent: bool, sent_last_week: i64, now: DateTime<Utc>) -> Gate {
    if !consent {
        Gate::NoConsent
    } else if quiet_hours(now) {
        Gate::Defer(next_send_time(now))
    } else if sent_last_week >= FREQ_CAP_PER_WEEK {
        Gate::Capped
    } else {
        Gate::Send
    }
}

/// Korean SMS advertising format. The opt-out number comes from the campaign (owner's own 080 line).
pub fn sms_ad_text(body: &str, optout: &str) -> String {
    format!("(광고) {body}\n무료수신거부 {optout}")
}

/// Opt-out numbers are digits with optional hyphens, 9 to 12 digits.
pub fn valid_optout(num: &str) -> bool {
    let digits = num.chars().filter(char::is_ascii_digit).count();
    num.chars().all(|c| c.is_ascii_digit() || c == '-') && (9..=12).contains(&digits)
}

#[derive(Debug, Clone, Deserialize, Serialize, PartialEq)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum Segment {
    /// Has booked before, and the last visit was at least N days ago.
    LastBookingOlderThan { days: i64 },
    NeverBooked,
    District { code: String },
    Service { code: String },
    Language { locale: String },
}

fn segment_ok(s: &Segment) -> bool {
    match s {
        Segment::LastBookingOlderThan { days } => (1..=3650).contains(days),
        Segment::NeverBooked => true,
        Segment::District { code } | Segment::Service { code } => {
            (1..=20).contains(&code.len()) && code.chars().all(|c| c.is_ascii_alphanumeric() || c == '_')
        }
        Segment::Language { locale } => crate::routes::me::SUPPORTED_LOCALES.contains(&locale.as_str()),
    }
}

/// Base audience: live customers with a phone. Each segment narrows it with an AND.
fn push_audience(qb: &mut QueryBuilder<'_, Postgres>, segments: &[Segment]) {
    qb.push("SELECT u.id, u.phone, u.locale FROM users u WHERE u.deleted_at IS NULL AND u.phone NOT LIKE 'deleted:%'");
    for seg in segments {
        qb.push(" AND ");
        match seg {
            Segment::LastBookingOlderThan { days } => {
                qb.push("(SELECT max(b.visit_date) FROM bookings b WHERE b.user_id = u.id AND b.status BETWEEN 1 AND 3) < (now() AT TIME ZONE 'Asia/Seoul')::date - ");
                qb.push_bind(*days as i32);
            }
            Segment::NeverBooked => {
                qb.push("NOT EXISTS (SELECT 1 FROM bookings b WHERE b.user_id = u.id AND b.status BETWEEN 1 AND 3)");
            }
            Segment::District { code } => {
                qb.push("EXISTS (SELECT 1 FROM addresses a WHERE a.user_id = u.id AND a.deleted_at IS NULL AND a.district_code = ");
                qb.push_bind(code.clone());
                qb.push(")");
            }
            Segment::Service { code } => {
                qb.push("EXISTS (SELECT 1 FROM bookings b WHERE b.user_id = u.id AND b.service_code = ");
                qb.push_bind(code.clone());
                qb.push(")");
            }
            Segment::Language { locale } => {
                qb.push("u.locale = ");
                qb.push_bind(locale.clone());
            }
        }
    }
}

/// Latest marketing consent row is a grant for the current policy version.
fn push_consented(qb: &mut QueryBuilder<'_, Postgres>) {
    qb.push("EXISTS (SELECT 1 FROM (SELECT DISTINCT ON (kind) kind, granted, version FROM user_consents WHERE user_id = u.id ORDER BY kind, created_at DESC, id DESC) c WHERE c.kind = 'marketing' AND c.granted AND c.version = ");
    qb.push_bind(CONSENT_VERSION);
    qb.push(")");
}

#[derive(sqlx::FromRow)]
struct Target {
    id: Uuid,
    phone: String,
}

async fn audience(db: &PgPool, segments: &[Segment]) -> sqlx::Result<Vec<Target>> {
    let mut qb = QueryBuilder::new("");
    push_audience(&mut qb, segments);
    qb.build_query_as::<Target>().fetch_all(db).await
}

/// Copy for one advertising message. `kind` is the notify kind, which must start with `marketing.`.
pub struct Copy<'a> {
    pub kind: &'static str,
    pub title: &'a str,
    pub body: &'a str,
    pub optout: &'a str,
}

async fn sent_last_week(db: &PgPool, user: Uuid) -> sqlx::Result<i64> {
    sqlx::query_scalar("SELECT count(*) FROM marketing_sends WHERE user_id = $1 AND status = 'sent' AND created_at > now() - interval '7 days'")
        .bind(user)
        .fetch_one(db)
        .await
}

enum Step {
    Done,
    Deferred(DateTime<Utc>),
}

/// Runs the gate for one customer and one channel. Idempotent: a recorded dedupe key is never sent again.
/// Capped customers are not recorded, so a later pass can still reach them.
async fn advertise(s: &AppState, t: &Target, channel: &str, scope: &str, campaign: Option<Uuid>, copy: &Copy<'_>, seam: Option<DateTime<Utc>>) -> ApiResult<Step> {
    let key = format!("{scope}:{}:{channel}", t.id);
    let seen: Option<i64> = sqlx::query_scalar("SELECT 1::bigint FROM marketing_sends WHERE dedupe_key = $1").bind(&key).fetch_optional(&s.db).await?;
    if seen.is_some() {
        return Ok(Step::Done);
    }
    let consent = privacy::marketing_allowed(&s.db, t.id).await?;
    let weekly = sent_last_week(&s.db, t.id).await?;
    // Read the clock per customer: a long pass must not send at a time that was quiet when it started.
    let now = seam.unwrap_or_else(Utc::now);
    let (status, error) = match gate(consent, weekly, now) {
        Gate::Defer(at) => return Ok(Step::Deferred(at)),
        Gate::Capped => return Ok(Step::Done),
        Gate::NoConsent => ("skipped_consent", None),
        Gate::Send => match deliver(s, t, channel, copy).await {
            Ok(()) => ("sent", None),
            Err(code) => ("failed", Some(code)),
        },
    };
    sqlx::query("INSERT INTO marketing_sends (dedupe_key, campaign_id, user_id, channel, status, error) VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT (dedupe_key) DO NOTHING")
        .bind(&key)
        .bind(campaign)
        .bind(t.id)
        .bind(channel)
        .bind(status)
        .bind(error)
        .execute(&s.db)
        .await?;
    Ok(Step::Done)
}

/// Sends through the channel's provider. Errors are fixed codes, so no provider detail reaches the log table.
async fn deliver(s: &AppState, t: &Target, channel: &str, copy: &Copy<'_>) -> Result<(), &'static str> {
    match channel {
        "push" => {
            // Advertising push carries the (광고) marker and how to opt out (정보통신망법 제50조).
            let title = format!("(광고) {}", copy.title);
            let body = format!("{}\n광고 수신은 설정 > 알림에서 끌 수 있어요", copy.body);
            notify(s, Recipient::User(t.id), copy.kind, &title, &body, json!({ "marketing": true })).await.map_err(|_| "push_failed")
        }
        "sms" => s.providers.send_sms(&t.phone, &sms_ad_text(copy.body, copy.optout)).await.map_err(|_| "sms_failed"),
        _ => Err("unknown_channel"),
    }
}

#[derive(sqlx::FromRow, Serialize)]
pub struct CampaignRow {
    id: Uuid,
    name: String,
    channel: String,
    title: String,
    body: String,
    audience: Value,
    optout_number: Option<String>,
    status: String,
    scheduled_at: Option<DateTime<Utc>>,
    sent_at: Option<DateTime<Utc>>,
    created_at: DateTime<Utc>,
}

enum Run {
    Done,
    Deferred(DateTime<Utc>),
}

async fn run_campaign(s: &AppState, c: &CampaignRow, seam: Option<DateTime<Utc>>) -> ApiResult<Run> {
    let segments: Vec<Segment> = serde_json::from_value(c.audience.clone()).map_err(|_| ApiError::Internal("campaign audience".into()))?;
    let copy = Copy { kind: "marketing.campaign", title: &c.title, body: &c.body, optout: c.optout_number.as_deref().unwrap_or("") };
    let scope = format!("campaign:{}", c.id);
    for t in audience(&s.db, &segments).await? {
        if let Step::Deferred(at) = advertise(s, &t, &c.channel, &scope, Some(c.id), &copy, seam).await? {
            return Ok(Run::Deferred(at));
        }
    }
    Ok(Run::Done)
}

async fn reopen(db: &PgPool, id: Uuid, at: DateTime<Utc>) -> sqlx::Result<u64> {
    Ok(sqlx::query("UPDATE campaigns SET status = 'scheduled', scheduled_at = $2 WHERE id = $1").bind(id).bind(at).execute(db).await?.rows_affected())
}

/// Picks up due campaigns. A campaign that hits quiet hours goes back to `scheduled` for 08:00 KST and resumes
/// there, skipping customers already recorded.
pub async fn dispatch_due(s: &AppState) -> ApiResult<usize> {
    dispatch_seam(s, None).await
}

/// `dispatch_due` at an explicit instant, so quiet hours can be tested without the wall clock.
pub async fn dispatch_at(s: &AppState, now: DateTime<Utc>) -> ApiResult<usize> {
    dispatch_seam(s, Some(now)).await
}

async fn dispatch_seam(s: &AppState, seam: Option<DateTime<Utc>>) -> ApiResult<usize> {
    let due: Vec<Uuid> = sqlx::query_scalar("SELECT id FROM campaigns WHERE status = 'scheduled' AND scheduled_at <= now() ORDER BY scheduled_at LIMIT 20")
        .fetch_all(&s.db)
        .await?;
    let mut ran = 0;
    for id in due {
        let claimed: Option<CampaignRow> = sqlx::query_as(&format!("UPDATE campaigns SET status = 'sending' WHERE id = $1 AND status = 'scheduled' RETURNING {CAMPAIGN_COLS}"))
            .bind(id)
            .fetch_optional(&s.db)
            .await?;
        let Some(c) = claimed else {
            continue;
        };
        ran += 1;
        let outcome = match run_campaign(s, &c, seam).await {
            Ok(Run::Done) => sqlx::query("UPDATE campaigns SET status = 'sent', sent_at = now() WHERE id = $1").bind(id).execute(&s.db).await.map(|_| ()).map_err(ApiError::from),
            Ok(Run::Deferred(at)) => reopen(&s.db, id, at).await.map(|_| ()).map_err(ApiError::from),
            Err(e) => {
                tracing::warn!(error = %e, campaign = %id, "campaign run failed; retry in 10 minutes");
                reopen(&s.db, id, Utc::now() + Duration::minutes(10)).await.map(|_| ()).map_err(ApiError::from)
            }
        };
        if let Err(e) = outcome {
            tracing::warn!(error = %e, campaign = %id, "campaign status update failed");
        }
    }
    Ok(ran)
}

/// Re-booking nudge (N days after a completed visit, no later booking) and abandoned-quote nudge (quote
/// requested 24-48 hours ago, not paid). Both are push only and skipped in quiet hours.
pub async fn run_nudges(s: &AppState) -> ApiResult<usize> {
    run_nudges_seam(s, None).await
}

/// `run_nudges` at an explicit instant. Quiet hours are checked against `now`; the SQL windows use DB time.
pub async fn run_nudges_at(s: &AppState, now: DateTime<Utc>) -> ApiResult<usize> {
    run_nudges_seam(s, Some(now)).await
}

async fn run_nudges_seam(s: &AppState, seam: Option<DateTime<Utc>>) -> ApiResult<usize> {
    if quiet_hours(seam.unwrap_or_else(Utc::now)) {
        return Ok(0);
    }
    let rebook: Vec<(Uuid, Uuid, String, String)> = sqlx::query_as(
        "SELECT b.id, u.id, u.phone, u.locale FROM bookings b JOIN users u ON u.id = b.user_id
         WHERE b.status = 3 AND b.visit_date = (now() AT TIME ZONE 'Asia/Seoul')::date - $1::int
           AND u.deleted_at IS NULL AND u.phone NOT LIKE 'deleted:%'
           AND NOT EXISTS (SELECT 1 FROM bookings n WHERE n.user_id = b.user_id AND n.status BETWEEN 0 AND 3 AND n.created_at > b.created_at)
         LIMIT $2",
    )
    .bind(NUDGE_REBOOK_DAYS)
    .bind(NUDGE_BATCH)
    .fetch_all(&s.db)
    .await?;
    let quotes: Vec<(Uuid, Uuid, String, String)> = sqlx::query_as(
        "SELECT b.id, u.id, u.phone, u.locale FROM bookings b JOIN users u ON u.id = b.user_id
         WHERE b.status = 0 AND b.created_at BETWEEN now() - interval '48 hours' AND now() - interval '24 hours'
           AND u.deleted_at IS NULL AND u.phone NOT LIKE 'deleted:%'
           AND NOT EXISTS (SELECT 1 FROM checkouts k WHERE k.booking_id = b.id AND k.status = 'paid')
         LIMIT $1",
    )
    .bind(NUDGE_BATCH)
    .fetch_all(&s.db)
    .await?;
    let mut sent = 0;
    // Korean source text: notify() translates push and inbox copy into the recipient's language.
    let rebook_copy = Copy { kind: "marketing.rebook", title: "다음 청소를 예약해 보세요", body: "지난번과 같은 조건으로 빠르게 예약할 수 있어요", optout: "" };
    let quote_copy = Copy { kind: "marketing.quote", title: "견적 요청이 아직 남아 있어요", body: "원하는 시간에 청소팀을 바로 받아 보세요", optout: "" };
    for (booking, user, phone, _locale) in rebook {
        let t = Target { id: user, phone };
        if let Step::Done = advertise(s, &t, "push", &format!("nudge:rebook:{booking}"), None, &rebook_copy, seam).await? {
            sent += 1;
        }
    }
    for (booking, user, phone, _locale) in quotes {
        let t = Target { id: user, phone };
        if let Step::Done = advertise(s, &t, "push", &format!("nudge:quote:{booking}"), None, &quote_copy, seam).await? {
            sent += 1;
        }
    }
    Ok(sent)
}

/// Day-before reminder for confirmed or assigned bookings. Transactional, so no marketing gate.
/// Claimed once per booking through alert_sends. Korean customers get AlimTalk (SMS fallback); others get SMS.
pub async fn send_reminders(s: &AppState) -> ApiResult<usize> {
    let rows: Vec<(Uuid, String, String, String)> = sqlx::query_as(
        "SELECT b.id, b.number, u.phone, u.locale FROM bookings b JOIN users u ON u.id = b.user_id
         WHERE b.status IN (1, 2) AND b.visit_date = (now() AT TIME ZONE 'Asia/Seoul')::date + 1
           AND u.deleted_at IS NULL AND u.phone NOT LIKE 'deleted:%'
         LIMIT $1",
    )
    .bind(NUDGE_BATCH)
    .fetch_all(&s.db)
    .await?;
    let mut sent = 0;
    for (id, number, phone, locale) in rows {
        let claimed = sqlx::query("INSERT INTO alert_sends (dedupe_key) VALUES ($1) ON CONFLICT DO NOTHING")
            .bind(format!("reminder:{id}"))
            .execute(&s.db)
            .await?
            .rows_affected();
        if claimed == 0 {
            continue;
        }
        let title = crate::i18n::tr(&locale, "내일 청소 예정이에요");
        let sent_result = if locale == "ko" {
            let brand = crate::routes::setup::brand_name(&s.db).await;
            s.providers.send_customer_message(&phone, TPL_REMINDER, &brand, "내일 청소 예정이에요", &number).await
        } else {
            s.providers.send_sms(&phone, &format!("{title}\n{number}")).await
        };
        match sent_result {
            Ok(()) => sent += 1,
            Err(e) => tracing::warn!(error = %e, "reminder failed"),
        }
    }
    Ok(sent)
}

/// Starts the periodic pass: due campaigns, nudges, reminders. Each step logs its own failure.
pub fn spawn(state: AppState) -> JoinHandle<()> {
    let mut stop = state.hub.drain_signal();
    tokio::spawn(async move {
        let mut tick = tokio::time::interval(PASS_EVERY);
        while lifecycle::next_tick(&mut tick, &mut stop).await {
            if let Err(e) = dispatch_due(&state).await {
                tracing::warn!(error = %e, job = "campaigns", "marketing pass failed");
            }
            if let Err(e) = run_nudges(&state).await {
                tracing::warn!(error = %e, job = "nudges", "marketing pass failed");
            }
            if let Err(e) = send_reminders(&state).await {
                tracing::warn!(error = %e, job = "reminders", "marketing pass failed");
            }
        }
    })
}

#[derive(Deserialize)]
pub struct NewCampaign {
    name: String,
    channel: String,
    title: String,
    body: String,
    #[serde(default)]
    audience: Vec<Segment>,
    optout_number: Option<String>,
}

fn validate(c: &NewCampaign) -> ApiResult<()> {
    if !CHANNELS.contains(&c.channel.as_str()) {
        return Err(ApiError::BadRequest("channel"));
    }
    if !(1..=60).contains(&c.name.trim().chars().count()) || !(1..=60).contains(&c.title.chars().count()) {
        return Err(ApiError::BadRequest("name_or_title"));
    }
    if !(1..=500).contains(&c.body.chars().count()) {
        return Err(ApiError::BadRequest("body"));
    }
    if c.channel == "sms" && !c.optout_number.as_deref().is_some_and(valid_optout) {
        return Err(ApiError::BadRequest("optout_number"));
    }
    if !c.audience.iter().all(segment_ok) {
        return Err(ApiError::BadRequest("audience"));
    }
    Ok(())
}

pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/campaigns", get(list).post(create))
        .route("/campaigns/preview", post(preview))
        .route("/campaigns/test", post(test_send))
        .route("/campaigns/{id}", get(detail))
        .route("/campaigns/{id}/schedule", post(schedule))
        .route("/campaigns/{id}/cancel", post(cancel))
}

async fn list(State(s): State<AppState>, _st: Admin) -> ApiResult<Json<Vec<CampaignRow>>> {
    let rows = sqlx::query_as(&format!("SELECT {CAMPAIGN_COLS} FROM campaigns ORDER BY created_at DESC LIMIT 100")).fetch_all(&s.db).await?;
    Ok(Json(rows))
}

async fn create(State(s): State<AppState>, Admin(st): Admin, Json(c): Json<NewCampaign>) -> ApiResult<Json<CampaignRow>> {
    validate(&c)?;
    let audience = serde_json::to_value(&c.audience).map_err(|_| ApiError::BadRequest("audience"))?;
    let row: CampaignRow = sqlx::query_as(&format!(
        "INSERT INTO campaigns (name, channel, title, body, audience, optout_number, created_by) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING {CAMPAIGN_COLS}"
    ))
    .bind(c.name.trim())
    .bind(&c.channel)
    .bind(&c.title)
    .bind(&c.body)
    .bind(audience)
    .bind(c.optout_number.as_deref())
    .bind(st.id)
    .fetch_one(&s.db)
    .await?;
    audit(&s.db, "staff", Some(st.id), "campaign.create", &row.id.to_string(), json!({ "channel": row.channel })).await?;
    Ok(Json(row))
}

async fn detail(State(s): State<AppState>, _st: Admin, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    let row: CampaignRow = sqlx::query_as(&format!("SELECT {CAMPAIGN_COLS} FROM campaigns WHERE id = $1")).bind(id).fetch_optional(&s.db).await?.ok_or(ApiError::NotFound)?;
    let stats: Vec<(String, i64)> = sqlx::query_as("SELECT status, count(*) FROM marketing_sends WHERE campaign_id = $1 GROUP BY status").bind(id).fetch_all(&s.db).await?;
    let stats: serde_json::Map<String, Value> = stats.into_iter().map(|(k, v)| (k, json!(v))).collect();
    Ok(Json(json!({ "campaign": row, "stats": stats })))
}

#[derive(Deserialize)]
pub struct ScheduleBody {
    /// None sends as soon as the next pass runs (within 5 minutes).
    at: Option<DateTime<Utc>>,
}

async fn schedule(State(s): State<AppState>, Admin(st): Admin, Path(id): Path<Uuid>, Json(b): Json<ScheduleBody>) -> ApiResult<Json<CampaignRow>> {
    let at = b.at.unwrap_or_else(Utc::now).max(Utc::now());
    let row: Option<CampaignRow> = sqlx::query_as(&format!(
        "UPDATE campaigns SET status = 'scheduled', scheduled_at = $2 WHERE id = $1 AND status IN ('draft', 'scheduled') RETURNING {CAMPAIGN_COLS}"
    ))
    .bind(id)
    .bind(at)
    .fetch_optional(&s.db)
    .await?;
    let row = row.ok_or(ApiError::Conflict("campaign_closed"))?;
    audit(&s.db, "staff", Some(st.id), "campaign.schedule", &id.to_string(), json!({ "at": at })).await?;
    Ok(Json(row))
}

async fn cancel(State(s): State<AppState>, Admin(st): Admin, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    let done = sqlx::query("UPDATE campaigns SET status = 'cancelled' WHERE id = $1 AND status IN ('draft', 'scheduled')").bind(id).execute(&s.db).await?.rows_affected();
    if done == 0 {
        return Err(ApiError::Conflict("campaign_closed"));
    }
    audit(&s.db, "staff", Some(st.id), "campaign.cancel", &id.to_string(), json!({})).await?;
    Ok(Json(json!({ "ok": true })))
}

#[derive(Deserialize)]
pub struct PreviewBody {
    #[serde(default)]
    audience: Vec<Segment>,
}

/// Audience size before sending: everyone matching the segments, and how many of them hold marketing consent.
async fn preview(State(s): State<AppState>, _st: Admin, Json(b): Json<PreviewBody>) -> ApiResult<Json<Value>> {
    if !b.audience.iter().all(segment_ok) {
        return Err(ApiError::BadRequest("audience"));
    }
    let mut qb = QueryBuilder::new("SELECT count(*), count(*) FILTER (WHERE ");
    push_consented(&mut qb);
    qb.push(") FROM (");
    push_audience(&mut qb, &b.audience);
    qb.push(") u");
    let (total, consented) = qb.build_query_as::<(i64, i64)>().fetch_one(&s.db).await?;
    Ok(Json(json!({ "total": total, "consented": consented })))
}

#[derive(Deserialize)]
pub struct TestBody {
    phone: String,
    body: String,
    optout_number: String,
}

/// Test send to the operator's own phone, SMS format (with the (광고) prefix and opt-out line). Not logged
/// as a campaign and not a customer send, so it skips consent and the frequency cap.
async fn test_send(State(s): State<AppState>, Admin(st): Admin, Json(b): Json<TestBody>) -> ApiResult<Json<Value>> {
    let phone: String = b.phone.chars().filter(char::is_ascii_digit).collect();
    if !(10..=11).contains(&phone.len()) || !phone.starts_with('0') {
        return Err(ApiError::BadRequest("phone"));
    }
    if !valid_optout(&b.optout_number) || !(1..=500).contains(&b.body.chars().count()) {
        return Err(ApiError::BadRequest("body_or_optout"));
    }
    // Only the owner's own phone (the alert phone) may receive a test, so a staff login cannot text arbitrary numbers.
    let own = crate::ops_alerts::load_prefs(&s.db).await?.alert_phone.unwrap_or_default();
    if own.is_empty() || own != phone {
        return Err(ApiError::BadRequest("phone_not_own"));
    }
    let recent: i64 = sqlx::query_scalar("SELECT count(*) FROM audit_log WHERE actor_id = $1 AND action = 'campaign.test_send' AND created_at > now() - interval '1 hour'")
        .bind(st.id)
        .fetch_one(&s.db)
        .await?;
    if recent >= TEST_SEND_PER_HOUR {
        return Err(ApiError::RateLimited);
    }
    s.providers.send_sms(&phone, &sms_ad_text(&b.body, &b.optout_number)).await.map_err(|_| ApiError::Unavailable("sms"))?;
    audit(&s.db, "staff", Some(st.id), "campaign.test_send", "self", json!({ "channel": "sms" })).await?;
    Ok(Json(json!({ "ok": true })))
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    fn kst_at(h: u32, m: u32) -> DateTime<Utc> {
        // 2026-11-11 HH:MM KST = previous day 15:00+m UTC offset arithmetic.
        Utc.with_ymd_and_hms(2026, 11, 11, h, m, 0).single().expect("valid") - Duration::hours(KST_OFFSET_HOURS)
    }

    #[test]
    fn quiet_hours_are_21_to_08_kst_and_nothing_else() {
        assert!(!quiet_hours(kst_at(20, 59)));
        assert!(quiet_hours(kst_at(21, 0)));
        assert!(quiet_hours(kst_at(23, 30)));
        assert!(quiet_hours(kst_at(0, 0)));
        assert!(quiet_hours(kst_at(7, 59)));
        assert!(!quiet_hours(kst_at(8, 0)));
        assert!(!quiet_hours(kst_at(12, 0)));
    }

    #[test]
    fn deferred_sends_wait_for_0800_kst_the_same_or_next_morning() {
        assert_eq!(next_send_time(kst_at(12, 0)), kst_at(12, 0));
        assert_eq!(next_send_time(kst_at(23, 0)), Utc.with_ymd_and_hms(2026, 11, 12, 8, 0, 0).single().expect("v") - Duration::hours(9));
        assert_eq!(next_send_time(kst_at(3, 0)), kst_at(8, 0));
    }

    #[test]
    fn gate_checks_consent_then_quiet_hours_then_frequency_cap() {
        let day = kst_at(12, 0);
        assert_eq!(gate(false, 0, day), Gate::NoConsent);
        assert_eq!(gate(false, 99, kst_at(23, 0)), Gate::NoConsent, "consent is checked before quiet hours");
        assert_eq!(gate(true, 0, kst_at(23, 0)), Gate::Defer(next_send_time(kst_at(23, 0))));
        assert_eq!(gate(true, FREQ_CAP_PER_WEEK - 1, day), Gate::Send);
        assert_eq!(gate(true, FREQ_CAP_PER_WEEK, day), Gate::Capped);
    }

    #[test]
    fn sms_ad_text_has_prefix_and_opt_out_line() {
        assert_eq!(sms_ad_text("이번 주 할인", "080-123-4567"), "(광고) 이번 주 할인\n무료수신거부 080-123-4567");
    }

    #[test]
    fn opt_out_number_must_be_digits_with_optional_hyphens() {
        assert!(valid_optout("080-123-4567"));
        assert!(valid_optout("0801234567"));
        assert!(!valid_optout("080-abc-4567"));
        assert!(!valid_optout("123"));
    }

    #[test]
    fn segment_validation_rejects_bad_codes_and_locales() {
        assert!(segment_ok(&Segment::LastBookingOlderThan { days: 30 }));
        assert!(!segment_ok(&Segment::LastBookingOlderThan { days: 0 }));
        assert!(segment_ok(&Segment::District { code: "11680".into() }));
        assert!(!segment_ok(&Segment::District { code: "1 OR 1=1".into() }));
        assert!(segment_ok(&Segment::Language { locale: "vi".into() }));
        assert!(!segment_ok(&Segment::Language { locale: "xx".into() }));
    }
}
