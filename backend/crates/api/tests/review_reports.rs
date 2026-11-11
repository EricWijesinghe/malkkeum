//! Review reports (Play UGC policy): one report per user, auto-hide at the threshold, the staff
//! queue and decisions, and blocked review authors. Same DB and fakes as growth.rs.

mod common;

use api::auth::{self, Role};
use axum::http::StatusCode;
use common::{PHOTO, SECRET, book, call, customer, seed_catalog, verified_pro};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

async fn complete_job(app: &axum::Router, pool: &PgPool, id: Uuid, pro: &str) {
    let (st, b) = call(app, "POST", &format!("/v1/partner/jobs/{id}/accept"), Some(pro), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    sqlx::query("UPDATE bookings SET visit_date = (now() AT TIME ZONE 'Asia/Seoul')::date WHERE id = $1").bind(id).execute(pool).await.expect("today");
    let pro_id: Uuid = sqlx::query_scalar("SELECT pro_id FROM bookings WHERE id = $1").bind(id).fetch_one(pool).await.expect("pro");
    common::register_photo(pool, pro_id).await;
    let done = json!({ "before_photos": [PHOTO], "after_photos": [PHOTO], "checklist": [true, true, true, true] });
    let (st, b) = call(app, "POST", &format!("/v1/partner/jobs/{id}/complete"), Some(pro), Some(done)).await;
    assert_eq!(st, StatusCode::OK, "{b}");
}

async fn public_review_ids(app: &axum::Router) -> Vec<String> {
    let (_, proof) = call(app, "GET", "/v1/public/proof", None, None).await;
    proof["reviews"].as_array().expect("reviews").iter().map(|r| r["booking_id"].as_str().unwrap_or_default().to_string()).collect()
}

#[sqlx::test(migrations = "../../migrations")]
async fn reports_are_validated_once_per_user_and_hide_at_the_threshold(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let author = customer(&app, &pool, "010-5300-0001").await;
    let (pro, _) = verified_pro(&app, &pool, "010-5300-0101").await;
    let (id, _) = book(&app, &author, 10, None).await;
    complete_job(&app, &pool, id, pro.as_str()).await;
    let (st, b) = call(&app, "POST", &format!("/v1/bookings/{id}/review"), Some(author.token.as_str()), Some(json!({ "rating": 5, "body": "좋아요", "photos": [] }))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let uri = format!("/v1/reviews/{id}/report");
    let spam = json!({ "reason": "spam", "note": "" });

    let (st, _) = call(&app, "POST", &uri, Some(author.token.as_str()), Some(spam.clone())).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "own review cannot be reported");
    let (st, _) = call(&app, "POST", &uri, Some(author.token.as_str()), Some(json!({ "reason": "rude", "note": "" }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "unknown reason");
    let long = json!({ "reason": "other", "note": "가".repeat(301) });
    let reporter = customer(&app, &pool, "010-5300-0002").await;
    let (st, _) = call(&app, "POST", &uri, Some(reporter.token.as_str()), Some(long)).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "note is at most 300 characters");
    let (st, _) = call(&app, "POST", &format!("/v1/reviews/{}/report", Uuid::now_v7()), Some(reporter.token.as_str()), Some(spam.clone())).await;
    assert_eq!(st, StatusCode::NOT_FOUND, "unknown review");

    let (st, b) = call(&app, "POST", &uri, Some(reporter.token.as_str()), Some(spam.clone())).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (st, b) = call(&app, "POST", &uri, Some(reporter.token.as_str()), Some(spam)).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::CONFLICT, Some("already_reported")), "{b}");
    assert!(public_review_ids(&app).await.contains(&id.to_string()), "one report of three does not hide");

    let second = customer(&app, &pool, "010-5300-0003").await;
    call(&app, "POST", &uri, Some(second.token.as_str()), Some(json!({ "reason": "offensive", "note": "" }))).await;
    let third = customer(&app, &pool, "010-5300-0004").await;
    let (st, _) = call(&app, "POST", &uri, Some(third.token.as_str()), Some(json!({ "reason": "personal_info", "note": "전화번호 포함" }))).await;
    assert_eq!(st, StatusCode::OK);
    assert!(!public_review_ids(&app).await.contains(&id.to_string()), "three distinct reports hide the review");

    let staff = auth::issue_access(SECRET, Uuid::now_v7(), Role::StaffAdmin).expect("token");
    let consultant = auth::issue_access(SECRET, Uuid::now_v7(), Role::StaffConsultant).expect("token");
    let (st, q) = call(&app, "GET", "/v1/admin/reviews/reports", Some(consultant.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{q}");
    let item = &q[0];
    assert_eq!(item["booking_id"], id.to_string());
    assert_eq!(item["reports"].as_array().map(Vec::len), Some(3), "{item}");
    assert!(item["reports"][0].get("reporter_id").is_none(), "reporter identity stays hidden");

    let (st, _) = call(&app, "PUT", &format!("/v1/admin/reviews/{id}/decision"), Some(consultant.as_str()), Some(json!({ "action": "keep" }))).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "only the admin decides");
    let (st, _) = call(&app, "PUT", &format!("/v1/admin/reviews/{id}/decision"), Some(staff.as_str()), Some(json!({ "action": "keep" }))).await;
    assert_eq!(st, StatusCode::OK);
    assert!(public_review_ids(&app).await.contains(&id.to_string()), "keep shows it again");
    let (_, q) = call(&app, "GET", "/v1/admin/reviews/reports", Some(staff.as_str()), None).await;
    assert_eq!(q.as_array().map(Vec::len), Some(0), "keep clears the queue");
    let n: i64 = sqlx::query_scalar("SELECT count(*) FROM review_reports WHERE booking_id = $1").bind(id).fetch_one(&pool).await.expect("count");
    assert_eq!(n, 0, "keep clears the reports");

    let (st, _) = call(&app, "PUT", &format!("/v1/admin/reviews/{id}/decision"), Some(staff.as_str()), Some(json!({ "action": "delete" }))).await;
    assert_eq!(st, StatusCode::OK);
    let (st, _) = call(&app, "PUT", &format!("/v1/admin/reviews/{id}/decision"), Some(staff.as_str()), Some(json!({ "action": "hide" }))).await;
    assert_eq!(st, StatusCode::NOT_FOUND, "deleted review is gone");
}

#[sqlx::test(migrations = "../../migrations")]
async fn blocked_authors_cannot_post_new_reviews(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let author = customer(&app, &pool, "010-5300-0010").await;
    let (pro, _) = verified_pro(&app, &pool, "010-5300-0110").await;
    let (id, _) = book(&app, &author, 10, None).await;
    complete_job(&app, &pool, id, pro.as_str()).await;
    let (st, b) = call(&app, "POST", &format!("/v1/bookings/{id}/review"), Some(author.token.as_str()), Some(json!({ "rating": 5, "body": "첫 후기", "photos": [] }))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (id2, _) = book(&app, &author, 12, None).await;
    complete_job(&app, &pool, id2, pro.as_str()).await;
    let staff = auth::issue_access(SECRET, Uuid::now_v7(), Role::StaffAdmin).expect("token");

    let (st, _) = call(&app, "PUT", &format!("/v1/admin/reviews/{id}/author"), Some(staff.as_str()), Some(json!({ "blocked": true }))).await;
    assert_eq!(st, StatusCode::OK);
    let (st, b) = call(&app, "POST", &format!("/v1/bookings/{id2}/review"), Some(author.token.as_str()), Some(json!({ "rating": 4, "body": "", "photos": [] }))).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::CONFLICT, Some("review_blocked")), "{b}");
    let (st, _) = call(&app, "PUT", &format!("/v1/admin/reviews/{id}/author"), Some(staff.as_str()), Some(json!({ "blocked": false }))).await;
    assert_eq!(st, StatusCode::OK);
    let (st, _) = call(&app, "POST", &format!("/v1/bookings/{id2}/review"), Some(author.token.as_str()), Some(json!({ "rating": 4, "body": "", "photos": [] }))).await;
    assert_eq!(st, StatusCode::OK, "unblocked author can review again");
}
