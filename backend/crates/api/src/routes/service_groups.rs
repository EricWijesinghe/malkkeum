//! Home service groups (서비스 묶음): the tiles the apps show, and their console editor.
//! A group's member services are listed in `service_groups.services` (order matters); each
//! member's `services.group_code` points back, so a service belongs to at most one group.

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
use serde::Deserialize;
use serde_json::{Value, json};

const CHOOSERS: [&str; 3] = ["move", "list", "direct"];
const HOME_TYPES: [&str; 3] = ["one_two_room", "apartment", "villa_house"];
const MAX_MEMBERS: usize = 20;
const MAX_TITLE_CHARS: usize = 40;
const MAX_SORT_ORDER: i32 = 99;
const PUBLIC_CACHE: &str = "public, max-age=60";

pub fn public_routes() -> Router<AppState> {
    Router::new().route("/service-groups", get(list_public))
}

pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/service-groups", get(list_admin))
        .route("/service-groups/{code}", put(update_group))
}

#[derive(sqlx::FromRow)]
struct GroupRow {
    code: String,
    title_ko: String,
    title_en: String,
    sort_order: i32,
    active: bool,
    icon: String,
    chooser: String,
    services: Vec<String>,
    config: sqlx::types::Json<Value>,
}

#[derive(sqlx::FromRow)]
struct ServiceRow {
    code: String,
    group_code: Option<String>,
    active: bool,
    badge: Option<String>,
}

#[derive(Deserialize)]
struct GroupUpdate {
    title_ko: String,
    title_en: String,
    sort_order: i32,
    active: bool,
    icon: String,
    chooser: String,
    services: Vec<String>,
    config: Value,
}

async fn load(db: &sqlx::PgPool) -> ApiResult<(Vec<GroupRow>, Vec<ServiceRow>)> {
    let groups = sqlx::query_as(
        "SELECT code, title_ko, title_en, sort_order, active, icon, chooser, services, config
         FROM service_groups ORDER BY sort_order, code",
    )
    .fetch_all(db)
    .await?;
    let services = sqlx::query_as("SELECT code, group_code, active, content->>'badge' AS badge FROM services")
        .fetch_all(db)
        .await?;
    Ok((groups, services))
}

async fn list_public(State(s): State<AppState>) -> ApiResult<Response> {
    let (groups, services) = load(&s.db).await?;
    let out: Vec<Value> = groups
        .iter()
        .filter(|g| g.active)
        .map(|g| view(g, &services, true))
        .filter(|v| v["services"].as_array().is_some_and(|a| !a.is_empty()))
        .collect();
    Ok(([(header::CACHE_CONTROL, PUBLIC_CACHE)], Json(json!({ "groups": out }))).into_response())
}

async fn list_admin(State(s): State<AppState>, _st: Staff) -> ApiResult<Json<Value>> {
    let (groups, services) = load(&s.db).await?;
    let out: Vec<Value> = groups.iter().map(|g| view(g, &services, false)).collect();
    Ok(Json(json!({ "groups": out })))
}

/// One group as the apps (live members only) or the console (every configured member) see it.
fn view(g: &GroupRow, services: &[ServiceRow], live_only: bool) -> Value {
    let members: Vec<&ServiceRow> = g
        .services
        .iter()
        .filter_map(|c| services.iter().find(|s| &s.code == c && s.group_code.as_deref() == Some(g.code.as_str())))
        .filter(|s| !live_only || s.active)
        .collect();
    let badges: Vec<Option<String>> = members.iter().map(|m| m.badge.clone()).collect();
    let codes: Vec<&str> = members.iter().map(|m| m.code.as_str()).collect();
    json!({
        "code": g.code,
        "title": { "ko": g.title_ko, "en": g.title_en },
        "sort_order": g.sort_order,
        "active": g.active,
        "icon": g.icon,
        "chooser": g.chooser,
        "badge": derive_badge(&badges),
        "services": codes,
        "config": g.config.0.clone(),
    })
}

/// HOT wins over N; N only when a member carries it.
fn derive_badge(badges: &[Option<String>]) -> Option<&'static str> {
    let has = |want: &str| badges.iter().any(|b| b.as_deref() == Some(want));
    if has("HOT") {
        Some("HOT")
    } else if has("N") {
        Some("N")
    } else {
        None
    }
}

async fn update_group(State(s): State<AppState>, Admin(a): Admin, Path(code): Path<String>, Json(u): Json<GroupUpdate>) -> ApiResult<Json<Value>> {
    let (_, services) = load(&s.db).await?;
    check_update(&code, &u, &services).map_err(ApiError::BadRequest)?;
    let mut tx = s.db.begin().await?;
    let r = sqlx::query(
        "UPDATE service_groups SET title_ko=$2, title_en=$3, sort_order=$4, active=$5, icon=$6, chooser=$7,
            services=$8, config=$9, updated_at=now() WHERE code=$1",
    )
    .bind(&code)
    .bind(u.title_ko.trim())
    .bind(u.title_en.trim())
    .bind(u.sort_order)
    .bind(u.active)
    .bind(&u.icon)
    .bind(&u.chooser)
    .bind(&u.services)
    .bind(sqlx::types::Json(&u.config))
    .execute(&mut *tx)
    .await?;
    if r.rows_affected() == 0 {
        return Err(ApiError::NotFound);
    }
    sqlx::query("UPDATE services SET group_code = NULL WHERE group_code = $1 AND NOT (code = ANY($2))")
        .bind(&code)
        .bind(&u.services)
        .execute(&mut *tx)
        .await?;
    sqlx::query("UPDATE services SET group_code = $1 WHERE code = ANY($2)")
        .bind(&code)
        .bind(&u.services)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    audit(
        &s.db,
        "staff",
        Some(a.id),
        "service_group.update",
        &code,
        json!({ "services": u.services, "active": u.active, "chooser": u.chooser }),
    )
    .await?;
    Ok(Json(json!({ "ok": true })))
}

/// Returns the reason the update is refused, as a short code the console maps to a Korean message.
fn check_update(code: &str, u: &GroupUpdate, services: &[ServiceRow]) -> Result<(), &'static str> {
    let title_ok = |t: &str| (1..=MAX_TITLE_CHARS).contains(&t.trim().chars().count());
    if !title_ok(u.title_ko.as_str()) || !title_ok(u.title_en.as_str()) {
        return Err("invalid_group_title");
    }
    if !(0..=MAX_SORT_ORDER).contains(&u.sort_order) {
        return Err("invalid_group_order");
    }
    if u.icon.is_empty() || u.icon.len() > 40 || !u.icon.chars().all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '_') {
        return Err("invalid_group_icon");
    }
    if !CHOOSERS.contains(&u.chooser.as_str()) {
        return Err("invalid_group_chooser");
    }
    check_members(code, &u.services, services)?;
    if !u.config.is_object() || !config_fits(&u.chooser, &u.config, &u.services) {
        return Err("invalid_group_config");
    }
    Ok(())
}

fn check_members(code: &str, members: &[String], services: &[ServiceRow]) -> Result<(), &'static str> {
    let unique = members.iter().enumerate().all(|(i, m)| !members[..i].contains(m));
    if !unique || members.len() > MAX_MEMBERS {
        return Err("invalid_group_services");
    }
    for m in members {
        let Some(row) = services.iter().find(|s| &s.code == m) else {
            return Err("unknown_service");
        };
        if row.group_code.as_deref().is_some_and(|g| g != code) {
            return Err("service_in_other_group");
        }
    }
    Ok(())
}

/// A move tile needs its build-age targets among its members and at least one known home type.
/// A direct tile opens one service, so it must have exactly one member.
fn config_fits(chooser: &str, config: &Value, members: &[String]) -> bool {
    match chooser {
        "direct" => members.len() == 1,
        "move" => {
            let target = |k: &str| {
                config
                    .get("build_age")
                    .and_then(|b| b.get(k))
                    .and_then(Value::as_str)
                    .is_some_and(|c| members.iter().any(|m| m == c))
            };
            let types_ok = config
                .get("home_types")
                .and_then(Value::as_array)
                .is_some_and(|a| !a.is_empty() && a.iter().all(|t| t.as_str().is_some_and(|t| HOME_TYPES.contains(&t))));
            target("new") && target("old") && types_ok
        }
        _ => true,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn svc(code: &str, group: Option<&str>, badge: Option<&str>) -> ServiceRow {
        ServiceRow {
            code: code.into(),
            group_code: group.map(Into::into),
            active: true,
            badge: badge.map(Into::into),
        }
    }

    fn update(chooser: &str, services: &[&str], config: Value) -> GroupUpdate {
        GroupUpdate {
            title_ko: "이사·입주 청소".into(),
            title_en: "Move".into(),
            sort_order: 0,
            active: true,
            icon: "svc_move".into(),
            chooser: chooser.into(),
            services: services.iter().map(|s| s.to_string()).collect(),
            config,
        }
    }

    #[test]
    fn hot_wins_over_new_and_both_need_a_member() {
        let some = |s: &str| Some(s.to_string());
        assert_eq!(derive_badge(&[None, some("N"), some("HOT")]), Some("HOT"));
        assert_eq!(derive_badge(&[some("N"), None]), Some("N"));
        assert_eq!(derive_badge(&[None]), None);
        assert_eq!(derive_badge(&[]), None);
    }

    #[test]
    fn move_tile_needs_build_age_targets_and_known_home_types() {
        let members = vec!["move_in".to_string(), "move_out".to_string()];
        let ok = json!({ "build_age": { "new": "move_in", "old": "move_out" }, "home_types": ["apartment"] });
        assert!(config_fits("move", &ok, &members));
        let missing = json!({ "build_age": { "new": "move_in", "old": "studio" }, "home_types": ["apartment"] });
        assert!(!config_fits("move", &missing, &members));
        let bad_type = json!({ "build_age": { "new": "move_in", "old": "move_out" }, "home_types": ["castle"] });
        assert!(!config_fits("move", &bad_type, &members));
    }

    #[test]
    fn direct_tile_has_exactly_one_member() {
        assert!(config_fits("direct", &json!({}), &["aircon".to_string()]));
        assert!(!config_fits("direct", &json!({}), &[]));
    }

    #[test]
    fn a_service_cannot_move_out_of_another_group() {
        let services = vec![svc("aircon", Some("appliance"), None)];
        assert_eq!(check_members("living", &["aircon".to_string()], &services), Err("service_in_other_group"));
        assert_eq!(check_members("appliance", &["aircon".to_string()], &services), Ok(()));
        assert_eq!(check_members("living", &["nope".to_string()], &services), Err("unknown_service"));
    }

    #[test]
    fn title_and_order_are_bounded() {
        let services = vec![svc("aircon", None, None)];
        let mut u = update("list", &["aircon"], json!({}));
        assert_eq!(check_update("appliance", &u, &services), Ok(()));
        u.title_ko = "   ".into();
        assert_eq!(check_update("appliance", &u, &services), Err("invalid_group_title"));
        u.title_ko = "가".into();
        u.sort_order = 100;
        assert_eq!(check_update("appliance", &u, &services), Err("invalid_group_order"));
    }

    #[test]
    fn members_are_listed_once() {
        let services = vec![svc("aircon", None, None)];
        assert_eq!(
            check_members("appliance", &["aircon".into(), "aircon".into()], &services),
            Err("invalid_group_services")
        );
    }
}
