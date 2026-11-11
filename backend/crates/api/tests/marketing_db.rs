//! Marketing dispatcher, weekly frequency cap, quiet-hour deferral, nudges, and the analytics funnel and
//! cohort SQL, against real Postgres. Needs DATABASE_URL (sqlx::test). Time rules run at fixed instants
//! through `dispatch_at` / `run_nudges_at`, so the tests do not depend on the wall clock's hour.

mod common;

use api::{auth, marketing, privacy::CONSENT_VERSION, state::AppState};
use axum::http::StatusCode;
use chrono::{DateTime, Duration, TimeZone, Utc};
use common::{SECRET, app, book, call, customer, login, seed_catalog};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

/// 2026-11-11 12:00 KST: inside the sending window.
fn daytime() -> DateTime<Utc> {
    Utc.with_ymd_and_hms(2026, 11, 11, 3, 0, 0).single().expect("valid instant")
}

/// 2026-11-11 23:30 KST: inside quiet hours (21:00-08:00).
fn night() -> DateTime<Utc> {
    Utc.with_ymd_and_hms(2026, 11, 11, 14, 30, 0).single().expect("valid instant")
}

fn state(pool: &PgPool) -> AppState {
    api::build_state(pool.clone(), common::test_config()).expect("app state")
}

fn staff_token() -> String {
    auth::issue_access(SECRET, Uuid::now_v7(), auth::Role::StaffAdmin).expect("staff token")
}

async fn grant_marketing(db: &PgPool, user: Uuid, granted: bool) {
    sqlx::query("INSERT INTO user_consents (user_id, kind, version, granted) VALUES ($1, 'marketing', $2, $3)")
        .bind(user)
        .bind(CONSENT_VERSION)
        .bind(granted)
        .execute(db)
        .await
        .expect("consent row");
}

async fn scheduled_push(db: &PgPool, at: DateTime<Utc>) -> Uuid {
    sqlx::query_scalar(
        "INSERT INTO campaigns (name, channel, title, body, status, scheduled_at) VALUES ('test', 'push', '신규 혜택', '이번 주 할인 안내', 'scheduled', $1) RETURNING id",
    )
    .bind(at)
    .fetch_one(db)
    .await
    .expect("campaign")
}

async fn campaign_status(db: &PgPool, id: Uuid) -> String {
    sqlx::query_scalar("SELECT status FROM campaigns WHERE id = $1").bind(id).fetch_one(db).await.expect("status")
}

async fn send_status(db: &PgPool, user: Uuid) -> Option<String> {
    sqlx::query_scalar("SELECT status FROM marketing_sends WHERE user_id = $1 AND campaign_id IS NOT NULL")
        .bind(user)
        .fetch_optional(db)
        .await
        .expect("send row")
}

async fn seed_sent(db: &PgPool, user: Uuid, n: usize) {
    for i in 0..n {
        sqlx::query("INSERT INTO marketing_sends (dedupe_key, user_id, channel, status) VALUES ($1, $2, 'push', 'sent')")
            .bind(format!("seed:{user}:{i}"))
            .bind(user)
            .execute(db)
            .await
            .expect("seed send");
    }
}

#[sqlx::test(migrations = "../../migrations")]
async fn campaign_reaches_consented_customers_and_logs_the_rest(pool: PgPool) {
    let app = app(pool.clone());
    let yes = customer(&app, &pool, "010-5400-0001").await;
    let no = customer(&app, &pool, "010-5400-0002").await;
    grant_marketing(&pool, yes.user, true).await;
    grant_marketing(&pool, no.user, false).await;
    let campaign = scheduled_push(&pool, Utc::now() - Duration::minutes(1)).await;

    assert_eq!(marketing::dispatch_at(&state(&pool), daytime()).await.expect("dispatch"), 1);

    assert_eq!(campaign_status(&pool, campaign).await, "sent");
    assert_eq!(send_status(&pool, yes.user).await.as_deref(), Some("sent"));
    assert_eq!(send_status(&pool, no.user).await.as_deref(), Some("skipped_consent"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn quiet_hours_defer_the_campaign_to_eight_kst(pool: PgPool) {
    let app = app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0003").await;
    grant_marketing(&pool, c.user, true).await;
    let campaign = scheduled_push(&pool, Utc::now() - Duration::minutes(1)).await;

    marketing::dispatch_at(&state(&pool), night()).await.expect("dispatch");

    assert_eq!(campaign_status(&pool, campaign).await, "scheduled", "reopened, not sent");
    let resume: Option<DateTime<Utc>> = sqlx::query_scalar("SELECT scheduled_at FROM campaigns WHERE id = $1").bind(campaign).fetch_one(&pool).await.expect("resume");
    // 2026-11-12 08:00 KST is 2026-11-11 23:00 UTC.
    assert_eq!(resume, Some(Utc.with_ymd_and_hms(2026, 11, 11, 23, 0, 0).single().expect("valid instant")));
    assert_eq!(send_status(&pool, c.user).await, None, "nothing recorded during quiet hours");
}

#[sqlx::test(migrations = "../../migrations")]
async fn weekly_cap_skips_capped_customers_without_recording_them(pool: PgPool) {
    let app = app(pool.clone());
    let capped = customer(&app, &pool, "010-5400-0004").await;
    let open = customer(&app, &pool, "010-5400-0005").await;
    for user in [capped.user, open.user] {
        grant_marketing(&pool, user, true).await;
    }
    seed_sent(&pool, capped.user, marketing::FREQ_CAP_PER_WEEK as usize).await;
    seed_sent(&pool, open.user, marketing::FREQ_CAP_PER_WEEK as usize - 1).await;
    scheduled_push(&pool, Utc::now() - Duration::minutes(1)).await;

    marketing::dispatch_at(&state(&pool), daytime()).await.expect("dispatch");

    assert_eq!(send_status(&pool, capped.user).await, None, "capped: no row, so a later pass can still reach them");
    assert_eq!(send_status(&pool, open.user).await.as_deref(), Some("sent"), "one send left under the cap");
}

#[sqlx::test(migrations = "../../migrations")]
async fn rebook_nudge_is_held_during_quiet_hours(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0006").await;
    grant_marketing(&pool, c.user, true).await;
    let (booking, _) = book(&app, &c, 1, None).await;
    sqlx::query("UPDATE bookings SET status = 3, visit_date = (now() AT TIME ZONE 'Asia/Seoul')::date - 30 WHERE id = $1")
        .bind(booking)
        .execute(&pool)
        .await
        .expect("completed 30 days ago");
    let key = format!("nudge:rebook:{booking}");

    assert_eq!(marketing::run_nudges_at(&state(&pool), night()).await.expect("nudges"), 0);
    let held: Option<String> = sqlx::query_scalar("SELECT status FROM marketing_sends WHERE dedupe_key = $1").bind(&key).fetch_optional(&pool).await.expect("row");
    assert_eq!(held, None);

    assert_eq!(marketing::run_nudges_at(&state(&pool), daytime()).await.expect("nudges"), 1);
    let sent: Option<String> = sqlx::query_scalar("SELECT status FROM marketing_sends WHERE dedupe_key = $1").bind(&key).fetch_optional(&pool).await.expect("row");
    assert_eq!(sent.as_deref(), Some("sent"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn funnel_and_cohorts_count_installs_signups_and_bookings(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = app(pool.clone());
    let buyer = customer(&app, &pool, "010-5400-0007").await;
    let _browser = login(&app, "010-5400-0008", "customer").await;
    let (opened, quoted) = (Uuid::now_v7(), Uuid::now_v7());
    let (st, _) = call(&app, "POST", "/v1/events", None, Some(json!({ "anon_id": opened, "events": [{ "name": "app_open", "platform": "android" }] }))).await;
    assert_eq!(st, StatusCode::OK);
    let (st, _) = call(&app, "POST", "/v1/events", None, Some(json!({ "anon_id": quoted, "events": [{ "name": "quote_view", "screen": "quote" }] }))).await;
    assert_eq!(st, StatusCode::OK);
    book(&app, &buyer, 1, None).await;
    let token = staff_token();

    let (st, funnel) = call(&app, "GET", "/v1/admin/analytics/funnel?days=30", Some(&token), None).await;
    assert_eq!(st, StatusCode::OK, "{funnel}");
    assert_eq!(funnel["installs"], 1, "only installs that sent app_open count");
    assert_eq!(funnel["signed_up"], 2);
    assert_eq!(funnel["quoted"], 1);
    assert_eq!(funnel["booked"], 1);
    assert_eq!(funnel["paid"], 1);
    assert_eq!(funnel["repeat_buyers"], 0);

    let (st, cohorts) = call(&app, "GET", "/v1/admin/analytics/cohorts?weeks=8", Some(&token), None).await;
    assert_eq!(st, StatusCode::OK, "{cohorts}");
    let rows = cohorts.as_array().expect("cohort rows");
    let size: i64 = rows.iter().map(|r: &Value| r["size"].as_i64().unwrap_or_default()).sum();
    let w1: i64 = rows.iter().map(|r: &Value| r["w1"].as_i64().unwrap_or_default()).sum();
    assert_eq!(size, 2, "both signups land in a cohort");
    assert_eq!(w1, 0, "no booking falls in week 1 after signup");
}
