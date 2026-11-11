mod admin;
mod admin_content;
mod auth;
mod booking_core;
mod bookings;
mod catalog;
pub(crate) mod chat;
mod checkout_policy;
pub(crate) mod growth;
pub(crate) mod checkouts;
mod finance;
pub(crate) mod payouts;
pub(crate) mod me;
mod member;
mod ops;
mod partner;
mod partner_jobs;
pub(crate) mod payments;
pub mod setup;
pub mod uploads;
mod webhooks;

use crate::{realtime, state::AppState};
use axum::{
    Json, Router,
    http::{HeaderValue, Method, header},
    routing::get,
};
use serde_json::json;
use std::time::Duration;

/// Release version baked in at image build (`--build-arg APP_VERSION=1.2.3`); `dev` for local builds.
pub const APP_VERSION: &str = match option_env!("APP_VERSION") {
    Some(v) => v,
    None => "dev",
};
use tower_http::{
    cors::{AllowOrigin, CorsLayer},
    limit::RequestBodyLimitLayer,
    timeout::TimeoutLayer,
    trace::TraceLayer,
};

const BODY_LIMIT_BYTES: usize = 12 * 1024 * 1024;
const REQUEST_TIMEOUT: Duration = Duration::from_secs(30);

pub fn router(state: AppState) -> Router {
    let origins: Vec<HeaderValue> = state.config.allowed_origins.iter().filter_map(|o| o.parse().ok()).collect();
    let cors = CorsLayer::new()
        .allow_origin(AllowOrigin::list(origins))
        .allow_methods([Method::GET, Method::POST, Method::PUT, Method::PATCH, Method::DELETE])
        .allow_headers([header::AUTHORIZATION, header::CONTENT_TYPE]);
    let gate = std::sync::Arc::new(crate::ratelimit::Gate::new(&state.config, std::time::Instant::now()));

    let api = Router::new()
        .merge(auth::routes())
        .merge(me::routes())
        .merge(catalog::routes())
        .merge(bookings::routes())
        .merge(chat::routes())
        .merge(uploads::routes())
        .merge(checkouts::routes())
        .merge(growth::public_routes())
        .merge(growth::customer_routes())
        .merge(payments::routes())
        .merge(webhooks::routes())
        .merge(setup::public_routes())
        .nest(
            "/admin",
            admin::routes()
                .merge(admin_content::routes())
                .merge(growth::admin_routes())
                .merge(payments::admin_routes())
                .merge(checkouts::admin_routes())
                .merge(setup::admin_routes())
                .merge(chat::admin_routes())
                .merge(finance::routes())
                .merge(ops::admin_routes()),
        )
        .nest("/partner", partner::routes().merge(partner_jobs::routes()).merge(finance::partner_routes()))
        .nest("/member", member::routes())
        .route("/ws", get(realtime::ws_handler));

    Router::new()
        .route("/health", get(|| async { Json(json!({ "ok": true, "version": APP_VERSION })) }))
        .nest("/v1", api)
        .layer(RequestBodyLimitLayer::new(BODY_LIMIT_BYTES))
        .layer(TimeoutLayer::with_status_code(axum::http::StatusCode::REQUEST_TIMEOUT, REQUEST_TIMEOUT))
        .layer(cors)
        .layer(axum::middleware::from_fn_with_state(state.clone(), uploads::sign_json))
        .layer(axum::middleware::from_fn_with_state(gate, crate::ratelimit::limit))
        // Span records the path only: query strings can carry tokens (/v1/ws?token=...).
        .layer(
            TraceLayer::new_for_http()
                .make_span_with(|req: &axum::http::Request<_>| tracing::info_span!("http", method = %req.method(), path = %req.uri().path())),
        )
        .layer(axum::middleware::from_fn_with_state(state.clone(), crate::ops::count_5xx))
        .with_state(state)
}

/// Writes an audit record for any staff or money-moving action.
pub(crate) async fn audit(
    db: &sqlx::PgPool,
    actor_role: &str,
    actor_id: Option<uuid::Uuid>,
    action: &str,
    target: &str,
    data: serde_json::Value,
) -> Result<(), sqlx::Error> {
    sqlx::query("INSERT INTO audit_log (actor_role, actor_id, action, target, data) VALUES ($1,$2,$3,$4,$5)")
        .bind(actor_role)
        .bind(actor_id)
        .bind(action)
        .bind(target)
        .bind(data)
        .execute(db)
        .await
        .map(|_| ())
}
