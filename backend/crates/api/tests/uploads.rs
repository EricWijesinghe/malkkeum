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
use serde_json::{Value, json};
use sqlx::PgPool;
use std::net::SocketAddr;
use tower::ServiceExt;

/// Smallest container the metadata stripper accepts: signature, IHDR, IEND.
const PNG: &[u8] = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00IEND\x00\x00\x00\x00";

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
async fn a_photo_can_only_be_attached_by_its_uploader(pool: PgPool) {
    seed_catalog(&pool).await;
    std::fs::create_dir_all(test_config().upload_dir).expect("upload dir");
    let app = common::app(pool.clone());
    let owner = customer(&app, &pool, "010-5000-0603").await;
    let other = customer(&app, &pool, "010-5000-0604").await;
    let (_, name) = path_of(&upload(&app, &owner.token).await);
    let stored = vec![format!("/files/{name}")];
    assert!(api::routes::uploads::owned(&pool, Some(owner.user), &stored).await.expect("check"));
    assert!(!api::routes::uploads::owned(&pool, Some(other.user), &stored).await.expect("check"), "someone else's photo");
    assert!(api::routes::uploads::owned(&pool, None, &stored).await.expect("check"), "staff may reference any upload");
    assert!(!api::routes::uploads::owned(&pool, None, &["/files/ffffffffffffffffffffffffffffffff.jpg".to_string()]).await.expect("check"), "unknown file");
}

#[test]
fn only_photo_fields_are_signed() {
    let stored = "/files/0123456789abcdef0123456789abcdef.jpg";
    let mut v = json!({
        "url": stored,
        "body": { "text": format!("look {stored}") },
        "note": stored,
        "photos": { "before": [stored], "after": [] },
    });
    api::routes::uploads::sign_urls(&test_config(), &mut v);
    assert!(v["url"].as_str().is_some_and(|u| u.starts_with(&format!("{BASE_URL}/v1/files/"))));
    assert!(v["photos"]["before"][0].as_str().is_some_and(|u| u.starts_with(&format!("{BASE_URL}/v1/files/"))));
    assert_eq!(v["body"]["text"].as_str(), Some(format!("look {stored}").as_str()), "free text is not signed");
    assert_eq!(v["note"].as_str(), Some(stored), "unknown key is not signed");
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

/// Uploads arbitrary bytes as the customer. Returns the status and the JSON body.
async fn upload_raw(app: &Router, token: &str, bytes: &[u8]) -> (StatusCode, Value) {
    let boundary = "XBOUNDARY";
    let mut body = format!("--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"p.bin\"\r\nContent-Type: application/octet-stream\r\n\r\n").into_bytes();
    body.extend_from_slice(bytes);
    body.extend_from_slice(format!("\r\n--{boundary}--\r\n").as_bytes());
    let req = Request::builder()
        .method("POST")
        .uri("/v1/uploads")
        .header(header::AUTHORIZATION, format!("Bearer {token}"))
        .header(header::CONTENT_TYPE, format!("multipart/form-data; boundary={boundary}"))
        .body(Body::from(body))
        .expect("request");
    let (status, _, bytes) = send(app, req).await;
    (status, serde_json::from_slice(&bytes).unwrap_or(Value::Null))
}

fn jpeg_segment(marker: u8, body: &[u8]) -> Vec<u8> {
    let mut s = vec![0xFF, marker];
    s.extend_from_slice(&u16::try_from(body.len() + 2).expect("small").to_be_bytes());
    s.extend_from_slice(body);
    s
}

/// A JPEG whose EXIF block carries GPS coordinates, device and time, plus an XMP block.
fn jpeg_with_gps() -> Vec<u8> {
    let mut j = vec![0xFF, 0xD8];
    j.extend(jpeg_segment(0xE0, b"JFIF\0\x01\x01\0\0\x01\0\x01\0\0"));
    j.extend(jpeg_segment(0xE1, b"Exif\0\0MM\0*\0\0\0\x08GPSLatitude37.5665N GPSLongitude126.9780E Make=Acme DateTimeOriginal"));
    j.extend(jpeg_segment(0xE1, b"http://ns.adobe.com/xap/1.0/\0<x:xmpmeta>GPSLatitude</x:xmpmeta>"));
    j.extend(jpeg_segment(0xDB, &[0; 65]));
    j.extend(jpeg_segment(0xDA, &[1, 1, 0, 0, 63, 0]));
    j.extend_from_slice(&[0x12, 0x34, 0xFF, 0xD9]);
    j
}

fn contains(hay: &[u8], needle: &[u8]) -> bool {
    hay.windows(needle.len()).any(|w| w == needle)
}

#[sqlx::test(migrations = "../../migrations")]
async fn uploaded_photos_are_stored_without_exif_or_gps(pool: PgPool) {
    seed_catalog(&pool).await;
    std::fs::create_dir_all(test_config().upload_dir).expect("upload dir");
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5000-0602").await;
    let (status, body) = upload_raw(&app, &c.token, &jpeg_with_gps()).await;
    assert_eq!(status, StatusCode::OK, "{body}");
    let (path, name) = path_of(body["url"].as_str().expect("url"));
    let stored = std::fs::read(test_config().upload_dir.join(&name)).expect("stored file");
    for needle in [&b"GPSLatitude"[..], b"GPSLongitude", b"Exif", b"Make=Acme", b"xmpmeta"] {
        assert!(!contains(&stored, needle), "{} survived on disk", String::from_utf8_lossy(needle));
    }
    assert!(stored.ends_with(&[0x12, 0x34, 0xFF, 0xD9]), "image data is untouched");
    let (status, kind, served) = send(&app, get(&path)).await;
    assert_eq!((status, kind.as_str()), (StatusCode::OK, "image/jpeg"));
    assert_eq!(served, stored, "what is served is what was stripped");
}

#[sqlx::test(migrations = "../../migrations")]
async fn images_that_cannot_be_cleaned_are_refused(pool: PgPool) {
    seed_catalog(&pool).await;
    std::fs::create_dir_all(test_config().upload_dir).expect("upload dir");
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5000-0603").await;
    let heic = b"\0\0\0\x18ftypheic\0\0\0\0mif1heicEXIF-GPS";
    let truncated_jpeg = [0xFF, 0xD8, 0xFF, 0xE1, 0x00, 0x40, b'E'];
    for (label, bytes) in [("heic keeps its EXIF inside the container", &heic[..]), ("a truncated jpeg", &truncated_jpeg[..])] {
        let (status, body) = upload_raw(&app, &c.token, bytes).await;
        assert_eq!((status, body["error"]["code"].as_str()), (StatusCode::BAD_REQUEST, Some("unsupported_image")), "{label}: {body}");
    }
    let rows: i64 = sqlx::query_scalar("SELECT count(*) FROM uploads WHERE owner_id = $1").bind(c.user).fetch_one(&pool).await.expect("count");
    assert_eq!(rows, 0, "refused images leave no upload row");
}
