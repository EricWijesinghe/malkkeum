//! Subscription engine, one pass every few minutes:
//! 1. plans visits up to `HORIZON_DAYS` ahead for active subscriptions (preferred arrival window first, then any free one);
//! 2. charges each planned visit that is due tomorrow: booking and charge in one transaction, so a declined card leaves no booking;
//! 3. a failed charge retries after `RETRY_AFTER_HOURS`; `PAUSE_AFTER_FAILURES` in a row pauses the subscription;
//! 4. planned visits whose day has arrived without a charge become `missed`.

use super::{
    booking_core::{BookingBody, Prepared, after_booking_created, insert_paid, lock_slot, prepare, record_payment},
    partner_jobs::VISIBLE,
};
use crate::{
    error::{ApiError, ApiResult},
    providers::ProviderError,
    realtime::{Recipient, notify},
    state::AppState,
    util::{KST_TODAY, best_effort, lock_and_count_slot, refund_or_alert, today_kst},
};
use chrono::{Duration, NaiveDate, Utc};
use domain::{
    Won,
    pricing::{PriceBreakdown, price_booking},
    schedule::{STANDARD_SLOTS, check_capacity},
    subscription::{Cadence, HORIZON_DAYS, Retry, after_failure, visit_dates, visit_price},
};
use serde_json::{Value, json};
use sqlx::{PgConnection, PgPool};
use std::time::Duration as StdDuration;
use tokio::task::JoinHandle;
use uuid::Uuid;

const PASS_EVERY: StdDuration = StdDuration::from_secs(5 * 60);
const DUE_BATCH: i64 = 200;

#[derive(Debug, Default, PartialEq, Eq)]
pub struct PassReport {
    pub planned: usize,
    pub booked: usize,
    pub failed: usize,
    pub missed: usize,
}

#[derive(sqlx::FromRow)]
struct Due {
    visit_id: Uuid,
    sub_id: Uuid,
    user_id: Uuid,
    visit_date: NaiveDate,
    start_hour: i16,
}

#[derive(sqlx::FromRow)]
struct SubRow {
    user_id: Uuid,
    service_code: String,
    unit_index: Option<i16>,
    address_id: Uuid,
    payment_method_id: Uuid,
    preferred_pro_id: Option<Uuid>,
    discount_percent: i16,
}

/// Why a charge did not book. Declines and blocked attempts both retry; only a decline is a card problem.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Failure {
    Declined(String),
    Blocked,
}

#[derive(Debug, PartialEq, Eq)]
enum Attempt {
    Booked(Uuid),
    Failed(Failure),
    /// The subscription was paused or cancelled, or the visit moved, since the pass started.
    Skipped,
}

pub fn spawn(state: AppState) -> JoinHandle<()> {
    let mut stop = state.hub.drain_signal();
    tokio::spawn(async move {
        let mut tick = tokio::time::interval(PASS_EVERY);
        while crate::lifecycle::next_tick(&mut tick, &mut stop).await {
            if let Err(e) = pass(&state).await {
                tracing::warn!(error = %e, "subscription pass failed");
            }
        }
    })
}

/// One full pass. Each step logs its own errors so a bad row cannot stop the others.
pub async fn pass(s: &AppState) -> ApiResult<PassReport> {
    let planned = plan(s).await?;
    let (booked, failed) = charge_due(s).await?;
    let missed = expire(s).await?;
    Ok(PassReport { planned, booked, failed, missed })
}

/// Plans visits for every active subscription inside the horizon. Returns how many were added.
async fn plan(s: &AppState) -> ApiResult<usize> {
    let subs: Vec<(Uuid,)> = sqlx::query_as("SELECT id FROM subscriptions WHERE status = 'active'").fetch_all(&s.db).await?;
    let mut added = 0;
    for (sub,) in subs {
        match plan_subscription(&s.db, sub).await {
            Ok(n) => added += n,
            Err(e) => tracing::warn!(error = %e, subscription = %sub, "planning a subscription failed"),
        }
    }
    Ok(added)
}

/// Plans one active subscription's visits inside the horizon. Used on create and on every pass.
pub async fn plan_subscription(db: &PgPool, sub: Uuid) -> ApiResult<usize> {
    let row: Option<(i16, NaiveDate, i16)> = sqlx::query_as("SELECT cadence_weeks, anchor_date, start_hour FROM subscriptions WHERE id = $1 AND status = 'active'")
        .bind(sub)
        .fetch_optional(db)
        .await?;
    let Some((weeks, anchor, hour)) = row else {
        return Ok(0);
    };
    let cadence = Cadence::from_weeks(i64::from(weeks))?;
    let (from, until) = (today_kst() + Duration::days(1), today_kst() + Duration::days(HORIZON_DAYS));
    let mut added = 0;
    for date in visit_dates(anchor, cadence, from, until) {
        if plan_visit(db, sub, date, hour as u8).await? {
            added += 1;
        }
    }
    Ok(added)
}

async fn plan_visit(db: &PgPool, sub: Uuid, date: NaiveDate, preferred: u8) -> ApiResult<bool> {
    let mut tx = db.begin().await?;
    let hour = free_hour(&mut tx, date, preferred).await?;
    let inserted = sqlx::query(
        "INSERT INTO subscription_visits (subscription_id, visit_date, start_hour) VALUES ($1, $2, $3) ON CONFLICT (subscription_id, visit_date) DO NOTHING",
    )
    .bind(sub)
    .bind(date)
    .bind(i16::from(hour))
    .execute(&mut *tx)
    .await?
    .rows_affected();
    tx.commit().await?;
    Ok(inserted == 1)
}

/// The customer's arrival window when it has room, else the first standard window that does.
/// When every window is full the preferred one is kept, and the charge step reports the shortage.
async fn free_hour(conn: &mut PgConnection, date: NaiveDate, preferred: u8) -> ApiResult<u8> {
    let order = std::iter::once(preferred).chain(STANDARD_SLOTS.iter().copied().filter(|h| *h != preferred));
    for hour in order {
        let (used, cap) = lock_and_count_slot(conn, date, hour, None).await?;
        if check_capacity(used, cap).is_ok() {
            return Ok(hour);
        }
    }
    Ok(preferred)
}

/// Charges every planned visit due tomorrow (KST) whose retry time has come. Returns (booked, failed).
async fn charge_due(s: &AppState) -> ApiResult<(usize, usize)> {
    let due: Vec<Due> = sqlx::query_as(&format!(
        "SELECT v.id AS visit_id, s.id AS sub_id, s.user_id, v.visit_date, v.start_hour
         FROM subscription_visits v JOIN subscriptions s ON s.id = v.subscription_id
         WHERE v.state = 'planned' AND s.status = 'active' AND v.visit_date = {KST_TODAY} + 1
           AND (v.retry_at IS NULL OR v.retry_at <= now())
         ORDER BY v.start_hour, v.id LIMIT $1"
    ))
    .bind(DUE_BATCH)
    .fetch_all(&s.db)
    .await?;
    let (mut booked, mut failed) = (0, 0);
    for d in &due {
        match charge_visit(s, d).await {
            Ok(Attempt::Booked(_)) => booked += 1,
            Ok(Attempt::Failed(f)) => {
                failed += 1;
                if let Err(e) = record_failure(s, d, &f).await {
                    tracing::warn!(error = %e, visit = %d.visit_id, "recording a failed charge failed");
                }
            }
            Ok(Attempt::Skipped) => {}
            Err(e) => tracing::warn!(error = %e, visit = %d.visit_id, "subscription charge errored; retried next pass"),
        }
    }
    Ok((booked, failed))
}

/// Converts a booking-side refusal (bad address, full slot, missing card) into a retryable failure.
/// Internal and database errors are not refusals, so they propagate.
fn blocked(e: ApiError) -> ApiResult<Attempt> {
    match e {
        ApiError::Db(_) | ApiError::Internal(_) => Err(e),
        other => {
            tracing::warn!(error = %other, "subscription visit blocked");
            Ok(Attempt::Failed(Failure::Blocked))
        }
    }
}

async fn charge_visit(s: &AppState, d: &Due) -> ApiResult<Attempt> {
    let sub: SubRow = sqlx::query_as(
        "SELECT user_id, service_code, unit_index, address_id, payment_method_id, preferred_pro_id, discount_percent FROM subscriptions WHERE id = $1",
    )
    .bind(d.sub_id)
    .fetch_one(&s.db)
    .await?;
    let body = BookingBody {
        service_code: sub.service_code.clone(),
        unit_index: sub.unit_index.map(|u| u as usize),
        address_id: sub.address_id,
        visit_date: d.visit_date,
        start_hour: d.start_hour as u8,
        coupon_id: None,
        answers: None,
        visit_notes: Value::Null,
        household: None,
    };
    let prep = match prepare(&s.db, sub.user_id, &body).await {
        Ok(p) => p,
        Err(e) => return blocked(e),
    };
    let list = price_booking(&prep.service, body.unit_index, None, Utc::now())?;
    let vp = visit_price(list.list_price.0, u8::try_from(sub.discount_percent).unwrap_or(0))?;
    let price = PriceBreakdown { list_price: list.list_price, discount: Won(vp.discount), total: Won(vp.total), minutes: list.minutes };
    let key: Option<String> = sqlx::query_scalar("SELECT billing_key FROM payment_methods WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL")
        .bind(sub.payment_method_id)
        .bind(sub.user_id)
        .fetch_optional(&s.db)
        .await?;
    let Some(key) = key else {
        return Ok(Attempt::Failed(Failure::Blocked));
    };
    book_and_charge(s, d, &sub, &prep, &body, &price, &key).await
}

/// One transaction: lock the subscription, take the slot, insert the paid booking, then charge.
/// A decline or a refusal returns before commit, so nothing is stored. A charge that cannot be saved is refunded.
#[allow(clippy::too_many_arguments)]
async fn book_and_charge(
    s: &AppState,
    d: &Due,
    sub: &SubRow,
    prep: &Prepared,
    body: &BookingBody,
    price: &PriceBreakdown,
    key: &str,
) -> ApiResult<Attempt> {
    let id = Uuid::now_v7();
    let mut tx = s.db.begin().await?;
    let live: Option<(String, String)> = sqlx::query_as(
        "SELECT s.status, v.state FROM subscription_visits v JOIN subscriptions s ON s.id = v.subscription_id
         WHERE v.id = $1 FOR UPDATE OF s, v",
    )
    .bind(d.visit_id)
    .fetch_optional(&mut *tx)
    .await?;
    if !matches!(&live, Some((status, state)) if status == "active" && state == "planned") {
        return Ok(Attempt::Skipped);
    }
    if let Err(e) = lock_slot(&mut tx, d.visit_date, d.start_hour as u8).await {
        return blocked(e);
    }
    let number = insert_paid(&mut tx, &s.config.data_key, id, d.user_id, prep, body, price).await?;
    // PortOne payment ids allow only [A-Za-z0-9_-], so no colon here.
    let idem = format!("subscription-{id}");
    let tx_id = if price.total.0 > 0 {
        match s.providers.charge_billing(key, price.total.0, &idem, "정기 청소", d.user_id).await {
            Ok(t) => Some(t),
            Err(ProviderError::Declined(code)) => return Ok(Attempt::Failed(Failure::Declined(code))),
            Err(e) => {
                tracing::warn!(error = %e, "subscription charge unavailable");
                return Ok(Attempt::Failed(Failure::Blocked));
            }
        }
    } else {
        None
    };
    if let Some(t) = &tx_id
        && let Err(e) = record_payment(&mut tx, id, price.total.0, "full", "portone", t, &idem).await
    {
        refund_or_alert(s, "portone", t, price.total.0).await;
        return Err(e);
    }
    let saved = commit_booking(tx, id, d, sub).await;
    match saved {
        Ok(()) => {
            after_booking_created(s, id, &number).await;
            Ok(Attempt::Booked(id))
        }
        Err(e) => {
            if let Some(t) = &tx_id {
                refund_or_alert(s, "portone", t, price.total.0).await;
            }
            Err(e)
        }
    }
}

/// Links the booking to the subscription, pins the preferred partner when free, and marks the visit booked.
async fn commit_booking(mut tx: sqlx::Transaction<'_, sqlx::Postgres>, id: Uuid, d: &Due, sub: &SubRow) -> ApiResult<()> {
    sqlx::query("UPDATE bookings SET subscription_id = $2 WHERE id = $1")
        .bind(id)
        .bind(d.sub_id)
        .execute(&mut *tx)
        .await?;
    if let Some(pro) = sub.preferred_pro_id
        && pro_free_for(&mut *tx, id, pro).await?
    {
        sqlx::query(
            "UPDATE bookings SET pro_id = $2, status = 2, accepted_at = now(), updated_at = now(),
               assignee_id = (SELECT id FROM team_members WHERE pro_id = $2 AND role = 'owner')
             WHERE id = $1",
        )
        .bind(id)
        .bind(pro)
        .execute(&mut *tx)
        .await?;
    }
    sqlx::query("UPDATE subscription_visits SET state = 'booked', booking_id = $2, charge_attempts = charge_attempts + 1, retry_at = NULL, updated_at = now() WHERE id = $1")
        .bind(d.visit_id)
        .bind(id)
        .execute(&mut *tx)
        .await?;
    sqlx::query("UPDATE subscriptions SET consecutive_failures = 0, updated_at = now() WHERE id = $1")
        .bind(d.sub_id)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    Ok(())
}

/// Whether the preferred partner may take this booking: verified, prefs match, and no job already at that slot.
async fn pro_free_for(conn: &mut PgConnection, booking: Uuid, pro: Uuid) -> ApiResult<bool> {
    let ok: bool = sqlx::query_scalar(&format!(
        "SELECT EXISTS (SELECT 1 FROM bookings b, pros p JOIN partner_prefs pp ON pp.pro_id = p.id
           WHERE b.id = $1 AND p.id = $2 AND {VISIBLE}
             AND NOT EXISTS (SELECT 1 FROM bookings x WHERE x.pro_id = p.id AND x.visit_date = b.visit_date AND x.start_hour = b.start_hour AND x.status = 2))"
    ))
    .bind(booking)
    .bind(pro)
    .fetch_one(&mut *conn)
    .await?;
    Ok(ok)
}

/// Counts a failed attempt, schedules the retry, and pauses after repeated failures. The customer is told each time.
async fn record_failure(s: &AppState, d: &Due, failure: &Failure) -> ApiResult<()> {
    let failures: i32 = sqlx::query_scalar("UPDATE subscriptions SET consecutive_failures = consecutive_failures + 1, updated_at = now() WHERE id = $1 RETURNING consecutive_failures")
        .bind(d.sub_id)
        .fetch_one(&s.db)
        .await?;
    let retry = after_failure(u32::try_from(failures).unwrap_or(u32::MAX));
    let hours = match retry {
        Retry::After { hours } => Some(hours as i32),
        Retry::Pause => None,
    };
    sqlx::query(
        "UPDATE subscription_visits SET charge_attempts = charge_attempts + 1,
           retry_at = CASE WHEN $2::int IS NULL THEN NULL ELSE now() + make_interval(hours => $2::int) END, updated_at = now()
         WHERE id = $1",
    )
    .bind(d.visit_id)
    .bind(hours)
    .execute(&s.db)
    .await?;
    if retry == Retry::Pause {
        let reason = match failure {
            Failure::Declined(_) => "payment",
            Failure::Blocked => "booking",
        };
        let paused = sqlx::query("UPDATE subscriptions SET status = 'paused', paused_reason = $2, updated_at = now() WHERE id = $1 AND status = 'active'")
            .bind(d.sub_id)
            .bind(reason)
            .execute(&s.db)
            .await?
            .rows_affected();
        if paused == 1 {
            best_effort(
                "notify",
                notify(s, Recipient::User(d.user_id), "subscription.paused", "정기 청소가 일시 정지됐어요", "결제 수단을 확인한 뒤 재개해 주세요", json!({ "subscription_id": d.sub_id })),
            )
            .await;
        }
    }
    best_effort(
        "notify",
        notify(
            s,
            Recipient::User(d.user_id),
            "subscription.payment_failed",
            "정기 청소 결제가 실패했어요",
            "카드 정보를 확인해 주세요",
            json!({ "subscription_id": d.sub_id, "visit_date": d.visit_date }),
        ),
    )
    .await;
    Ok(())
}

/// Planned visits whose day has arrived without a charge become `missed`. Returns how many.
async fn expire(s: &AppState) -> ApiResult<usize> {
    let missed: Vec<(Uuid,)> = sqlx::query_as(&format!(
        "UPDATE subscription_visits v SET state = 'missed', updated_at = now() FROM subscriptions s
         WHERE s.id = v.subscription_id AND v.state = 'planned' AND v.visit_date <= {KST_TODAY}
         RETURNING s.user_id"
    ))
    .fetch_all(&s.db)
    .await?;
    for (user,) in &missed {
        best_effort(
            "notify",
            notify(s, Recipient::User(*user), "subscription.visit_missed", "이번 정기 청소를 잡지 못했어요", "고객센터로 문의해 주세요", json!({})),
        )
        .await;
    }
    Ok(missed.len())
}
