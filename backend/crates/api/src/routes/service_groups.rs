//! Home categories (CR-8.1): the public group list the app reads, and the console's audited edits.
//! Membership is `services.group_code`; the listed order is written into the members' `sort_order` slots.

use super::audit;
use crate::{
    auth::{Admin, Staff},
    error::{ApiError, ApiResult},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Path, State},
    http::header,
    response::{IntoResponse, Response},
    routing::{get, put},
};
use domain::service_group::{GROUP_CODES, derive_badge, valid_config};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use std::collections::HashSet;

/// Group list changes rarely; the app may keep it a minute.
const PUBLIC_CACHE: &str = "public, max-age=60";
const MAX_TITLE_CHARS: usize = 40;
const MAX_ICON_CHARS: usize = 40;

pub fn routes() -> Router<AppState> {
    Router::new().route("/service-groups", get(public_groups))
}

pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/service-groups", get(admin_groups))
        .route("/service-groups/{code}", put(update_group))
}

#[derive(sqlx::FromRow)]
struct GroupRow {
    code: String,
    title: Value,
    sort_order: i32,
    active: bool,
    chooser: String,
    icon: String,
    config: Value,
    services: Vec<String>,
    badges: Vec<String>,
}

#[derive(Serialize)]
struct GroupDto {
    code: String,
    title: Value,
    sort_order: i32,
    active: bool,
    chooser: String,
    icon: String,
    /// Derived from the members' badges: "HOT" wins over "N"; null when no member has one.
    badge: Option<&'static str>,
    services: Vec<String>,
    config: Value,
}

/// Groups in home order. `public` hides inactive groups and inactive member services.
async fn load_groups(db: &sqlx::PgPool, public: bool) -> ApiResult<Vec<GroupDto>> {
    let rows: Vec<GroupRow> = sqlx::query_as(
        "SELECT g.code, g.title, g.sort_order, g.active, g.chooser, g.icon, g.config,
                COALESCE(array_agg(s.code ORDER BY s.sort_order, s.code) FILTER (WHERE s.code IS NOT NULL AND (NOT $1 OR s.active)), '{}') AS services,
                COALESCE(array_agg(s.content->>'badge') FILTER (WHERE s.active AND s.content->>'badge' IS NOT NULL), '{}') AS badges
         FROM service_groups g LEFT JOIN services s ON s.group_code = g.code
         WHERE NOT $1 OR g.active
         GROUP BY g.code ORDER BY g.sort_order, g.code",
    )
    .bind(public)
    .fetch_all(db)
    .await?;
    Ok(rows
        .into_iter()
        .map(|r| GroupDto {
            badge: derive_badge(r.badges.iter().map(String::as_str)),
            code: r.code,
            title: r.title,
            sort_order: r.sort_order,
            active: r.active,
            chooser: r.chooser,
            icon: r.icon,
            services: r.services,
            config: r.config,
        })
        .collect())
}

async fn public_groups(State(s): State<AppState>) -> ApiResult<Response> {
    let groups = load_groups(&s.db, true).await?;
    Ok(([(header::CACHE_CONTROL, PUBLIC_CACHE)], Json(json!({ "groups": groups }))).into_response())
}

async fn admin_groups(State(s): State<AppState>, _st: Staff) -> ApiResult<Json<Value>> {
    let groups = load_groups(&s.db, false).await?;
    Ok(Json(json!({ "groups": groups })))
}

#[derive(Deserialize)]
struct Title {
    ko: String,
    en: String,
}

/// Editable fields. `services` is the full member list in the order the home shows it.
#[derive(Deserialize)]
struct GroupUpdate {
    title: Title,
    sort_order: i32,
    active: bool,
    icon: String,
    services: Vec<String>,
    config: Value,
}

fn valid_title_part(text: &str) -> bool {
    let len = text.trim().chars().count();
    (1..=MAX_TITLE_CHARS).contains(&len)
}

/// Lowercase ASCII token for the icon, like the service codes.
fn valid_icon(icon: &str) -> bool {
    (1..=MAX_ICON_CHARS).contains(&icon.len()) && icon.chars().all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '_')
}

/// Korean and English titles, at least one unique member, a short icon and a well-formed config.
fn valid_update(u: &GroupUpdate) -> bool {
    let unique = u.services.iter().collect::<HashSet<_>>().len() == u.services.len();
    valid_title_part(&u.title.ko)
        && valid_title_part(&u.title.en)
        && u.sort_order >= 0
        && valid_icon(&u.icon)
        && !u.services.is_empty()
        && unique
        && valid_config(&u.config)
}

async fn update_group(State(s): State<AppState>, Admin(a): Admin, Path(code): Path<String>, Json(u): Json<GroupUpdate>) -> ApiResult<Json<Value>> {
    if !GROUP_CODES.contains(&code.as_str()) {
        return Err(ApiError::NotFound);
    }
    if !valid_update(&u) {
        return Err(ApiError::BadRequest("invalid_group"));
    }
    let mut tx = s.db.begin().await?;
    apply_group(&mut tx, &code, &u).await?;
    tx.commit().await?;
    audit(
        &s.db,
        "staff",
        Some(a.id),
        "service_group.update",
        &code,
        json!({ "services": u.services, "active": u.active }),
    )
    .await?;
    Ok(Json(json!({ "ok": true })))
}

/// Writes one group in the caller's transaction: membership, member order (reusing the members' own
/// sort slots, so other services keep their places), then the group row itself.
async fn apply_group(tx: &mut sqlx::Transaction<'_, sqlx::Postgres>, code: &str, u: &GroupUpdate) -> ApiResult<()> {
    let found: i64 = sqlx::query_scalar("SELECT count(*) FROM services WHERE code = ANY($1)")
        .bind(&u.services)
        .fetch_one(&mut **tx)
        .await?;
    if usize::try_from(found).ok() != Some(u.services.len()) {
        return Err(ApiError::BadRequest("unknown_service"));
    }
    let slots: Vec<i32> = sqlx::query_scalar("SELECT sort_order FROM services WHERE code = ANY($1) ORDER BY sort_order")
        .bind(&u.services)
        .fetch_all(&mut **tx)
        .await?;
    sqlx::query("UPDATE services SET group_code = NULL WHERE group_code = $1 AND NOT (code = ANY($2))")
        .bind(code)
        .bind(&u.services)
        .execute(&mut **tx)
        .await?;
    for (service, slot) in u.services.iter().zip(slots) {
        sqlx::query("UPDATE services SET group_code = $2, sort_order = $3, updated_at = now() WHERE code = $1")
            .bind(service)
            .bind(code)
            .bind(slot)
            .execute(&mut **tx)
            .await?;
    }
    let title = json!({ "ko": u.title.ko.trim(), "en": u.title.en.trim() });
    let r = sqlx::query("UPDATE service_groups SET title = $2, sort_order = $3, active = $4, icon = $5, config = $6, updated_at = now() WHERE code = $1")
        .bind(code)
        .bind(title)
        .bind(u.sort_order)
        .bind(u.active)
        .bind(&u.icon)
        .bind(&u.config)
        .execute(&mut **tx)
        .await?;
    if r.rows_affected() == 0 {
        return Err(ApiError::NotFound);
    }
    Ok(())
}
