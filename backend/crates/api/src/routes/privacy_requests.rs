//! Console: customer rights requests (PIPA 열람·삭제). Admins look a customer up by phone, export that
//! customer's data (JSON or CSV) and see the outcome of each request. Export and deletion need a TOTP step-up
//! within five minutes, and deleting needs the customer's phone typed back in. Every step is audit-logged
//! and recorded in `privacy_requests`.

use super::{audit, finance::csv_response, staff_mfa::require_recent_stepup};
use crate::{
    auth::{Admin, Staff, normalize_phone},
    error::{ApiError, ApiResult},
    privacy,
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Path, Query, State},
    response::{IntoResponse, Response},
    routing::{get, post},
};
use chrono::{DateTime, Utc};
use domain::finance::{Cell, csv_document};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

const LIST_LIMIT: i64 = 200;

pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/privacy/customers", get(lookup))
        .route("/privacy/customers/{id}/export", get(export))
        .route("/privacy/customers/{id}/delete", post(delete))
        .route("/privacy/requests", get(list_requests))
}

#[derive(Deserialize)]
struct PhoneQuery {
    phone: String,
}

#[derive(Serialize, sqlx::FromRow)]
struct Found {
    id: Uuid,
    name: String,
    phone: String,
    created_at: DateTime<Utc>,
    bookings: i64,
}

/// Live customers with this phone number (one at most in practice; deleted accounts keep no phone).
async fn lookup(State(s): State<AppState>, Admin(st): Admin, Query(q): Query<PhoneQuery>) -> ApiResult<Json<Vec<Found>>> {
    let phone = normalize_phone(&q.phone).ok_or(ApiError::BadRequest("invalid_phone"))?;
    audit(&s.db, "staff", Some(st.id), "privacy.lookup", "users", json!({})).await?;
    let rows: Vec<Found> = sqlx::query_as(
        "SELECT u.id, u.name, u.phone, u.created_at, (SELECT count(*) FROM bookings b WHERE b.user_id = u.id) AS bookings
         FROM users u WHERE u.phone = $1 AND u.deleted_at IS NULL",
    )
    .bind(&phone)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}

/// The phone of a live customer; a deleted or unknown id is 404.
async fn live_phone(db: &PgPool, id: Uuid) -> ApiResult<String> {
    sqlx::query_scalar("SELECT phone FROM users WHERE id = $1 AND deleted_at IS NULL")
        .bind(id)
        .fetch_optional(db)
        .await?
        .ok_or(ApiError::NotFound)
}

/// Records the outcome of a request. The row holds ids and the result only, never the customer's details.
/// Runs after the work has committed, so a failed insert is logged, not returned: the caller's answer stands.
async fn record<T>(db: &PgPool, kind: &str, customer: Uuid, staff: Uuid, result: &ApiResult<T>) {
    let status = if result.is_ok() { "done" } else { "failed" };
    let inserted = sqlx::query("INSERT INTO privacy_requests (kind, customer_id, staff_id, status) VALUES ($1,$2,$3,$4)")
        .bind(kind)
        .bind(customer)
        .bind(staff)
        .bind(status)
        .execute(db)
        .await;
    if let Err(e) = inserted {
        tracing::error!(error = %e, kind, %customer, "privacy request outcome not recorded");
    }
}

#[derive(Deserialize)]
struct ExportQuery {
    format: Option<String>,
}

/// Flattens the export into `section, detail` rows: one row per item, the item as JSON text.
fn csv_rows(doc: &Value) -> Vec<Vec<Cell>> {
    let mut rows = vec![vec![text("section"), text("detail")]];
    let Value::Object(sections) = doc else {
        return rows;
    };
    for (section, value) in sections {
        match value {
            Value::Array(items) => rows.extend(items.iter().map(|item| vec![text(section), text(item.to_string())])),
            other => rows.push(vec![text(section), text(other.to_string())]),
        }
    }
    rows
}

fn text(v: impl Into<String>) -> Cell {
    Cell::Text(v.into())
}

async fn export(State(s): State<AppState>, Admin(st): Admin, Path(id): Path<Uuid>, Query(q): Query<ExportQuery>) -> ApiResult<Response> {
    require_recent_stepup(&s, st.id).await?;
    let format = match q.format.as_deref() {
        None | Some("json") => "json",
        Some("csv") => "csv",
        Some(_) => return Err(ApiError::BadRequest("invalid_format")),
    };
    live_phone(&s.db, id).await?;
    audit(&s.db, "staff", Some(st.id), "customer.export", &id.to_string(), json!({ "format": format })).await?;
    let result = privacy::export_doc(&s.db, id).await;
    record(&s.db, "export", id, st.id, &result).await;
    let doc = result?;
    if format == "csv" {
        return csv_response(&format!("malkkeum-customer-{id}"), csv_document(&csv_rows(&doc)));
    }
    Ok(Json(doc).into_response())
}

#[derive(Deserialize)]
struct DeleteBody {
    /// The customer's phone, typed again by the admin: a deletion needs this confirmation.
    phone: String,
}

async fn delete(State(s): State<AppState>, Admin(st): Admin, Path(id): Path<Uuid>, Json(body): Json<DeleteBody>) -> ApiResult<Json<Value>> {
    require_recent_stepup(&s, st.id).await?;
    let phone = live_phone(&s.db, id).await?;
    let typed = normalize_phone(&body.phone).ok_or(ApiError::BadRequest("invalid_phone"))?;
    if typed != phone {
        return Err(ApiError::BadRequest("phone_confirmation_mismatch"));
    }
    audit(&s.db, "staff", Some(st.id), "customer.delete", &id.to_string(), json!({})).await?;
    let result = privacy::delete_account(&s, id).await;
    record(&s.db, "delete", id, st.id, &result).await;
    result?;
    Ok(Json(json!({ "ok": true })))
}

#[derive(Serialize, sqlx::FromRow)]
struct RequestRow {
    id: i64,
    kind: String,
    customer_id: Uuid,
    status: String,
    staff_name: Option<String>,
    created_at: DateTime<Utc>,
}

async fn list_requests(State(s): State<AppState>, Staff(_): Staff) -> ApiResult<Json<Vec<RequestRow>>> {
    let rows: Vec<RequestRow> = sqlx::query_as(
        "SELECT r.id, r.kind, r.customer_id, r.status, st.name AS staff_name, r.created_at
         FROM privacy_requests r LEFT JOIN staff st ON st.id = r.staff_id
         ORDER BY r.created_at DESC, r.id DESC LIMIT $1",
    )
    .bind(LIST_LIMIT)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}
