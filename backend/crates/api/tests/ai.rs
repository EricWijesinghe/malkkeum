//! AI support agent over the real router and a migrated Postgres. A fake Anthropic endpoint stands in
//! for the Messages API, so no test ever calls the real service.

mod common;

use api::{
    ai::{AiConfig, Caps, DEFAULT_MODEL, Mode, answer},
    auth::{self, Role},
    build_state,
    integrations::Integrations,
    routes,
    state::AppState,
};
use axum::{
    Json, Router,
    extract::State,
    http::{HeaderMap, StatusCode},
    routing::{get, post},
};
use common::{SECRET, call, login, seed_catalog};
use serde_json::{Value, json};
use sqlx::PgPool;
use std::{
    sync::{Arc, Mutex},
    time::{Duration, Instant},
};
use uuid::Uuid;

const HANDOFF_KO: &str = "상담원이 확인 후 답변드릴게요.";

/// Fake Anthropic: records every Messages call and answers with `stop` as the stop reason.
#[derive(Clone, Default)]
struct Fake {
    stop: Arc<Mutex<&'static str>>,
    calls: Arc<Mutex<Vec<(HeaderMap, Value)>>>,
}

async fn messages(State(f): State<Fake>, headers: HeaderMap, Json(body): Json<Value>) -> Json<Value> {
    let stop = *f.stop.lock().expect("stop lock");
    f.calls.lock().expect("calls lock").push((headers, body));
    Json(json!({
        "stop_reason": stop,
        "content": [{ "type": "text", "text": "AI reply" }],
        "usage": { "input_tokens": 120, "output_tokens": 8, "cache_read_input_tokens": 100, "cache_creation_input_tokens": 0 }
    }))
}

async fn models() -> Json<Value> {
    Json(json!({ "data": [] }))
}

/// Starts the fake on a free local port and returns its base URL.
async fn fake_anthropic(fake: Fake) -> String {
    let app = Router::new()
        .route("/v1/messages", post(messages))
        .route("/v1/models", get(models))
        .with_state(fake);
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.expect("bind fake");
    let addr = listener.local_addr().expect("fake addr");
    tokio::spawn(async move { axum::serve(listener, app).await.expect("fake serves") });
    format!("http://{addr}")
}

struct World {
    app: Router,
    state: AppState,
    fake: Fake,
    thread: Uuid,
    customer: String,
}

/// Customer with one open thread, AI configured in `mode`, business hours closed unless a test opens them.
async fn world(db: PgPool, mode: Mode) -> World {
    seed_catalog(&db).await;
    let fake = Fake::default();
    *fake.stop.lock().expect("stop lock") = "end_turn";
    let mut cfg = common::test_config();
    cfg.anthropic_base_url = fake_anthropic(fake.clone()).await;
    let state = build_state(db.clone(), cfg.clone()).expect("state");
    let mut integ = Integrations::from_config(&cfg);
    integ.ai = Some(AiConfig { api_key: "sk-ant-test-key".into(), model: DEFAULT_MODEL.into(), mode, caps: Caps::default() });
    state.providers.set_integrations(integ);
    let app = routes::router(state.clone());
    let (customer, _) = login(&app, "010-5100-0001", "customer").await;
    let (st, opened) = call(&app, "POST", "/v1/chat/threads", Some(customer.as_str()), Some(json!({ "topic": "other" }))).await;
    assert_eq!(st, StatusCode::OK, "{opened}");
    let thread = opened["id"].as_str().expect("thread id").parse().expect("uuid");
    set_hours(&db, false).await;
    World { app, state, fake, thread, customer }
}

async fn set_hours(db: &PgPool, open_all_day: bool) {
    let hours = if open_all_day {
        json!({ "weekdays": [0, 1, 2, 3, 4, 5, 6], "open": "00:00", "close": "23:59" })
    } else {
        json!({ "weekdays": [], "open": "09:00", "close": "18:00" })
    };
    sqlx::query("UPDATE settings SET value = $1 WHERE key = 'business_hours'")
        .bind(hours)
        .execute(db)
        .await
        .expect("set hours");
}

async fn customer_says(db: &PgPool, thread: Uuid, text: &str) {
    sqlx::query("INSERT INTO chat_messages (thread_id, sender, kind, body) VALUES ($1, 'customer', 'text', $2)")
        .bind(thread)
        .bind(json!({ "text": text }))
        .execute(db)
        .await
        .expect("customer message");
}

async fn ai_replies(db: &PgPool, thread: Uuid) -> Vec<Value> {
    sqlx::query_scalar("SELECT body FROM chat_messages WHERE thread_id = $1 AND sender = 'staff' AND body->>'ai' = 'true' ORDER BY created_at")
        .bind(thread)
        .fetch_all(db)
        .await
        .expect("ai replies")
}

async fn admin_token(db: &PgPool) -> String {
    let id: Uuid = sqlx::query_scalar(
        "INSERT INTO staff (email, name, password_hash, role) VALUES ('ai-admin@test.local', 'Owner', 'unused', 'admin') RETURNING id",
    )
    .fetch_one(db)
    .await
    .expect("admin row");
    auth::issue_access(SECRET, id, Role::StaffAdmin).expect("admin token")
}

async fn staff_token(db: &PgPool) -> String {
    let id: Uuid = sqlx::query_scalar(
        "INSERT INTO staff (email, name, password_hash, role) VALUES ('ai-consultant@test.local', 'Consultant', 'unused', 'consultant') RETURNING id",
    )
    .fetch_one(db)
    .await
    .expect("staff row");
    auth::issue_access(SECRET, id, Role::StaffConsultant).expect("staff token")
}

#[sqlx::test(migrations = "../../migrations")]
async fn quick_customer_messages_get_one_ai_reply_through_the_debounce(pool: PgPool) {
    let w = world(pool.clone(), Mode::Offline).await;
    let uri = format!("/v1/chat/threads/{}/messages", w.thread);
    for text in ["청소 가격이 얼마예요?", "두 번째 질문", "세 번째 질문"] {
        let (st, sent) = call(&w.app, "POST", &uri, Some(w.customer.as_str()), Some(json!({ "kind": "text", "text": text }))).await;
        assert_eq!(st, StatusCode::OK, "{sent}");
    }
    let deadline = Instant::now() + Duration::from_secs(15);
    while ai_replies(&pool, w.thread).await.is_empty() {
        assert!(Instant::now() < deadline, "no AI reply within 15 s");
        tokio::time::sleep(Duration::from_millis(200)).await;
    }
    // Give any stale debounce task time to run; it must find its ticket superseded.
    tokio::time::sleep(Duration::from_secs(4)).await;
    let replies = ai_replies(&pool, w.thread).await;
    assert_eq!(replies.len(), 1, "one answer for the burst: {replies:?}");
    assert_eq!(replies[0]["text"], "AI reply");

    let calls = w.fake.calls.lock().expect("calls").clone();
    assert_eq!(calls.len(), 1, "one model call for the burst");
    let (headers, body) = &calls[0];
    assert_eq!(headers["x-api-key"], "sk-ant-test-key");
    assert_eq!(headers["anthropic-version"], "2026-10-21");
    assert_eq!(headers["anthropic-beta"], "server-side-fallback-2026-07-01");
    assert_eq!(body["fallbacks"], "default");
    assert_eq!(body["model"], DEFAULT_MODEL);
    assert!(body["system"][1]["text"].as_str().expect("shop block").contains("studio"), "catalogue in the cached block");
    assert_eq!(body["system"][1]["cache_control"]["type"], "ephemeral");
    let last = body["messages"].as_array().expect("turns").last().expect("a turn");
    assert_eq!(last["role"], "user");
    assert!(last["content"].as_str().expect("text").contains("세 번째 질문"));

    let (outcome, tokens): (String, i32) = sqlx::query_as("SELECT outcome, input_tokens FROM ai_usage WHERE thread_id = $1")
        .bind(w.thread)
        .fetch_one(&pool)
        .await
        .expect("usage row");
    assert_eq!((outcome.as_str(), tokens), ("answered", 120));
}

#[sqlx::test(migrations = "../../migrations")]
async fn staff_online_in_offline_mode_keeps_the_ai_quiet_during_hours(pool: PgPool) {
    let w = world(pool.clone(), Mode::Offline).await;
    set_hours(&pool, true).await;
    let _staff_connected = w.state.hub.staff_join();
    customer_says(&pool, w.thread, "환불해 주세요").await;
    answer(&w.state, w.thread).await.expect("decision runs");
    assert!(ai_replies(&pool, w.thread).await.is_empty());
    assert!(w.fake.calls.lock().expect("calls").is_empty());
}

#[sqlx::test(migrations = "../../migrations")]
async fn always_first_answers_even_while_staff_is_connected(pool: PgPool) {
    let w = world(pool.clone(), Mode::AlwaysFirst).await;
    set_hours(&pool, true).await;
    let _staff_connected = w.state.hub.staff_join();
    customer_says(&pool, w.thread, "예약 확인 부탁해요").await;
    answer(&w.state, w.thread).await.expect("answer");
    assert_eq!(ai_replies(&pool, w.thread).await.len(), 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn refusal_posts_the_fixed_handoff_and_records_the_call(pool: PgPool) {
    let w = world(pool.clone(), Mode::Offline).await;
    *w.fake.stop.lock().expect("stop") = "refusal";
    customer_says(&pool, w.thread, "환불 안 해주면 고소할 거예요").await;
    answer(&w.state, w.thread).await.expect("answer");
    let replies = ai_replies(&pool, w.thread).await;
    assert_eq!(replies.len(), 1);
    assert_eq!(replies[0]["text"], HANDOFF_KO);
    assert_eq!(replies[0]["ai"], true);
    let outcome: String = sqlx::query_scalar("SELECT outcome FROM ai_usage WHERE thread_id = $1")
        .bind(w.thread)
        .fetch_one(&pool)
        .await
        .expect("usage row");
    assert_eq!(outcome, "handoff");
}

#[sqlx::test(migrations = "../../migrations")]
async fn staff_pause_switch_stops_the_ai_until_resumed(pool: PgPool) {
    let w = world(pool.clone(), Mode::Offline).await;
    let staff = staff_token(&pool).await;
    let uri = format!("/v1/admin/threads/{}/ai", w.thread);
    let (st, paused) = call(&w.app, "PUT", &uri, Some(staff.as_str()), Some(json!({ "paused": true }))).await;
    assert_eq!(st, StatusCode::OK, "{paused}");
    assert_eq!(paused["ai_paused"], true);

    customer_says(&pool, w.thread, "안녕하세요").await;
    answer(&w.state, w.thread).await.expect("answer");
    assert!(w.fake.calls.lock().expect("calls").is_empty(), "paused thread gets no call");

    let (st, _) = call(&w.app, "PUT", &uri, Some(staff.as_str()), Some(json!({ "paused": false }))).await;
    assert_eq!(st, StatusCode::OK);
    answer(&w.state, w.thread).await.expect("answer");
    assert_eq!(ai_replies(&pool, w.thread).await.len(), 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_recent_human_staff_reply_blocks_the_ai(pool: PgPool) {
    let w = world(pool.clone(), Mode::AlwaysFirst).await;
    sqlx::query("INSERT INTO chat_messages (thread_id, sender, kind, body) VALUES ($1, 'staff', 'text', $2)")
        .bind(w.thread)
        .bind(json!({ "text": "제가 확인할게요" }))
        .execute(&pool)
        .await
        .expect("staff message");
    customer_says(&pool, w.thread, "네 감사합니다").await;
    answer(&w.state, w.thread).await.expect("answer");
    assert!(w.fake.calls.lock().expect("calls").is_empty());
}

#[sqlx::test(migrations = "../../migrations")]
async fn per_thread_hourly_cap_stops_repeat_spend(pool: PgPool) {
    let w = world(pool.clone(), Mode::AlwaysFirst).await;
    sqlx::query("INSERT INTO ai_usage (thread_id, model, outcome) SELECT $1, 'x', 'answered' FROM generate_series(1, 12)")
        .bind(w.thread)
        .execute(&pool)
        .await
        .expect("usage rows");
    customer_says(&pool, w.thread, "또 질문이요").await;
    answer(&w.state, w.thread).await.expect("answer");
    assert!(w.fake.calls.lock().expect("calls").is_empty());
}

#[sqlx::test(migrations = "../../migrations")]
async fn caps_saved_in_the_console_limit_replies(pool: PgPool) {
    let w = world(pool.clone(), Mode::AlwaysFirst).await;
    let admin = admin_token(&pool).await;
    let saved = json!({ "api_key": "sk-ant-test-key", "mode": "always_first", "thread_hourly_cap": "1" });
    let (st, body) = call(&w.app, "PUT", "/v1/admin/setup/ai", Some(admin.as_str()), Some(saved)).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    sqlx::query("INSERT INTO ai_usage (thread_id, model, outcome) VALUES ($1, 'x', 'answered')")
        .bind(w.thread)
        .execute(&pool)
        .await
        .expect("usage row");
    customer_says(&pool, w.thread, "또 질문이요").await;
    answer(&w.state, w.thread).await.expect("answer");
    assert!(w.fake.calls.lock().expect("calls").is_empty(), "the saved cap of 1 per hour is already used");
}

#[sqlx::test(migrations = "../../migrations")]
async fn cap_values_outside_their_bounds_are_refused(pool: PgPool) {
    let w = world(pool.clone(), Mode::AlwaysFirst).await;
    let admin = admin_token(&pool).await;
    let bad = json!({ "api_key": "sk-ant-test-key", "daily_cap": "0" });
    let (st, body) = call(&w.app, "PUT", "/v1/admin/setup/ai", Some(admin.as_str()), Some(bad)).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{body}");
    assert_eq!(body["error"]["code"], "invalid_cap", "{body}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn usage_endpoint_reports_the_month_for_staff(pool: PgPool) {
    let w = world(pool.clone(), Mode::Offline).await;
    customer_says(&pool, w.thread, "청소 시간이 얼마나 걸려요?").await;
    answer(&w.state, w.thread).await.expect("answer");
    let staff = staff_token(&pool).await;
    let (st, usage) = call(&w.app, "GET", "/v1/admin/ai/usage", Some(staff.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{usage}");
    assert_eq!(usage["configured"], true);
    assert_eq!(usage["mode"], "offline");
    assert_eq!(usage["month"]["calls"], 1);
    assert_eq!(usage["month"]["answered"], 1);
    assert_eq!(usage["month"]["input_tokens"], 120);
    assert_eq!(usage["month"]["cache_read_tokens"], 100);
}

#[sqlx::test(migrations = "../../migrations")]
async fn customers_cannot_pause_the_ai(pool: PgPool) {
    let w = world(pool.clone(), Mode::Offline).await;
    let uri = format!("/v1/admin/threads/{}/ai", w.thread);
    let (st, _) = call(&w.app, "PUT", &uri, Some(w.customer.as_str()), Some(json!({ "paused": true }))).await;
    assert_eq!(st, StatusCode::FORBIDDEN);
}
