//! Console: sample data for demos and training. Load needs an admin and refuses over real data; clear also
//! needs the owner's TOTP code, the same gate as the keys bundle.

use super::{audit, keys::owner_gate};
use crate::{
    auth::Admin,
    demo::{self, DemoError},
    error::{ApiError, ApiResult},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{ConnectInfo, State},
    http::HeaderMap,
    routing::post,
};
use serde_json::{Value, json};
use std::net::SocketAddr;

pub fn admin_routes() -> Router<AppState> {
    Router::new().route("/demo/load", post(load)).route("/demo/clear", post(clear))
}

fn demo_failure(e: DemoError) -> ApiError {
    match e {
        DemoError::AlreadyLoaded => ApiError::Conflict("demo_already_loaded"),
        DemoError::RealData { .. } => ApiError::Conflict("demo_real_data"),
        other => ApiError::Internal(format!("demo: {other}")),
    }
}

async fn load(State(s): State<AppState>, Admin(a): Admin) -> ApiResult<Json<Value>> {
    let report = demo::load(&s.db, &s.config, false).await.map_err(demo_failure)?;
    audit(&s.db, "staff", Some(a.id), "demo.load", "demo", json!(report)).await?;
    Ok(Json(json!({ "ok": true, "tables": report })))
}

async fn clear(State(s): State<AppState>, ConnectInfo(peer): ConnectInfo<SocketAddr>, headers: HeaderMap, Admin(a): Admin) -> ApiResult<Json<Value>> {
    owner_gate(&s, peer, &headers, a.id).await?;
    let report = demo::clear(&s.db, &s.config).await.map_err(demo_failure)?;
    audit(&s.db, "staff", Some(a.id), "demo.clear", "demo", json!(report)).await?;
    Ok(Json(json!({ "ok": true, "tables": report })))
}
