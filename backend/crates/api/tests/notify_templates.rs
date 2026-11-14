//! Owner-edited notification text: console CRUD and preview over the real router, and the text customers see.

mod common;

use api::auth::Role;
use axum::http::StatusCode;
use common::{call, customer, seed_catalog};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

const CANCELLED: &str = "booking.cancelled";

async fn booking_number(db: &PgPool, id: Uuid) -> String {
    sqlx::query_scalar("SELECT number FROM bookings WHERE id = $1")
        .bind(id)
        .fetch_one(db)
        .await
        .expect("number")
}

#[sqlx::test(migrations = "../../migrations")]
async fn only_admins_edit_and_unknown_placeholders_are_refused(pool: PgPool) {
    let app = common::app(pool.clone());
    let (admin, _) = common::staff_token(&pool, Role::StaffAdmin).await;
    let (consultant, _) = common::staff_token(&pool, Role::StaffConsultant).await;
    let uri = format!("/v1/admin/notify-templates/{CANCELLED}/ko");

    let (st, body) = call(&app, "PUT", &uri, Some(consultant.as_str()), Some(json!({ "title": "안내", "body": "안내" }))).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "{body}");

    let (st, body) = call(
        &app,
        "PUT",
        &uri,
        Some(admin.as_str()),
        Some(json!({ "title": "안내", "body": "{이름}님 취소" })),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{body}");
    assert_eq!(body["error"]["code"], "unknown_variable", "{body}");

    let (st, body) = call(&app, "PUT", &uri, Some(admin.as_str()), Some(json!({ "title": "안내", "body": "{예약번호" }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{body}");
    assert_eq!(body["error"]["code"], "unbalanced_braces", "{body}");

    let (st, body) = call(
        &app,
        "PUT",
        "/v1/admin/notify-templates/no.such.event/ko",
        Some(admin.as_str()),
        Some(json!({ "title": "a", "body": "b" })),
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{body}");
    assert_eq!(body["error"]["code"], "unknown_kind", "{body}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn owner_text_saves_previews_lists_and_resets(pool: PgPool) {
    let app = common::app(pool.clone());
    let (admin, _) = common::staff_token(&pool, Role::StaffAdmin).await;
    let uri = format!("/v1/admin/notify-templates/{CANCELLED}/ko");

    let (st, body) = call(
        &app,
        "PUT",
        &uri,
        Some(admin.as_str()),
        Some(json!({ "title": " 취소 안내 ", "body": "{예약번호} 예약이 취소됐어요" })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{body}");

    let (st, listed) = call(&app, "GET", "/v1/admin/notify-templates", Some(admin.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{listed}");
    let item = listed["items"]
        .as_array()
        .expect("items")
        .iter()
        .find(|i| i["kind"] == CANCELLED)
        .expect("event listed");
    assert_eq!(item["ko"]["custom"]["title"], "취소 안내", "{item}");
    assert_eq!(item["ko"]["default"]["title"], "예약이 취소됐어요", "{item}");
    assert!(item["en"]["custom"].is_null(), "{item}");

    let (st, preview) = call(
        &app,
        "POST",
        "/v1/admin/notify-templates/preview",
        Some(admin.as_str()),
        Some(json!({ "kind": CANCELLED, "locale": "ko", "title": "취소", "body": "{예약번호} 취소" })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{preview}");
    assert_eq!(preview["body"], "B-20261111-0042 취소", "{preview}");

    let (st, body) = call(&app, "DELETE", &uri, Some(admin.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    let (_, listed) = call(&app, "GET", "/v1/admin/notify-templates", Some(admin.as_str()), None).await;
    let item = listed["items"]
        .as_array()
        .expect("items")
        .iter()
        .find(|i| i["kind"] == CANCELLED)
        .expect("event listed");
    assert!(item["ko"]["custom"].is_null(), "{item}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn customer_sees_owner_text_and_built_in_text_when_it_cannot_fill(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6100-0001").await;
    let (id, _) = common::book(&app, &c, 10, None).await;
    let number = booking_number(&pool, id).await;
    let data = json!({ "booking_id": id });

    let built_in = api::i18n::notice(&pool, "ko", CANCELLED, "예약이 취소됐어요", &number, &data).await;
    assert_eq!(built_in, ("예약이 취소됐어요".to_string(), number.clone()));

    sqlx::query("INSERT INTO notify_templates (kind, locale, title, body) VALUES ($1, 'ko', '취소 안내', '{예약번호} 취소됐어요')")
        .bind(CANCELLED)
        .execute(&pool)
        .await
        .expect("template");
    let owner = api::i18n::notice(&pool, "ko", CANCELLED, "예약이 취소됐어요", &number, &data).await;
    assert_eq!(owner, ("취소 안내".to_string(), format!("{number} 취소됐어요")));

    // No booking to fill the placeholder from: the built-in text, not a half-filled one.
    let no_booking = api::i18n::notice(&pool, "ko", CANCELLED, "예약이 취소됐어요", &number, &json!({})).await;
    assert_eq!(no_booking, ("예약이 취소됐어요".to_string(), number.clone()));

    // A stored row with an unknown placeholder (written around the API) falls back too.
    sqlx::query("UPDATE notify_templates SET body = '{이름} 취소됐어요' WHERE kind = $1")
        .bind(CANCELLED)
        .execute(&pool)
        .await
        .expect("update");
    let broken = api::i18n::notice(&pool, "ko", CANCELLED, "예약이 취소됐어요", &number, &data).await;
    assert_eq!(broken, ("예약이 취소됐어요".to_string(), number));
}
