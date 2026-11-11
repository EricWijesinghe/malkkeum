//! Backend HTTP API. `main.rs` calls [`serve`]; integration tests build the router from these modules.
//! New top-level modules are declared here (not in main.rs).

pub mod address;
pub mod app_links;
pub mod ai;
pub mod auth;
pub mod backup;
pub mod client_errors;
pub mod config;
pub mod contract;
pub mod crypto;
pub mod demo;
pub mod error;
pub mod i18n;
pub mod idempotency;
pub mod integrations;
pub mod lifecycle;
pub mod metrics;
pub mod openapi;
pub mod noshow;
pub mod ops;
pub mod ops_alerts;
pub mod payout;
pub mod payout_sync;
pub mod privacy;
pub mod retention;
pub mod safety;
pub mod providers;
pub mod ratelimit;
pub mod realtime;
pub mod reconciler;
pub mod routes;
pub mod seed;
pub mod seo;
pub mod state;
pub mod telemetry;
pub mod totp;
pub mod util;

use crate::{config::Config, providers::Providers, realtime::Hub, state::AppState};
use sqlx::{PgPool, postgres::PgPoolOptions};
use std::{net::SocketAddr, sync::Arc, time::Duration};
use tokio::task::JoinHandle;

const DB_MAX_CONNECTIONS: u32 = 20;
const DB_ACQUIRE_TIMEOUT: Duration = Duration::from_secs(5);

/// Shared application state over a pool and config. Used by `serve` and the integration tests.
pub fn build_state(db: PgPool, config: Config) -> Result<AppState, reqwest::Error> {
    Ok(AppState {
        providers: Arc::new(Providers::new(config.clone(), db.clone())?),
        hub: Hub::new(db.clone()),
        db,
        config: Arc::new(config),
        ai_debounce: Default::default(),
        address_search: Default::default(),
        review_reports: Default::default(),
    })
}

/// Reads config, connects, migrates, seeds and serves until SIGTERM or Ctrl+C, then drains.
pub async fn serve() -> Result<(), Box<dyn std::error::Error>> {
    crate::ops::mark_started();
    let config = Config::from_env()?;
    let db = PgPoolOptions::new()
        .max_connections(DB_MAX_CONNECTIONS)
        .acquire_timeout(DB_ACQUIRE_TIMEOUT)
        .connect(&config.database_url)
        .await?;
    sqlx::migrate!("../../migrations").run(&db).await?;
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
            let ok = routes::setup::reload(&state).await.inspect_err(|e| tracing::warn!(error = %e, "settings refresh failed")).is_ok();
            metrics::job_pass("settings_refresh", ok);
        }
    })
}
