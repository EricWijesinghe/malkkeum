//! Pro and team-member schedules: one live job per time window. Writers take `lock_schedule` for the
//! pro first, write, then ask `schedule_clash` whether the written row now overlaps another live job.

use crate::error::ApiResult;
use sqlx::{PgConnection, Postgres, Transaction};
use uuid::Uuid;

/// Minutes a booking holds its hour when no estimate is stored.
const SLOT_MINUTES: u32 = 60;

/// SQL: booking `o` clashes with the booking aliased `cand` (same visit date, live, windows overlap).
/// A window runs from its start hour for its estimated minutes, one slot when there is no estimate.
pub fn clash(cand: &str) -> String {
    format!(
        "o.id <> {cand}.id AND o.visit_date = {cand}.visit_date AND o.status >= 0
           AND o.start_hour * 60 < {cand}.start_hour * 60 + COALESCE({cand}.minutes, {SLOT_MINUTES})
           AND {cand}.start_hour * 60 < o.start_hour * 60 + COALESCE(o.minutes, {SLOT_MINUTES})"
    )
}

/// Serializes schedule writes per pro, so two overlap checks cannot both pass before either commits.
pub async fn lock_schedule(tx: &mut Transaction<'_, Postgres>, pro: Uuid) -> ApiResult<()> {
    sqlx::query("SELECT pg_advisory_xact_lock(hashtextextended($1, 0))")
        .bind(pro.to_string())
        .execute(&mut **tx)
        .await?;
    Ok(())
}

/// Whether booking `job` clashes with a live booking whose `owner_col` (pro or assignee) is `owner`.
pub async fn schedule_clash(conn: &mut PgConnection, job: Uuid, owner_col: &str, owner: Uuid) -> ApiResult<bool> {
    let sql = format!(
        "SELECT EXISTS (SELECT 1 FROM bookings c, bookings o WHERE c.id = $1 AND o.{owner_col} = $2 AND {})",
        clash("c")
    );
    Ok(sqlx::query_scalar(&sql).bind(job).bind(owner).fetch_one(conn).await?)
}
