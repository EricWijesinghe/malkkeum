use crate::{config::Config, providers::Providers, realtime::Hub};
use sqlx::PgPool;
use std::sync::Arc;

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
    pub config: Arc<Config>,
    pub providers: Arc<Providers>,
    pub hub: Hub,
    pub ai_debounce: crate::ai::Debounce,
    pub address_search: Arc<crate::routes::address::SearchGate>,
}
