//! Review reports (Play UGC policy): one report per user, the threshold queues for staff (never auto-hides), the staff
//! queue and decisions, and blocked review authors. Same DB and fakes as growth.rs.

mod common;

use api::auth::{self, Role};
use axum::http::StatusCode;
use common::{Customer, PHOTO, SECRET, book, call, customer, seed_catalog, verified_pro};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

async fn complete_job(app: &axum::Router, pool: &PgPool, id: Uuid, pro: &str) {
    let (st, b) = call(app, "POST", &format!("/v1/partner/jobs/{id}/accept"), Some(pro), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    sqlx::query("UPDATE bookings SET visit_date = (now() AT TIME ZONE 'Asia/Seoul')::date WHERE id = $1")
        .bind(id)
        .execute(pool)
        .await
        .expect("today");
    let pro_id: Uuid = sqlx::query_scalar("SELECT pro_id FROM bookings WHERE id = $1")
        .bind(id)
        .fetch_one(pool)
        .await
        .expect("pro");
    let (st, b) = call(app, "POST", &format!("/v1/partner/jobs/{id}/check-in"), Some(pro), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    common::register_photo(pool, pro_id).await;
    let done = json!({ "before_photos": [PHOTO], "after_photos": [PHOTO], "checklist": [true, true, true, true] });
    let (st, b) = call(app, "POST", &format!("/v1/partner/jobs/{id}/complete"), Some(pro), Some(done)).await;
    assert_eq!(st, StatusCode::OK, "{b}");
}

/// A customer with a completed booking with `pro` (the booking is moved to the pro directly).
async fn customer_who_booked(app: &axum::Router, pool: &PgPool, pro: Uuid, phone: &str, days: i64) -> Customer {
    let c = customer(app, pool, phone).await;
    let (booking, _) = book(app, &c, days, None).await;
    sqlx::query("UPDATE bookings SET pro_id = $1, status = 3 WHERE id = $2")
        .bind(pro)
        .bind(booking)
        .execute(pool)
        .await
        .expect("complete");
    c
}

async fn review_state(pool: &PgPool, id: Uuid) -> (bool, bool) {
    sqlx::query_as("SELECT hidden, report_pending FROM reviews WHERE booking_id = $1")
        .bind(id)
        .fetch_one(pool)
        .await
        .expect("review")
}

async fn reviewed_booking(app: &axum::Router, pool: &PgPool, pro: &str, author_phone: &str) -> Uuid {
    let author = customer(app, pool, author_phone).await;
    let (id, _) = book(app, &author, 10, None).await;
    complete_job(app, pool, id, pro).await;
    let (st, b) = call(
        app,
        "POST",
        &format!("/v1/bookings/{id}/review"),
        Some(author.token.as_str()),
        Some(json!({ "rating": 5, "body": "좋아요", "photos": [] })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{b}");
    id
}

async fn public_review_ids(app: &axum::Router) -> Vec<String> {
    let (_, proof) = call(app, "GET", "/v1/public/proof", None, None).await;
    proof["reviews"]
        .as_array()
        .expect("reviews")
        .iter()
        .map(|r| r["booking_id"].as_str().unwrap_or_default().to_string())
        .collect()
}

#[sqlx::test(migrations = "../../migrations")]
async fn reports_are_validated_once_per_user_and_hide_at_the_threshold(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let author = customer(&app, &pool, "010-5300-0001").await;
    let (pro, pro_id) = verified_pro(&app, &pool, "010-5300-0101").await;
    let (id, _) = book(&app, &author, 10, None).await;
    complete_job(&app, &pool, id, pro.as_str()).await;
    let (st, b) = call(
        &app,
        "POST",
        &format!("/v1/bookings/{id}/review"),
        Some(author.token.as_str()),
        Some(json!({ "rating": 5, "body": "좋아요", "photos": [] })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let uri = format!("/v1/reviews/{id}/report");
    let spam = json!({ "reason": "spam", "note": "" });

    let (st, _) = call(&app, "POST", &uri, Some(author.token.as_str()), Some(spam.clone())).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "own review cannot be reported");
    let (st, _) = call(&app, "POST", &uri, Some(author.token.as_str()), Some(json!({ "reason": "rude", "note": "" }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "unknown reason");
    let long = json!({ "reason": "other", "note": "가".repeat(301) });
    let reporter = customer_who_booked(&app, &pool, pro_id, "010-5300-0002", 11).await;
    let (st, _) = call(&app, "POST", &uri, Some(reporter.token.as_str()), Some(long)).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "note is at most 300 characters");
    let (st, _) = call(
        &app,
        "POST",
        &format!("/v1/reviews/{}/report", Uuid::now_v7()),
        Some(reporter.token.as_str()),
        Some(spam.clone()),
    )
    .await;
    assert_eq!(st, StatusCode::NOT_FOUND, "unknown review");

    let (st, b) = call(&app, "POST", &uri, Some(reporter.token.as_str()), Some(spam.clone())).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (st, b) = call(&app, "POST", &uri, Some(reporter.token.as_str()), Some(spam)).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::CONFLICT, Some("already_reported")), "{b}");
    assert!(public_review_ids(&app).await.contains(&id.to_string()), "one report of three does not hide");

    let second = customer_who_booked(&app, &pool, pro_id, "010-5300-0003", 12).await;
    call(
        &app,
        "POST",
        &uri,
        Some(second.token.as_str()),
        Some(json!({ "reason": "offensive", "note": "" })),
    )
    .await;
    let third = customer_who_booked(&app, &pool, pro_id, "010-5300-0004", 13).await;
    let (st, _) = call(
        &app,
        "POST",
        &uri,
        Some(third.token.as_str()),
        Some(json!({ "reason": "personal_info", "note": "전화번호 포함" })),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    assert_eq!(
        review_state(&pool, id).await,
        (false, true),
        "three distinct reports queue it for staff, it stays visible"
    );
    assert!(public_review_ids(&app).await.contains(&id.to_string()), "reports never hide on their own");

    let staff = auth::issue_access(SECRET, Uuid::now_v7(), Role::StaffAdmin).expect("token");
    let consultant = auth::issue_access(SECRET, Uuid::now_v7(), Role::StaffConsultant).expect("token");
    let (st, q) = call(&app, "GET", "/v1/admin/reviews/reports", Some(consultant.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{q}");
    let item = &q[0];
    assert_eq!(item["booking_id"], id.to_string());
    assert_eq!(item["reports"].as_array().map(Vec::len), Some(3), "{item}");
    assert!(item["reports"][0].get("reporter_id").is_none(), "reporter identity stays hidden");

    let (st, _) = call(
        &app,
        "PUT",
        &format!("/v1/admin/reviews/{id}/decision"),
        Some(consultant.as_str()),
        Some(json!({ "action": "keep" })),
    )
    .await;
    assert_eq!(st, StatusCode::FORBIDDEN, "only the admin decides");
    let (st, _) = call(
        &app,
        "PUT",
        &format!("/v1/admin/reviews/{id}/decision"),
        Some(staff.as_str()),
        Some(json!({ "action": "keep" })),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    assert!(public_review_ids(&app).await.contains(&id.to_string()), "keep shows it again");
    let (_, q) = call(&app, "GET", "/v1/admin/reviews/reports", Some(staff.as_str()), None).await;
    assert_eq!(q.as_array().map(Vec::len), Some(0), "keep clears the queue");
    let n: i64 = sqlx::query_scalar("SELECT count(*) FROM review_reports WHERE booking_id = $1")
        .bind(id)
        .fetch_one(&pool)
        .await
        .expect("count");
    assert_eq!(n, 0, "keep clears the reports");

    let (st, _) = call(
        &app,
        "PUT",
        &format!("/v1/admin/reviews/{id}/decision"),
        Some(staff.as_str()),
        Some(json!({ "action": "delete" })),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    let (st, _) = call(
        &app,
        "PUT",
        &format!("/v1/admin/reviews/{id}/decision"),
        Some(staff.as_str()),
        Some(json!({ "action": "hide" })),
    )
    .await;
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
    let (st, b) = call(
        &app,
        "POST",
        &format!("/v1/bookings/{id}/review"),
        Some(author.token.as_str()),
        Some(json!({ "rating": 5, "body": "첫 후기", "photos": [] })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (id2, _) = book(&app, &author, 12, None).await;
    complete_job(&app, &pool, id2, pro.as_str()).await;
    let staff = auth::issue_access(SECRET, Uuid::now_v7(), Role::StaffAdmin).expect("token");

    let (st, _) = call(
        &app,
        "PUT",
        &format!("/v1/admin/reviews/{id}/author"),
        Some(staff.as_str()),
        Some(json!({ "blocked": true })),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    let (st, b) = call(
        &app,
        "POST",
        &format!("/v1/bookings/{id2}/review"),
        Some(author.token.as_str()),
        Some(json!({ "rating": 4, "body": "", "photos": [] })),
    )
    .await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::CONFLICT, Some("review_blocked")), "{b}");
    let (st, _) = call(
        &app,
        "PUT",
        &format!("/v1/admin/reviews/{id}/author"),
        Some(staff.as_str()),
        Some(json!({ "blocked": false })),
    )
    .await;
    assert_eq!(st, StatusCode::OK);
    let (st, _) = call(
        &app,
        "POST",
        &format!("/v1/bookings/{id2}/review"),
        Some(author.token.as_str()),
        Some(json!({ "rating": 4, "body": "", "photos": [] })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "unblocked author can review again");
}

#[sqlx::test(migrations = "../../migrations")]
async fn reports_from_accounts_without_a_completed_booking_only_queue_the_review(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let (pro, _) = verified_pro(&app, &pool, "010-5310-0101").await;
    let id = reviewed_booking(&app, &pool, &pro, "010-5310-0001").await;
    let uri = format!("/v1/reviews/{id}/report");
    for (i, phone) in ["010-5310-0002", "010-5310-0003", "010-5310-0004"].into_iter().enumerate() {
        let throwaway = customer(&app, &pool, phone).await;
        let (st, b) = call(
            &app,
            "POST",
            &uri,
            Some(throwaway.token.as_str()),
            Some(json!({ "reason": "spam", "note": format!("{i}") })),
        )
        .await;
        assert_eq!(st, StatusCode::OK, "{b}");
    }
    assert_eq!(
        review_state(&pool, id).await,
        (false, true),
        "three throwaway accounts cannot hide it, staff decide"
    );
    assert!(public_review_ids(&app).await.contains(&id.to_string()));
}

#[sqlx::test(migrations = "../../migrations")]
async fn the_pro_and_its_team_cannot_hide_a_review_by_reporting(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let (pro, pro_id) = verified_pro(&app, &pool, "010-5320-0101").await;
    let id = reviewed_booking(&app, &pool, &pro, "010-5320-0001").await;
    let uri = format!("/v1/reviews/{id}/report");

    // The pro's own login token is not a customer: it cannot report at all.
    let (st, _) = call(&app, "POST", &uri, Some(pro.as_str()), Some(json!({ "reason": "spam", "note": "" }))).await;
    assert_eq!(st, StatusCode::FORBIDDEN);

    // A team member and the pro's own phone, each with a customer account that has a completed booking with this pro.
    let member = customer_who_booked(&app, &pool, pro_id, "010-5320-0002", 11).await;
    let owner = customer_who_booked(&app, &pool, pro_id, "010-5320-0003", 12).await;
    let member_phone: String = sqlx::query_scalar("SELECT phone FROM users WHERE id = $1")
        .bind(member.user)
        .fetch_one(&pool)
        .await
        .expect("phone");
    sqlx::query("INSERT INTO team_members (pro_id, name, phone, role, invite_status) VALUES ($1, 'Member', $2, 'member', 'active')")
        .bind(pro_id)
        .bind(&member_phone)
        .execute(&pool)
        .await
        .expect("team member");
    sqlx::query("UPDATE users SET phone = (SELECT phone FROM pros WHERE id = $1) WHERE id = $2")
        .bind(pro_id)
        .bind(owner.user)
        .execute(&pool)
        .await
        .expect("same phone as pro");
    let honest = customer_who_booked(&app, &pool, pro_id, "010-5320-0004", 13).await;

    for who in [&member, &owner, &honest] {
        let (st, b) = call(&app, "POST", &uri, Some(who.token.as_str()), Some(json!({ "reason": "offensive", "note": "" }))).await;
        assert_eq!(st, StatusCode::OK, "{b}");
    }
    assert_eq!(
        review_state(&pool, id).await,
        (false, true),
        "one real customer plus the pro's own people: queued, not hidden"
    );

    let second = customer_who_booked(&app, &pool, pro_id, "010-5320-0005", 14).await;
    let third = customer_who_booked(&app, &pool, pro_id, "010-5320-0006", 15).await;
    for who in [&second, &third] {
        call(&app, "POST", &uri, Some(who.token.as_str()), Some(json!({ "reason": "offensive", "note": "" }))).await;
    }
    assert_eq!(review_state(&pool, id).await, (false, true), "reaching the threshold queues it, never hides it");
}
