//! Public address search (juso.go.kr proxy) and the feature switches the apps read at start-up.

use crate::{
    address::{self, Invalid},
    error::{ApiError, ApiResult},
    providers::portone,
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Query, State},
    routing::get,
};
use serde::Deserialize;
use serde_json::{Value, json};

pub fn public_routes() -> Router<AppState> {
    Router::new().route("/address/search", get(search)).route("/features", get(features))
}

#[derive(Deserialize)]
struct SearchQuery {
    #[serde(default)]
    q: String,
    page: Option<u32>,
}

/// Rate-limited by the general per-IP bucket like every `/v1` route. Answers 503 when no key is set.
async fn search(State(s): State<AppState>, Query(query): Query<SearchQuery>) -> ApiResult<Json<Value>> {
    let integ = s.providers.integ();
    let key = integ.juso_confm_key.as_deref().ok_or(ApiError::Unavailable("provider_not_configured"))?;
    let keyword = address::clean_keyword(&query.q).map_err(|Invalid(code)| ApiError::BadRequest(code))?;
    let page = query.page.unwrap_or(1);
    if !(1..=address::MAX_PAGE).contains(&page) {
        return Err(ApiError::BadRequest("invalid_page"));
    }
    let hits = address::search(s.providers.http(), key, &keyword, page).await?;
    Ok(Json(json!({ "results": hits, "page": page })))
}

/// Which optional integrations are configured, so the apps can hide what would not work.
async fn features(State(s): State<AppState>) -> Json<Value> {
    let integ = s.providers.integ();
    Json(json!({
        "address_search": integ.juso_confm_key.is_some(),
        "card_billing": portone::billing_ready(&integ.portone),
    }))
}
