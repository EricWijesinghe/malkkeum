//! Tax-invoice CSV export is idempotent: a second export returns no rows, and a confirmed re-export sends the same
//! rows again without clearing exported_at. Needs DATABASE_URL (sqlx::test).

mod common;

use api::auth::{self, Role};
use axum::{
    Router,
    body::Body,
    extract::ConnectInfo,
    http::{Request, StatusCode, header},
};
use common::{SECRET, seed_catalog};
use sqlx::PgPool;
use std::net::SocketAddr;
use tower::ServiceExt;
use uuid::Uuid;

const EXPORT: &str = "/v1/admin/finance/export/tax-invoices?period=custom&from=2026-03-01&to=2026-03-31";
const RE_EXPORT: &str = "/v1/admin/finance/export/tax-invoices/re-export?period=custom&from=2026-03-01&to=2026-03-31";

/// Sends one request and returns the status and the raw body (the export is CSV, not JSON).
async fn send(app: &Router, method: &str, uri: &str) -> (StatusCode, String) {
    let token = auth::issue_access(SECRET, Uuid::now_v7(), Role::StaffAdmin).expect("token");
    let mut request = Request::builder()
        .method(method)
        .uri(uri)
        .header(header::AUTHORIZATION, format!("Bearer {token}"))
        .body(Body::empty())
        .expect("request");
    request.extensions_mut().insert(ConnectInfo(SocketAddr::from(([127, 0, 0, 1], 40_000))));
    let resp = app.clone().oneshot(request).await.expect("router is infallible");
    let status = resp.status();
    let bytes = axum::body::to_bytes(resp.into_body(), usize::MAX).await.expect("response body");
    (status, String::from_utf8_lossy(&bytes).into_owned())
}

/// Two queued (state 'requested') invoices in March, each with a paid payment.
async fn seed_requests(db: &PgPool) {
    seed_catalog(db).await;
    let user: Uuid = sqlx::query_scalar("INSERT INTO users (phone, name) VALUES ('01070000201', 'tax') RETURNING id")
        .fetch_one(db)
        .await
        .expect("user");
    for (i, company) in ["ACME-ONE", "ACME-TWO"].iter().enumerate() {
        let booking: Uuid = sqlx::query_scalar(
            "INSERT INTO bookings (number, user_id, service_code, address, district_code, visit_date, start_hour, status, final_price, list_price, discount, created_at)
             VALUES ($1, $2, 'studio', '{}'::jsonb, '11680', '2026-03-15', 10, 3, 110000, 110000, 0, '2026-03-05T10:00:00+09'::timestamptz)
             RETURNING id",
        )
        .bind(format!("BKT-{i}"))
        .bind(user)
        .fetch_one(db)
        .await
        .expect("booking");
        let payment: Uuid = sqlx::query_scalar(
            "INSERT INTO payments (booking_id, amount, kind, status, provider, idempotency_key, created_at)
             VALUES ($1, 110000, 'full', 'paid', 'fake', $2, '2026-03-05T10:00:00+09'::timestamptz) RETURNING id",
        )
        .bind(booking)
        .bind(format!("tax-{i}"))
        .fetch_one(db)
        .await
        .expect("payment");
        let checkout: Uuid = sqlx::query_scalar(
            "INSERT INTO checkouts (user_id, kind, booking_id, method, amount, status, expires_at, created_at)
             VALUES ($1, 'booking', $2, 'card', 110000, 'paid', now() + interval '1 day', '2026-03-05T10:00:00+09'::timestamptz)
             RETURNING id",
        )
        .bind(user)
        .bind(booking)
        .fetch_one(db)
        .await
        .expect("checkout");
        sqlx::query(
            "INSERT INTO tax_invoice_requests (checkout_id, payment_id, business_number, company_name, email, state, created_at)
             VALUES ($1, $2, '2208162517', $3, 'tax@example.test', 'requested', '2026-03-05T10:00:00+09'::timestamptz)",
        )
        .bind(checkout)
        .bind(payment)
        .bind(*company)
        .execute(db)
        .await
        .expect("tax invoice request");
    }
}

#[sqlx::test(migrations = "../../migrations")]
async fn second_export_returns_no_rows(pool: PgPool) {
    seed_requests(&pool).await;
    let app = common::app(pool.clone());

    let (status, first) = send(&app, "GET", EXPORT).await;
    assert_eq!(status, StatusCode::OK, "{first}");
    assert!(first.contains("ACME-ONE") && first.contains("ACME-TWO"), "first export: {first}");

    let (status, second) = send(&app, "GET", EXPORT).await;
    assert_eq!(status, StatusCode::OK, "{second}");
    assert!(!second.contains("ACME-"), "second export must be empty: {second}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn re_export_requires_confirm_and_returns_the_same_rows(pool: PgPool) {
    seed_requests(&pool).await;
    let app = common::app(pool.clone());
    let (status, _) = send(&app, "GET", EXPORT).await;
    assert_eq!(status, StatusCode::OK);

    let (status, body) = send(&app, "POST", RE_EXPORT).await;
    assert_eq!(status, StatusCode::BAD_REQUEST, "without confirm: {body}");

    let (status, body) = send(&app, "POST", &format!("{RE_EXPORT}&confirm=true")).await;
    assert_eq!(status, StatusCode::OK, "{body}");
    assert!(body.contains("ACME-ONE") && body.contains("ACME-TWO"), "re-export: {body}");

    let exported: i64 = sqlx::query_scalar("SELECT count(*) FROM tax_invoice_requests WHERE exported_at IS NOT NULL")
        .fetch_one(&pool)
        .await
        .expect("count");
    assert_eq!(exported, 2, "re-export must not clear or change exported_at");
    let audited: i64 = sqlx::query_scalar("SELECT count(*) FROM audit_log WHERE action = 'tax_invoice.re_export'")
        .fetch_one(&pool)
        .await
        .expect("audit count");
    assert_eq!(audited, 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn re_export_skips_rows_never_exported(pool: PgPool) {
    seed_requests(&pool).await;
    let app = common::app(pool.clone());

    let (status, body) = send(&app, "POST", &format!("{RE_EXPORT}&confirm=true")).await;
    assert_eq!(status, StatusCode::OK, "{body}");
    assert!(!body.contains("ACME-"), "re-export before any export must hand out nothing: {body}");

    let exported: i64 = sqlx::query_scalar("SELECT count(*) FROM tax_invoice_requests WHERE exported_at IS NOT NULL")
        .fetch_one(&pool)
        .await
        .expect("count");
    assert_eq!(exported, 0, "re-export must not mark rows exported");
}
