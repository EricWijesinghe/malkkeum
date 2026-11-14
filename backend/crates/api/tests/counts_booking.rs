//! Counts services over the real router: a booking takes one count per option, prices it on the
//! server and returns the counts. Legacy unit_index bookings (mattress) keep working.

mod common;

use axum::http::StatusCode;
use common::{call, customer, seed_catalog};
use serde_json::{Value, json};
use sqlx::PgPool;

async fn book_counts(app: &axum::Router, c: &common::Customer, service: &str, counts: Value) -> (StatusCode, Value) {
    let visit = api::util::today_kst() + chrono::Duration::days(10);
    call(
        app,
        "POST",
        "/v1/bookings",
        Some(c.token.as_str()),
        Some(json!({
            "service_code": service,
            "counts": counts,
            "address_id": c.address,
            "visit_date": visit,
            "start_hour": 9,
            "visit_notes": {},
            "payment_method_id": c.card
        })),
    )
    .await
}

#[sqlx::test(migrations = "../../migrations")]
async fn aircon_counts_book_price_and_read_back_unit_counts(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5100-0001").await;
    // 2 stand + 1 wall: 317,000 less 10% = 285,300, 5 h 30 min.
    let (st, b) = book_counts(&app, &c, "aircon", json!([1, 2, 0, 0])).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert_eq!(b["unit_counts"], json!([1, 2, 0, 0]), "{b}");
    assert_eq!((b["paid_amount"].as_i64(), b["minutes"].as_i64()), (Some(285_300), Some(330)), "{b}");

    let id = b["id"].as_str().expect("id");
    let (st, read) = call(&app, "GET", &format!("/v1/bookings/{id}"), Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{read}");
    assert_eq!(read["unit_counts"], json!([1, 2, 0, 0]), "{read}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn disinfection_multi_select_takes_ten_percent_off(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5100-0002").await;
    // Pest 80,000 + sick house 300,000 = 380,000, less 10%.
    let (st, b) = book_counts(&app, &c, "disinfection", json!([1, 0, 0, 1])).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert_eq!((b["paid_amount"].as_i64(), b["minutes"].as_i64()), (Some(342_000), Some(330)), "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn disinfection_refuses_a_kind_twice(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5100-0003").await;
    let (st, b) = book_counts(&app, &c, "disinfection", json!([2, 0, 0, 0])).await;
    assert!(st.is_client_error(), "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn counts_with_the_wrong_length_are_refused(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5100-0004").await;
    let (st, b) = book_counts(&app, &c, "window", json!([1])).await;
    assert!(st.is_client_error(), "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn legacy_mattress_unit_index_books_one_mattress(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5100-0005").await;
    let visit = api::util::today_kst() + chrono::Duration::days(10);
    let (st, b) = call(
        &app,
        "POST",
        "/v1/bookings",
        Some(c.token.as_str()),
        Some(json!({
            "service_code": "mattress",
            "unit_index": 0,
            "address_id": c.address,
            "visit_date": visit,
            "start_hour": 9,
            "visit_notes": {},
            "payment_method_id": c.card
        })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert_eq!((b["unit_counts"].clone(), b["paid_amount"].as_i64()), (json!([1]), Some(59_000)), "{b}");
}
