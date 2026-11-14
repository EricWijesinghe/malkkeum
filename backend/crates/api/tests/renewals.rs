//! Renewal calendar over the real router and a migrated database: admin-only CRUD with audit rows, and the
//! reminder pass sends one SMS per threshold, re-arms when a due date moves, and derives the keys test.
//! Needs DATABASE_URL (sqlx::test).

mod common;

use api::{
    auth::Role,
    build_state,
    ops_alerts::{self, Prefs},
    renewals,
};
use axum::http::StatusCode;
use chrono::{Duration, Utc};
use common::{app, call, staff_token, test_config};
use serde_json::json;
use sqlx::PgPool;

const OWNER_PHONE: &str = "01012345678";

fn in_days(n: i64) -> String {
    (renewals::kst_today(Utc::now()) + Duration::days(n)).to_string()
}

async fn set_owner_phone(db: &PgPool) {
    let prefs = Prefs {
        alert_phone: Some(OWNER_PHONE.into()),
        ..Prefs::default()
    };
    ops_alerts::save_prefs(db, &prefs).await.expect("save alert phone");
}

async fn renewal_sms_count(db: &PgPool) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM notification_outbox WHERE kind = 'renewal.due'")
        .fetch_one(db)
        .await
        .expect("count sms")
}

async fn audit_count(db: &PgPool, action: &str) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM audit_log WHERE action = $1")
        .bind(action)
        .fetch_one(db)
        .await
        .expect("count audit")
}

#[sqlx::test(migrations = "../../migrations")]
async fn admin_manages_items_and_consultant_is_refused(db: PgPool) {
    let app = app(db.clone());
    let (admin, _) = staff_token(&db, Role::StaffAdmin).await;
    let (consultant, _) = staff_token(&db, Role::StaffConsultant).await;
    let body = json!({ "kind": "domain", "name": "malkkeum.kr", "due_on": in_days(90) });

    let (status, _) = call(&app, "POST", "/admin/renewals", Some(&consultant), Some(body.clone())).await;
    assert_eq!(status, StatusCode::FORBIDDEN);

    let (status, created) = call(&app, "POST", "/admin/renewals", Some(&admin), Some(body)).await;
    assert_eq!(status, StatusCode::OK);
    let id = created["id"].as_str().expect("id").to_owned();

    let (status, listed) = call(&app, "GET", "/admin/renewals", Some(&admin), None).await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(listed["items"][0]["name"], "malkkeum.kr");
    assert_eq!(listed["items"][0]["days_left"], 90);

    let moved = json!({ "kind": "domain_alias", "name": "old.kr", "due_on": in_days(10) });
    let (status, _) = call(&app, "PUT", &format!("/admin/renewals/{id}"), Some(&admin), Some(moved)).await;
    assert_eq!(status, StatusCode::OK);

    let (status, _) = call(&app, "DELETE", &format!("/admin/renewals/{id}"), Some(&admin), None).await;
    assert_eq!(status, StatusCode::OK);
    let (status, _) = call(&app, "DELETE", &format!("/admin/renewals/{id}"), Some(&admin), None).await;
    assert_eq!(status, StatusCode::NOT_FOUND);

    assert_eq!(audit_count(&db, "renewal.create").await, 1);
    assert_eq!(audit_count(&db, "renewal.update").await, 1);
    assert_eq!(audit_count(&db, "renewal.delete").await, 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn bad_input_is_refused_before_writing(db: PgPool) {
    let app = app(db.clone());
    let (admin, _) = staff_token(&db, Role::StaffAdmin).await;
    let bad = json!({ "kind": "hosting", "name": "", "due_on": in_days(5) });
    let (status, _) = call(&app, "POST", "/admin/renewals", Some(&admin), Some(bad)).await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    let missing = json!({ "kind": "hosting", "name": "x", "due_on": in_days(5) });
    let (status, _) = call(&app, "PUT", "/admin/renewals/00000000-0000-0000-0000-000000000000", Some(&admin), Some(missing)).await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    assert_eq!(audit_count(&db, "renewal.create").await, 0);
}

#[sqlx::test(migrations = "../../migrations")]
async fn keys_test_is_listed_only_after_a_passing_upload(db: PgPool) {
    let app = app(db.clone());
    let (admin, _) = staff_token(&db, Role::StaffAdmin).await;
    let (_, before) = call(&app, "GET", "/admin/renewals", Some(&admin), None).await;
    assert_eq!(before["items"].as_array().map(Vec::len), Some(0));

    let verified = Utc::now() - Duration::days(335);
    sqlx::query("INSERT INTO key_bundle_checks (id, verified_at) VALUES (1, $1)")
        .bind(verified)
        .execute(&db)
        .await
        .expect("record upload test");
    let (_, after) = call(&app, "GET", "/admin/renewals", Some(&admin), None).await;
    assert_eq!(after["items"][0]["id"], renewals::KEYS_TEST_ID);
    assert_eq!(after["items"][0]["days_left"], 30);
}

#[sqlx::test(migrations = "../../migrations")]
async fn reminders_fire_once_per_threshold_and_rearm_on_a_new_date(db: PgPool) {
    set_owner_phone(&db).await;
    let state = build_state(db.clone(), test_config()).expect("state");
    let app = app(db.clone());
    let (admin, _) = staff_token(&db, Role::StaffAdmin).await;
    let body = json!({ "kind": "domain", "name": "malkkeum.kr", "due_on": in_days(30) });
    let (_, created) = call(&app, "POST", "/admin/renewals", Some(&admin), Some(body)).await;
    let id = created["id"].as_str().expect("id").to_owned();

    assert_eq!(renewals::run_once(&state).await.expect("pass"), 1, "30-day text");
    assert_eq!(renewals::run_once(&state).await.expect("pass"), 0, "not twice");
    assert_eq!(renewal_sms_count(&db).await, 1);

    let near = json!({ "kind": "domain", "name": "malkkeum.kr", "due_on": in_days(7) });
    call(&app, "PUT", &format!("/admin/renewals/{id}"), Some(&admin), Some(near)).await;
    assert_eq!(renewals::run_once(&state).await.expect("pass"), 1, "7-day text on the moved date");
    assert_eq!(renewals::run_once(&state).await.expect("pass"), 0);
    assert_eq!(renewal_sms_count(&db).await, 2);
}

#[sqlx::test(migrations = "../../migrations")]
async fn keys_test_reminds_thirty_days_before_its_year_is_up(db: PgPool) {
    set_owner_phone(&db).await;
    let state = build_state(db.clone(), test_config()).expect("state");
    sqlx::query("INSERT INTO key_bundle_checks (id, verified_at) VALUES (1, $1)")
        .bind(Utc::now() - Duration::days(335))
        .execute(&db)
        .await
        .expect("record upload test");

    assert_eq!(renewals::run_once(&state).await.expect("pass"), 1);
    assert_eq!(renewals::run_once(&state).await.expect("pass"), 0);
    assert_eq!(renewal_sms_count(&db).await, 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn no_owner_phone_means_no_text_and_no_record(db: PgPool) {
    let state = build_state(db.clone(), test_config()).expect("state");
    let app = app(db.clone());
    let (admin, _) = staff_token(&db, Role::StaffAdmin).await;
    let body = json!({ "kind": "apple", "name": "Apple 개발자", "due_on": in_days(3) });
    call(&app, "POST", "/admin/renewals", Some(&admin), Some(body)).await;

    let queued = renewals::run_once(&state).await.expect("pass");
    assert_eq!(queued, 0);
    let recorded: i64 = sqlx::query_scalar("SELECT count(*) FROM renewal_reminders")
        .fetch_one(&db)
        .await
        .expect("count");
    assert_eq!(recorded, 0);
}
