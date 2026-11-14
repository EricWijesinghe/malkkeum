//! No-show watch. An assigned partner who has not checked in `NOSHOW_GRACE_MINUTES` after the arrival
//! window starts opens a no-show case and alerts staff. Staff can move the job to another partner
//! who matches the partner's prefs (same rule as the feed) and tell everyone.

use crate::{
    error::{ApiError, ApiResult},
    realtime::{Recipient, notify},
    routes::{
        bookings::load_booking,
        cases::{self, NewCase},
        partner_jobs::VISIBLE,
    },
    schedule::{clash, lock_schedule},
    settings_registry,
    state::AppState,
    util::{KST_TODAY, best_effort, today_kst},
};
use domain::{booking::BookingStatus, coupon::COUPON_LIFETIME_DAYS};
use serde_json::json;
use sqlx::PgPool;
use std::time::Duration;
use tokio::task::JoinHandle;
use uuid::Uuid;

const PASS_EVERY: Duration = Duration::from_secs(5 * 60);

/// Opens a no-show case for every assigned job past its grace period with no check-in.
/// Returns how many cases were opened.
pub async fn scan(s: &AppState) -> ApiResult<usize> {
    let grace = settings_registry::get(&s.db, &s.config, "noshow_grace_minutes").await?;
    let assigned = BookingStatus::TeamAssigned.as_i16();
    let due: Vec<(Uuid, String)> = sqlx::query_as(&format!(
        "SELECT b.id, b.number FROM bookings b
         WHERE b.status = {assigned} AND b.pro_id IS NOT NULL AND b.checked_in_at IS NULL AND b.visit_date <= {KST_TODAY}
           AND ((b.visit_date + make_interval(hours => b.start_hour::int)) AT TIME ZONE 'Asia/Seoul')
               + make_interval(mins => $1) <= now()
           AND NOT EXISTS (SELECT 1 FROM cases c WHERE c.booking_id = b.id AND c.kind = 'no_show')"
    ))
    .bind(grace as i32)
    .fetch_all(&s.db)
    .await?;
    let mut opened = 0;
    for (id, number) in &due {
        // Per booking: one that fails must not leave the rest of the batch without a case.
        match open_case(&s.db, *id).await {
            Ok(Some(case)) => {
                opened += 1;
                tracing::warn!(booking = %number, "no-show case opened");
                best_effort(
                    "no-show: staff",
                    notify(
                        s,
                        Recipient::Staff,
                        "case.no_show",
                        "도착 확인 없음",
                        number,
                        json!({ "booking_id": id, "case_id": case }),
                    ),
                )
                .await;
            }
            Ok(None) => {}
            Err(e) => tracing::warn!(error = %e, booking = %number, "no-show case not opened; the next scan retries"),
        }
    }
    Ok(opened)
}

/// Opens the case unless the booking already has one. The lock makes check-then-insert safe when two
/// scans (two replicas, or overlapping passes) reach the same booking. None when another scan won.
async fn open_case(db: &PgPool, booking: Uuid) -> ApiResult<Option<Uuid>> {
    let mut tx = db.begin().await?;
    sqlx::query("SELECT pg_advisory_xact_lock(hashtext($1))")
        .bind(format!("no_show:{booking}"))
        .execute(&mut *tx)
        .await?;
    let exists: bool = sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM cases WHERE booking_id = $1 AND kind = 'no_show')")
        .bind(booking)
        .fetch_one(&mut *tx)
        .await?;
    if exists {
        return Ok(None);
    }
    // The unique index is the last guard; a scan that loses the race gets None from ON CONFLICT.
    let case = cases::insert_no_show(
        &mut *tx,
        NewCase {
            booking: Some(booking),
            kind: "no_show",
            source: "no_show",
            reporter: "system",
            reporter_id: None,
            summary: "partner has not checked in",
            photos: json!([]),
        },
    )
    .await?;
    tx.commit().await?;
    Ok(case)
}

/// Starts the periodic scan. Errors are logged and the loop goes on.
pub fn spawn(state: AppState) -> JoinHandle<()> {
    let mut stop = state.hub.drain_signal();
    tokio::spawn(async move {
        let mut tick = tokio::time::interval(PASS_EVERY);
        while crate::lifecycle::next_tick(&mut tick, &mut stop).await {
            crate::jobs::run(&state, "noshow", scan(&state)).await;
        }
    })
}

/// Moves an unstarted job to the first partner (fewest jobs that day) whose prefs match and who
/// is free that slot. The old partner, the new partner and the customer are told. `coupon` is an
/// apology coupon amount (0 for none). Returns the new partner.
pub async fn reassign(s: &AppState, booking: Uuid, coupon: i64) -> ApiResult<Uuid> {
    let b = load_booking(&s.db, booking).await?;
    if b.status()? != BookingStatus::TeamAssigned || b.checked_in_at.is_some() || b.visit_date < today_kst() {
        return Err(ApiError::Conflict("reassign_closed"));
    }
    let assigned = BookingStatus::TeamAssigned.as_i16();
    let next: Option<Uuid> = sqlx::query_scalar(&format!(
        "SELECT p.id FROM bookings b, pros p JOIN partner_prefs pp ON pp.pro_id = p.id
         WHERE b.id = $1 AND p.id IS DISTINCT FROM b.pro_id AND {VISIBLE}
           AND NOT EXISTS (SELECT 1 FROM bookings o WHERE o.pro_id = p.id AND {})
         ORDER BY (SELECT count(*) FROM bookings x WHERE x.pro_id = p.id AND x.visit_date = b.visit_date), p.id
         LIMIT 1",
        clash("b")
    ))
    .bind(booking)
    .fetch_optional(&s.db)
    .await?;
    let next = next.ok_or(ApiError::Conflict("no_partner_available"))?;
    let mut tx = s.db.begin().await?;
    lock_schedule(&mut tx, next).await?;
    let moved = sqlx::query(&format!(
        "UPDATE bookings SET pro_id = $2, assignee_id = (SELECT id FROM team_members WHERE pro_id = $2 AND role = 'owner'), accepted_at = now(), updated_at = now()
         WHERE id = $1 AND status = {assigned} AND checked_in_at IS NULL AND pro_id IS NOT DISTINCT FROM $3
           AND NOT EXISTS (SELECT 1 FROM bookings o WHERE o.pro_id = $2 AND {})",
        clash("bookings")
    ))
    .bind(booking)
    .bind(next)
    .bind(b.pro_id)
    .execute(&mut *tx)
    .await?
    .rows_affected();
    if moved == 0 {
        return Err(ApiError::Conflict("reassign_closed"));
    }
    tx.commit().await?;
    if coupon > 0 {
        sqlx::query(
            "INSERT INTO coupons (user_id, name, amount, campaign, issued_at, expires_at)
             VALUES ($1, '불편 사과 쿠폰', $2, 'no_show_apology', now(), now() + make_interval(days => $3))",
        )
        .bind(b.user_id)
        .bind(coupon)
        .bind(COUPON_LIFETIME_DAYS as i32)
        .execute(&s.db)
        .await?;
    }
    if let Some(old) = b.pro_id {
        best_effort(
            "reassign: old partner",
            notify(
                s,
                Recipient::Pro(old),
                "job.updated",
                "배정이 변경됐어요",
                &b.number,
                json!({ "booking_id": booking }),
            ),
        )
        .await;
    }
    best_effort(
        "reassign: new partner",
        notify(
            s,
            Recipient::Pro(next),
            "job.assigned",
            "새 현장이 배정됐어요",
            &b.number,
            json!({ "booking_id": booking }),
        ),
    )
    .await;
    best_effort(
        "reassign: customer",
        notify(
            s,
            Recipient::User(b.user_id),
            "booking.status",
            "청소팀이 변경됐어요",
            "불편을 드려 죄송합니다. 다른 청소팀이 배정됐어요.",
            json!({ "booking_id": booking, "status": 2 }),
        ),
    )
    .await;
    s.hub.send(Recipient::Staff, "booking.updated", json!({ "booking_id": booking }));
    Ok(next)
}
