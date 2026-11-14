//! First-touch acquisition: UTM and referral params the site and customer app captured. Stored once on customer
//! signup (`users.acquisition`, never overwritten) and summarised for the console by source, medium and campaign.

use crate::{auth::Admin, error::ApiResult, state::AppState};
use axum::{
    Json, Router,
    extract::{Query, State},
    routing::get,
};
use chrono::{NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use serde_json::{Map, Value, json};

pub const KEYS: [&str; 6] = ["utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term", "ref"];
const MAX_CHARS: usize = 80;
const DEFAULT_WINDOW_DAYS: i64 = 30;
const MAX_WINDOW_DAYS: i64 = 366;
const MAX_ROWS: i64 = 200;

pub fn admin_routes() -> Router<AppState> {
    Router::new().route("/acquisition", get(table))
}

/// Known keys only, trimmed, control characters removed, at most 80 characters each. None when nothing is left.
pub fn clean(input: Option<&Value>) -> Option<Value> {
    let obj = input?.as_object()?;
    let out: Map<String, Value> = KEYS
        .iter()
        .filter_map(|k| {
            let v: String = obj.get(*k)?.as_str()?.trim().chars().filter(|c| !c.is_control()).take(MAX_CHARS).collect();
            (!v.is_empty()).then(|| ((*k).to_string(), json!(v)))
        })
        .collect();
    (!out.is_empty()).then_some(Value::Object(out))
}

#[derive(Deserialize)]
pub struct Range {
    pub from: Option<NaiveDate>,
    pub to: Option<NaiveDate>,
}

#[derive(Serialize, sqlx::FromRow)]
pub struct Row {
    pub source: String,
    pub medium: String,
    pub campaign: String,
    pub signups: i64,
    pub booked_customers: i64,
    pub bookings: i64,
}

/// Signups created in `[from, to]` (Seoul days, both inclusive) grouped by first-touch source. Bookings are
/// counted only when not cancelled. Direct traffic (no UTM, no ref) is grouped as `direct`.
async fn table(State(s): State<AppState>, Admin(_): Admin, Query(q): Query<Range>) -> ApiResult<Json<Value>> {
    let today = Utc::now().date_naive();
    let to = q.to.unwrap_or(today);
    let from = q.from.unwrap_or(to - chrono::Duration::days(DEFAULT_WINDOW_DAYS - 1));
    let span = (to - from).num_days().clamp(0, MAX_WINDOW_DAYS);
    let from = to - chrono::Duration::days(span);
    let rows: Vec<Row> = sqlx::query_as(
        "WITH signups AS (
           SELECT u.id,
                  COALESCE(u.acquisition->>'utm_source', u.acquisition->>'ref', 'direct') AS source,
                  COALESCE(u.acquisition->>'utm_medium', '') AS medium,
                  COALESCE(u.acquisition->>'utm_campaign', '') AS campaign
           FROM users u
           WHERE u.created_at >= ($1::date::timestamp AT TIME ZONE 'Asia/Seoul')
             AND u.created_at < (($2::date + 1)::timestamp AT TIME ZONE 'Asia/Seoul')
         )
         SELECT s.source, s.medium, s.campaign,
                count(DISTINCT s.id) AS signups,
                count(DISTINCT b.user_id) AS booked_customers,
                count(b.id) AS bookings
         FROM signups s
         LEFT JOIN bookings b ON b.user_id = s.id AND b.status <> -1
         GROUP BY s.source, s.medium, s.campaign
         ORDER BY signups DESC, s.source
         LIMIT $3",
    )
    .bind(from)
    .bind(to)
    .bind(MAX_ROWS)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(json!({ "from": from, "to": to, "rows": rows })))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn keeps_known_keys_and_trims() {
        let v = json!({"utm_source": "  naver ", "utm_campaign": "move_in_11680", "evil": "x", "utm_term": ""});
        assert_eq!(clean(Some(&v)), Some(json!({"utm_source": "naver", "utm_campaign": "move_in_11680"})));
    }

    #[test]
    fn drops_control_chars_and_caps_length() {
        let long = "a".repeat(200);
        let v = json!({"utm_source": format!("x\u{7}{long}")});
        let out = clean(Some(&v)).unwrap();
        assert_eq!(out["utm_source"].as_str().unwrap().chars().count(), MAX_CHARS);
        assert!(!out["utm_source"].as_str().unwrap().contains('\u{7}'));
    }

    #[test]
    fn nothing_usable_is_none() {
        assert_eq!(clean(None), None);
        assert_eq!(clean(Some(&json!("naver"))), None);
        assert_eq!(clean(Some(&json!({"other": 1}))), None);
    }
}
