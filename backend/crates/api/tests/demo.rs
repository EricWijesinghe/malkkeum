//! Demo sample data over a migrated Postgres (sqlx::test makes one database per test).
//! Load fills every table it writes, clear returns each table to its pre-load count, real rows survive
//! both, and load refuses over real bookings unless forced.

mod common;

use api::demo::{self, DemoError};
use common::{app, book, customer, seed_catalog, test_config};
use sqlx::PgPool;

/// Every table `demo load` writes (see `CLEAR_ORDER` in demo/mod.rs).
const TOUCHED: &[&str] = &[
    "users", "user_identities", "addresses", "payment_methods", "coupons", "pros", "team_members", "partner_prefs",
    "payout_accounts", "staff", "refresh_tokens", "otp_codes", "bookings", "payments", "checkouts", "quotes",
    "completion_reports", "settlements", "reviews", "chat_threads", "chat_messages", "notifications", "push_tokens",
    "audit_log", "content_items", "uploads",
];

/// Per-test upload dir, so parallel tests never delete each other's placeholder file.
fn config() -> api::config::Config {
    let mut config = test_config();
    config.upload_dir = std::env::temp_dir().join(format!("demo-test-{}", rand::random::<u64>()));
    config
}

async fn counts(db: &PgPool) -> Vec<(&'static str, i64)> {
    let mut out = Vec::with_capacity(TOUCHED.len());
    for t in TOUCHED {
        let n: i64 = sqlx::query_scalar(&format!("SELECT count(*) FROM {t}")).fetch_one(db).await.expect("count");
        out.push((*t, n));
    }
    out
}

async fn demo_registry_rows(db: &PgPool) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM demo_rows").fetch_one(db).await.expect("registry count")
}

#[sqlx::test(migrations = "../../migrations")]
async fn load_fills_every_touched_table_and_clear_restores_counts(pool: PgPool) {
    seed_catalog(&pool).await;
    let config = config();
    let before = counts(&pool).await;

    let report = demo::load(&pool, &config, false).await.expect("demo load");
    assert!(!report.is_empty());
    for (table, n) in counts(&pool).await {
        assert!(n > 0, "{table} is empty after demo load");
    }
    assert!(config.upload_dir.join("de30de30de30de30de30de30de30de30.png").exists(), "placeholder photo written");

    // A second load is refused while demo data is in place.
    assert!(matches!(demo::load(&pool, &config, true).await, Err(DemoError::AlreadyLoaded)));

    let removed = demo::clear(&pool, &config).await.expect("demo clear");
    assert!(!removed.is_empty());
    assert_eq!(counts(&pool).await, before, "every touched table is back to its pre-load count");
    assert_eq!(demo_registry_rows(&pool).await, 0);
    assert!(!config.upload_dir.join("de30de30de30de30de30de30de30de30.png").exists(), "placeholder photo removed");
}

#[sqlx::test(migrations = "../../migrations")]
async fn load_refuses_over_real_bookings_unless_forced(pool: PgPool) {
    seed_catalog(&pool).await;
    let api = app(pool.clone());
    let c = customer(&api, &pool, "010-5000-0301").await;
    book(&api, &c, 10, None).await;
    let config = config();

    let err = demo::load(&pool, &config, false).await.expect_err("refused over a real booking");
    assert!(matches!(err, DemoError::RealData { bookings: 1, .. }), "{err}");
    assert_eq!(demo_registry_rows(&pool).await, 0, "nothing written when refused");
}

#[sqlx::test(migrations = "../../migrations")]
async fn real_rows_survive_load_and_clear(pool: PgPool) {
    seed_catalog(&pool).await;
    let api = app(pool.clone());
    // A real customer with an address and a card, but no booking: load is allowed over this.
    let c = customer(&api, &pool, "010-5000-0401").await;
    let config = config();
    let addresses_before: i64 = sqlx::query_scalar("SELECT count(*) FROM addresses WHERE user_id = $1").bind(c.user).fetch_one(&pool).await.expect("count");

    demo::load(&pool, &config, false).await.expect("demo load over real customer");
    demo::clear(&pool, &config).await.expect("demo clear");

    let still_there: i64 = sqlx::query_scalar("SELECT count(*) FROM users WHERE id = $1 AND name = ''").bind(c.user).fetch_one(&pool).await.expect("count");
    assert_eq!(still_there, 1, "real customer untouched");
    let addresses_after: i64 = sqlx::query_scalar("SELECT count(*) FROM addresses WHERE user_id = $1").bind(c.user).fetch_one(&pool).await.expect("count");
    assert_eq!(addresses_after, addresses_before);
}

async fn business(db: &PgPool) -> Option<serde_json::Value> {
    sqlx::query_scalar("SELECT value FROM settings WHERE key = 'business'").fetch_optional(db).await.expect("business")
}

#[sqlx::test(migrations = "../../migrations")]
async fn load_adds_a_fake_business_profile_and_clear_removes_only_that(pool: PgPool) {
    seed_catalog(&pool).await;
    let config = config();

    demo::load(&pool, &config, false).await.expect("demo load");
    let b = business(&pool).await.expect("demo profile written");
    assert_eq!(b["name"], "다해");
    assert_eq!(b["company"]["registration_no"], "000-00-00000", "fake registration number");
    assert!(b["company"]["hosting_provider"].as_str().is_some_and(|h| h.contains("예시")), "{b}");
    assert!(b["support_email"].as_str().is_some_and(|e| e.ends_with(".invalid")), "{b}");
    demo::clear(&pool, &config).await.expect("demo clear");
    assert!(business(&pool).await.is_none(), "untouched demo profile is removed");

    // A profile the owner saved is neither replaced by load nor removed by clear.
    sqlx::query("INSERT INTO settings (key, value) VALUES ('business', $1)")
        .bind(serde_json::json!({"name": "우리집청소"}))
        .execute(&pool)
        .await
        .expect("owner profile");
    demo::load(&pool, &config, false).await.expect("demo load");
    demo::clear(&pool, &config).await.expect("demo clear");
    assert_eq!(business(&pool).await.expect("owner profile kept")["name"], "우리집청소");
}

#[sqlx::test(migrations = "../../migrations")]
async fn demo_deposit_messages_carry_the_paid_amount(pool: PgPool) {
    seed_catalog(&pool).await;
    demo::load(&pool, &config(), false).await.expect("demo load");
    let amounts: Vec<Option<i64>> = sqlx::query_scalar(
        "SELECT (body->'params'->>'amount')::bigint FROM chat_messages WHERE kind = 'system' AND body->>'code' = 'deposit_paid'",
    )
    .fetch_all(&pool)
    .await
    .expect("deposit messages");
    assert!(!amounts.is_empty(), "the demo has paid quote deposits");
    // The app prints "예약금 {amount}원이 결제됐어요": a missing amount would read 0원.
    assert!(amounts.iter().all(|a| a.is_some_and(|n| n > 0)), "{amounts:?}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn demo_sign_in_customer_has_a_usable_coupon_and_home_content(pool: PgPool) {
    seed_catalog(&pool).await;
    demo::load(&pool, &config(), false).await.expect("demo load");
    // Checkout's coupon step needs one that is unused and has not expired.
    let usable: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM coupons k JOIN users u ON u.id = k.user_id
         WHERE u.phone = '01000000001' AND k.used_booking_id IS NULL AND k.service_code IS NULL
           AND k.issued_at <= now() AND k.expires_at > now() + interval '7 days'",
    )
    .fetch_one(&pool)
    .await
    .expect("usable coupons");
    assert!(usable >= 1, "the demo sign-in customer holds a valid coupon");
    // The home banner's art card and the schedule step's training link read these.
    let card: Option<String> = sqlx::query_scalar("SELECT body->'card'->'value'->>'ko' FROM content_items WHERE kind = 'banner' AND link = 'coupons' AND body ? 'card'")
        .fetch_optional(&pool)
        .await
        .expect("banner card")
        .flatten();
    assert_eq!(card.as_deref(), Some("15,000원"));
    let training: i64 = sqlx::query_scalar("SELECT count(*) FROM content_items WHERE kind = 'tip' AND slug = 'manager-training' AND active")
        .fetch_one(&pool)
        .await
        .expect("training tip");
    assert_eq!(training, 1);
}

async fn active_banners(db: &PgPool) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM content_items WHERE kind = 'banner' AND active").fetch_one(db).await.expect("banners")
}

#[sqlx::test(migrations = "../../migrations")]
async fn demo_hides_the_seed_welcome_banner_and_clear_brings_it_back(pool: PgPool) {
    seed_catalog(&pool).await;
    assert_eq!(active_banners(&pool).await, 1, "a real install has the seed welcome banner");
    let config = config();
    demo::load(&pool, &config, false).await.expect("demo load");
    let welcome: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM content_items WHERE kind = 'banner' AND active AND (link = 'coupons' OR body->>'link' = 'coupons')",
    )
    .fetch_one(&pool)
    .await
    .expect("welcome banners");
    assert_eq!(welcome, 1, "one welcome banner in the carousel with demo data");
    demo::clear(&pool, &config).await.expect("demo clear");
    assert_eq!(active_banners(&pool).await, 1, "clear shows the seed banner again");
    let flagged: i64 = sqlx::query_scalar("SELECT count(*) FROM content_items WHERE body ? 'demo_hidden'").fetch_one(&pool).await.expect("flag");
    assert_eq!(flagged, 0);
}
