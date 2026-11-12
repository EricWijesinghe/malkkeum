//! Postgres connection pool with server-side guards on every connection: a statement timeout, an
//! idle-in-transaction timeout, and a slow-statement log. Sizes come from `DB_*` env vars (see `config.rs`).

use log::LevelFilter;
use sqlx::{
    ConnectOptions, PgPool,
    postgres::{PgConnectOptions, PgPoolOptions},
};
use std::{str::FromStr, time::Duration};

const ACQUIRE_TIMEOUT: Duration = Duration::from_secs(5);

/// Pool and timeout settings. Defaults suit one API replica on a small VPS.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct DbSettings {
    pub max_connections: u32,
    /// Server-side cap per statement. 0 disables it (migrations need it: index builds can be long).
    pub statement_timeout_ms: u64,
    /// A transaction left open this long is killed, so a stuck request cannot pin locks forever.
    pub idle_tx_timeout_ms: u64,
    /// Statements slower than this are logged at WARN by the `sqlx::query` target.
    pub slow_query_ms: u64,
}

impl Default for DbSettings {
    fn default() -> Self {
        Self { max_connections: 10, statement_timeout_ms: 30_000, idle_tx_timeout_ms: 60_000, slow_query_ms: 500 }
    }
}

impl DbSettings {
    /// Same connection, no statement timeout, one connection: for running migrations.
    pub fn for_migrations(&self) -> Self {
        Self { max_connections: 1, statement_timeout_ms: 0, ..self.clone() }
    }
}

/// Opens a pool. The settings travel as startup parameters, so every connection the pool creates gets them.
pub async fn connect(url: &str, settings: &DbSettings) -> Result<PgPool, sqlx::Error> {
    let options = PgConnectOptions::from_str(url)?
        .options([
            ("statement_timeout", settings.statement_timeout_ms.to_string()),
            ("idle_in_transaction_session_timeout", settings.idle_tx_timeout_ms.to_string()),
        ])
        .log_slow_statements(LevelFilter::Warn, Duration::from_millis(settings.slow_query_ms));
    PgPoolOptions::new()
        .max_connections(settings.max_connections)
        .acquire_timeout(ACQUIRE_TIMEOUT)
        .connect_with(options)
        .await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn migrations_run_without_statement_timeout_on_one_connection() {
        let m = DbSettings::default().for_migrations();
        assert_eq!((m.max_connections, m.statement_timeout_ms), (1, 0));
        assert_eq!(m.idle_tx_timeout_ms, DbSettings::default().idle_tx_timeout_ms);
    }

    #[tokio::test]
    async fn pool_connections_carry_the_configured_timeouts() {
        let Ok(url) = std::env::var("DATABASE_URL") else { return };
        let settings = DbSettings { max_connections: 2, statement_timeout_ms: 1234, idle_tx_timeout_ms: 5678, slow_query_ms: 1 };
        let pool = connect(&url, &settings).await.expect("connect");
        let (stmt, idle): (String, String) = sqlx::query_as(
            "SELECT current_setting('statement_timeout'), current_setting('idle_in_transaction_session_timeout')",
        )
        .fetch_one(&pool)
        .await
        .expect("settings readable");
        assert_eq!((stmt.as_str(), idle.as_str()), ("1234ms", "5678ms"));
    }
}
