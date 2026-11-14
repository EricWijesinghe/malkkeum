//! Personalized home feed. `GET /v1/feed` serves guests from device context only (district code,
//! unfinished draft); `GET /v1/me/feed` adds the customer's own history, saved home and consent.
//! The ranking lives in `domain::feed`; this file only gathers facts.

use crate::privacy;
use crate::{auth::Customer, error::ApiResult, state::AppState, util::today_kst};
use axum::{
    Json, Router,
    extract::{Query, State},
    routing::get,
};
use chrono::{Datelike, Duration, NaiveDate};
use domain::feed::{self, FeedFacts, LastClean};
use serde::Deserialize;
use serde_json::{Value, json};
use sqlx::PgPool;
use std::{
    collections::HashMap,
    sync::{Mutex, OnceLock},
};
use uuid::Uuid;

/// Cached district counts, per district and week. Cleared whole when it grows past this many entries.
const CACHE_MAX: usize = 512;

pub fn routes() -> Router<AppState> {
    Router::new().route("/feed", get(guest_feed)).route("/me/feed", get(my_feed))
}

#[derive(Deserialize, Default)]
struct FeedQuery {
    /// Address district code the device has chosen.
    district: Option<String>,
    /// Service the customer left half-finished on this device.
    draft: Option<String>,
}

/// Device-supplied codes are matched only as plain identifiers, never interpolated.
fn code_or_none(raw: Option<String>) -> Option<String> {
    raw.map(|s| s.trim().to_owned())
        .filter(|s| !s.is_empty() && s.len() <= 32 && s.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'_'))
}

/// The last complete KST week as [from, to) dates.
fn previous_week_kst() -> (NaiveDate, NaiveDate) {
    let today = today_kst();
    let monday = today - Duration::days(i64::from(today.weekday().num_days_from_monday()));
    (monday - Duration::days(7), monday)
}

fn district_cache() -> &'static Mutex<HashMap<(String, NaiveDate), i64>> {
    static CACHE: OnceLock<Mutex<HashMap<(String, NaiveDate), i64>>> = OnceLock::new();
    CACHE.get_or_init(Mutex::default)
}

/// Distinct customers who booked in a district during the last complete KST week. The domain buckets the number.
/// Cached per district and week: the proof moves slowly and a scan per page view is not worth it.
async fn district_bookings(db: &PgPool, code: &str) -> ApiResult<i64> {
    let (from, to) = previous_week_kst();
    let key = (code.to_owned(), from);
    if let Some(n) = district_cache().lock().unwrap_or_else(|p| p.into_inner()).get(&key).copied() {
        return Ok(n);
    }
    let homes: i64 = sqlx::query_scalar(
        "SELECT count(DISTINCT user_id) FROM bookings WHERE district_code = $1 AND status >= 0
           AND created_at >= ($2::date::timestamp AT TIME ZONE 'Asia/Seoul') AND created_at < ($3::date::timestamp AT TIME ZONE 'Asia/Seoul')",
    )
    .bind(code)
    .bind(from)
    .bind(to)
    .fetch_one(db)
    .await?;
    let mut cache = district_cache().lock().unwrap_or_else(|p| p.into_inner());
    if cache.len() >= CACHE_MAX {
        cache.clear();
    }
    cache.insert(key, homes);
    Ok(homes)
}

async fn guest_feed(State(s): State<AppState>, Query(q): Query<FeedQuery>) -> ApiResult<Json<Value>> {
    let district = code_or_none(q.district.clone());
    let mut facts = FeedFacts {
        today: Some(today_kst()),
        draft_service: code_or_none(q.draft),
        ..Default::default()
    };
    if let Some(code) = district {
        facts.district = Some((code.clone(), district_bookings(&s.db, &code).await?));
    }
    Ok(Json(json!({ "cards": feed::rank(&facts) })))
}

async fn my_feed(State(s): State<AppState>, Customer(a): Customer, Query(q): Query<FeedQuery>) -> ApiResult<Json<Value>> {
    let db = &s.db;
    let today = today_kst();
    let last: Vec<(String, NaiveDate, Option<Uuid>, Option<i16>)> = sqlx::query_as(
        "SELECT DISTINCT ON (b.service_code) b.service_code, (b.completed_at AT TIME ZONE 'Asia/Seoul')::date, b.pro_id, r.rating
         FROM bookings b LEFT JOIN reviews r ON r.booking_id = b.id
         WHERE b.user_id = $1 AND b.status = 3 AND b.completed_at IS NOT NULL
         ORDER BY b.service_code, b.completed_at DESC",
    )
    .bind(a.id)
    .fetch_all(db)
    .await?;
    let recent_bookings: i64 =
        sqlx::query_scalar("SELECT count(*) FROM bookings WHERE user_id = $1 AND status >= 0 AND created_at >= now() - interval '90 days'")
            .bind(a.id)
            .fetch_one(db)
            .await?;
    let size_pyeong: Option<i16> = sqlx::query_scalar(
        "SELECT size_pyeong FROM addresses WHERE user_id = $1 AND deleted_at IS NULL ORDER BY (kind = 'home') DESC, created_at DESC LIMIT 1",
    )
    .bind(a.id)
    .fetch_optional(db)
    .await?;
    // Same rule as every advertising send: current policy version and granted (privacy::marketing_allowed).
    let marketing = privacy::marketing_allowed(db, a.id).await?;
    let district = code_or_none(q.district.clone());
    let mut facts = FeedFacts {
        today: Some(today),
        last_cleans: last
            .into_iter()
            .map(|(service, completed_on, partner, rating)| LastClean {
                service,
                completed_on,
                partner_id: partner.map(|p| p.to_string()),
                rating,
            })
            .collect(),
        recent_bookings,
        size_pyeong: size_pyeong.and_then(|p| u16::try_from(p).ok()),
        draft_service: code_or_none(q.draft),
        district: None,
        marketing_consent: marketing,
    };
    if let Some(code) = district {
        facts.district = Some((code.clone(), district_bookings(db, &code).await?));
    }
    Ok(Json(json!({ "cards": feed::rank(&facts) })))
}
