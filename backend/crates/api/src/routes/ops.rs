//! Operations API for the console: the status page and the owner's alert settings. Staff can read;
//! only the owner changes alert settings.

use super::audit;
use crate::{
    auth::{Admin, Staff},
    error::{ApiError, ApiResult},
    ops, ops_alerts,
    state::AppState,
};
use axum::{
    Json, Router,
    extract::State,
    routing::get,
};
use serde_json::{Value, json};

pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/ops/status", get(status))
        .route("/ops/alerts", get(get_alerts).put(put_alerts))
}

async fn status(State(s): State<AppState>, _st: Staff) -> ApiResult<Json<Value>> {
    Ok(Json(ops::status(&s).await?))
}

async fn get_alerts(State(s): State<AppState>, _st: Staff) -> ApiResult<Json<Value>> {
    let prefs = ops_alerts::load_prefs(&s.db).await?;
    let default_phone = ops_alerts::business_phone(&s.db).await?;
    Ok(Json(json!({ "prefs": prefs, "rules": ops_alerts::RULES, "default_phone": default_phone, "cooldown_hours": ops_alerts::COOLDOWN_HOURS })))
}

async fn put_alerts(State(s): State<AppState>, Admin(a): Admin, Json(input): Json<Value>) -> ApiResult<Json<Value>> {
    let prefs = ops_alerts::parse_input(&input).map_err(ApiError::BadRequest)?;
    ops_alerts::save_prefs(&s.db, &prefs).await?;
    audit(&s.db, a.role.as_str(), Some(a.id), "ops.alerts", "ops_alerts", json!({ "rules": prefs.rules.len() })).await?;
    Ok(Json(json!({ "prefs": prefs })))
}
