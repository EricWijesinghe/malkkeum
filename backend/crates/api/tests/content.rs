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
    let staff: Uuid =
        sqlx::query_scalar("INSERT INTO staff (email, name, password_hash, role) VALUES ('owner@test.local', 'Owner', 'unused', 'admin') RETURNING id")
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

    let titles = |v: &Value| -> Vec<String> {
        v.as_array()
            .expect("list")
            .iter()
            .map(|c| c["title"]["ko"].as_str().expect("title").to_string())
            .collect()
    };
    let (st, news) = call(&app, "GET", "/v1/content?kind=news", None, None).await;
    assert_eq!(st, StatusCode::OK, "{news}");
    assert_eq!(titles(&news), ["원룸 청소 서비스 지역 확대"], "public, no token, news only");
    assert!(news[0]["created_at"].is_string(), "the posting date rides along: {news}");
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

async fn service_order(pool: &PgPool) -> Vec<String> {
    sqlx::query_scalar("SELECT code FROM services ORDER BY sort_order, code")
        .fetch_all(pool)
        .await
        .expect("services")
}

#[sqlx::test(migrations = "../../migrations")]
async fn seed_orders_tiles_per_the_brief_and_keeps_an_owner_order(pool: PgPool) {
    common::seed_catalog(&pool).await;
    assert_eq!(service_order(&pool).await, api::seed::SEED_ORDER);

    sqlx::query("UPDATE services SET sort_order = 99 WHERE code = 'studio'")
        .execute(&pool)
        .await
        .expect("owner order");
    common::seed_catalog(&pool).await;
    assert_eq!(
        service_order(&pool).await.last().map(String::as_str),
        Some("studio"),
        "a re-seed never resets the owner's order"
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn seed_fixes_only_the_untouched_old_two_coupon_banner(pool: PgPool) {
    let old = json!({ "ko": "첫 예약 쿠폰 2장 받기", "en": "2 welcome coupons for your first booking", "ja": "初回予約クーポン2枚", "zh": "首单优惠券2张", "vi": "2 phiếu giảm giá cho lần đặt đầu" });
    let edited = json!({ "ko": "첫 예약 쿠폰 2장 받기!", "en": "Owner's own banner" });
    for (title, order) in [(&old, 0), (&edited, 1)] {
        sqlx::query("INSERT INTO content_items (kind, title, body, sort_order) VALUES ('banner', $1, '{}', $2)")
            .bind(title)
            .bind(order)
            .execute(&pool)
            .await
            .expect("banner");
    }
    common::seed_catalog(&pool).await;
    let titles: Vec<Value> = sqlx::query_scalar("SELECT title FROM content_items WHERE kind = 'banner' ORDER BY sort_order")
        .fetch_all(&pool)
        .await
        .expect("titles");
    assert_eq!(titles[0]["ko"], "첫 청소 15,000원 웰컴쿠폰");
    assert_eq!(titles[1], edited, "an owner-edited banner is left alone");
}
#[sqlx::test(migrations = "../../migrations")]
async fn seed_badges_mattress_new_and_aircon_hot_once(pool: PgPool) {
    common::seed_catalog(&pool).await;
    let badges: Vec<(String, String)> = sqlx::query_as("SELECT code, content->>'badge' FROM services WHERE content ? 'badge' ORDER BY code")
        .fetch_all(&pool)
        .await
        .expect("badges");
    let expected: Vec<(String, String)> = vec![("aircon".into(), "hot".into()), ("mattress".into(), "new".into())];
    assert_eq!(badges, expected);

    sqlx::query("UPDATE services SET content = '{}'::jsonb WHERE code = 'aircon'")
        .execute(&pool)
        .await
        .expect("owner removes the badge");
    common::seed_catalog(&pool).await;
    let left: Vec<String> = sqlx::query_scalar("SELECT code FROM services WHERE content ? 'badge'")
        .fetch_all(&pool)
        .await
        .expect("badges");
    assert_eq!(left, ["mattress"], "a re-seed never brings back a removed badge");
}
