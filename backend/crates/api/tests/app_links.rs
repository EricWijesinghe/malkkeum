//! Android App Links and Apple Universal Links over the real router: env fallback, owner-saved values
//! beating env, validation, the dry run, and who may save.

mod common;

use api::{auth::Role, build_state, routes};
use axum::{Router, http::StatusCode};
use common::{call, staff_token};
use serde_json::{Value, json};
use sqlx::PgPool;

const ENV_CERT: &str = "CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD:CD";
const SAVED_CERT: &str = "EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF:EF";
const ENV_TEAM: &str = "ABCDE12345";
const SAVED_TEAM: &str = "ZYXWV98765";

/// Router whose env already carries link values (production-style deploy before any console save).
fn env_app(db: PgPool) -> Router {
    let mut cfg = common::test_config();
    cfg.android_cert_sha256 = vec![ENV_CERT.into()];
    cfg.apple_team_id = Some(ENV_TEAM.into());
    routes::router(build_state(db, cfg).expect("http client"))
}

async fn well_known(app: &Router, path: &str) -> (StatusCode, Value) {
    call(app, "GET", path, None, None).await
}

async fn admin_put(app: &Router, token: &str, body: Value) -> (StatusCode, Value) {
    call(app, "PUT", "/v1/admin/app-links", Some(token), Some(body)).await
}

#[sqlx::test(migrations = "../../migrations")]
async fn env_values_serve_both_files_until_the_owner_saves(db: PgPool) {
    let app = env_app(db.clone());
    let (st, android) = well_known(&app, "/.well-known/assetlinks.json").await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(android[0]["target"]["sha256_cert_fingerprints"], json!([ENV_CERT]));
    let (st, aasa) = well_known(&app, "/.well-known/apple-app-site-association").await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(aasa["webcredentials"]["apps"][0], format!("{ENV_TEAM}.com.malkkeum.customer"));

    let (token, _) = staff_token(&db, Role::StaffAdmin).await;
    let (st, status) = call(&app, "GET", "/v1/admin/app-links", Some(&token), None).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(status["source"], "environment");
}

#[sqlx::test(migrations = "../../migrations")]
async fn saved_values_replace_the_env_values(db: PgPool) {
    let app = env_app(db.clone());
    let (token, _) = staff_token(&db, Role::StaffAdmin).await;
    let (st, saved) = admin_put(
        &app,
        &token,
        json!({ "android_cert_sha256": [SAVED_CERT.to_lowercase()], "apple_team_id": SAVED_TEAM }),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{saved}");
    assert_eq!(saved["source"], "database");

    let (_, android) = well_known(&app, "/.well-known/assetlinks.json").await;
    assert_eq!(android[0]["target"]["sha256_cert_fingerprints"], json!([SAVED_CERT]));
    let (_, aasa) = well_known(&app, "/.well-known/apple-app-site-association").await;
    assert_eq!(aasa["webcredentials"]["apps"][1], format!("{SAVED_TEAM}.com.malkkeum.partner"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn clearing_the_values_turns_both_files_off(db: PgPool) {
    let app = env_app(db.clone());
    let (token, _) = staff_token(&db, Role::StaffAdmin).await;
    let (st, _) = admin_put(&app, &token, json!({ "android_cert_sha256": [], "apple_team_id": null })).await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(well_known(&app, "/.well-known/assetlinks.json").await.0, StatusCode::NOT_FOUND);
    assert_eq!(well_known(&app, "/.well-known/apple-app-site-association").await.0, StatusCode::NOT_FOUND);
}

#[sqlx::test(migrations = "../../migrations")]
async fn bad_values_are_refused_and_the_env_values_stay(db: PgPool) {
    let app = env_app(db.clone());
    let (token, _) = staff_token(&db, Role::StaffAdmin).await;
    let (st, _) = admin_put(&app, &token, json!({ "android_cert_sha256": ["AA:BB"], "apple_team_id": null })).await;
    assert_eq!(st, StatusCode::BAD_REQUEST);
    let (st, _) = admin_put(&app, &token, json!({ "android_cert_sha256": [], "apple_team_id": "short" })).await;
    assert_eq!(st, StatusCode::BAD_REQUEST);
    let (_, aasa) = well_known(&app, "/.well-known/apple-app-site-association").await;
    assert_eq!(aasa["webcredentials"]["apps"][0], format!("{ENV_TEAM}.com.malkkeum.customer"));
    let stored: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM settings WHERE key = 'app_links'")
        .fetch_one(&db)
        .await
        .expect("count");
    assert_eq!(stored, 0);
}

#[sqlx::test(migrations = "../../migrations")]
async fn verify_shows_the_files_and_saves_nothing(db: PgPool) {
    let app = common::app(db.clone());
    let (token, _) = staff_token(&db, Role::StaffAdmin).await;
    let (st, dry) = call(
        &app,
        "POST",
        "/v1/admin/app-links/verify",
        Some(&token),
        Some(json!({ "android_cert_sha256": [SAVED_CERT], "apple_team_id": SAVED_TEAM })),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(dry["source"], "unsaved");
    assert!(dry["aasa"]["applinks"].is_object());
    assert_eq!(well_known(&app, "/.well-known/assetlinks.json").await.0, StatusCode::NOT_FOUND);
}

#[sqlx::test(migrations = "../../migrations")]
async fn only_the_owner_may_save_and_a_save_is_audited(db: PgPool) {
    let app = env_app(db.clone());
    let (consultant, _) = staff_token(&db, Role::StaffConsultant).await;
    let (st, _) = admin_put(&app, &consultant, json!({ "android_cert_sha256": [], "apple_team_id": null })).await;
    assert_eq!(st, StatusCode::FORBIDDEN);

    let (owner, _) = staff_token(&db, Role::StaffAdmin).await;
    let (st, _) = admin_put(&app, &owner, json!({ "android_cert_sha256": [SAVED_CERT], "apple_team_id": null })).await;
    assert_eq!(st, StatusCode::OK);
    let rows: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM audit_log WHERE action = 'app_links.update'")
        .fetch_one(&db)
        .await
        .expect("audit");
    assert_eq!(rows, 1);
}
