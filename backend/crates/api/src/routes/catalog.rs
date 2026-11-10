//! Public catalogue and content: services, slot availability, estimate preview, notices/FAQ/banners.

use crate::{error::ApiResult, state::AppState};
use axum::{
    Json, Router,
    extract::{Query, State},
    routing::{get, post},
};
use chrono::NaiveDate;
use domain::{
    catalog::{Pricing, Service},
    quote::{Estimate, QuoteAnswers, QuoteFormula},
    schedule::{QUOTE_SLOTS, STANDARD_SLOTS},
};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/services", get(list_services))
        .route("/slots", get(slots))
        .route("/quote/estimate", post(estimate))
        .route("/content", get(content))
}

#[derive(Serialize)]
pub struct ServiceDto {
    #[serde(flatten)]
    pub service: Service,
    pub content: Value,
}

#[derive(sqlx::FromRow)]
pub struct ServiceRow {
    pub code: String,
    pub pricing: sqlx::types::Json<Pricing>,
    pub needs_preparation: bool,
    pub max_pyeong: Option<i16>,
    pub content: Value,
}

impl ServiceRow {
    pub fn into_domain(self) -> Service {
        Service {
            code: self.code,
            pricing: self.pricing.0,
            needs_preparation: self.needs_preparation,
            max_pyeong: self.max_pyeong.and_then(|p| u16::try_from(p).ok()),
        }
    }
}

pub const SERVICE_COLS: &str = "code, pricing, needs_preparation, max_pyeong, content";

pub async fn load_service(db: &sqlx::PgPool, code: &str) -> ApiResult<Service> {
    let row: ServiceRow = sqlx::query_as(&format!("SELECT {SERVICE_COLS} FROM services WHERE code = $1 AND active"))
        .bind(code)
        .fetch_optional(db)
        .await?
        .ok_or(crate::error::ApiError::NotFound)?;
    Ok(row.into_domain())
}

pub async fn load_formula(db: &sqlx::PgPool) -> ApiResult<QuoteFormula> {
    let v: Option<sqlx::types::Json<QuoteFormula>> = sqlx::query_scalar("SELECT value FROM settings WHERE key = 'quote_formula'")
        .fetch_optional(db)
        .await?;
    Ok(v.map(|j| j.0).unwrap_or_default())
}

async fn list_services(State(s): State<AppState>) -> ApiResult<Json<Vec<ServiceDto>>> {
    let rows: Vec<ServiceRow> = sqlx::query_as(&format!("SELECT {SERVICE_COLS} FROM services WHERE active ORDER BY sort_order"))
        .fetch_all(&s.db)
        .await?;
    Ok(Json(
        rows.into_iter()
            .map(|r| {
                let content = r.content.clone();
                ServiceDto {
                    service: r.into_domain(),
                    content,
                }
            })
            .collect(),
    ))
}

#[derive(Deserialize)]
struct SlotQuery {
    date: NaiveDate,
    quote: Option<bool>,
}

#[derive(Serialize)]
struct SlotDto {
    start_hour: u8,
    available: bool,
}

/// Availability for one date; capacity per start hour is set in the console.
async fn slots(State(s): State<AppState>, Query(q): Query<SlotQuery>) -> ApiResult<Json<Vec<SlotDto>>> {
    let hours: &[u8] = if q.quote.unwrap_or(false) { &QUOTE_SLOTS } else { &STANDARD_SLOTS };
    let rows: Vec<(i16, Option<i32>, i64)> = sqlx::query_as(
        "SELECT h.hour, c.capacity, (SELECT count(*) FROM bookings b WHERE b.visit_date = $1 AND b.start_hour = h.hour AND b.status >= 0)
         FROM unnest($2::smallint[]) AS h(hour) LEFT JOIN slot_capacity c ON c.start_hour = h.hour",
    )
    .bind(q.date)
    .bind(hours.iter().map(|h| i16::from(*h)).collect::<Vec<_>>())
    .fetch_all(&s.db)
    .await?;
    Ok(Json(
        rows.into_iter()
            .map(|(h, cap, used)| SlotDto {
                start_hour: h as u8,
                available: cap.is_none_or(|c| used < i64::from(c)),
            })
            .collect(),
    ))
}

async fn estimate(State(s): State<AppState>, Json(a): Json<QuoteAnswers>) -> ApiResult<Json<Estimate>> {
    Ok(Json(load_formula(&s.db).await?.estimate(&a)?))
}

#[derive(Deserialize)]
struct ContentQuery {
    kind: String,
}

#[derive(Serialize, sqlx::FromRow)]
struct ContentRow {
    id: Uuid,
    kind: String,
    slug: Option<String>,
    title: Value,
    body: Value,
    image_url: Option<String>,
    link: Option<String>,
}

async fn content(State(s): State<AppState>, Query(q): Query<ContentQuery>) -> ApiResult<Json<Vec<ContentRow>>> {
    let rows = sqlx::query_as(
        "SELECT id, kind, slug, title, body, image_url, link FROM content_items
         WHERE kind = $1 AND active AND (starts_at IS NULL OR starts_at <= now()) AND (ends_at IS NULL OR ends_at > now())
         ORDER BY sort_order, created_at DESC",
    )
    .bind(q.kind)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}
