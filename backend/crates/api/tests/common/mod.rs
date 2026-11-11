#![allow(dead_code)]
//! Shared helpers for the DB-backed flow tests: the router with dev-mode fakes, a JSON call helper,
//! and setup steps (sign-in, verified pro, customer with card and address, paid booking).

use api::{
    build_state,
    config::{Config, PortOne},
    routes, seed,
};
use axum::{
    Router,
    body::Body,
    extract::ConnectInfo,
    http::{Request, StatusCode, header},
};
use chrono::{Duration, Utc};
use serde_json::{Value, json};
use sqlx::PgPool;
use std::net::SocketAddr;
use tower::ServiceExt;
use uuid::Uuid;

pub const SECRET: &[u8] = b"flow-test-secret-flow-test-secret-0000";
/// Photo URL that passes `is_own_upload` for the test config's public base URL.
pub const PHOTO: &str = "http://127.0.0.1:8080/files/0123456789abcdef0123456789abcdef.jpg";
/// District of every test address; the test pros cover it.
pub const DISTRICT: &str = "11680";
/// Public base URL of the test config; signed file URLs are built on it.
pub const BASE_URL: &str = "http://127.0.0.1:8080";

/// Dev-mode configuration: fake SMS, payments and push. Keep in step with `Config` fields.
pub fn test_config() -> Config {
    Config {
        database_url: String::new(),
        bind: "127.0.0.1:0".parse().expect("bind addr"),
        jwt_secret: SECRET.to_vec(),
        data_key: [7u8; 32],
        upload_dir: std::env::temp_dir().join("api-flow-tests"),
        public_base_url: BASE_URL.into(),
        dev_mode: true,
        allowed_origins: Vec::new(),
        seed_admin: None,
        setup_code: None,
        kakao_app_id: None,
        google_client_ids: Vec::new(),
        apple_client_ids: Vec::new(),
        portone: PortOne::default(),
        solapi: None,
        fcm: None,
        trusted_proxy: false,
        rate_auth_per_min: 1_000,
        rate_upload_per_min: 1_000,
        rate_general_per_min: 10_000,
        upload_daily_quota: 1_000,
        max_open_quote_requests: 100,
        max_threads_per_day: 100,
        reconcile_interval_secs: 60,
        anthropic_base_url: "http://127.0.0.1:9".into(),
    }
}

/// The API router over `db`, configured like `DEV_MODE=1`.
pub fn app(db: PgPool) -> Router {
    let state = build_state(db, test_config()).expect("http client");
    routes::router(state)
}

/// Catalogue, quote formula, slot capacity and starter content (what first boot inserts).
pub async fn seed_catalog(db: &PgPool) {
    seed::run(db, &test_config()).await.expect("seed");
}

/// One request through the router. Returns the status and the parsed JSON body (Null when empty).
pub async fn call(app: &Router, method: &str, uri: &str, token: Option<&str>, body: Option<Value>) -> (StatusCode, Value) {
    let mut req = Request::builder().method(method).uri(uri);
    if let Some(t) = token {
        req = req.header(header::AUTHORIZATION, format!("Bearer {t}"));
    }
    let payload = match body {
        Some(v) => {
            req = req.header(header::CONTENT_TYPE, "application/json");
            Body::from(v.to_string())
        }
        None => Body::empty(),
    };
    let mut request = req.body(payload).expect("valid request");
    request.extensions_mut().insert(ConnectInfo(SocketAddr::from(([127, 0, 0, 1], 40_000))));
    let resp = app.clone().oneshot(request).await.expect("router is infallible");
    let status = resp.status();
    let bytes = axum::body::to_bytes(resp.into_body(), usize::MAX).await.expect("response body");
    (status, serde_json::from_slice(&bytes).unwrap_or(Value::Null))
}

/// Signs in through the OTP flow (dev mode echoes the code). Returns (access token, subject id).
pub async fn login(app: &Router, phone: &str, audience: &str) -> (String, String) {
    let (st, sent) = call(app, "POST", "/v1/auth/otp", None, Some(json!({ "phone": phone }))).await;
    assert_eq!(st, StatusCode::OK, "otp request: {sent}");
    let code = sent["dev_code"].as_str().expect("dev_code in dev mode").to_string();
    let (st, tokens) = call(
        app,
        "POST",
        "/v1/auth/verify",
        None,
        Some(json!({ "phone": phone, "code": code, "audience": audience })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "verify: {tokens}");
    (
        tokens["access_token"].as_str().expect("access token").to_string(),
        tokens["subject"].as_str().expect("subject").to_string(),
    )
}

/// Pro signed in and made verified, taking studio jobs in the test district on every weekday.
/// Returns (access token, pro id).
pub async fn verified_pro(app: &Router, db: &PgPool, phone: &str) -> (String, Uuid) {
    let (token, subject) = login(app, phone, "partner").await;
    let id: Uuid = subject.parse().expect("pro id");
    sqlx::query("UPDATE pros SET status = 'verified' WHERE id = $1")
        .bind(id)
        .execute(db)
        .await
        .expect("verify pro");
    sqlx::query(
        "UPDATE partner_prefs SET services = ARRAY['studio'], districts = ARRAY[$2::text],
           weekdays = ARRAY[0,1,2,3,4,5,6]::smallint[], day_parts = ARRAY['morning','afternoon'] WHERE pro_id = $1",
    )
    .bind(id)
    .bind(DISTRICT)
    .execute(db)
    .await
    .expect("pro prefs");
    (token, id)
}

/// Records `PHOTO` as uploaded by `owner`, as the upload route would. Completion and review refuse
/// photos the caller did not upload, so every test that attaches `PHOTO` registers it first.
pub async fn register_photo(db: &PgPool, owner: Uuid) {
    sqlx::query("INSERT INTO uploads (owner_role, owner_id, file, bytes) VALUES ('test', $1, '0123456789abcdef0123456789abcdef.jpg', 1)")
        .bind(owner)
        .execute(db)
        .await
        .expect("register photo");
}

pub struct Customer {
    pub token: String,
    pub user: Uuid,
    pub address: Uuid,
    pub card: Uuid,
}

/// Customer signed up by OTP, with an address in the test district and a saved card (dev billing key).
pub async fn customer(app: &Router, db: &PgPool, phone: &str) -> Customer {
    let (token, subject) = login(app, phone, "customer").await;
    let user: Uuid = subject.parse().expect("user id");
    let (st, addr) = call(
        app,
        "POST",
        "/v1/me/addresses",
        Some(token.as_str()),
        Some(json!({
            "kind": "home",
            "label": "집",
            "road_address": "서울특별시 강남구 테헤란로 1",
            "detail": "",
            "district_code": DISTRICT,
            "size_pyeong": 8
        })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "address: {addr}");
    let card: Uuid =
        sqlx::query_scalar("INSERT INTO payment_methods (user_id, provider, billing_key, display_name) VALUES ($1, 'pg', 'bk_test', 'test card') RETURNING id")
            .bind(user)
            .fetch_one(db)
            .await
            .expect("payment method");
    Customer {
        token,
        user,
        address: addr["id"].as_str().expect("address id").parse().expect("uuid"),
        card,
    }
}

/// Books a studio clean `days` from now, paid with the customer's card. Returns (booking id, response body).
pub async fn book(app: &Router, c: &Customer, days: i64, coupon: Option<Uuid>) -> (Uuid, Value) {
    let visit = (Utc::now() + Duration::days(days)).date_naive();
    let (st, b) = call(
        app,
        "POST",
        "/v1/bookings",
        Some(c.token.as_str()),
        Some(json!({
            "service_code": "studio",
            "address_id": c.address,
            "visit_date": visit,
            "start_hour": 9,
            "coupon_id": coupon,
            "visit_notes": {},
            "payment_method_id": c.card
        })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "booking: {b}");
    let id = b["id"].as_str().expect("booking id").parse().expect("uuid");
    (id, b)
}
