//! Staff activity log for the owner: `GET /v1/admin/audit`. Newest first, cursor-paged on
//! `(created_at, id)`. Filters are checked here before they reach SQL. Recorded `data` leaves as
//! plain text (a JSON string), so the console shows it as text and never interprets it.

use crate::{
    auth::Admin,
    contract,
    error::{ApiError, ApiResult},
    state::AppState,
};
use axum::{
    Router,
    extract::{Query, State},
    response::Response,
    routing::get,
};
use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Actor roles the server writes into `audit_log.actor_role`.
const ACTOR_ROLES: [&str; 5] = ["staff", "customer", "pro", "member", "system"];
/// Longest action code the server writes is well under this; longer input is a typo or probing.
const MAX_ACTION_CHARS: usize = 64;
/// Recorded `data` is cut here so one row cannot make a page huge.
const MAX_DATA_CHARS: i32 = 4000;

pub fn admin_routes() -> Router<AppState> {
    Router::new().route("/audit", get(list))
}

#[derive(Deserialize, Default)]
struct AuditQuery {
    limit: Option<i64>,
    cursor: Option<String>,
    actor_role: Option<String>,
    actor_id: Option<Uuid>,
    /// Exact action or a prefix such as `case.`.
    action: Option<String>,
    target: Option<String>,
    /// Seoul calendar days, both inclusive.
    from: Option<NaiveDate>,
    to: Option<NaiveDate>,
}

#[derive(Debug, Default, PartialEq)]
struct Filter {
    actor_role: Option<String>,
    actor_id: Option<Uuid>,
    action: Option<String>,
    target: Option<String>,
    from: Option<NaiveDate>,
    to: Option<NaiveDate>,
}

#[derive(Serialize, sqlx::FromRow)]
struct AuditRow {
    id: i64,
    actor_role: String,
    actor_id: Option<Uuid>,
    actor_name: Option<String>,
    action: String,
    target: String,
    data_text: String,
    created_at: DateTime<Utc>,
}

/// Empty strings from `?action=` mean "no filter".
fn non_empty(v: Option<&str>) -> Option<&str> {
    v.map(str::trim).filter(|s| !s.is_empty())
}

fn check_action(action: &str) -> ApiResult<()> {
    let ok = action.len() <= MAX_ACTION_CHARS && action.bytes().all(|b| b.is_ascii_lowercase() || b == b'.' || b == b'_');
    if ok { Ok(()) } else { Err(ApiError::BadRequest("invalid_action")) }
}

impl Filter {
    fn from_query(q: &AuditQuery) -> ApiResult<Self> {
        let actor_role = non_empty(q.actor_role.as_deref());
        if actor_role.is_some_and(|r| !ACTOR_ROLES.contains(&r)) {
            return Err(ApiError::BadRequest("invalid_actor_role"));
        }
        let action = non_empty(q.action.as_deref());
        if let Some(a) = action {
            check_action(a)?;
        }
        let target = non_empty(q.target.as_deref());
        if target.is_some_and(|t| t.chars().count() > contract::MAX_TEXT_CHARS) {
            return Err(ApiError::BadRequest("invalid_target"));
        }
        if q.from.zip(q.to).is_some_and(|(from, to)| from > to) {
            return Err(ApiError::BadRequest("invalid_range"));
        }
        Ok(Self {
            actor_role: actor_role.map(str::to_owned),
            actor_id: q.actor_id,
            action: action.map(str::to_owned),
            target: target.map(str::to_owned),
            from: q.from,
            to: q.to,
        })
    }
}

/// Decodes `(created_at, id)` from the cursor; a malformed cursor is a 400, never the first page.
fn cursor_key(cursor: Option<&str>) -> ApiResult<Option<(DateTime<Utc>, i64)>> {
    let Some(parts) = contract::decode_cursor(cursor, 2)? else { return Ok(None) };
    Ok(Some((contract::cursor_part(&parts[0])?, contract::cursor_part(&parts[1])?)))
}

async fn list(State(s): State<AppState>, Admin(_): Admin, Query(q): Query<AuditQuery>) -> ApiResult<Response> {
    let limit = contract::page_limit(q.limit)?;
    let key = cursor_key(q.cursor.as_deref())?;
    let f = Filter::from_query(&q)?;
    let (cursor_at, cursor_id) = key.map_or((None, None), |(at, id)| (Some(at), Some(id)));
    let rows: Vec<AuditRow> = sqlx::query_as(
        "SELECT a.id, a.actor_role, a.actor_id, st.name AS actor_name, a.action, a.target,
                left(a.data::text, $10::int) AS data_text, a.created_at
         FROM audit_log a
         LEFT JOIN staff st ON st.id = a.actor_id
         WHERE ($1::text IS NULL OR a.actor_role = $1)
           AND ($2::uuid IS NULL OR a.actor_id = $2)
           AND ($3::text IS NULL OR left(a.action, char_length($3::text)) = $3::text)
           AND ($4::text IS NULL OR a.target = $4)
           AND ($5::date IS NULL OR a.created_at >= ($5::date::timestamp AT TIME ZONE 'Asia/Seoul'))
           AND ($6::date IS NULL OR a.created_at < (($6::date + 1)::timestamp AT TIME ZONE 'Asia/Seoul'))
           AND ($7::timestamptz IS NULL OR (a.created_at, a.id) < ($7::timestamptz, $8::bigint))
         ORDER BY a.created_at DESC, a.id DESC
         LIMIT $9",
    )
    .bind(f.actor_role)
    .bind(f.actor_id)
    .bind(f.action)
    .bind(f.target)
    .bind(f.from)
    .bind(f.to)
    .bind(cursor_at)
    .bind(cursor_id)
    .bind(limit)
    .bind(MAX_DATA_CHARS)
    .fetch_all(&s.db)
    .await?;
    Ok(contract::paged(rows, limit, |r| {
        contract::encode_cursor(&[&contract::ts_key(r.created_at), &r.id.to_string()])
    }))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn query() -> AuditQuery {
        AuditQuery::default()
    }

    #[test]
    fn empty_filters_mean_none() {
        let q = AuditQuery {
            action: Some("  ".into()),
            actor_role: Some(String::new()),
            ..query()
        };
        assert_eq!(Filter::from_query(&q).expect("valid"), Filter::default());
    }

    #[test]
    fn rejects_unknown_role_and_odd_action() {
        let role = AuditQuery {
            actor_role: Some("root".into()),
            ..query()
        };
        assert!(Filter::from_query(&role).is_err());
        for bad in ["Case.Refund", "case%", "case;drop", "a b"] {
            let q = AuditQuery {
                action: Some(bad.into()),
                ..query()
            };
            assert!(Filter::from_query(&q).is_err(), "{bad} should be refused");
        }
        let ok = AuditQuery {
            action: Some("case.".into()),
            ..query()
        };
        assert_eq!(Filter::from_query(&ok).expect("prefix").action.as_deref(), Some("case."));
    }

    #[test]
    fn refuses_reversed_range_and_long_target() {
        let d = |s: &str| NaiveDate::parse_from_str(s, "%Y-%m-%d").expect("date");
        let reversed = AuditQuery {
            from: Some(d("2026-05-02")),
            to: Some(d("2026-05-01")),
            ..query()
        };
        assert!(Filter::from_query(&reversed).is_err());
        let same_day = AuditQuery {
            from: Some(d("2026-05-01")),
            to: Some(d("2026-05-01")),
            ..query()
        };
        assert!(Filter::from_query(&same_day).is_ok());
        let long = AuditQuery {
            target: Some("x".repeat(contract::MAX_TEXT_CHARS + 1)),
            ..query()
        };
        assert!(Filter::from_query(&long).is_err());
    }

    #[test]
    fn cursor_must_have_two_parts() {
        assert!(cursor_key(None).expect("none").is_none());
        let bad = contract::encode_cursor(&["2026-05-01T00:00:00Z"]);
        assert!(cursor_key(Some(&bad)).is_err());
    }
}
