//! Wire behaviour against the real router: idempotency replay, error envelope, paging limits, spec access.

mod common;

use axum::{
    Router,
    body::{Body, to_bytes},
    http::{HeaderMap, Request, StatusCode, header},
};
use common::{app, login};
use serde_json::{Value, json};
use sqlx::PgPool;
use tower::ServiceExt;
use uuid::Uuid;

async fn send(app: &Router, method: &str, uri: &str, token: Option<&str>, key: Option<&str>, body: Value) -> (StatusCode, HeaderMap, Value) {
    let mut req = Request::builder().method(method).uri(uri).header(header::CONTENT_TYPE, "application/json");
    if let Some(t) = token {
        req = req.header(header::AUTHORIZATION, format!("Bearer {t}"));
    }
    if let Some(k) = key {
        req = req.header("idempotency-key", k);
    }
    let res = app.clone().oneshot(req.body(Body::from(body.to_string())).expect("request")).await.expect("service");
    let status = res.status();
    let headers = res.headers().clone();
    let bytes = to_bytes(res.into_body(), 1 << 20).await.expect("body");
    (status, headers, serde_json::from_slice(&bytes).unwrap_or(Value::Null))
}

#[sqlx::test(migrations = "../../migrations")]
async fn same_key_replays_first_answer_and_other_body_is_rejected(pool: PgPool) {
    let app = app(pool);
    let (token, _) = login(&app, "010-5000-0901", "customer").await;
    let uri = format!("/v1/checkouts/{}/confirm", Uuid::now_v7());
    let (s1, _, b1) = send(&app, "POST", &uri, Some(&token), Some("k-replay-1"), json!({})).await;
    assert_eq!(s1, StatusCode::NOT_FOUND);
    let (s2, h2, b2) = send(&app, "POST", &uri, Some(&token), Some("k-replay-1"), json!({})).await;
    assert_eq!(s2, s1, "replayed status");
    assert_eq!(b2, b1, "replayed body");
    assert_eq!(h2.get("idempotent-replayed").and_then(|v| v.to_str().ok()), Some("true"));
    let (s3, _, b3) = send(&app, "POST", &uri, Some(&token), Some("k-replay-1"), json!({ "other": 1 })).await;
    assert_eq!(s3, StatusCode::BAD_REQUEST);
    assert_eq!(b3["error"]["code"], "idempotency_key_reused");
}

#[sqlx::test(migrations = "../../migrations")]
async fn malformed_key_is_rejected_before_any_work(pool: PgPool) {
    let app = app(pool);
    let (token, _) = login(&app, "010-5000-0902", "customer").await;
    let (status, _, body) = send(&app, "POST", "/v1/checkouts", Some(&token), Some("bad key"), json!({})).await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert_eq!(body["error"]["code"], "invalid_idempotency_key");
}

#[sqlx::test(migrations = "../../migrations")]
async fn unknown_route_uses_error_envelope(pool: PgPool) {
    let app = app(pool);
    let (status, _, body) = send(&app, "GET", "/v1/no-such-route", None, None, json!(null)).await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    assert_eq!(body["error"]["code"], "not_found");
}

#[sqlx::test(migrations = "../../migrations")]
async fn list_limit_out_of_range_is_400(pool: PgPool) {
    let app = app(pool);
    let (token, _) = login(&app, "010-5000-0903", "customer").await;
    let (status, _, body) = send(&app, "GET", "/v1/bookings?limit=0", Some(&token), None, json!(null)).await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert_eq!(body["error"]["code"], "invalid_limit");
    let (status, _, body) = send(&app, "GET", "/v1/bookings?cursor=!!!", Some(&token), None, json!(null)).await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert_eq!(body["error"]["code"], "invalid_cursor");
}

#[sqlx::test(migrations = "../../migrations")]
async fn checkout_status_filter_is_validated(pool: PgPool) {
    let app = app(pool);
    let (token, _) = login(&app, "010-5000-0904", "customer").await;
    let (status, _, body) = send(&app, "GET", "/v1/checkouts?status=bogus", Some(&token), None, json!(null)).await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
    assert_eq!(body["error"]["code"], "invalid_status");
    let (status, _, _) = send(&app, "GET", "/v1/checkouts?status=failed&limit=5", Some(&token), None, json!(null)).await;
    assert_eq!(status, StatusCode::OK);
}

#[sqlx::test(migrations = "../../migrations")]
async fn openapi_spec_is_not_public(pool: PgPool) {
    let app = app(pool);
    let (token, _) = login(&app, "010-5000-0905", "customer").await;
    let (status, _, _) = send(&app, "GET", "/v1/openapi.json", None, None, json!(null)).await;
    assert_eq!(status, StatusCode::UNAUTHORIZED);
    let (status, _, _) = send(&app, "GET", "/v1/openapi.json", Some(&token), None, json!(null)).await;
    assert_eq!(status, StatusCode::FORBIDDEN);
}
