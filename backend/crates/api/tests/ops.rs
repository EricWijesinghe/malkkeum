//! Operations API over the real router and a migrated database: the status page is for staff only,
//! alert settings are owner-only, and a failing integration shows up as red with its error code.

mod common;

use api::{
    auth::{self, Role},
    ops,
};
use axum::http::StatusCode;
use common::{SECRET, call, customer};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

async fn staff_token(pool: &PgPool, email: &str, role: Role) -> String {
    let hash = auth::hash_password("staff-pass-123").expect("hash");
    let db_role = if role == Role::StaffAdmin { "admin" } else { "consultant" };
    let id: Uuid = sqlx::query_scalar("INSERT INTO staff (email, name, password_hash, role) VALUES ($1, 'Staff', $2, $3) RETURNING id")
        .bind(email)
        .bind(hash)
        .bind(db_role)
        .fetch_one(pool)
        .await
        .expect("staff row");
    auth::issue_access(SECRET, id, role).expect("token")
}

#[sqlx::test(migrations = "../../migrations")]
async fn status_is_staff_only(pool: PgPool) {
    let app = common::app(pool.clone());
    let (st, _) = call(&app, "GET", "/v1/admin/ops/status", None, None).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "anonymous");

    let c = customer(&app, &pool, "010-7000-0001").await;
    let (st, _) = call(&app, "GET", "/v1/admin/ops/status", Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "customer");

    let consultant = staff_token(&pool, "ops-consultant@test.local", Role::StaffConsultant).await;
    let (st, body) = call(&app, "GET", "/v1/admin/ops/status", Some(consultant.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    assert!(body["checks"].as_array().is_some_and(|c| c.len() == 6), "six checks: {body}");
    assert!(body["integrations"].as_array().is_some_and(|i| i.len() == ops::INTEGRATIONS.len()));

    let (st, _) = call(&app, "PUT", "/v1/admin/ops/alerts", Some(consultant.as_str()), Some(json!({"quiet_start": 22, "quiet_end": 7}))).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "consultant cannot change alert settings");
}

#[sqlx::test(migrations = "../../migrations")]
async fn owner_saves_alert_settings_and_bad_input_is_refused(pool: PgPool) {
    let app = common::app(pool.clone());
    let owner = staff_token(&pool, "ops-owner@test.local", Role::StaffAdmin).await;
    let (st, body) = call(
        &app,
        "PUT",
        "/v1/admin/ops/alerts",
        Some(owner.as_str()),
        Some(json!({"rules": {"sms_failing": false}, "quiet_start": 23, "quiet_end": 6, "alert_phone": "010-2222-3333"})),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{body}");
    let (st, saved) = call(&app, "GET", "/v1/admin/ops/alerts", Some(owner.as_str()), None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(saved["prefs"]["rules"]["sms_failing"], false);
    assert_eq!(saved["prefs"]["alert_phone"], "01022223333");

    let (st, _) = call(&app, "PUT", "/v1/admin/ops/alerts", Some(owner.as_str()), Some(json!({"quiet_start": 30, "quiet_end": 6}))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST);
}

#[sqlx::test(migrations = "../../migrations")]
async fn failing_integration_turns_red_with_its_code_and_recovers(pool: PgPool) {
    let app = common::app(pool.clone());
    let consultant = staff_token(&pool, "ops-red@test.local", Role::StaffConsultant).await;
    ops::write_outcome(&pool, "solapi", Err("provider_error")).await.expect("record failure");
    let (_, body) = call(&app, "GET", "/v1/admin/ops/status", Some(consultant.as_str()), None).await;
    let solapi = body["integrations"].as_array().expect("list").iter().find(|i| i["code"] == "solapi").expect("solapi row").clone();
    assert_eq!(solapi["last_error"], "provider_error");
    assert_eq!(solapi["level"], "yellow", "not configured in the test config");
    assert_eq!(ops::failures_within(&pool, &["solapi"], 15).await.expect("count"), 1);

    ops::write_outcome(&pool, "solapi", Ok(())).await.expect("record success");
    let (_, body) = call(&app, "GET", "/v1/admin/ops/status", Some(consultant.as_str()), None).await;
    let solapi = body["integrations"].as_array().expect("list").iter().find(|i| i["code"] == "solapi").expect("solapi row").clone();
    assert!(solapi["last_ok_at"].is_string(), "success is recorded");
}
