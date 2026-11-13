//! Text messages (SMS, AlimTalk) through the notification outbox: the retry schedule, the dead-letter
//! state and its owner alert, the channel chosen at enqueue, and OTP codes that stay inline.

mod common;

use api::{
    build_state,
    config::{Config, SolapiConfig},
    integrations::Integrations,
    ops, ops_alerts,
    sms_outbox::{self, Message},
    state::AppState,
};
use axum::http::StatusCode;
use common::{call, test_config};
use serde_json::json;
use sqlx::PgPool;

/// Live mode without Solapi keys: a text fails at once, with no network call.
fn unconfigured(pool: &PgPool) -> AppState {
    build_state(pool.clone(), Config { dev_mode: false, ..test_config() }).expect("app state")
}

fn solapi(templates: &[(&str, &str)]) -> SolapiConfig {
    SolapiConfig {
        api_key: "key".into(),
        api_secret: "secret".into(),
        sender: "0212345678".into(),
        pf_id: Some("PF1".into()),
        templates: templates.iter().map(|(k, v)| (k.to_string(), v.to_string())).collect(),
    }
}

/// A plain SMS row, due now, as the queue holds it.
async fn insert_sms(pool: &PgPool, attempts: i32) -> i64 {
    sqlx::query_scalar(
        "INSERT INTO notification_outbox (kind, title, body, data, channel, phone, attempts, next_attempt_at)
         VALUES ('booking.status', '', 'hello', '{}', 'sms', '01012345678', $1, now()) RETURNING id",
    )
    .bind(attempts)
    .fetch_one(pool)
    .await
    .expect("row")
}

/// (attempts, last_error, dead)
async fn state_of(pool: &PgPool, id: i64) -> (i32, Option<String>, bool) {
    sqlx::query_as("SELECT attempts, last_error, dead_at IS NOT NULL FROM notification_outbox WHERE id = $1")
        .bind(id)
        .fetch_one(pool)
        .await
        .expect("row state")
}

/// Seconds from now until the row's next attempt.
async fn secs_until_next(pool: &PgPool, id: i64) -> f64 {
    sqlx::query_scalar("SELECT extract(epoch FROM next_attempt_at - now())::float8 FROM notification_outbox WHERE id = $1")
        .bind(id)
        .fetch_one(pool)
        .await
        .expect("next attempt")
}

async fn make_due(pool: &PgPool, id: i64, attempts: i32) {
    sqlx::query("UPDATE notification_outbox SET attempts = $2, next_attempt_at = now() WHERE id = $1")
        .bind(id)
        .bind(attempts)
        .execute(pool)
        .await
        .expect("due");
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_failed_text_backs_off_then_dead_letters_and_alerts_the_owner(pool: PgPool) {
    let s = unconfigured(&pool);
    let id = insert_sms(&pool, 0).await;

    assert_eq!(sms_outbox::pass(&s).await.expect("pass"), 1);
    assert_eq!(state_of(&pool, id).await, (1, Some("sms_failed".into()), false));
    let first = secs_until_next(&pool, id).await;
    assert!((55.0..=65.0).contains(&first), "the first retry waits a minute: {first}");

    make_due(&pool, id, 1).await;
    assert_eq!(sms_outbox::pass(&s).await.expect("pass"), 1);
    let second = secs_until_next(&pool, id).await;
    assert!((115.0..=125.0).contains(&second), "the backoff doubles: {second}");

    // Attempt eight fails: the row is dead-lettered, kept for inspection and reported to the owner.
    make_due(&pool, id, 7).await;
    assert_eq!(sms_outbox::pass(&s).await.expect("pass"), 1);
    assert_eq!(state_of(&pool, id).await, (8, Some("sms_failed".into()), true));
    assert_eq!(sms_outbox::dead_count(&pool).await.expect("count"), 1, "the console counts it");
    assert_eq!(ops::failures_within(&pool, &["sms_dead_letter"], 60).await.expect("failures"), 1);
    let findings = ops_alerts::evaluate(&s).await.expect("findings");
    assert!(findings.iter().any(|f| f.rule == "sms_dead_letter"), "the owner alert fires: {findings:?}");

    assert_eq!(sms_outbox::pass(&s).await.expect("pass"), 0, "a dead text is not tried again");
}

#[sqlx::test(migrations = "../../migrations")]
async fn alimtalk_is_queued_only_when_its_template_and_channel_are_configured(pool: PgPool) {
    let s = unconfigured(&pool);
    let msg = || Message::Alimtalk { template: "booking.status", brand: "brand", title: "title", body: "body" };

    // Nothing configured in live mode: refused, no row at all.
    assert!(sms_outbox::enqueue(&s, None, "01012345678", "booking.status", msg()).await.is_err());

    s.providers.set_integrations(Integrations { solapi: Some(solapi(&[])), ..Default::default() });
    let plain = sms_outbox::enqueue(&s, None, "01012345678", "booking.status", msg()).await.expect("enqueue");
    let (channel, body): (String, String) = sqlx::query_as("SELECT channel, body FROM notification_outbox WHERE id = $1")
        .bind(plain)
        .fetch_one(&pool)
        .await
        .expect("row");
    assert_eq!((channel.as_str(), body.as_str()), ("sms", "title\nbody"), "no template: SMS with both lines");

    s.providers.set_integrations(Integrations { solapi: Some(solapi(&[("booking.status", "TPL1")])), ..Default::default() });
    let alimtalk = sms_outbox::enqueue(&s, None, "01012345678", "booking.status", msg()).await.expect("enqueue");
    let (channel, data): (String, serde_json::Value) = sqlx::query_as("SELECT channel, data FROM notification_outbox WHERE id = $1")
        .bind(alimtalk)
        .fetch_one(&pool)
        .await
        .expect("row");
    assert_eq!(channel, "alimtalk");
    assert_eq!(data, json!({ "template": "booking.status", "brand": "brand" }));
}

#[sqlx::test(migrations = "../../migrations")]
async fn live_without_solapi_refuses_a_plain_text_and_queues_nothing(pool: PgPool) {
    let s = unconfigured(&pool);
    assert!(sms_outbox::send(&s, None, "01012345678", "team.invite", Message::Sms("hi")).await.is_err());
    let queued: i64 = sqlx::query_scalar("SELECT count(*) FROM notification_outbox").fetch_one(&pool).await.expect("count");
    assert_eq!(queued, 0, "a text that was never sent is not queued or counted");
}

#[sqlx::test(migrations = "../../migrations")]
async fn dev_without_solapi_queues_a_plain_text_so_the_fake_log_gets_it(pool: PgPool) {
    let s = build_state(pool.clone(), test_config()).expect("app state");
    let id = sms_outbox::enqueue(&s, None, "01012345678", "team.invite", Message::Sms("hi")).await.expect("enqueue");
    let (channel, body): (String, String) = sqlx::query_as("SELECT channel, body FROM notification_outbox WHERE id = $1")
        .bind(id)
        .fetch_one(&pool)
        .await
        .expect("row");
    assert_eq!((channel.as_str(), body.as_str()), ("sms", "hi"));
    assert_eq!(sms_outbox::pass(&s).await.expect("pass"), 1, "the attempt runs and logs the text");
    let left: i64 = sqlx::query_scalar("SELECT count(*) FROM notification_outbox").fetch_one(&pool).await.expect("count");
    assert_eq!(left, 0, "delivered in dev: the row is removed");
}

#[sqlx::test(migrations = "../../migrations")]
async fn an_otp_code_is_sent_inline_and_never_queued(pool: PgPool) {
    let app = common::app(pool.clone());
    let (st, b) = call(&app, "POST", "/v1/auth/otp", None, Some(json!({ "phone": "010-7300-0001" }))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let queued: i64 = sqlx::query_scalar("SELECT count(*) FROM notification_outbox").fetch_one(&pool).await.expect("count");
    assert_eq!(queued, 0, "the user is waiting on the code: it is not left for the job");
}
