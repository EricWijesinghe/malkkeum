//! Setup wizard flows: owner account from the one-time code, business profile, integration keys.

mod common;

use api::routes::setup::ensure_setup_code;
use axum::http::StatusCode;
use common::call;
use serde_json::{Value, json};
use sqlx::PgPool;

async fn owner_token(app: &axum::Router) -> String {
    let (st, b) = call(
        app,
        "POST",
        "/v1/auth/staff/login",
        None,
        Some(json!({"email": "owner@test.local", "password": "owner-password-123"})),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{b}");
    b["access_token"].as_str().expect("token").to_string()
}

async fn create_owner(app: &axum::Router, code: &str) -> (StatusCode, Value) {
    call(
        app,
        "POST",
        "/v1/setup/admin",
        None,
        Some(json!({"code": code, "email": "Owner@Test.local", "name": "사장님", "password": "owner-password-123"})),
    )
    .await
}

#[sqlx::test(migrations = "../../migrations")]
async fn first_owner_needs_the_setup_code_and_only_one_can_be_created(pool: PgPool) {
    ensure_setup_code(&pool, Some("ABCD2345EFGH")).await.expect("code");
    let app = common::app(pool.clone());
    let (_, s) = call(&app, "GET", "/v1/setup", None, None).await;
    assert_eq!(s["needs_admin"], true);

    let (st, _) = create_owner(&app, "WRONG2345678").await;
    assert_eq!(st, StatusCode::FORBIDDEN);
    let (st, b) = create_owner(&app, "abcd-2345-efgh").await;
    assert_eq!(st, StatusCode::OK, "code is case and dash insensitive: {b}");
    let (st, _) = create_owner(&app, "abcd-2345-efgh").await;
    assert_eq!(st, StatusCode::CONFLICT, "second owner refused");

    let (_, s) = call(&app, "GET", "/v1/setup", None, None).await;
    assert_eq!(s["needs_admin"], false);
    owner_token(&app).await;
}

#[sqlx::test(migrations = "../../migrations")]
async fn owner_saves_business_and_keys_secrets_come_back_masked(pool: PgPool) {
    ensure_setup_code(&pool, Some("ABCD2345EFGH")).await.expect("code");
    let app = common::app(pool.clone());
    create_owner(&app, "ABCD2345EFGH").await;
    let t = owner_token(&app).await;
    let t = Some(t.as_str());

    let (st, b) = call(
        &app,
        "PUT",
        "/v1/admin/setup/business",
        t,
        Some(json!({"name": "말끔", "primary_color": "#3b5bfd"})),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (_, brand) = call(&app, "GET", "/v1/brand", None, None).await;
    assert_eq!(brand["name"], "말끔");
    assert_eq!(brand["primary_color"], "#3B5BFD");

    let (st, b) = call(&app, "PUT", "/v1/admin/setup/portone", t, Some(json!({"store_id": "store-1"}))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "secret is required: {b}");
    let keys = json!({"store_id": "store-1", "api_secret": "secret-value-9876", "channel_keys": {"card": "ch-card"}});
    let (st, card) = call(&app, "PUT", "/v1/admin/setup/portone", t, Some(keys)).await;
    assert_eq!(st, StatusCode::OK, "{card}");
    assert_eq!(card["source"], "console");
    let secret = card["fields"].as_array().unwrap().iter().find(|f| f["name"] == "api_secret").unwrap();
    assert_eq!(secret["preview"], "••••9876");
    let raw: String = sqlx::query_scalar("SELECT secret FROM integration_settings WHERE section = 'portone'")
        .fetch_one(&pool)
        .await
        .unwrap();
    assert!(!raw.contains("secret-value-9876"), "stored encrypted");

    // Blank secret keeps the saved one; the checkout now hands the app the console's store id.
    let (st, _) = call(
        &app,
        "PUT",
        "/v1/admin/setup/portone",
        t,
        Some(json!({"store_id": "store-2", "api_secret": ""})),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    let (_, all) = call(&app, "GET", "/v1/admin/setup", t, None).await;
    let portone = all["integrations"].as_array().unwrap().iter().find(|c| c["code"] == "portone").unwrap().clone();
    assert_eq!(portone["fields"][0]["preview"], "store-2");
    assert_eq!(portone["fields"][1]["set"], true);

    let (st, _) = call(&app, "DELETE", "/v1/admin/setup/portone", t, None).await;
    assert_eq!(st, StatusCode::OK);
    let (_, all) = call(&app, "GET", "/v1/admin/setup", t, None).await;
    let portone = all["integrations"].as_array().unwrap().iter().find(|c| c["code"] == "portone").unwrap().clone();
    assert_eq!(portone["source"], "none");
}

#[sqlx::test(migrations = "../../migrations")]
async fn customer_cannot_read_setup(pool: PgPool) {
    let app = common::app(pool.clone());
    let (token, _) = common::login(&app, "010-5000-0900", "customer").await;
    let (st, _) = call(&app, "GET", "/v1/admin/setup", Some(token.as_str()), None).await;
    assert_eq!(st, StatusCode::FORBIDDEN);
}
