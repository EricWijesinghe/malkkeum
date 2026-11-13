//! Staff activity log over the real router and a migrated database: owner only, newest first,
//! cursor pages with no gaps or repeats, filters that match Seoul calendar days, and bad input refused.

mod common;

use api::auth::Role;
use axum::{
    body::Body,
    extract::ConnectInfo,
    http::{Request, StatusCode, header},
};
use common::{call, staff_token};
use serde_json::{Value, json};
use sqlx::PgPool;
use std::net::SocketAddr;
use tower::ServiceExt;
use uuid::Uuid;

/// One GET through the router, keeping the `X-Next-Cursor` header that `call` drops.
async fn get_page(app: &axum::Router, uri: &str, token: &str) -> (StatusCode, Option<String>, Value) {
    let mut request = Request::builder()
        .method("GET")
        .uri(uri)
        .header(header::AUTHORIZATION, format!("Bearer {token}"))
        .body(Body::empty())
        .expect("request");
    request.extensions_mut().insert(ConnectInfo(SocketAddr::from(([127, 0, 0, 1], 40_000))));
    let resp = app.clone().oneshot(request).await.expect("router is infallible");
    let status = resp.status();
    let next = resp.headers().get("x-next-cursor").and_then(|v| v.to_str().ok()).map(str::to_owned);
    let bytes = axum::body::to_bytes(resp.into_body(), usize::MAX).await.expect("body");
    (status, next, serde_json::from_slice(&bytes).unwrap_or(Value::Null))
}

/// Writes one audit row at an explicit time (the Seoul offset is part of the timestamp).
async fn record(pool: &PgPool, actor: Option<Uuid>, role: &str, action: &str, target: &str, at: &str, data: Value) {
    sqlx::query("INSERT INTO audit_log (actor_role, actor_id, action, target, data, created_at) VALUES ($1, $2, $3, $4, $5, $6::timestamptz)")
        .bind(role)
        .bind(actor)
        .bind(action)
        .bind(target)
        .bind(data)
        .bind(at)
        .execute(pool)
        .await
        .expect("audit row");
}

/// Six rows over three Seoul days. B and B2 share a timestamp, so the id tie-break is exercised.
/// Returns the ids of the two staff members who wrote rows (s1 wrote A, B, B2; s2 wrote C, E).
async fn seed(pool: &PgPool) -> (Uuid, Uuid) {
    let (_, s1) = staff_token(pool, Role::StaffAdmin).await;
    let (_, s2) = staff_token(pool, Role::StaffConsultant).await;
    record(
        pool,
        Some(s1),
        "staff",
        "case.refund",
        "A",
        "2026-05-01T10:00:00+09:00",
        json!({ "amount": 5000 }),
    )
    .await;
    record(pool, Some(s1), "staff", "case.update", "B", "2026-05-01T12:00:00+09:00", json!({})).await;
    record(pool, Some(s1), "staff", "case.update", "B2", "2026-05-01T12:00:00+09:00", json!({})).await;
    record(pool, Some(s2), "staff", "points.adjust", "C", "2026-05-02T09:00:00+09:00", json!({})).await;
    record(pool, None, "system", "case.refund", "D", "2026-05-03T23:30:00+09:00", json!({})).await;
    record(pool, Some(s2), "staff", "service.update", "E", "2026-05-04T00:30:00+09:00", json!({})).await;
    (s1, s2)
}

fn targets(page: &Value) -> Vec<String> {
    page.as_array()
        .expect("array")
        .iter()
        .map(|r| r["target"].as_str().unwrap_or_default().to_owned())
        .collect()
}

#[sqlx::test(migrations = "../../migrations")]
async fn audit_is_owner_only(pool: PgPool) {
    let app = common::app(pool.clone());
    let (st, _) = call(&app, "GET", "/v1/admin/audit", None, None).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED, "anonymous");

    let c = common::customer(&app, &pool, "010-7100-0001").await;
    let (st, _) = call(&app, "GET", "/v1/admin/audit", Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "customer");

    let (consultant, _) = staff_token(&pool, Role::StaffConsultant).await;
    let (st, _) = call(&app, "GET", "/v1/admin/audit", Some(consultant.as_str()), None).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "consultant");

    let (owner, _) = staff_token(&pool, Role::StaffAdmin).await;
    let (st, body) = call(&app, "GET", "/v1/admin/audit", Some(owner.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{body}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn pages_are_newest_first_and_cover_every_row_once(pool: PgPool) {
    seed(&pool).await;
    let app = common::app(pool.clone());
    let (owner, _) = staff_token(&pool, Role::StaffAdmin).await;

    let mut seen: Vec<String> = Vec::new();
    let mut uri = "/v1/admin/audit?limit=2".to_owned();
    loop {
        let (st, next, page) = get_page(&app, &uri, &owner).await;
        assert_eq!(st, StatusCode::OK, "{page}");
        seen.extend(targets(&page));
        let Some(cursor) = next else { break };
        uri = format!("/v1/admin/audit?limit=2&cursor={cursor}");
    }
    assert_eq!(seen, ["E", "D", "C", "B2", "B", "A"]);
}

#[sqlx::test(migrations = "../../migrations")]
async fn filters_match_action_actor_target_and_seoul_days(pool: PgPool) {
    let (s1, _) = seed(&pool).await;
    let app = common::app(pool.clone());
    let (owner, _) = staff_token(&pool, Role::StaffAdmin).await;
    let cases = [
        ("", vec!["E", "D", "C", "B2", "B", "A"]),
        ("action=case.", vec!["D", "B2", "B", "A"]),
        ("action=case.refund", vec!["D", "A"]),
        ("actor_role=system", vec!["D"]),
        ("target=C", vec!["C"]),
    ];
    for (query, want) in cases {
        let uri = format!("/v1/admin/audit?{query}");
        let (st, _, page) = get_page(&app, &uri, &owner).await;
        assert_eq!(st, StatusCode::OK, "{uri}: {page}");
        assert_eq!(targets(&page), want, "{uri}");
    }
    let uri = format!("/v1/admin/audit?actor_id={s1}");
    let (_, _, page) = get_page(&app, &uri, &owner).await;
    assert_eq!(targets(&page), ["B2", "B", "A"], "by actor");

    // A day is Seoul midnight to midnight: 23:30 on the 3rd is in, 00:30 on the 4th is out.
    for (day, want) in [("2026-05-02", vec!["C"]), ("2026-05-03", vec!["D"]), ("2026-05-04", vec!["E"])] {
        let uri = format!("/v1/admin/audit?from={day}&to={day}");
        let (_, _, page) = get_page(&app, &uri, &owner).await;
        assert_eq!(targets(&page), want, "{uri}");
    }
    let (_, _, page) = get_page(&app, "/v1/admin/audit?action=case.&from=2026-05-01&to=2026-05-01", &owner).await;
    assert_eq!(targets(&page), ["B2", "B", "A"], "action and day together");
}

#[sqlx::test(migrations = "../../migrations")]
async fn data_comes_back_as_text(pool: PgPool) {
    seed(&pool).await;
    let app = common::app(pool.clone());
    let (owner, _) = staff_token(&pool, Role::StaffAdmin).await;
    let (_, _, page) = get_page(&app, "/v1/admin/audit?target=A", &owner).await;
    let row = &page[0];
    assert!(row["data_text"].is_string(), "data is a string: {row}");
    assert!(row["data_text"].as_str().unwrap_or_default().contains("5000"), "{row}");
    assert!(row.get("data").is_none(), "no structured data field: {row}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn bad_filters_and_cursors_are_refused(pool: PgPool) {
    seed(&pool).await;
    let app = common::app(pool.clone());
    let (owner, _) = staff_token(&pool, Role::StaffAdmin).await;
    let long_target = "x".repeat(201);
    let bad = [
        "action=Case.Refund".to_owned(),
        "action=case%25".to_owned(),
        "actor_role=root".to_owned(),
        "actor_id=not-a-uuid".to_owned(),
        "from=2026-13-01".to_owned(),
        "from=2026-05-05&to=2026-05-01".to_owned(),
        format!("target={long_target}"),
        "limit=0".to_owned(),
        "cursor=!!!".to_owned(),
    ];
    for query in bad {
        let uri = format!("/v1/admin/audit?{query}");
        let (st, _, body) = get_page(&app, &uri, &owner).await;
        assert_eq!(st, StatusCode::BAD_REQUEST, "{uri}: {body}");
    }
}
