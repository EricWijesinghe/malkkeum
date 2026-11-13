//! Malkkeum points ledger: cashback and welcome/referral grants, spend in split payments,
//! refund-returns-points, expiry and console adjustments. Loyalty only (no cash top-up, see
//! docs/finance-tax.md). Rules live in domain::points; this module moves rows. Every write is
//! keyed by `idempotency_key`, and each user's ledger is written under a row lock on `users`.

use crate::{
    auth::{Admin, Customer},
    error::{ApiError, ApiResult},
    routes::{
        audit,
        growth::{load_setting, save_setting},
    },
    settings_registry,
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Path, State},
    routing::{get, post, put},
};
use chrono::{DateTime, Utc};
use domain::{
    Won,
    growth::paid_in_full,
    points::{Lot, PointsError, PointsPolicy, Split, allocate, available, cashback, expiring_within, lapsed, split_payment},
};
use serde::Deserialize;
use serde_json::{Value, json};
use sqlx::{PgConnection, PgPool};
use uuid::Uuid;

pub const POLICY_KEY: &str = "points_policy";
const LEDGER_PAGE: i64 = 50;

pub fn customer_routes() -> Router<AppState> {
    Router::new().route("/me/points", get(my_points))
}

pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/growth/points", put(put_policy))
        .route("/growth/points/adjust", crate::idempotency::replayable(post(adjust)))
        .route("/growth/points/{user_id}", get(user_points))
}

/// Shared by the booking pricing and the apps: the owner's current programme.
pub async fn load_policy(conn: &mut PgConnection) -> ApiResult<PointsPolicy> {
    load_setting(&mut *conn, POLICY_KEY).await
}

/// One row to write. `lot: None` makes the row the start of its own lot (earn, grant, refund).
struct Entry {
    user: Uuid,
    kind: &'static str,
    amount: i64,
    lot: Option<Uuid>,
    expires_at: Option<DateTime<Utc>>,
    key: String,
    booking: Option<Uuid>,
    actor: Option<Uuid>,
    reason: Option<String>,
}

impl Entry {
    fn new(user: Uuid, kind: &'static str, amount: i64, key: String) -> Self {
        Self {
            user,
            kind,
            amount,
            lot: None,
            expires_at: None,
            key,
            booking: None,
            actor: None,
            reason: None,
        }
    }
}

/// Returns false when the key was already written (a retry), so callers never double-count.
async fn append(conn: &mut PgConnection, e: Entry) -> ApiResult<bool> {
    let done = sqlx::query(
        "INSERT INTO points_ledger (id, user_id, kind, amount, lot_id, expires_at, booking_id, idempotency_key, actor_id, reason)
         VALUES ($1, $2, $3, $4, COALESCE($5, $1), $6, $7, $8, $9, $10) ON CONFLICT (idempotency_key) DO NOTHING",
    )
    .bind(Uuid::now_v7())
    .bind(e.user)
    .bind(e.kind)
    .bind(e.amount)
    .bind(e.lot)
    .bind(e.expires_at)
    .bind(e.booking)
    .bind(e.key)
    .bind(e.actor)
    .bind(e.reason)
    .execute(&mut *conn)
    .await?;
    Ok(done.rows_affected() == 1)
}

async fn lock_user(conn: &mut PgConnection, user: Uuid) -> ApiResult<()> {
    sqlx::query("SELECT id FROM users WHERE id = $1 FOR UPDATE")
        .bind(user)
        .execute(&mut *conn)
        .await?;
    Ok(())
}

/// Every lot the user has ever been issued, with what has been consumed from it so far.
async fn lots(conn: &mut PgConnection, user: Uuid) -> ApiResult<Vec<Lot<Uuid>>> {
    let rows: Vec<(Uuid, i64, DateTime<Utc>, i64)> = sqlx::query_as(
        "SELECT l.lot_id, l.amount, l.expires_at, COALESCE(-SUM(c.amount), 0)::bigint
         FROM points_ledger l
         LEFT JOIN points_ledger c ON c.lot_id = l.lot_id AND c.amount < 0
         WHERE l.user_id = $1 AND l.amount > 0 AND l.kind IN ('earn','welcome','referral','refund','grant')
         GROUP BY l.id",
    )
    .bind(user)
    .fetch_all(&mut *conn)
    .await?;
    Ok(rows
        .into_iter()
        .map(|(id, issued, expires_at, consumed)| Lot {
            id,
            issued,
            consumed,
            expires_at,
        })
        .collect())
}

fn points_err(e: PointsError) -> ApiError {
    match e {
        PointsError::NonPositive => ApiError::BadRequest(e.code()),
        PointsError::Insufficient { .. } | PointsError::OverCap { .. } => ApiError::Conflict(e.code()),
    }
}

/// Grants points that start their own lot. Keyed, so the same event never pays twice.
pub async fn grant(conn: &mut PgConnection, user: Uuid, kind: &'static str, amount: i64, key: String) -> ApiResult<()> {
    if amount <= 0 {
        return Ok(());
    }
    let policy = load_policy(&mut *conn).await?;
    let expires_at = Some(policy.expires_at(Utc::now()));
    append(
        conn,
        Entry {
            lot: None,
            expires_at,
            ..Entry::new(user, kind, amount, key)
        },
    )
    .await?;
    Ok(())
}

/// Cashback and the one-time welcome grant, once a booking is completed and paid in full.
/// Safe to call from every completion path: the booking key makes repeats no-ops.
pub async fn on_completed(conn: &mut PgConnection, booking: Uuid) -> ApiResult<()> {
    let policy = load_policy(&mut *conn).await?;
    if !policy.enabled {
        return Ok(());
    }
    let (user, paid, final_price, completed): (Uuid, i64, Option<i64>, bool) =
        sqlx::query_as("SELECT user_id, paid_amount, COALESCE(final_price, list_price), status = 3 FROM bookings WHERE id = $1")
            .bind(booking)
            .fetch_one(&mut *conn)
            .await?;
    if !completed || !paid_in_full(paid, final_price) {
        return Ok(());
    }
    // Cashback is on cash paid only; points used to pay are not earned again.
    let spent = net_spent(&mut *conn, booking).await?;
    let earned = cashback(Won((paid - spent).max(0)), policy.earn_bps);
    let expires_at = Some(policy.expires_at(Utc::now()));
    if earned > 0 {
        let e = Entry {
            lot: None,
            expires_at,
            booking: Some(booking),
            ..Entry::new(user, "earn", earned, format!("earn:{booking}"))
        };
        append(conn, e).await?;
    }
    grant(conn, user, "welcome", policy.welcome_points, format!("welcome:{user}")).await
}

/// The split a request would get right now: programme on, booking not yet paid with points,
/// within the cap and the balance. Writes nothing. Returns the lots it was computed from.
async fn quote_lots(conn: &mut PgConnection, user: Uuid, booking: Option<Uuid>, total: Won, requested: i64) -> ApiResult<(Split, Vec<Lot<Uuid>>)> {
    let policy = load_policy(&mut *conn).await?;
    if requested > 0 && !policy.enabled {
        return Err(ApiError::Conflict("points_disabled"));
    }
    let already: bool = sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM points_ledger WHERE booking_id = $1 AND kind = 'spend')")
        .bind(booking)
        .fetch_one(&mut *conn)
        .await?;
    if already {
        return Err(ApiError::Conflict("points_already_spent"));
    }
    let owned = lots(&mut *conn, user).await?;
    let split = split_payment(total, requested, available(&owned, Utc::now()), policy.max_use_bps).map_err(points_err)?;
    Ok((split, owned))
}

/// Checkout preview: validates a points request without debiting it.
pub async fn quote(conn: &mut PgConnection, user: Uuid, booking: Option<Uuid>, total: Won, requested: i64) -> ApiResult<Split> {
    Ok(quote_lots(conn, user, booking, total, requested).await?.0)
}

/// Points a booking has paid with and not got back. Zero for most bookings.
pub async fn net_spent(conn: &mut PgConnection, booking: Uuid) -> ApiResult<i64> {
    Ok(
        sqlx::query_scalar("SELECT COALESCE(-SUM(amount), 0)::bigint FROM points_ledger WHERE booking_id = $1 AND kind IN ('spend','refund')")
            .bind(booking)
            .fetch_one(&mut *conn)
            .await?,
    )
}

/// Pays part of a booking total with points, inside the caller's transaction. Returns the
/// split: the PG must still charge `split.pg`. Asking for more than the cap or the balance fails.
pub async fn spend(conn: &mut PgConnection, user: Uuid, booking: Uuid, total: Won, requested: i64) -> ApiResult<Split> {
    lock_user(&mut *conn, user).await?;
    let (split, owned) = quote_lots(&mut *conn, user, Some(booking), total, requested).await?;
    if split.points == 0 {
        return Ok(split);
    }
    for (lot, take) in allocate(&owned, split.points, Utc::now()).map_err(points_err)? {
        let e = Entry {
            lot: Some(lot),
            booking: Some(booking),
            ..Entry::new(user, "spend", -take, format!("spend:{booking}:{lot}"))
        };
        append(conn, e).await?;
    }
    Ok(split)
}

/// A cancelled or refunded booking gives back the points it spent, in proportion to the cash
/// refunded so far (`refunded` of `paid`), as fresh lots with a new expiry. Cumulative: a repeat
/// call with the same refunded share writes nothing. Returns the points restored by this call.
pub async fn reverse_spend(conn: &mut PgConnection, booking: Uuid, refunded: i64, paid: i64) -> ApiResult<i64> {
    let spent: Option<(Uuid, i64)> =
        sqlx::query_as("SELECT user_id, (-SUM(amount))::bigint FROM points_ledger WHERE booking_id = $1 AND kind = 'spend' GROUP BY user_id")
            .bind(booking)
            .fetch_optional(&mut *conn)
            .await?;
    let Some((user, spent)) = spent else {
        return Ok(0);
    };
    let target = if paid <= 0 || refunded >= paid {
        spent
    } else {
        i64::try_from(i128::from(spent) * i128::from(refunded.max(0)) / i128::from(paid)).unwrap_or(spent)
    };
    lock_user(&mut *conn, user).await?;
    let returned: i64 = sqlx::query_scalar("SELECT COALESCE(SUM(amount), 0)::bigint FROM points_ledger WHERE booking_id = $1 AND kind = 'refund'")
        .bind(booking)
        .fetch_one(&mut *conn)
        .await?;
    let owed = target - returned;
    if owed <= 0 {
        return Ok(0);
    }
    let policy = load_policy(&mut *conn).await?;
    let e = Entry {
        expires_at: Some(policy.expires_at(Utc::now())),
        booking: Some(booking),
        ..Entry::new(user, "refund", owed, format!("refund:{booking}:{target}"))
    };
    append(conn, e).await?;
    Ok(owed)
}

/// Writes one `expire` row per lapsed lot remainder. Scheduled; re-running writes nothing new.
pub async fn expire_lapsed(db: &PgPool) -> ApiResult<u64> {
    let users: Vec<Uuid> = sqlx::query_scalar(
        "SELECT DISTINCT user_id FROM points_ledger WHERE amount > 0 AND kind IN ('earn','welcome','referral','refund','grant') AND expires_at <= now()",
    )
    .fetch_all(db)
    .await?;
    let now = Utc::now();
    let mut written = 0;
    for user in users {
        let mut tx = db.begin().await?;
        lock_user(&mut tx, user).await?;
        for (lot, left) in lapsed(&lots(&mut tx, user).await?, now) {
            let e = Entry {
                lot: Some(lot),
                ..Entry::new(user, "expire", -left, format!("expire:{lot}"))
            };
            if append(&mut tx, e).await? {
                written += 1;
            }
        }
        tx.commit().await?;
    }
    Ok(written)
}

/// Hourly expiry sweep. Errors are logged and the loop goes on.
pub fn spawn(state: AppState) -> tokio::task::JoinHandle<()> {
    let mut stop = state.hub.drain_signal();
    tokio::spawn(async move {
        let mut tick = tokio::time::interval(std::time::Duration::from_secs(60 * 60));
        while crate::lifecycle::next_tick(&mut tick, &mut stop).await {
            crate::jobs::run(&state, "points", expire_lapsed(&state.db)).await;
        }
    })
}

/// kind, amount, created, expires, booking, reason, actor.
type LedgerRow = (String, i64, DateTime<Utc>, Option<DateTime<Utc>>, Option<Uuid>, Option<String>, Option<Uuid>);

/// `staff` adds what only the console may see: the reason and the staff member behind an adjustment.
async fn snapshot(conn: &mut PgConnection, user: Uuid, staff: bool) -> ApiResult<Value> {
    let policy = load_policy(&mut *conn).await?;
    let owned = lots(&mut *conn, user).await?;
    let now = Utc::now();
    let entries: Vec<LedgerRow> = sqlx::query_as(
        "SELECT kind, amount, created_at, expires_at, booking_id, reason, actor_id FROM points_ledger WHERE user_id = $1 ORDER BY created_at DESC, id DESC LIMIT $2",
    )
    .bind(user)
    .bind(LEDGER_PAGE)
    .fetch_all(&mut *conn)
    .await?;
    let entries: Vec<Value> = entries
        .into_iter()
        .map(|(kind, amount, at, expires, booking, reason, actor)| {
            let mut e = json!({ "kind": kind, "amount": amount, "at": at, "expires_at": expires, "booking_id": booking });
            if staff {
                e["reason"] = json!(reason);
                e["actor_id"] = json!(actor);
            }
            e
        })
        .collect();
    Ok(json!({
        "enabled": policy.enabled,
        "balance": available(&owned, now),
        "expiring_soon": expiring_within(&owned, now, policy.notify_days),
        "notify_days": policy.notify_days,
        "max_use_bps": policy.max_use_bps,
        "entries": entries,
    }))
}

async fn my_points(State(s): State<AppState>, Customer(a): Customer) -> ApiResult<Json<Value>> {
    let mut conn = s.db.acquire().await?;
    Ok(Json(snapshot(&mut conn, a.id, false).await?))
}

async fn user_points(State(s): State<AppState>, Admin(_): Admin, Path(user): Path<Uuid>) -> ApiResult<Json<Value>> {
    let mut conn = s.db.acquire().await?;
    Ok(Json(snapshot(&mut conn, user, true).await?))
}

async fn put_policy(State(s): State<AppState>, Admin(a): Admin, Json(p): Json<PointsPolicy>) -> ApiResult<Json<Value>> {
    p.validate()?;
    save_setting(&s.db, POLICY_KEY, &p).await?;
    audit(&s.db, "staff", Some(a.id), "points.policy", POLICY_KEY, json!(p)).await?;
    Ok(Json(json!(p)))
}

#[derive(Deserialize)]
struct AdjustInput {
    user_id: Uuid,
    amount: i64,
    reason: String,
}

/// Console grant (positive) or deduction (negative, oldest lots first). Always audited.
async fn adjust(State(s): State<AppState>, Admin(a): Admin, Json(input): Json<AdjustInput>) -> ApiResult<Json<Value>> {
    if crate::auth::live_staff_role(&s.db, a.id).await? != crate::auth::Role::StaffAdmin {
        return Err(ApiError::Forbidden);
    }
    let reason = input.reason.trim().to_string();
    let max_adjust = settings_registry::get(&s.db, &s.config, "points_adjust_max").await?;
    if input.amount == 0 || input.amount.abs() > max_adjust {
        return Err(ApiError::BadRequest("points_adjust_amount"));
    }
    if reason.is_empty() || reason.chars().count() > 200 {
        return Err(ApiError::BadRequest("points_adjust_reason"));
    }
    let batch = Uuid::now_v7();
    let mut tx = s.db.begin().await?;
    lock_user(&mut tx, input.user_id).await?;
    let policy = load_policy(&mut tx).await?;
    if input.amount > 0 {
        let e = Entry {
            lot: None,
            expires_at: Some(policy.expires_at(Utc::now())),
            actor: Some(a.id),
            reason: Some(reason.clone()),
            ..Entry::new(input.user_id, "grant", input.amount, format!("adjust:{batch}"))
        };
        append(&mut tx, e).await?;
    } else {
        let now = Utc::now();
        let owned = lots(&mut tx, input.user_id).await?;
        for (lot, take) in allocate(&owned, -input.amount, now).map_err(points_err)? {
            let e = Entry {
                lot: Some(lot),
                actor: Some(a.id),
                reason: Some(reason.clone()),
                ..Entry::new(input.user_id, "deduct", -take, format!("deduct:{batch}:{lot}"))
            };
            append(&mut tx, e).await?;
        }
    }
    // Audit row goes in the same transaction: no adjustment without its record.
    sqlx::query("INSERT INTO audit_log (actor_role, actor_id, action, target, data) VALUES ('staff', $1, 'points.adjust', $2, $3)")
        .bind(a.id)
        .bind(input.user_id.to_string())
        .bind(json!({ "amount": input.amount, "reason": reason }))
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    Ok(Json(json!({ "ok": true })))
}
