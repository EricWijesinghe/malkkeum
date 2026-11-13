//! Backend HTTP API. `main.rs` calls [`serve`]; integration tests build the router from these modules.
//! New top-level modules are declared here (not in main.rs).

pub mod acquisition;
pub mod address;
pub mod ai;
pub mod analytics;
pub mod app_links;
pub mod auth;
pub mod backup;
pub mod client_errors;
pub mod config;
pub mod contract;
pub mod crypto;
pub mod db;
pub mod demo;
pub mod error;
pub mod i18n;
pub mod idempotency;
pub mod image_meta;
pub mod integrations;
pub mod keys_bundle;
pub mod jobs;
pub mod lifecycle;
pub mod lockout;
pub mod marketing;
pub mod metrics;
pub mod noshow;
pub mod openapi;
pub mod ops;
pub mod ops_alerts;
pub mod payout;
pub mod payout_sync;
pub mod points;
pub mod privacy;
pub mod quality;
pub mod retention;
pub mod safety;
pub mod sms_outbox;
pub mod providers;
pub mod ratelimit;
pub mod realtime;
pub mod realtime_ticket;
mod realtime_heartbeat;
pub mod reconciler;
pub mod retention;
pub mod routes;
pub mod safety;
pub mod seed;
pub mod seo;
pub mod settings_registry;
pub mod state;
pub mod telemetry;
pub mod totp;
pub mod util;

use crate::{config::Config, providers::Providers, realtime::Hub, state::AppState};
use sqlx::PgPool;
use std::{net::SocketAddr, sync::Arc, time::Duration};
use tokio::task::JoinHandle;

/// Shared application state over a pool and config. Used by `serve` and the integration tests.
pub fn build_state(db: PgPool, config: Config) -> Result<AppState, reqwest::Error> {
    Ok(AppState {
        providers: Arc::new(Providers::new(config.clone(), db.clone())?),
        hub: Hub::new(db.clone()),
        lockout: Arc::new(lockout::Lockout::new(db.clone())),
        db,
        config: Arc::new(config),
        ai_debounce: Default::default(),
        address_search: Default::default(),
        review_reports: Default::default(),
    })
}

/// Applies pending migrations. Rows written by a newer release are ignored, so the previous image
/// still starts after a rollback (migrations stay additive: expand, then contract a release later).
pub async fn migrate(db: &PgPool) -> Result<(), sqlx::migrate::MigrateError> {
    sqlx::migrate!("../../migrations").set_ignore_missing(true).run(db).await
}

/// Reads config, connects, migrates, seeds and serves until SIGTERM or Ctrl+C, then drains.
pub async fn serve() -> Result<(), Box<dyn std::error::Error>> {
    crate::ops::mark_started();
    let config = Config::from_env()?;
    // Migrations get their own single connection without the statement timeout (index builds can be slow).
    let migrate_db = db::connect(&config.database_url, &config.db.for_migrations()).await?;
    migrate(&migrate_db).await?;
    migrate_db.close().await;
    let db = db::connect(&config.database_url, &config.db).await?;
    seed::run(&db, &config).await?;
    let moved = safety::encrypt_legacy_codes(&db, &config.data_key).await?;
    if moved > 0 {
        tracing::warn!(moved, "entry codes moved into encrypted storage");
    }
    routes::setup::ensure_setup_code(&db, config.setup_code.as_deref()).await?;
    tokio::fs::create_dir_all(&config.upload_dir).await?;
    if config.dev_mode {
        tracing::warn!("DEV_MODE on: fake SMS, payments and push");
    }
    let bind = config.bind;
    let state = build_state(db, config)?;
    routes::setup::reload(&state).await?;
    let jobs = vec![
        spawn_settings_refresh(state.clone()),
        reconciler::spawn(state.clone()),
        ops_alerts::spawn(state.clone()),
        payout_sync::spawn(state.clone()),
        retention::spawn(state.clone()),
        noshow::spawn(state.clone()),
        points::spawn(state.clone()),
        marketing::spawn(state.clone()),
        quality::spawn(state.clone()),
        routes::waitlist::spawn(state.clone()),
        routes::subscription_engine::spawn(state.clone()),
        realtime::spawn_outbox(state.clone()),
        state.hub.spawn_listener(),
    ];
    let listener = tokio::net::TcpListener::bind(bind).await?;
    tracing::info!(%bind, "listening");
    let hub = state.hub.clone();
    // ConnectInfo gives the rate limiter the peer address.
    let app = routes::router(state).into_make_service_with_connect_info::<SocketAddr>();
    axum::serve(listener, app)
        .with_graceful_shutdown(async move {
            lifecycle::os_signal().await;
            hub.drain();
        })
        .await?;
    // Requests have finished; background jobs stop after their current pass.
    lifecycle::join_jobs(jobs).await;
    tracing::info!("stopped");
    Ok(())
}

/// Other replicas pick up keys saved in the setup wizard within this period.
const SETTINGS_REFRESH: Duration = Duration::from_secs(60);

fn spawn_settings_refresh(state: AppState) -> JoinHandle<()> {
    let mut stop = state.hub.drain_signal();
    tokio::spawn(async move {
        let mut tick = tokio::time::interval(SETTINGS_REFRESH);
        tick.tick().await;
        while lifecycle::next_tick(&mut tick, &mut stop).await {
            let ok = routes::setup::reload(&state)
                .await
                .inspect_err(|e| tracing::warn!(error = %e, "settings refresh failed"))
                .is_ok();
            metrics::job_pass("settings_refresh", ok);
        }
    })
}
