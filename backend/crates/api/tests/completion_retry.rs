//! A retried completion (the first response was lost on a bad signal) returns the first result, once.

mod common;

use axum::http::StatusCode;
use common::{PHOTO, book, call, customer, seed_catalog, verified_pro};
use serde_json::json;
use sqlx::PgPool;

#[sqlx::test(migrations = "../../migrations")]
async fn retried_completion_returns_the_first_result_without_a_second_settlement(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5000-0601").await;
    let (id, _) = book(&app, &c, 10, None).await;
    let (pro, pro_id) = verified_pro(&app, &pool, "010-5000-0602").await;
    let (st, b) = call(&app, "POST", &format!("/v1/partner/jobs/{id}/accept"), Some(pro.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    sqlx::query("UPDATE bookings SET visit_date = (now() AT TIME ZONE 'Asia/Seoul')::date WHERE id = $1")
        .bind(id)
        .execute(&pool)
        .await
        .expect("visit today");
    let (st, b) = call(&app, "POST", &format!("/v1/partner/jobs/{id}/check-in"), Some(pro.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    common::register_photo(&pool, pro_id).await;
    let done = json!({ "before_photos": [PHOTO], "after_photos": [PHOTO], "checklist": [true, true, true, true] });
    let url = format!("/v1/partner/jobs/{id}/complete");
    let (st, first) = call(&app, "POST", &url, Some(pro.as_str()), Some(done.clone())).await;
    assert_eq!(st, StatusCode::OK, "{first}");
    let (st, again) = call(&app, "POST", &url, Some(pro.as_str()), Some(done)).await;
    assert_eq!(st, StatusCode::OK, "{again}");
    assert_eq!(again["net"], first["net"]);
    assert_eq!(again["payout_date"], first["payout_date"]);
    let n: i64 = sqlx::query_scalar("SELECT count(*) FROM settlements WHERE booking_id = $1")
        .bind(id)
        .fetch_one(&pool)
        .await
        .expect("count");
    assert_eq!(n, 1, "one settlement per job");
}
