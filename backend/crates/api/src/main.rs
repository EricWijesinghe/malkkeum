mod auth;
mod config;
mod crypto;
mod error;
mod providers;
mod realtime;
mod routes;
mod seed;
mod state;
mod util;

use crate::{config::Config, providers::Providers, realtime::Hub, state::AppState};
use sqlx::postgres::PgPoolOptions;
use std::{sync::Arc, time::Duration};
use tracing_subscriber::EnvFilter;

const DB_MAX_CONNECTIONS: u32 = 20;
const DB_ACQUIRE_TIMEOUT: Duration = Duration::from_secs(5);

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| "info,sqlx=warn".into()))
        .init();
    if let Err(e) = run().await {
        tracing::error!(error = %e, "fatal");
        std::process::exit(1);
    }
}

async fn run() -> Result<(), Box<dyn std::error::Error>> {
    let config = Config::from_env()?;
    let db = PgPoolOptions::new()
        .max_connections(DB_MAX_CONNECTIONS)
        .acquire_timeout(DB_ACQUIRE_TIMEOUT)
        .connect(&config.database_url)
        .await?;
    sqlx::migrate!("../../migrations").run(&db).await?;
    seed::run(&db, &config).await?;
    tokio::fs::create_dir_all(&config.upload_dir).await?;
    if config.dev_mode {
        tracing::warn!("DEV_MODE on: fake SMS, payments and push");
    }
    let bind = config.bind;
    let state = AppState {
        db,
        providers: Arc::new(Providers::new(config.dev_mode)),
        config: Arc::new(config),
        hub: Hub::default(),
    };
    let listener = tokio::net::TcpListener::bind(bind).await?;
    tracing::info!(%bind, "listening");
    axum::serve(listener, routes::router(state)).with_graceful_shutdown(shutdown()).await?;
    Ok(())
}

async fn shutdown() {
    let _ = tokio::signal::ctrl_c().await;
    tracing::info!("shutting down");
}
