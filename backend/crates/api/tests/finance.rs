//! Owner finance over a migrated Postgres: the summary, partner and CSV numbers match hand-computed seed rows.
//! Needs DATABASE_URL (sqlx::test). Rows are inserted directly so every figure is known in advance.

mod common;

use api::auth::{self, Role};
use axum::{
    body::Body,
    http::{Request, StatusCode, header},
};
use common::{SECRET, call, seed_catalog};
use serde_json::json;
use sqlx::PgPool;
use tower::ServiceExt;
use uuid::Uuid;

const PERIOD: &str = "/v1/admin/finance/summary?period=custom&from=2026-03-01&to=2026-03-31";

async fn insert_booking(db: &PgPool, user: Uuid, number: &str, final_price: i64, discount: i64, status: i16, created: &str) -> Uuid {
    sqlx::query_scalar(
        "INSERT INTO bookings (number, user_id, service_code, address, district_code, visit_date, start_hour, status, final_price, list_price, discount, cancelled_at, created_at)
         VALUES ($1, $2, 'studio', '{}'::jsonb, '11680', '2026-03-15', 10, $3, $4, $4, $5,
                 CASE WHEN $3 = -1 THEN $6::timestamptz + interval '1 day' END, $6::timestamptz)
         RETURNING id",
    )
    .bind(number)
    .bind(user)
    .bind(status)
    .bind(final_price)
    .bind(discount)
    .bind(created)
    .fetch_one(db)
    .await
    .expect("booking")
}

#[allow(clippy::too_many_arguments)]
async fn insert_payment(db: &PgPool, booking: Uuid, amount: i64, refunded: i64, status: &str, key: &str, created: &str) {
    sqlx::query(
        "INSERT INTO payments (booking_id, amount, kind, status, refunded_amount, provider, idempotency_key, created_at)
         VALUES ($1, $2, 'full', $3, $4, 'fake', $5, $6::timestamptz)",
    )
    .bind(booking)
    .bind(amount)
    .bind(status)
    .bind(refunded)
    .bind(key)
    .bind(created)
    .execute(db)
    .await
    .expect("payment");
}

#[allow(clippy::too_many_arguments)]
async fn insert_settlement(db: &PgPool, pro: Uuid, booking: Uuid, gross: i64, fee: i64, state: &str, payout: &str, paid_at: Option<&str>, created: &str) {
    sqlx::query(
        "INSERT INTO settlements (pro_id, booking_id, gross, fee, net, payout_date, state, paid_at, created_at)
         VALUES ($1, $2, $3, $4, $3 - $4, $5::date, $6, $7::timestamptz, $8::timestamptz)",
    )
    .bind(pro)
    .bind(booking)
    .bind(gross)
    .bind(fee)
    .bind(payout)
    .bind(state)
    .bind(paid_at)
    .bind(created)
    .execute(db)
    .await
    .expect("settlement");
}

/// Three March bookings plus one out-of-period booking, with payments, settlements and checkouts.
async fn seed_march(db: &PgPool) -> Uuid {
    seed_catalog(db).await;
    let user: Uuid = sqlx::query_scalar("INSERT INTO users (phone, name) VALUES ('01070000001', 'fin') RETURNING id").fetch_one(db).await.expect("user");
    let pro: Uuid = sqlx::query_scalar(
        "INSERT INTO pros (phone, name, team_name, status) VALUES ('01070000101', 'pro', 'team', 'verified') RETURNING id",
    )
    .fetch_one(db)
    .await
    .expect("pro");

    // Completed and paid out on 2026-03-11.
    let b1 = insert_booking(db, user, "BKF-1", 100_000, 10_000, 3, "2026-03-05T10:00:00+09").await;
    insert_payment(db, b1, 90_000, 0, "paid", "fin-1", "2026-03-05T10:00:00+09").await;
    insert_settlement(db, pro, b1, 100_000, 20_000, "paid", "2026-03-11", Some("2026-03-11T12:00:00+09"), "2026-03-06T09:00:00+09").await;

    // Cancelled after payment: full refund on the cancel day (2026-03-09).
    let b2 = insert_booking(db, user, "BKF-2", 50_000, 0, -1, "2026-03-08T10:00:00+09").await;
    insert_payment(db, b2, 50_000, 50_000, "refunded", "fin-2", "2026-03-08T10:00:00+09").await;

    // Completed, awaiting the 2026-03-25 payout.
    let b3 = insert_booking(db, user, "BKF-3", 200_000, 0, 3, "2026-03-20T10:00:00+09").await;
    insert_payment(db, b3, 200_000, 0, "paid", "fin-3", "2026-03-20T10:00:00+09").await;
    insert_settlement(db, pro, b3, 200_000, 40_000, "pending", "2026-03-25", None, "2026-03-21T09:00:00+09").await;

    // Outside March: must not leak into any March figure.
    let old = insert_booking(db, user, "BKF-0", 999_000, 0, 3, "2026-02-27T10:00:00+09").await;
    insert_payment(db, old, 999_000, 0, "paid", "fin-0", "2026-02-27T10:00:00+09").await;

    for (key, method, amount, status) in [("ck-1", "card", 90_000, "paid"), ("ck-2", "kakaopay", 200_000, "paid"), ("ck-3", "card", 50_000, "failed")] {
        sqlx::query(
            "INSERT INTO checkouts (user_id, kind, method, amount, status, expires_at, created_at, provider_payment_id)
             VALUES ($1, 'booking', $2, $3, $4, now() + interval '1 day', '2026-03-10T10:00:00+09', $5)",
        )
        .bind(user)
        .bind(method)
        .bind(amount)
        .bind(status)
        .bind(key)
        .execute(db)
        .await
        .expect("checkout");
    }
    pro
}

async fn admin_token() -> String {
    auth::issue_access(SECRET, Uuid::now_v7(), Role::StaffAdmin).expect("token")
}

#[sqlx::test(migrations = "../../migrations")]
async fn summary_matches_the_seeded_march_numbers(pool: PgPool) {
    seed_march(&pool).await;
    let app = common::app(pool.clone());
    let (status, s) = call(&app, "GET", PERIOD, Some(&admin_token().await), None).await;
    assert_eq!(status, StatusCode::OK, "{s}");
    assert_eq!(s["bookings"], 3);
    assert_eq!(s["cancelled"], 1);
    assert_eq!(s["cancellation_bps"], 3_333);
    assert_eq!(s["avg_order_value"], 150_000, "(100k + 200k) / 2 active");
    assert_eq!(s["discount"], 10_000);
    assert_eq!(s["gross"], 340_000);
    assert_eq!(s["refunds"], 50_000);
    assert_eq!(s["net_revenue"], 290_000);
    assert_eq!(s["platform_fee"], 60_000);
    assert_eq!(s["vat_estimate"], 6_000);
    assert_eq!(s["payouts"]["paid"], 80_000);
    assert_eq!(s["payouts"]["pending"], 160_000);
    assert_eq!(s["payouts"]["held"], 0);
    assert_eq!(s["vat_basis"], "platform_fee_10pct_estimate");
    let methods = s["payment_methods"].as_array().expect("methods");
    assert_eq!(methods.len(), 2, "failed checkout is excluded: {s}");
    assert_eq!(methods[0]["method"], "kakaopay");
    assert_eq!(methods[0]["amount"], 200_000);
    assert_eq!(methods[1]["method"], "card");
    assert_eq!(methods[1]["amount"], 90_000);
}

#[sqlx::test(migrations = "../../migrations")]
async fn partner_table_and_service_table_agree_with_the_summary(pool: PgPool) {
    seed_march(&pool).await;
    let app = common::app(pool.clone());
    let token = admin_token().await;
    let (_, partners) = call(&app, "GET", "/v1/admin/finance/partners?period=custom&from=2026-03-01&to=2026-03-31", Some(&token), None).await;
    let p = &partners[0];
    assert_eq!(p["name"], "pro");
    assert_eq!(p["jobs"], 2);
    assert_eq!(p["settled_gross"], 300_000);
    assert_eq!(p["fee"], 60_000);
    assert_eq!(p["net"], 240_000);
    assert_eq!(p["paid"], 80_000);
    assert_eq!(p["pending"], 160_000);

    let (_, services) = call(&app, "GET", "/v1/admin/finance/services?period=custom&from=2026-03-01&to=2026-03-31", Some(&token), None).await;
    assert_eq!(services[0]["service_code"], "studio");
    assert_eq!(services[0]["gross"], 340_000);
    assert_eq!(services[0]["net_revenue"], 290_000);
}

#[sqlx::test(migrations = "../../migrations")]
async fn series_shapes_and_grain_validation(pool: PgPool) {
    seed_march(&pool).await;
    let app = common::app(pool.clone());
    let token = admin_token().await;
    let (status, days) = call(&app, "GET", "/v1/admin/finance/series?grain=day&days=30", Some(&token), None).await;
    assert_eq!(status, StatusCode::OK, "{days}");
    assert_eq!(days.as_array().map(Vec::len), Some(30));
    let (_, weeks) = call(&app, "GET", "/v1/admin/finance/series?grain=week", Some(&token), None).await;
    assert_eq!(weeks.as_array().map(Vec::len), Some(12));
    let (_, months) = call(&app, "GET", "/v1/admin/finance/series?grain=month", Some(&token), None).await;
    assert_eq!(months.as_array().map(Vec::len), Some(12));
    let (status, _) = call(&app, "GET", "/v1/admin/finance/series?grain=year", Some(&token), None).await;
    assert_eq!(status, StatusCode::BAD_REQUEST);
}

#[sqlx::test(migrations = "../../migrations")]
async fn exports_are_bom_csv_with_guarded_cells_and_admin_only(pool: PgPool) {
    seed_march(&pool).await;
    let app = common::app(pool.clone());
    let token = admin_token().await;
    let uri = "/v1/admin/finance/export/monthly?period=custom&from=2026-03-01&to=2026-03-31";
    let req = Request::builder()
        .method("GET")
        .uri(uri)
        .header(header::AUTHORIZATION, format!("Bearer {token}"))
        .body(Body::empty())
        .expect("request");
    let resp = app.clone().oneshot(req).await.expect("router");
    assert_eq!(resp.status(), StatusCode::OK);
    assert_eq!(resp.headers()[header::CONTENT_TYPE], "text/csv; charset=utf-8");
    let bytes = axum::body::to_bytes(resp.into_body(), usize::MAX).await.expect("body");
    let text = String::from_utf8(bytes.to_vec()).expect("utf8");
    assert!(text.starts_with('\u{feff}'), "BOM first");
    let lines: Vec<&str> = text.trim_start_matches('\u{feff}').lines().collect();
    assert_eq!(lines[0].split(',').count(), 11);
    assert_eq!(lines[1], "2026-03,3,1,340000,50000,290000,60000,6000,80000,160000,0");
    assert!(lines.last().expect("total").starts_with("합계,"));

    // A consultant (staff, not owner) may read the summary but not export.
    let consultant = auth::issue_access(SECRET, Uuid::now_v7(), Role::StaffConsultant).expect("token");
    let (s, _) = call(&app, "GET", uri, Some(&consultant), None).await;
    assert_eq!(s, StatusCode::FORBIDDEN);
    let (s, _) = call(&app, "GET", PERIOD, Some(&consultant), None).await;
    assert_eq!(s, StatusCode::OK);
}

#[sqlx::test(migrations = "../../migrations")]
async fn partner_earnings_show_the_next_payout_and_hide_from_members(pool: PgPool) {
    let pro = seed_march(&pool).await;
    let app = common::app(pool.clone());
    let token = auth::issue_access(SECRET, pro, Role::Pro).expect("token");
    let (status, e) = call(&app, "GET", "/v1/partner/earnings?grain=month", Some(&token), None).await;
    assert_eq!(status, StatusCode::OK, "{e}");
    assert_eq!(e["next_payout"], json!({ "date": "2026-03-25", "amount": 160_000, "count": 1 }));
    assert_eq!(e["pending_total"], 160_000);
    assert_eq!(e["paid_total"], 80_000);
    assert_eq!(e["series"].as_array().map(Vec::len), Some(12));

    let member = auth::issue_access(SECRET, Uuid::now_v7(), Role::Member).expect("token");
    let (s, _) = call(&app, "GET", "/v1/partner/earnings", Some(&member), None).await;
    assert_eq!(s, StatusCode::FORBIDDEN);
    let (s, _) = call(&app, "GET", "/v1/partner/earnings", Some(&token), None).await;
    assert_eq!(s, StatusCode::OK);
}
