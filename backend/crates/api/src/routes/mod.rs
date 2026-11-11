pub(crate) mod address;
mod admin;
mod admin_content;
mod auth;
mod booking_core;
pub(crate) mod bookings;
pub mod cases;
mod catalog;
pub(crate) mod chat;
mod cash_receipts;
mod checkout_policy;
mod tax_invoices;
pub(crate) mod config;
pub(crate) mod checkouts;
mod finance;
pub(crate) mod growth;
pub(crate) mod me;
mod member;
mod ops;
mod partner;
pub(crate) mod partner_jobs;
pub mod site;
pub(crate) mod payments;
pub(crate) mod payouts;
pub mod setup;
pub mod uploads;
mod staff_mfa;
mod staff_password;
mod webhooks;

use crate::{contract, lifecycle, metrics, realtime, state::AppState, telemetry};
use axum::{
    Router,
    extract::DefaultBodyLimit,
    http::{HeaderName, HeaderValue, Method, header},
    routing::get,
};
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
        .allow_headers([header::AUTHORIZATION, header::CONTENT_TYPE, HeaderName::from_static("idempotency-key")])
        .expose_headers([contract::NEXT_CURSOR]);
    let gate = std::sync::Arc::new(crate::ratelimit::Gate::new(&state.config, std::time::Instant::now()));

    let api = Router::new()
        .merge(auth::routes().layer(DefaultBodyLimit::max(contract::AUTH_BODY_LIMIT)))
        .merge(staff_mfa::routes())
        .merge(staff_password::public_routes())
        .merge(me::routes())
        .merge(catalog::routes())
        .merge(bookings::routes())
        .merge(cases::customer_routes())
        .merge(bookings::public_routes())
        .merge(chat::routes())
        .merge(uploads::routes().layer(DefaultBodyLimit::max(contract::UPLOAD_BODY_LIMIT)))
        .merge(checkouts::routes())
        .merge(cash_receipts::routes())
        .merge(tax_invoices::routes())
        .merge(growth::public_routes())
        .merge(growth::customer_routes())
        .merge(payments::routes())
        .merge(webhooks::routes())
        .merge(setup::public_routes())
        .merge(address::public_routes())
        .merge(config::routes())
        .merge(crate::client_errors::routes())
        .nest(
            "/admin",
            admin::routes()
                .merge(staff_password::admin_routes())
                .merge(admin_content::routes())
                .merge(growth::admin_routes())
                .merge(payments::admin_routes())
                .merge(checkouts::admin_routes())
                .merge(setup::admin_routes())
                .merge(config::admin_routes())
                .merge(crate::client_errors::admin_routes())
                .merge(chat::admin_routes())
                .merge(finance::routes())
                .merge(cash_receipts::admin_routes())
                .merge(tax_invoices::admin_routes())
                .merge(ops::admin_routes())
                .merge(cases::admin_routes())
                .merge(site::admin_routes()),
        )
        .nest("/partner", partner::routes().merge(partner_jobs::routes()).merge(finance::partner_routes()).merge(cases::partner_routes()).merge(site::partner_routes()))
        .nest("/member", member::routes())
        .route("/ws", get(realtime::ws_handler))
        .route("/openapi.json", get(crate::openapi::spec))
        .layer(DefaultBodyLimit::max(contract::JSON_BODY_LIMIT));

    Router::new()
        // Liveness never touches the DB; readiness does. Neither is proxied publicly (see deploy/Caddyfile).
        .route("/health", get(lifecycle::live))
        .route("/ready", get(lifecycle::ready))
        .route("/metrics", get(metrics::handler))
        .merge(crate::app_links::routes())
        .nest("/v1", api)
        .layer(axum::middleware::from_fn_with_state(state.clone(), config::enforce))
        .layer(RequestBodyLimitLayer::new(BODY_LIMIT_BYTES))
        .layer(TimeoutLayer::with_status_code(axum::http::StatusCode::REQUEST_TIMEOUT, REQUEST_TIMEOUT))
        .layer(cors)
        .layer(axum::middleware::from_fn_with_state(state.clone(), uploads::sign_json))
        .layer(axum::middleware::from_fn_with_state(gate, crate::ratelimit::limit))
        // Span records the path only: query strings can carry tokens (/v1/ws?token=...).
        .layer(TraceLayer::new_for_http().make_span_with(|req: &axum::http::Request<_>| {
            let request_id = req.extensions().get::<telemetry::RequestId>().map_or("", |r| r.0.as_str());
            tracing::info_span!("http", method = %req.method(), path = %req.uri().path(), request_id)
        }))
        .layer(axum::middleware::from_fn_with_state(state.clone(), crate::ops::count_5xx))
        .layer(axum::middleware::from_fn(metrics::track))
        // Idempotency replay reads the pool from an extension (route layers cannot take state).
        .layer(axum::Extension(state.db.clone()))
        .layer(axum::middleware::from_fn(contract::error_envelope))
        // Outermost: every request (and every error body) gets its id before anything else runs.
        .layer(axum::middleware::from_fn(telemetry::request_id))
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
