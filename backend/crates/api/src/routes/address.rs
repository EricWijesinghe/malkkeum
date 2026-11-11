//! Address search (juso.go.kr proxy) for signed-in customers and partners, and the public feature
//! switches the apps read at start-up.

use crate::{
    address::{self, Invalid},
    auth::{Auth, Role},
    error::{ApiError, ApiResult},
    providers::portone,
    ratelimit::UserLimiter,
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Query, State},
    routing::get,
};
use serde::Deserialize;
use serde_json::{Value, json};
use std::{
    collections::HashMap,
    sync::Mutex,
    time::{Duration, Instant},
};

/// Searches one user may run per minute. Juso charges per call; the per-IP bucket alone is too loose.
const SEARCH_PER_MIN: usize = 30;
const CACHE_TTL: Duration = Duration::from_secs(300);
/// Bound on cached (query, page) entries; a full cache takes no new entries until stale ones age out.
const CACHE_MAX: usize = 500;

type CacheKey = (String, u32);

/// Per-user search limit and a short-lived result cache, shared by every request in this process.
#[derive(Default)]
pub struct SearchGate {
    per_user: UserLimiter,
    cache: Mutex<HashMap<CacheKey, (Instant, Value)>>,
}

impl SearchGate {
    fn cached(&self, key: &CacheKey, now: Instant) -> Option<Value> {
        let cache = self.cache.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
        cache.get(key).filter(|(at, _)| now.duration_since(*at) < CACHE_TTL).map(|(_, v)| v.clone())
    }

    fn remember(&self, key: CacheKey, value: Value, now: Instant) {
        let mut cache = self.cache.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
        cache.retain(|_, (at, _)| now.duration_since(*at) < CACHE_TTL);
        if cache.len() < CACHE_MAX {
            cache.insert(key, (now, value));
        }
    }
}

pub fn public_routes() -> Router<AppState> {
    Router::new().route("/address/search", get(search)).route("/features", get(features))
}

#[derive(Deserialize)]
struct SearchQuery {
    #[serde(default)]
    q: String,
    page: Option<u32>,
}

/// Customers and partners only, at most `SEARCH_PER_MIN` searches a minute each. Answers 503 when no key is set.
async fn search(State(s): State<AppState>, a: Auth, Query(query): Query<SearchQuery>) -> ApiResult<Json<Value>> {
    if !matches!(a.role, Role::Customer | Role::Pro) {
        return Err(ApiError::Forbidden);
    }
    let now = Instant::now();
    if !s.address_search.per_user.admit(a.id, SEARCH_PER_MIN, now) {
        return Err(ApiError::RateLimited);
    }
    let integ = s.providers.integ();
    let key = integ.juso_confm_key.as_deref().ok_or(ApiError::Unavailable("provider_not_configured"))?;
    let keyword = address::clean_keyword(&query.q).map_err(|Invalid(code)| ApiError::BadRequest(code))?;
    let page = query.page.unwrap_or(1);
    if !(1..=address::MAX_PAGE).contains(&page) {
        return Err(ApiError::BadRequest("invalid_page"));
    }
    let cache_key = (keyword.clone(), page);
    if let Some(hit) = s.address_search.cached(&cache_key, now) {
        return Ok(Json(hit));
    }
    let hits = address::search(s.providers.http(), key, &keyword, page).await?;
    let body = json!({ "results": hits, "page": page });
    s.address_search.remember(cache_key, body.clone(), now);
    Ok(Json(body))
}

/// Which optional integrations are configured, so the apps can hide what would not work.
async fn features(State(s): State<AppState>) -> Json<Value> {
    let integ = s.providers.integ();
    Json(json!({
        "address_search": integ.juso_confm_key.is_some(),
        "card_billing": portone::billing_ready(&integ.portone),
    }))
}
