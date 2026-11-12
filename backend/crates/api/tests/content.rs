//! Console content over the real router: the `news` kind (migration 0106) from create to the
//! public, kind-filtered list the customer home reads.

mod common;

use api::auth::{self, Role};
use axum::http::StatusCode;
use common::{SECRET, call};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

fn item(kind: &str, title: &str, active: bool) -> Value {
    json!({
        "kind": kind, "slug": null, "title": { "ko": title }, "body": { "text": { "ko": "본문" } },
        "image_url": null, "link": null, "sort_order": 0, "starts_at": null, "ends_at": null, "active": active,
    })
}

#[sqlx::test(migrations = "../../migrations")]
async fn news_is_created_edited_and_listed_publicly_by_kind(pool: PgPool) {
    let app = common::app(pool.clone());
    let staff: Uuid = sqlx::query_scalar("INSERT INTO staff (email, name, password_hash, role) VALUES ('owner@test.local', 'Owner', 'unused', 'admin') RETURNING id")
        .fetch_one(&pool)
        .await
        .expect("staff row");
    let admin = auth::issue_access(SECRET, staff, Role::StaffAdmin).expect("token");
    let admin = Some(admin.as_str());

    let (st, made) = call(&app, "POST", "/v1/admin/content", admin, Some(item("news", "원룸 청소 서비스 지역 확대", true))).await;
    assert_eq!(st, StatusCode::OK, "{made}");
    let id = made["id"].as_str().expect("id").to_string();
    let (st, b) = call(&app, "POST", "/v1/admin/content", admin, Some(item("tip", "에어컨 냄새의 원인은?", true))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (st, b) = call(&app, "POST", "/v1/admin/content", admin, Some(item("blog", "없는 종류", true))).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::BAD_REQUEST, Some("invalid_content")), "{b}");

    let titles = |v: &Value| -> Vec<String> { v.as_array().expect("list").iter().map(|c| c["title"]["ko"].as_str().expect("title").to_string()).collect() };
    let (st, news) = call(&app, "GET", "/v1/content?kind=news", None, None).await;
    assert_eq!(st, StatusCode::OK, "{news}");
    assert_eq!(titles(&news), ["원룸 청소 서비스 지역 확대"], "public, no token, news only");
    let (_, tips) = call(&app, "GET", "/v1/content?kind=tip", None, None).await;
    assert_eq!(titles(&tips), ["에어컨 냄새의 원인은?"]);
    let (_, listed) = call(&app, "GET", "/v1/admin/content?kind=news", admin, None).await;
    assert_eq!(listed.as_array().map(Vec::len), Some(1));

    // Switched off: staff still see it, customers do not.
    let uri = format!("/v1/admin/content/{id}");
    let (st, b) = call(&app, "PUT", &uri, admin, Some(item("news", "수정한 소식", false))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (_, news) = call(&app, "GET", "/v1/content?kind=news", None, None).await;
    assert!(titles(&news).is_empty());
    let (_, listed) = call(&app, "GET", "/v1/admin/content?kind=news", admin, None).await;
    assert_eq!(titles(&listed), ["수정한 소식"]);

    let (st, b) = call(&app, "DELETE", &uri, admin, None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (_, listed) = call(&app, "GET", "/v1/admin/content?kind=news", admin, None).await;
    assert!(titles(&listed).is_empty());
}
