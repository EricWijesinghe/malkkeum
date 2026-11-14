//! Console: owner-editable limits and thresholds, one group at a time (see `settings_registry`).

use crate::{auth::Admin, error::ApiResult, settings_registry, state::AppState};
use axum::{
    Json, Router,
    extract::{Path, State},
    routing::get,
};
use serde::Deserialize;
use serde_json::{Map, Value};

pub fn admin_routes() -> Router<AppState> {
    Router::new().route("/settings/{group}", get(get_group).put(put_group))
}

#[derive(Deserialize)]
struct SaveBody {
    values: Map<String, Value>,
}

async fn get_group(State(s): State<AppState>, Admin(_): Admin, Path(group): Path<String>) -> ApiResult<Json<Value>> {
    Ok(Json(settings_registry::group_view(&s.db, &s.config, &group).await?))
}

async fn put_group(State(s): State<AppState>, Admin(a): Admin, Path(group): Path<String>, Json(body): Json<SaveBody>) -> ApiResult<Json<Value>> {
    settings_registry::ensure_can_write(&s.db, a.id).await?;
    let saved = settings_registry::save_group(&s.db, &s.config, &group, a.id, &body.values).await?;
    // The ops group holds the maintenance switch that the public config document reads.
    super::config::invalidate();
    Ok(Json(saved))
}
