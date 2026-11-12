//! Subscriptions over the real router: planning, the day-before charge, declines and pause, partner continuity,
//! slot capacity, skip and move, cancel, owner edits, policy and metrics. PortOne billing runs in dev mode;
//! the `fake_decline` billing key is the mock decline.

mod common;

use api::{
    auth::{self, Role},
    build_state,
    providers::FAKE_DECLINE_KEY,
    routes::{self, subscription_engine},
    state::AppState,
};
use axum::{Router, http::StatusCode};
use chrono::{Datelike, Duration, NaiveDate, Utc};
use common::{Customer, SECRET, call, customer, seed_catalog, test_config, verified_pro};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

fn kst_today() -> NaiveDate {
    (Utc::now() + Duration::hours(9)).date_naive()
}

/// Monday = 0, the convention the apps and partner prefs use.
fn weekday_index(d: NaiveDate) -> u8 {
    d.weekday().num_days_from_monday() as u8
}

fn app_and_state(db: PgPool) -> (Router, AppState) {
    let state = build_state(db, test_config()).expect("state");
    (routes::router(state.clone()), state)
}

fn admin() -> String {
    auth::issue_access(SECRET, Uuid::now_v7(), Role::StaffAdmin).expect("token")
}

async fn subscribe(app: &Router, c: &Customer, weekday: u8, cadence: i64, hour: u8, pro: Option<Uuid>) -> (StatusCode, Value) {
    call(
        app,
        "POST",
        "/v1/subscriptions",
        Some(c.token.as_str()),
        Some(json!({
            "service_code": "studio",
            "address_id": c.address,
            "payment_method_id": c.card,
            "cadence_weeks": cadence,
            "weekday": weekday,
            "start_hour": hour,
            "preferred_pro_id": pro,
        })),
    )
    .await
}

fn sub_id(body: &Value) -> Uuid {
    body["subscription"]["id"].as_str().expect("sub id").parse().expect("uuid")
}

fn visits(body: &Value) -> Vec<Value> {
    body["visits"].as_array().cloned().unwrap_or_default()
}

async fn set_policy(db: &PgPool, discount: i64) {
    sqlx::query("INSERT INTO settings (key, value) VALUES ('subscription_policy', $1) ON CONFLICT (key) DO UPDATE SET value = $1")
        .bind(json!({ "discount_percent": discount }))
        .execute(db)
        .await
        .expect("policy");
}

async fn sub_status(db: &PgPool, id: Uuid) -> (String, Option<String>, i32) {
    sqlx::query_as("SELECT status, paused_reason, consecutive_failures FROM subscriptions WHERE id = $1")
        .bind(id)
        .fetch_one(db)
        .await
        .expect("subscription row")
}

#[sqlx::test(migrations = "../../migrations")]
async fn create_plans_visits_on_the_requested_weekday(pool: PgPool) {
    seed_catalog(&pool).await;
    let (app, _) = app_and_state(pool.clone());
    let c = customer(&app, &pool, "010-7000-0001").await;
    let (st, body) = subscribe(&app, &c, 2, 1, 9, None).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    let all = visits(&body);
    let planned: Vec<&Value> = all.iter().filter(|v| v["state"] == "planned").collect();
    // Weekly over the 28-day horizon: at least three Wednesdays.
    assert!(planned.len() >= 3, "{body}");
    for v in planned {
        let d: NaiveDate = v["visit_date"].as_str().unwrap().parse().unwrap();
        assert_eq!(weekday_index(d), 2, "{v}");
        assert!(d > kst_today() && d <= kst_today() + Duration::days(28), "{v}");
        assert_eq!(v["start_hour"], 9);
    }
}

#[sqlx::test(migrations = "../../migrations")]
async fn bad_cadence_and_weekday_are_refused(pool: PgPool) {
    seed_catalog(&pool).await;
    let (app, _) = app_and_state(pool.clone());
    let c = customer(&app, &pool, "010-7000-0002").await;
    let (st, _) = subscribe(&app, &c, 2, 3, 9, None).await;
    assert!(st.is_client_error(), "cadence 3 accepted: {st}");
    let (st, _) = subscribe(&app, &c, 7, 1, 9, None).await;
    assert!(st.is_client_error(), "weekday 7 accepted: {st}");
    let (st, _) = subscribe(&app, &c, 2, 1, 10, None).await;
    assert!(st.is_client_error(), "slot 10 accepted: {st}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn due_visit_is_booked_and_charged_at_the_policy_discount(pool: PgPool) {
    seed_catalog(&pool).await;
    set_policy(&pool, 10).await;
    let (app, state) = app_and_state(pool.clone());
    let c = customer(&app, &pool, "010-7000-0003").await;
    let (st, body) = subscribe(&app, &c, weekday_index(kst_today() + Duration::days(1)), 1, 9, None).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    assert_eq!(body["subscription"]["discount_percent"], 10);

    let report = subscription_engine::pass(&state).await.expect("pass");
    assert_eq!(report.booked, 1, "{report:?}");

    let (list, discount, paid, linked): (i64, i64, i64, Option<Uuid>) =
        sqlx::query_as("SELECT list_price, discount, paid_amount, subscription_id FROM bookings WHERE subscription_id = $1")
            .bind(sub_id(&body))
            .fetch_one(&pool)
            .await
            .expect("booking");
    assert_eq!(linked, Some(sub_id(&body)));
    assert_eq!(discount, list / 10, "10% of the list price");
    assert_eq!(paid, list - discount);
    let provider: String = sqlx::query_scalar("SELECT provider FROM payments WHERE booking_id = (SELECT id FROM bookings WHERE subscription_id = $1)")
        .bind(sub_id(&body))
        .fetch_one(&pool)
        .await
        .expect("payment");
    assert_eq!(provider, "portone");
    let (st, view) = call(&app, "GET", &format!("/v1/subscriptions/{}", sub_id(&body)), Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    assert!(visits(&view).iter().any(|v| v["state"] == "booked"), "{view}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn declined_card_retries_then_pauses_until_a_new_card(pool: PgPool) {
    seed_catalog(&pool).await;
    let (app, state) = app_and_state(pool.clone());
    let c = customer(&app, &pool, "010-7000-0004").await;
    sqlx::query("UPDATE payment_methods SET billing_key = $2 WHERE id = $1")
        .bind(c.card)
        .bind(FAKE_DECLINE_KEY)
        .execute(&pool)
        .await
        .expect("decline card");
    let (_, body) = subscribe(&app, &c, weekday_index(kst_today() + Duration::days(1)), 1, 9, None).await;
    let id = sub_id(&body);

    let first = subscription_engine::pass(&state).await.expect("pass");
    assert_eq!((first.booked, first.failed), (0, 1), "{first:?}");
    let booked: i64 = sqlx::query_scalar("SELECT count(*) FROM bookings WHERE subscription_id = $1").bind(id).fetch_one(&pool).await.unwrap();
    assert_eq!(booked, 0, "a declined charge leaves no booking");
    assert_eq!(sub_status(&pool, id).await.2, 1);

    // Open the retry window twice more: the third consecutive decline pauses for payment.
    for _ in 0..2 {
        sqlx::query("UPDATE subscription_visits SET retry_at = NULL WHERE subscription_id = $1").bind(id).execute(&pool).await.unwrap();
        subscription_engine::pass(&state).await.expect("pass");
    }
    let (status, reason, failures) = sub_status(&pool, id).await;
    assert_eq!((status.as_str(), reason.as_deref(), failures), ("paused", Some("payment"), 3));

    // Paused: no charge, even with the window open.
    sqlx::query("UPDATE subscription_visits SET retry_at = NULL WHERE subscription_id = $1").bind(id).execute(&pool).await.unwrap();
    assert_eq!(subscription_engine::pass(&state).await.expect("pass").booked, 0);

    // A new card and a resume: the visit is charged on the next pass.
    let second: Uuid = sqlx::query_scalar(
        "INSERT INTO payment_methods (user_id, provider, billing_key, display_name) VALUES ($1, 'pg', $2, 'card 2') RETURNING id",
    )
    .bind(c.user)
    .bind(format!("bk_test_second_{}", c.user))
    .fetch_one(&pool)
    .await
    .unwrap();
    let (st, resumed) = call(&app, "POST", &format!("/v1/subscriptions/{id}/resume"), Some(c.token.as_str()), Some(json!({ "payment_method_id": second }))).await;
    assert_eq!(st, StatusCode::OK, "{resumed}");
    assert_eq!(sub_status(&pool, id).await.0, "active");
    assert_eq!(subscription_engine::pass(&state).await.expect("pass").booked, 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn preferred_partner_gets_the_visit_and_is_the_only_one_who_sees_it(pool: PgPool) {
    seed_catalog(&pool).await;
    let (app, state) = app_and_state(pool.clone());
    let c = customer(&app, &pool, "010-7000-0005").await;
    let (ptoken, pro) = verified_pro(&app, &pool, "010-7000-0900").await;
    verified_pro(&app, &pool, "010-7000-0901").await;
    let (_, body) = subscribe(&app, &c, weekday_index(kst_today() + Duration::days(1)), 1, 9, Some(pro)).await;
    assert_eq!(subscription_engine::pass(&state).await.expect("pass").booked, 1);

    let (pro_of_booking, status): (Option<Uuid>, i16) = sqlx::query_as("SELECT pro_id, status FROM bookings WHERE subscription_id = $1")
        .bind(sub_id(&body))
        .fetch_one(&pool)
        .await
        .expect("booking");
    assert_eq!((pro_of_booking, status), (Some(pro), 2));

    let (st, mine) = call(&app, "GET", "/v1/partner/subscriptions", Some(ptoken.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{mine}");
    assert_eq!(mine.as_array().map(Vec::len), Some(1), "{mine}");
    assert_eq!(mine[0]["district_code"], common::DISTRICT);
    assert!(mine[0].get("user_id").is_none() && mine[0].get("address").is_none(), "partner sees contact-free rows only");
}

#[sqlx::test(migrations = "../../migrations")]
async fn planning_falls_back_when_the_customers_window_is_full(pool: PgPool) {
    seed_catalog(&pool).await;
    sqlx::query("INSERT INTO slot_capacity (start_hour, capacity) VALUES (9, 0) ON CONFLICT (start_hour) DO UPDATE SET capacity = 0")
        .execute(&pool)
        .await
        .unwrap();
    let (app, _) = app_and_state(pool.clone());
    let c = customer(&app, &pool, "010-7000-0006").await;
    let (st, body) = subscribe(&app, &c, 2, 1, 9, None).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    let planned = visits(&body);
    assert!(!planned.is_empty());
    assert!(planned.iter().all(|v| v["start_hour"] == 8), "{body}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn customer_skips_moves_pauses_and_cancels(pool: PgPool) {
    seed_catalog(&pool).await;
    let (app, _) = app_and_state(pool.clone());
    let c = customer(&app, &pool, "010-7000-0007").await;
    let (_, body) = subscribe(&app, &c, weekday_index(kst_today() + Duration::days(2)), 1, 9, None).await;
    let id = sub_id(&body);
    let planned: Vec<Value> = visits(&body).into_iter().filter(|v| v["state"] == "planned").collect();
    assert!(planned.len() >= 2, "{body}");
    let (first, second) = (planned[0]["id"].as_str().unwrap().to_string(), planned[1]["id"].as_str().unwrap().to_string());

    let (st, v) = call(&app, "POST", &format!("/v1/subscriptions/{id}/visits/{first}/skip"), Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{v}");
    assert!(visits(&v).iter().any(|x| x["id"] == first.as_str() && x["state"] == "skipped"));

    let moved_to = (kst_today() + Duration::days(20)).to_string();
    let (st, v) = call(
        &app,
        "POST",
        &format!("/v1/subscriptions/{id}/visits/{second}/reschedule"),
        Some(c.token.as_str()),
        Some(json!({ "visit_date": moved_to, "start_hour": 13 })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{v}");
    assert!(visits(&v).iter().any(|x| x["visit_date"] == moved_to.as_str() && x["start_hour"] == 13), "{v}");

    let (st, _) = call(&app, "POST", &format!("/v1/subscriptions/{id}/pause"), Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(sub_status(&pool, id).await, ("paused".into(), Some("customer".into()), 0));
    let (st, _) = call(&app, "POST", &format!("/v1/subscriptions/{id}/pause"), Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::CONFLICT, "pausing twice");

    let (st, _) = call(&app, "POST", &format!("/v1/subscriptions/{id}/resume"), Some(c.token.as_str()), Some(json!({}))).await;
    assert_eq!(st, StatusCode::OK);

    let (st, v) = call(&app, "POST", &format!("/v1/subscriptions/{id}/cancel"), Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{v}");
    assert_eq!(v["subscription"]["status"], "cancelled");
    assert_eq!(v["booked_visits"], json!([]));
    let left: i64 = sqlx::query_scalar("SELECT count(*) FROM subscription_visits WHERE subscription_id = $1 AND state = 'planned'")
        .bind(id)
        .fetch_one(&pool)
        .await
        .unwrap();
    assert_eq!(left, 0, "cancel clears planned visits");
}

#[sqlx::test(migrations = "../../migrations")]
async fn another_customers_subscription_is_not_found(pool: PgPool) {
    seed_catalog(&pool).await;
    let (app, _) = app_and_state(pool.clone());
    let owner = customer(&app, &pool, "010-7000-0008").await;
    let other = customer(&app, &pool, "010-7000-0009").await;
    let (_, body) = subscribe(&app, &owner, 2, 1, 9, None).await;
    let id = sub_id(&body);
    let (st, _) = call(&app, "GET", &format!("/v1/subscriptions/{id}"), Some(other.token.as_str()), None).await;
    assert_eq!(st, StatusCode::NOT_FOUND);
    let (st, _) = call(&app, "POST", &format!("/v1/subscriptions/{id}/cancel"), Some(other.token.as_str()), None).await;
    assert_eq!(st, StatusCode::NOT_FOUND);
}

#[sqlx::test(migrations = "../../migrations")]
async fn visit_that_passed_unpaid_becomes_missed(pool: PgPool) {
    seed_catalog(&pool).await;
    let (app, state) = app_and_state(pool.clone());
    let c = customer(&app, &pool, "010-7000-0010").await;
    let (_, body) = subscribe(&app, &c, weekday_index(kst_today() + Duration::days(1)), 1, 9, None).await;
    let id = sub_id(&body);
    sqlx::query("UPDATE subscription_visits SET visit_date = $2 WHERE subscription_id = $1 AND visit_date = $3")
        .bind(id)
        .bind(kst_today() - Duration::days(1))
        .bind(kst_today() + Duration::days(1))
        .execute(&pool)
        .await
        .unwrap();
    let report = subscription_engine::pass(&state).await.expect("pass");
    assert!(report.missed >= 1, "{report:?}");
    let missed: i64 = sqlx::query_scalar("SELECT count(*) FROM subscription_visits WHERE subscription_id = $1 AND state = 'missed'").bind(id).fetch_one(&pool).await.unwrap();
    assert_eq!(missed, 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn owner_edits_pauses_and_reads_metrics(pool: PgPool) {
    seed_catalog(&pool).await;
    set_policy(&pool, 0).await;
    let (app, _) = app_and_state(pool.clone());
    let c = customer(&app, &pool, "010-7000-0011").await;
    let (_, body) = subscribe(&app, &c, 2, 1, 9, None).await;
    let id = sub_id(&body);
    let token = admin();

    let (st, edited) = call(&app, "PUT", &format!("/v1/admin/subscriptions/{id}"), Some(token.as_str()), Some(json!({ "weekday": 4, "cadence_weeks": 2 }))).await;
    assert_eq!(st, StatusCode::OK, "{edited}");
    assert_eq!(edited["subscription"]["cadence_weeks"], 2);
    assert!(visits(&edited).iter().filter(|v| v["state"] == "planned").all(|v| {
        let d: NaiveDate = v["visit_date"].as_str().unwrap().parse().unwrap();
        weekday_index(d) == 4
    }), "{edited}");
    let audited: i64 = sqlx::query_scalar("SELECT count(*) FROM audit_log WHERE action = 'subscription.edit' AND target = $1")
        .bind(id.to_string())
        .fetch_one(&pool)
        .await
        .unwrap();
    assert_eq!(audited, 1);

    let (st, metrics) = call(&app, "GET", "/v1/admin/subscriptions/metrics", Some(token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{metrics}");
    assert_eq!(metrics["active"], 1);
    assert!(metrics["mrr"].as_i64().unwrap() > 0, "{metrics}");

    let (st, _) = call(&app, "POST", &format!("/v1/admin/subscriptions/{id}/pause"), Some(token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    let (_, metrics) = call(&app, "GET", "/v1/admin/subscriptions/metrics", Some(token.as_str()), None).await;
    assert_eq!((metrics["active"].as_i64(), metrics["mrr"].as_i64()), (Some(0), Some(0)), "{metrics}");

    let (st, _) = call(&app, "POST", &format!("/v1/subscriptions/{id}/cancel"), Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    let (_, metrics) = call(&app, "GET", "/v1/admin/subscriptions/metrics", Some(token.as_str()), None).await;
    assert_eq!(metrics["cancelled"], 1, "{metrics}");

    // The owner's finance summary carries the same recurring block.
    let (st, fin) = call(&app, "GET", "/v1/admin/finance/summary?period=custom&from=2026-03-01&to=2026-03-31", Some(token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{fin}");
    assert!(fin.get("recurring").is_some(), "{fin}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn discount_policy_is_bounded_and_public(pool: PgPool) {
    seed_catalog(&pool).await;
    let (app, _) = app_and_state(pool.clone());
    let token = admin();
    let (st, _) = call(&app, "PUT", "/v1/admin/subscriptions/policy", Some(token.as_str()), Some(json!({ "discount_percent": 31 }))).await;
    assert!(st.is_client_error(), "31% accepted: {st}");
    let (st, _) = call(&app, "PUT", "/v1/admin/subscriptions/policy", Some(token.as_str()), Some(json!({ "discount_percent": 15 }))).await;
    assert_eq!(st, StatusCode::OK);
    let (st, public) = call(&app, "GET", "/v1/policy/subscription", None, None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(public["discount_percent"], 15);
}
