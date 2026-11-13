//! Owner-editable settings over the real router and DB: database beats env, every write is audited,
//! read-only and tighten-only rules hold, a bad entry rejects the whole group, and only staff admins get in.
//! Needs DATABASE_URL (sqlx::test).

mod common;

use api::{auth::Role, settings_registry};
use axum::http::StatusCode;
use common::{call, staff_token, test_config};
use serde_json::{Value, json};
use sqlx::PgPool;

fn item<'a>(doc: &'a Value, key: &str) -> &'a Value {
    doc["items"].as_array().expect("items").iter().find(|i| i["key"] == key).expect("key in group")
}

#[sqlx::test(migrations = "../../migrations")]
async fn database_value_beats_env_seed(pool: PgPool) {
    let app = common::app(pool.clone());
    let (token, _) = staff_token(&pool, Role::StaffAdmin).await;
    let cfg = test_config();
    assert_eq!(
        settings_registry::get(&pool, &cfg, "upload_daily_quota").await.expect("get"),
        i64::from(cfg.upload_daily_quota)
    );

    let (st, doc) = call(
        &app,
        "PUT",
        "/v1/admin/settings/business",
        Some(&token),
        Some(json!({ "values": { "upload_daily_quota": 500 } })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{doc}");
    assert_eq!(item(&doc, "upload_daily_quota")["value"], 500);
    assert_eq!(item(&doc, "upload_daily_quota")["source"], "db");
    assert_eq!(settings_registry::get(&pool, &cfg, "upload_daily_quota").await.expect("get"), 500);

    let (st, doc) = call(
        &app,
        "PUT",
        "/v1/admin/settings/business",
        Some(&token),
        Some(json!({ "values": { "upload_daily_quota": null } })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{doc}");
    assert_eq!(item(&doc, "upload_daily_quota")["source"], "env", "reset returns to the env seed");
}

#[sqlx::test(migrations = "../../migrations")]
async fn every_change_writes_an_audit_row_with_old_and_new(pool: PgPool) {
    let app = common::app(pool.clone());
    let (token, admin) = staff_token(&pool, Role::StaffAdmin).await;
    let (st, _) = call(
        &app,
        "PUT",
        "/v1/admin/settings/marketing",
        Some(&token),
        Some(json!({ "values": { "nudge_rebook_days": 45 } })),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    let (action, actor, data): (String, uuid::Uuid, Value) =
        sqlx::query_as("SELECT action, actor_id, data FROM audit_log WHERE action = 'settings.update' AND target = 'nudge_rebook_days'")
            .fetch_one(&pool)
            .await
            .expect("one audit row");
    assert_eq!(action, "settings.update");
    assert_eq!(actor, admin);
    assert_eq!(data["old"], Value::Null);
    assert_eq!(data["new"], 45);
}

#[sqlx::test(migrations = "../../migrations")]
async fn read_only_rows_refuse_a_write(pool: PgPool) {
    let app = common::app(pool.clone());
    let (token, _) = staff_token(&pool, Role::StaffAdmin).await;
    let (st, doc) = call(
        &app,
        "PUT",
        "/v1/admin/settings/business",
        Some(&token),
        Some(json!({ "values": { "reconcile_interval_secs": 120 } })),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{doc}");
    let n: i64 = sqlx::query_scalar("SELECT count(*) FROM settings WHERE key = 'reg.reconcile_interval_secs'")
        .fetch_one(&pool)
        .await
        .expect("count");
    assert_eq!(n, 0);
}

#[sqlx::test(migrations = "../../migrations")]
async fn one_bad_entry_rejects_the_whole_group(pool: PgPool) {
    let app = common::app(pool.clone());
    let (token, _) = staff_token(&pool, Role::StaffAdmin).await;
    let body = json!({ "values": { "upload_daily_quota": 200, "max_open_quote_requests": 0 } });
    let (st, _) = call(&app, "PUT", "/v1/admin/settings/business", Some(&token), Some(body)).await;
    assert_eq!(st, StatusCode::BAD_REQUEST);
    let n: i64 = sqlx::query_scalar("SELECT count(*) FROM settings WHERE key LIKE 'reg.%'")
        .fetch_one(&pool)
        .await
        .expect("count");
    assert_eq!(n, 0, "nothing is written when any entry fails");
}

#[sqlx::test(migrations = "../../migrations")]
async fn tighten_only_refuses_a_loosening(pool: PgPool) {
    let app = common::app(pool.clone());
    let (token, _) = staff_token(&pool, Role::StaffAdmin).await;
    let (st, _) = call(
        &app,
        "PUT",
        "/v1/admin/settings/marketing",
        Some(&token),
        Some(json!({ "values": { "freq_cap_per_week": 3 } })),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "the marketing cap can only go down from 2");
    let (st, _) = call(
        &app,
        "PUT",
        "/v1/admin/settings/marketing",
        Some(&token),
        Some(json!({ "values": { "freq_cap_per_week": 1 } })),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
}

#[sqlx::test(migrations = "../../migrations")]
async fn consultant_cannot_read_or_write(pool: PgPool) {
    let app = common::app(pool.clone());
    let (consultant, _) = staff_token(&pool, Role::StaffConsultant).await;
    let (st, _) = call(&app, "GET", "/v1/admin/settings/ops", Some(&consultant), None).await;
    assert_eq!(st, StatusCode::FORBIDDEN);
    let (st, _) = call(
        &app,
        "PUT",
        "/v1/admin/settings/ops",
        Some(&consultant),
        Some(json!({ "values": { "disk_low_pct": 15 } })),
    )
    .await;
    assert_eq!(st, StatusCode::FORBIDDEN);
}

#[sqlx::test(migrations = "../../migrations")]
async fn unknown_group_and_key_are_refused(pool: PgPool) {
    let app = common::app(pool.clone());
    let (token, _) = staff_token(&pool, Role::StaffAdmin).await;
    let (st, _) = call(&app, "GET", "/v1/admin/settings/nope", Some(&token), None).await;
    assert_eq!(st, StatusCode::NOT_FOUND);
    let (st, _) = call(
        &app,
        "PUT",
        "/v1/admin/settings/ops",
        Some(&token),
        Some(json!({ "values": { "upload_daily_quota": 5 } })),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "a key outside the group is refused");
}

#[sqlx::test(migrations = "../../migrations")]
async fn order_rules_refuse_inverted_alert_levels(pool: PgPool) {
    let app = common::app(pool.clone());
    let (token, _) = staff_token(&pool, Role::StaffAdmin).await;
    let body = json!({ "values": { "backup_stale_hours": 10 } });
    let (st, doc) = call(&app, "PUT", "/v1/admin/settings/ops", Some(&token), Some(body)).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "yellow (26h) would sit above red (10h): {doc}");
    let body = json!({ "values": { "disk_low_pct": 25 } });
    let (st, _) = call(&app, "PUT", "/v1/admin/settings/ops", Some(&token), Some(body)).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "red threshold (25%) would sit above yellow (20%)");
    let body = json!({ "values": { "backup_stale_hours": 30 } });
    let (st, doc) = call(&app, "PUT", "/v1/admin/settings/ops", Some(&token), Some(body)).await;
    assert_eq!(st, StatusCode::OK, "{doc}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn destructive_limits_hold_their_floors(pool: PgPool) {
    let app = common::app(pool.clone());
    let cfg = test_config();
    let (token, _) = staff_token(&pool, Role::StaffAdmin).await;
    let (st, _) = call(
        &app,
        "PUT",
        "/v1/admin/settings/business",
        Some(&token),
        Some(json!({ "values": { "ai_chat_retention_days": 29 } })),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "chat history cannot be purged inside 30 days");
    let (st, _) = call(
        &app,
        "PUT",
        "/v1/admin/settings/business",
        Some(&token),
        Some(json!({ "values": { "ai_chat_retention_days": 30 } })),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(
        settings_registry::get(&pool, &cfg, "ai_chat_retention_days").await.expect("get"),
        30,
        "the purge reads the stored value"
    );
    let (st, _) = call(
        &app,
        "PUT",
        "/v1/admin/settings/business",
        Some(&token),
        Some(json!({ "values": { "review_report_threshold": 1 } })),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "one report must not hide a review");
}

#[sqlx::test(migrations = "../../migrations")]
async fn maintenance_flag_and_message_round_trip(pool: PgPool) {
    let app = common::app(pool.clone());
    let cfg = test_config();
    let (token, _) = staff_token(&pool, Role::StaffAdmin).await;
    let body = json!({ "values": { "maintenance_on": true, "maintenance_message": "  잠시 쉬어요  " } });
    let (st, doc) = call(&app, "PUT", "/v1/admin/settings/ops", Some(&token), Some(body)).await;
    assert_eq!(st, StatusCode::OK, "{doc}");
    assert_eq!(item(&doc, "maintenance_on")["type"], "bool");
    assert_eq!(item(&doc, "maintenance_message")["value"], "잠시 쉬어요");
    assert!(settings_registry::get_flag(&pool, &cfg, "maintenance_on").await.expect("flag"));
    let (st, _) = call(
        &app,
        "PUT",
        "/v1/admin/settings/ops",
        Some(&token),
        Some(json!({ "values": { "maintenance_on": "yes" } })),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "a flag takes only true or false");
}
