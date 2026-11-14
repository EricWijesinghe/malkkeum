//! Renewal calendar for the console (갱신 일정). Admins only. Every write is audited; reminders are sent by
//! `renewals::spawn`, so changing a due date re-arms its reminders.

use super::audit;
use crate::{
    auth::Admin,
    error::{ApiError, ApiResult},
    renewals::{self, KINDS},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Path, State},
    routing::{get, put},
};
use chrono::Utc;
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/renewals", get(list).post(create))
        .route("/renewals/{id}", put(update).delete(remove))
}

async fn list(State(s): State<AppState>, Admin(_): Admin) -> ApiResult<Json<Value>> {
    let today = renewals::kst_today(Utc::now());
    let items: Vec<Value> = renewals::due_items(&s.db)
        .await?
        .into_iter()
        .map(|d| {
            let left = renewals::days_left(d.due_on, today);
            json!({ "id": d.id, "kind": d.kind, "name": d.name, "due_on": d.due_on, "days_left": left })
        })
        .collect();
    Ok(Json(json!({ "today": today, "items": items, "kinds": KINDS })))
}

async fn create(State(s): State<AppState>, Admin(a): Admin, Json(input): Json<Value>) -> ApiResult<Json<Value>> {
    let input = renewals::parse_input(&input).map_err(ApiError::BadRequest)?;
    let id: Uuid = sqlx::query_scalar("INSERT INTO renewals (kind, name, due_on) VALUES ($1, $2, $3) RETURNING id")
        .bind(&input.kind)
        .bind(&input.name)
        .bind(input.due_on)
        .fetch_one(&s.db)
        .await?;
    audit(
        &s.db,
        a.role.as_str(),
        Some(a.id),
        "renewal.create",
        "renewals",
        json!({ "id": id, "kind": input.kind }),
    )
    .await?;
    Ok(Json(json!({ "id": id })))
}

async fn update(State(s): State<AppState>, Admin(a): Admin, Path(id): Path<Uuid>, Json(input): Json<Value>) -> ApiResult<Json<Value>> {
    let input = renewals::parse_input(&input).map_err(ApiError::BadRequest)?;
    let done = sqlx::query("UPDATE renewals SET kind = $2, name = $3, due_on = $4, updated_at = now() WHERE id = $1")
        .bind(id)
        .bind(&input.kind)
        .bind(&input.name)
        .bind(input.due_on)
        .execute(&s.db)
        .await?;
    if done.rows_affected() == 0 {
        return Err(ApiError::NotFound);
    }
    audit(
        &s.db,
        a.role.as_str(),
        Some(a.id),
        "renewal.update",
        "renewals",
        json!({ "id": id, "kind": input.kind }),
    )
    .await?;
    Ok(Json(json!({ "id": id })))
}

async fn remove(State(s): State<AppState>, Admin(a): Admin, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    if delete_row(&s.db, id).await? == 0 {
        return Err(ApiError::NotFound);
    }
    audit(&s.db, a.role.as_str(), Some(a.id), "renewal.delete", "renewals", json!({ "id": id })).await?;
    Ok(Json(json!({ "deleted": true })))
}

async fn delete_row(db: &PgPool, id: Uuid) -> Result<u64, sqlx::Error> {
    sqlx::query("DELETE FROM renewals WHERE id = $1")
        .bind(id)
        .execute(db)
        .await
        .map(|r| r.rows_affected())
}
