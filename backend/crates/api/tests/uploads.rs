//! Uploads over the real router: photos are reachable only through signed `/v1/files` links, and every
//! stored upload path leaves the API as a fresh signed URL. Needs DATABASE_URL (sqlx::test).

mod common;

use api::routes::uploads::{sign, url_key};
use axum::{
    Router,
    body::Body,
    extract::ConnectInfo,
    http::{Request, StatusCode, header},
};
use chrono::Utc;
use common::{BASE_URL, call, customer, seed_catalog, test_config};
use serde_json::Value;
use sqlx::PgPool;
use std::net::SocketAddr;
use tower::ServiceExt;

const PNG: &[u8] = b"\x89PNG\r\n\x1a\nphoto-bytes";

async fn send(app: &Router, mut req: Request<Body>) -> (StatusCode, String, Vec<u8>) {
    req.extensions_mut().insert(ConnectInfo(SocketAddr::from(([127, 0, 0, 1], 40_000))));
    let res = app.clone().oneshot(req).await.expect("router is infallible");
    let status = res.status();
    let kind = res.headers().get(header::CONTENT_TYPE).and_then(|v| v.to_str().ok()).unwrap_or_default().to_string();
    let bytes = axum::body::to_bytes(res.into_body(), usize::MAX).await.expect("body").to_vec();
    (status, kind, bytes)
}

/// Uploads one PNG as the customer and returns the URL the API hands back.
async fn upload(app: &Router, token: &str) -> String {
    let boundary = "XBOUNDARY";
    let mut body = format!("--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"p.png\"\r\nContent-Type: image/png\r\n\r\n").into_bytes();
    body.extend_from_slice(PNG);
    body.extend_from_slice(format!("\r\n--{boundary}--\r\n").as_bytes());
    let req = Request::builder()
        .method("POST")
        .uri("/v1/uploads")
        .header(header::AUTHORIZATION, format!("Bearer {token}"))
        .header(header::CONTENT_TYPE, format!("multipart/form-data; boundary={boundary}"))
        .body(Body::from(body))
        .expect("request");
    let (status, _, bytes) = send(app, req).await;
    assert_eq!(status, StatusCode::OK, "upload: {}", String::from_utf8_lossy(&bytes));
    let v: Value = serde_json::from_slice(&bytes).expect("json");
    v["url"].as_str().expect("url").to_string()
}

fn get(uri: &str) -> Request<Body> {
    Request::builder().method("GET").uri(uri).body(Body::empty()).expect("request")
}

/// The request path (with query) and the file name for a URL the API returned.
fn path_of(url: &str) -> (String, String) {
    let path = url.strip_prefix(BASE_URL).expect("URL under the configured base");
    let name = path.trim_start_matches("/v1/files/").split('?').next().expect("name").to_string();
    (path.to_string(), name)
}

#[sqlx::test(migrations = "../../migrations")]
async fn signed_upload_is_served_and_the_public_path_is_gone(pool: PgPool) {
    seed_catalog(&pool).await;
    std::fs::create_dir_all(test_config().upload_dir).expect("upload dir");
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5000-0601").await;
    let url = upload(&app, &c.token).await;
    assert!(url.starts_with(&format!("{BASE_URL}/v1/files/")), "{url}");
    let (path, name) = path_of(&url);

    let (status, kind, bytes) = send(&app, get(&path)).await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(kind, "image/png");
    assert_eq!(bytes, PNG);

    let (status, _, _) = send(&app, get(&format!("/files/{name}"))).await;
    assert_eq!(status, StatusCode::NOT_FOUND, "no public static path");
}

#[sqlx::test(migrations = "../../migrations")]
async fn missing_tampered_or_expired_signatures_are_refused(pool: PgPool) {
    seed_catalog(&pool).await;
    std::fs::create_dir_all(test_config().upload_dir).expect("upload dir");
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5000-0602").await;
    let (path, name) = path_of(&upload(&app, &c.token).await);
    let (base_path, query) = path.split_once('?').expect("query");
    let exp = query.split('&').next().expect("exp").trim_start_matches("exp=");
    let sig = query.split("sig=").nth(1).expect("sig");

    let (status, _, _) = send(&app, get(base_path)).await;
    assert_eq!(status, StatusCode::FORBIDDEN, "no signature");
    let flipped = format!("{}{}", if sig.starts_with('0') { "1" } else { "0" }, &sig[1..]);
    let (status, _, _) = send(&app, get(&format!("{base_path}?exp={exp}&sig={flipped}"))).await;
    assert_eq!(status, StatusCode::FORBIDDEN, "tampered signature");

    let expired_at = Utc::now().timestamp() - 10;
    let old_sig = sign(&url_key(&test_config()), &name, expired_at);
    let (status, _, _) = send(&app, get(&format!("/v1/files/{name}?exp={expired_at}&sig={old_sig}"))).await;
    assert_eq!(status, StatusCode::FORBIDDEN, "expired link");
}

#[sqlx::test(migrations = "../../migrations")]
async fn traversal_names_are_not_served(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool);
    let exp = Utc::now().timestamp() + 600;
    let sig = sign(&url_key(&test_config()), "../secret.png", exp);
    let (status, _, _) = send(&app, get(&format!("/v1/files/..%2Fsecret.png?exp={exp}&sig={sig}"))).await;
    assert_eq!(status, StatusCode::NOT_FOUND);
}

#[sqlx::test(migrations = "../../migrations")]
async fn stored_photo_paths_leave_the_api_signed(pool: PgPool) {
    seed_catalog(&pool).await;
    sqlx::query("INSERT INTO content_items (kind, title, image_url, active) VALUES ('banner', '{\"ko\":\"t\"}', '/files/0123456789abcdef0123456789abcdef.png', true)")
        .execute(&pool)
        .await
        .expect("banner");
    let app = common::app(pool);
    let (status, body) = call(&app, "GET", "/v1/content?kind=banner", None, None).await;
    assert_eq!(status, StatusCode::OK, "{body}");
    let url = body[0]["image_url"].as_str().expect("image_url");
    assert!(url.starts_with(&format!("{BASE_URL}/v1/files/0123456789abcdef0123456789abcdef.png?exp=")), "{url}");
    assert!(url.contains("&sig="), "{url}");
}
