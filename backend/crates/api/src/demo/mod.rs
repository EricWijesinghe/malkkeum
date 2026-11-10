//! Sample data for demos and training: `api demo load [--force]` fills the app's tables with a coherent
//! Korean dataset, `api demo clear` removes exactly what load wrote.
//!
//! Safety rules (keep them when extending):
//! - Every row load writes is listed in `demo_rows` (migration 0011); clear deletes only listed rows.
//! - Demo people use reserved phone numbers (010-0000-*, 010-0001-*, 010-0002-*), `.invalid` emails,
//!   `demo_` provider ids and passwords nobody knows. Load never calls SMS, push or payment providers.
//! - Load refuses when real bookings or payments exist, unless `--force`.
//! - Demo staff are deleted by clear, so no demo login outlives it.
//!
//! NEW TABLES: when a migration adds a table that load writes, register its rows with `Ctx::reg`
//! and add it to `CLEAR_ORDER` (children before parents). Tables load never writes need nothing.

mod bookings;
mod people;
mod social;

use crate::config::Config;
use chrono::{DateTime, Duration, FixedOffset, Utc};
use rand::{RngCore, SeedableRng, rngs::StdRng, seq::SliceRandom, Rng};
use sqlx::{PgPool, Postgres, Transaction};
use std::{collections::BTreeMap, fmt, path::PathBuf};
use uuid::Uuid;

/// Fixed seed: the same run always produces the same names, amounts and choices.
const DEMO_SEED: u64 = 0x004D_414C_4B45_554D;
/// Advisory lock so two loads or a load and a clear never interleave.
const DEMO_LOCK: i64 = 0x6D61_6C6B;
/// Placeholder photo: one 1x1 PNG, named with a fixed 32-hex stem so `is_own_upload` accepts it.
const PLACEHOLDER_FILE: &str = "de30de30de30de30de30de30de30de30.png";
const PLACEHOLDER_PNG: &str = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==";
const KST_OFFSET_SECS: i32 = 9 * 3600;

/// Every table load can write, with its primary-key column, children before parents.
/// Clear walks this list; a registry entry for a table missing here aborts the clear.
const CLEAR_ORDER: &[(&str, &str)] = &[
    ("chat_messages", "id"),
    ("notifications", "id"),
    ("push_tokens", "token"),
    ("audit_log", "id"),
    ("uploads", "id"),
    ("refresh_tokens", "token_hash"),
    ("otp_codes", "id"),
    ("user_identities", "id"),
    ("reviews", "booking_id"),
    ("completion_reports", "booking_id"),
    ("settlements", "id"),
    ("quotes", "id"),
    ("payments", "id"),
    ("checkouts", "id"),
    ("chat_threads", "id"),
    ("bookings", "id"),
    ("coupons", "id"),
    ("payment_methods", "id"),
    ("addresses", "id"),
    ("partner_prefs", "pro_id"),
    ("payout_accounts", "pro_id"),
    ("team_members", "id"),
    ("pros", "id"),
    ("users", "id"),
    ("staff", "id"),
    ("content_items", "id"),
];

#[derive(Debug)]
pub enum DemoError {
    AlreadyLoaded,
    RealData { bookings: i64, payments: i64 },
    Db(sqlx::Error),
    Io(std::io::Error),
    Data(String),
}

impl fmt::Display for DemoError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::AlreadyLoaded => write!(f, "demo data is already loaded; run `demo clear` first"),
            Self::RealData { bookings, payments } => write!(
                f,
                "database has real data ({bookings} bookings, {payments} payments); demo load refused (use --force to add anyway)"
            ),
            Self::Db(e) => write!(f, "database: {e}"),
            Self::Io(e) => write!(f, "upload dir: {e}"),
            Self::Data(m) => write!(f, "{m}"),
        }
    }
}

impl From<sqlx::Error> for DemoError {
    fn from(e: sqlx::Error) -> Self {
        Self::Db(e)
    }
}

impl From<std::io::Error> for DemoError {
    fn from(e: std::io::Error) -> Self {
        Self::Io(e)
    }
}

/// Rows written (load) or removed (clear), per table, in table-name order.
pub type Report = Vec<(String, u64)>;

/// Working state for one load: the open transaction, seeded RNG and the clock.
pub(crate) struct Ctx<'t> {
    pub tx: Transaction<'t, Postgres>,
    pub rng: StdRng,
    pub now: DateTime<Utc>,
    pub kst: FixedOffset,
    pub public_base: String,
    pub data_key: [u8; 32],
    pub counts: BTreeMap<&'static str, u64>,
}

impl Ctx<'_> {
    pub fn id(&mut self) -> Uuid {
        Uuid::from_u64_pair(self.rng.next_u64(), self.rng.next_u64())
    }

    /// Random lowercase hex string of `bytes` bytes (2 characters each).
    pub fn hex(&mut self, bytes: usize) -> String {
        (0..bytes).map(|_| format!("{:02x}", self.rng.next_u32() as u8)).collect()
    }

    pub fn pick<'a, T>(&mut self, items: &'a [T]) -> &'a T {
        items.choose(&mut self.rng).expect("pick from a non-empty list")
    }

    pub fn range(&mut self, lo: i64, hi: i64) -> i64 {
        self.rng.gen_range(lo..=hi)
    }

    pub fn chance(&mut self, p: f64) -> bool {
        self.rng.gen_bool(p)
    }

    /// `now` minus a random number of days in `lo..=hi`, at a random KST-independent hour.
    pub fn ago_days(&mut self, lo: i64, hi: i64) -> DateTime<Utc> {
        let days = self.range(lo, hi);
        let hours = self.range(0, 23);
        self.now - Duration::days(days) - Duration::hours(hours)
    }

    /// Records one row written by load, so clear can find it again.
    pub async fn reg(&mut self, tbl: &'static str, key: impl ToString) -> Result<(), DemoError> {
        sqlx::query("INSERT INTO demo_rows (tbl, row_key) VALUES ($1, $2)")
            .bind(tbl)
            .bind(key.to_string())
            .execute(&mut *self.tx)
            .await?;
        *self.counts.entry(tbl).or_default() += 1;
        Ok(())
    }
}

async fn lock(tx: &mut Transaction<'_, Postgres>) -> Result<(), sqlx::Error> {
    sqlx::query("SELECT pg_advisory_xact_lock($1)").bind(DEMO_LOCK).execute(&mut **tx).await?;
    Ok(())
}

/// Writes the demo dataset in one transaction. Refuses to run over real bookings or payments
/// unless `force` is set, and never twice.
pub async fn load(db: &PgPool, config: &Config, force: bool) -> Result<Report, DemoError> {
    let mut tx = db.begin().await?;
    lock(&mut tx).await?;
    let loaded: bool = sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM demo_rows)").fetch_one(&mut *tx).await?;
    if loaded {
        return Err(DemoError::AlreadyLoaded);
    }
    let (bookings, payments): (i64, i64) = sqlx::query_as("SELECT (SELECT count(*) FROM bookings), (SELECT count(*) FROM payments)")
        .fetch_one(&mut *tx)
        .await?;
    if (bookings > 0 || payments > 0) && !force {
        return Err(DemoError::RealData { bookings, payments });
    }
    let kst = FixedOffset::east_opt(KST_OFFSET_SECS).expect("KST offset");
    let mut c = Ctx {
        tx,
        rng: StdRng::seed_from_u64(DEMO_SEED),
        now: Utc::now(),
        kst,
        public_base: config.public_base_url.clone(),
        data_key: config.data_key,
        counts: BTreeMap::new(),
    };
    let mut world = people::run(&mut c).await?;
    let booked = bookings::run(&mut c, &mut world).await?;
    social::run(&mut c, &world, &booked).await?;
    // Written before commit: a failed commit leaves a file that clear removes.
    tokio::fs::create_dir_all(&config.upload_dir).await?;
    tokio::fs::write(placeholder_path(config), placeholder_bytes()).await?;
    let report = c.counts.iter().map(|(t, n)| ((*t).to_string(), *n)).collect();
    c.tx.commit().await?;
    Ok(report)
}

/// Deletes every registered demo row (children first), then the registry, then the placeholder file.
pub async fn clear(db: &PgPool, config: &Config) -> Result<Report, DemoError> {
    let mut tx = db.begin().await?;
    lock(&mut tx).await?;
    let known: Vec<String> = sqlx::query_scalar("SELECT DISTINCT tbl FROM demo_rows").fetch_all(&mut *tx).await?;
    if let Some(unknown) = known.iter().find(|t| !CLEAR_ORDER.iter().any(|(name, _)| name == t)) {
        return Err(DemoError::Data(format!("demo_rows lists table `{unknown}` that clear does not know; add it to CLEAR_ORDER")));
    }
    let mut report = Vec::new();
    for (tbl, pk) in CLEAR_ORDER {
        // Table and column names come from the constant list above, never from input.
        let sql = format!("DELETE FROM {tbl} WHERE {pk}::text IN (SELECT row_key FROM demo_rows WHERE tbl = $1)");
        let n = sqlx::query(&sql).bind(*tbl).execute(&mut *tx).await?.rows_affected();
        if n > 0 {
            report.push(((*tbl).to_string(), n));
        }
    }
    sqlx::query("DELETE FROM demo_rows").execute(&mut *tx).await?;
    tx.commit().await?;
    match tokio::fs::remove_file(placeholder_path(config)).await {
        Ok(()) => {}
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => {}
        Err(e) => return Err(e.into()),
    }
    Ok(report)
}

fn placeholder_path(config: &Config) -> PathBuf {
    config.upload_dir.join(PLACEHOLDER_FILE)
}

fn placeholder_bytes() -> Vec<u8> {
    use base64::Engine;
    base64::engine::general_purpose::STANDARD.decode(PLACEHOLDER_PNG).expect("placeholder png is valid base64")
}

/// Shared by people, bookings and social: the demo placeholder photo URL.
pub(crate) fn photo_url(public_base: &str) -> String {
    format!("{public_base}/files/{PLACEHOLDER_FILE}")
}

/// `api demo load [--force]` / `api demo clear`, run inside the api container or locally.
/// Returns the process exit code.
pub async fn cli(args: &[String]) -> i32 {
    let config = match Config::from_env() {
        Ok(c) => c,
        Err(e) => return fail(&format!("config: {e}")),
    };
    let db = match sqlx::postgres::PgPoolOptions::new().max_connections(2).connect(&config.database_url).await {
        Ok(db) => db,
        Err(e) => return fail(&format!("database: {e}")),
    };
    if let Err(e) = sqlx::migrate!("../../migrations").run(&db).await {
        return fail(&format!("migrate: {e}"));
    }
    let result = match args.first().map(String::as_str) {
        Some("load") => load(&db, &config, args.iter().any(|a| a == "--force")).await,
        Some("clear") => clear(&db, &config).await,
        _ => return fail("usage: api demo load [--force] | api demo clear"),
    };
    match result {
        Ok(report) => {
            let total: u64 = report.iter().map(|(_, n)| n).sum();
            for (table, n) in &report {
                println!("{table}: {n}");
            }
            println!("ok: {total} rows in {} tables", report.len());
            0
        }
        Err(e) => fail(&e.to_string()),
    }
}

fn fail(msg: &str) -> i32 {
    eprintln!("error: {msg}");
    1
}
