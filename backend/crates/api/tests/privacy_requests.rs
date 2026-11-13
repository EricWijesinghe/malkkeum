//! Staff handling of customer rights requests over the real router and a migrated database: lookup by
//! phone, the per-customer export (JSON and CSV), deletion limited to admins with the phone typed back,
//! and the request log. Consultants may look up and export, never delete.

mod common;

use api::auth::{self, Role};
use axum::{
    body::Body,
    extract::ConnectInfo,
    http::{Request, StatusCode, header},
};
use common::{SECRET, app, call, customer};
use serde_json::json;
use sqlx::PgPool;
use std::net::SocketAddr;
use tower::ServiceExt;
use uuid::Uuid;

/// Staff member of the given console role ("admin" or "consultant") and a token for it.
async fn staff_token(pool: &PgPool, email: &str, role: &str) -> String {
    let hash = auth::hash_password("staff-pass-123").expect("hash");
    let id: Uuid = sqlx::query_scalar("INSERT INTO staff (email, name, password_hash, role) VALUES ($1, '처리 직원', $2, $3) RETURNING id")
        .bind(email)
        .bind(hash)
        .bind(role)
        .fetch_one(pool)
        .await
        .expect("staff");
    let access = if role == "admin" { Role::StaffAdmin } else { Role::StaffConsultant };
    auth::issue_access(SECRET, id, access).expect("token")
}

/// GET that returns the status, content type and raw body (the CSV export is not JSON).
async fn raw_get(app: &axum::Router, uri: &str, token: &str) -> (StatusCode, String, String) {
    let mut request = Request::builder()
        .method("GET")
        .uri(uri)
        .header(header::AUTHORIZATION, format!("Bearer {token}"))
        .body(Body::empty())
        .expect("request");
    request.extensions_mut().insert(ConnectInfo(SocketAddr::from(([127, 0, 0, 1], 40_000))));
    let resp = app.clone().oneshot(request).await.expect("router is infallible");
    let status = resp.status();
    let kind = resp
        .headers()
        .get(header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or_default()
        .to_string();
    let bytes = axum::body::to_bytes(resp.into_body(), usize::MAX).await.expect("body");
    (status, kind, String::from_utf8_lossy(&bytes).into_owned())
}

#[sqlx::test(migrations = "../../migrations")]
async fn lookup_finds_the_live_customer_by_phone_and_rejects_a_bad_number(pool: PgPool) {
    let app = app(pool.clone());
    let c = customer(&app, &pool, "010-8200-0001").await;
    let consultant = staff_token(&pool, "lookup@test.local", "consultant").await;

    let (st, found) = call(&app, "GET", "/v1/admin/privacy/customers?phone=010-8200-0001", Some(consultant.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{found}");
    assert_eq!(found[0]["id"], c.user.to_string());

    let (st, body) = call(&app, "GET", "/v1/admin/privacy/customers?phone=12", Some(consultant.as_str()), None).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{body}");
    let (st, _) = call(&app, "GET", "/v1/admin/privacy/customers?phone=010-8200-0001", Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "customers cannot use staff lookup");
}

#[sqlx::test(migrations = "../../migrations")]
async fn export_holds_only_the_requested_customers_rows_in_json_and_csv(pool: PgPool) {
    let app = app(pool.clone());
    let first = customer(&app, &pool, "010-8200-0002").await;
    let second = customer(&app, &pool, "010-8200-0003").await;
    let consultant = staff_token(&pool, "export@test.local", "consultant").await;

    let (st, doc) = call(
        &app,
        "GET",
        &format!("/v1/admin/privacy/customers/{}/export", first.user),
        Some(consultant.as_str()),
        None,
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{doc}");
    assert_eq!(doc["profile"]["phone"], "01082000002");
    assert_eq!(doc["addresses"].as_array().map(Vec::len), Some(1));
    assert!(!doc.to_string().contains(&second.user.to_string()), "other customers never appear");
    assert!(!doc.to_string().contains("bk_test_"), "billing keys never leave the server");

    let (st, kind, csv) = raw_get(&app, &format!("/v1/admin/privacy/customers/{}/export?format=csv", first.user), &consultant).await;
    assert_eq!(st, StatusCode::OK, "{csv}");
    assert!(kind.starts_with("text/csv"), "content type {kind}");
    assert!(csv.starts_with('\u{feff}') && csv.contains("section,detail"), "BOM and header row");
    assert!(csv.contains("profile,") && csv.contains("addresses,"), "sections present");
    assert!(!csv.contains(&second.user.to_string()), "CSV holds only the requested customer");

    let (st, _) = call(
        &app,
        "GET",
        &format!("/v1/admin/privacy/customers/{}/export?format=xml", first.user),
        Some(consultant.as_str()),
        None,
    )
    .await;
    assert_eq!(st, StatusCode::BAD_REQUEST);
}

#[sqlx::test(migrations = "../../migrations")]
async fn only_an_admin_deletes_and_the_phone_must_be_typed_back(pool: PgPool) {
    let app = app(pool.clone());
    let c = customer(&app, &pool, "010-8200-0004").await;
    let consultant = staff_token(&pool, "scope@test.local", "consultant").await;
    let admin = staff_token(&pool, "boss@test.local", "admin").await;
    let path = format!("/v1/admin/privacy/customers/{}/delete", c.user);

    let (st, body) = call(&app, "POST", &path, Some(consultant.as_str()), Some(json!({ "phone": "01082000004" }))).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "consultant scope: {body}");

    let (st, body) = call(&app, "POST", &path, Some(admin.as_str()), Some(json!({ "phone": "01082000099" }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "wrong phone refused: {body}");
    let still_live: i64 = sqlx::query_scalar("SELECT count(*) FROM users WHERE id = $1 AND deleted_at IS NULL")
        .bind(c.user)
        .fetch_one(&pool)
        .await
        .expect("count");
    assert_eq!(still_live, 1, "nothing deleted on a mismatch");

    let (st, body) = call(&app, "POST", &path, Some(admin.as_str()), Some(json!({ "phone": "010-8200-0004" }))).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    let phone: String = sqlx::query_scalar("SELECT phone FROM users WHERE id = $1")
        .bind(c.user)
        .fetch_one(&pool)
        .await
        .expect("phone");
    assert!(phone.starts_with("deleted:"), "contact data removed");

    let (st, _) = call(&app, "POST", &path, Some(admin.as_str()), Some(json!({ "phone": "010-8200-0004" }))).await;
    assert_eq!(st, StatusCode::NOT_FOUND, "a deleted customer is not deleted twice");
    let logged: i64 = sqlx::query_scalar("SELECT count(*) FROM audit_log WHERE action = 'customer.delete' AND target = $1")
        .bind(c.user.to_string())
        .fetch_one(&pool)
        .await
        .expect("audit");
    assert_eq!(logged, 1, "the deletion is audit-logged once");
}

#[sqlx::test(migrations = "../../migrations")]
async fn each_request_is_recorded_and_listed_without_personal_details(pool: PgPool) {
    let app = app(pool.clone());
    let c = customer(&app, &pool, "010-8200-0005").await;
    let admin = staff_token(&pool, "log@test.local", "admin").await;

    let (st, _) = call(
        &app,
        "GET",
        &format!("/v1/admin/privacy/customers/{}/export", c.user),
        Some(admin.as_str()),
        None,
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    let (st, _) = call(
        &app,
        "POST",
        &format!("/v1/admin/privacy/customers/{}/delete", c.user),
        Some(admin.as_str()),
        Some(json!({ "phone": "01082000005" })),
    )
    .await;
    assert_eq!(st, StatusCode::OK);

    let (st, list) = call(&app, "GET", "/v1/admin/privacy/requests", Some(admin.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{list}");
    let rows = list.as_array().expect("list");
    assert_eq!(rows.len(), 2);
    assert_eq!(rows[0]["kind"], "delete");
    assert_eq!(rows[1]["kind"], "export");
    assert!(rows.iter().all(|r| r["status"] == "done" && r["staff_name"] == "처리 직원"));
    assert!(!list.to_string().contains("01082000005"), "no phone number in the request log");
}
