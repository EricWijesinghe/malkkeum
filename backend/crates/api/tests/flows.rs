//! End-to-end flows over the real router and a migrated Postgres (sqlx::test creates one database per test).
//! Needs DATABASE_URL pointing at a superuser on the local Postgres. Providers run as dev fakes.

mod common;

use api::auth::{self, Role};
use axum::http::StatusCode;
use chrono::{Duration, Utc};
use common::{PHOTO, SECRET, book, call, customer, login, seed_catalog, verified_pro};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

#[sqlx::test(migrations = "../../migrations")]
async fn customer_signs_up_adds_address_and_books_a_paid_job(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5000-0001").await;
    let (_, b) = book(&app, &c, 10, None).await;
    // Paid, waiting for a pro.
    assert_eq!(b["status"], 1, "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn two_pros_racing_for_one_job_get_one_200_and_one_409(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5000-0002").await;
    let (id, _) = book(&app, &c, 10, None).await;
    let (t1, _) = verified_pro(&app, &pool, "010-5000-0101").await;
    let (t2, _) = verified_pro(&app, &pool, "010-5000-0102").await;
    let uri = format!("/v1/partner/jobs/{id}/accept");
    let (a, b) = tokio::join!(
        call(&app, "POST", &uri, Some(t1.as_str()), None),
        call(&app, "POST", &uri, Some(t2.as_str()), None)
    );
    let mut codes = vec![a.0.as_u16(), b.0.as_u16()];
    codes.sort_unstable();
    assert_eq!(codes, vec![200, 409]);
}

#[sqlx::test(migrations = "../../migrations")]
async fn customer_cancel_refunds_the_payment_and_restores_the_coupon(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5000-0003").await;
    let coupon: Uuid =
        sqlx::query_scalar("INSERT INTO coupons (user_id, name, amount, expires_at) VALUES ($1, 'welcome', 5000, now() + interval '30 days') RETURNING id")
            .bind(c.user)
            .fetch_one(&pool)
            .await
            .expect("coupon");
    let (id, b) = book(&app, &c, 10, Some(coupon)).await;
    assert_eq!(b["status"], 1, "{b}");
    let used: Option<Uuid> = sqlx::query_scalar("SELECT used_booking_id FROM coupons WHERE id = $1")
        .bind(coupon)
        .fetch_one(&pool)
        .await
        .expect("coupon row");
    assert_eq!(used, Some(id), "booking spends the coupon");

    let (st, cancelled) = call(&app, "POST", &format!("/v1/bookings/{id}/cancel"), Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{cancelled}");
    assert_eq!(cancelled["status"], -1);

    let (paid, refunded): (i64, i64) =
        sqlx::query_as("SELECT COALESCE(SUM(amount), 0)::bigint, COALESCE(SUM(refunded_amount), 0)::bigint FROM payments WHERE booking_id = $1")
            .bind(id)
            .fetch_one(&pool)
            .await
            .expect("payments");
    assert!(paid > 0, "a payment was taken");
    assert_eq!(refunded, paid, "the payment is fully refunded");
    let used: Option<Uuid> = sqlx::query_scalar("SELECT used_booking_id FROM coupons WHERE id = $1")
        .bind(coupon)
        .fetch_one(&pool)
        .await
        .expect("coupon row");
    assert_eq!(used, None, "coupon is restored");
}

#[sqlx::test(migrations = "../../migrations")]
async fn member_sees_only_the_assigned_job_and_can_complete_it(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5000-0004").await;
    let (job_a, _) = book(&app, &c, 10, None).await;
    let (job_b, _) = book(&app, &c, 11, None).await;
    let (owner, _) = verified_pro(&app, &pool, "010-5000-0201").await;
    for id in [job_a, job_b] {
        let (st, body) = call(&app, "POST", &format!("/v1/partner/jobs/{id}/accept"), Some(owner.as_str()), None).await;
        assert_eq!(st, StatusCode::OK, "{body}");
    }

    let (st, team) = call(
        &app,
        "POST",
        "/v1/partner/team",
        Some(owner.as_str()),
        Some(json!({ "name": "김팀원", "phone": "010-5000-0202" })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{team}");
    let member_id = team["id"].as_str().expect("member id").to_string();
    let (st, assigned) = call(
        &app,
        "POST",
        &format!("/v1/partner/jobs/{job_a}/assign"),
        Some(owner.as_str()),
        Some(json!({ "member_id": member_id })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{assigned}");

    // The invited phone signs in on the partner app and gets a member session.
    let (m, subject) = login(&app, "010-5000-0202", "partner").await;
    assert_eq!(subject, member_id);
    let (st, me) = call(&app, "GET", "/v1/member/me", Some(m.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{me}");

    let from = Utc::now().date_naive();
    let to = from + Duration::days(30);
    let (st, list) = call(&app, "GET", &format!("/v1/member/jobs?from={from}&to={to}"), Some(m.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{list}");
    let ids: Vec<String> = list
        .as_array()
        .expect("job list")
        .iter()
        .filter_map(|r| r["id"].as_str().map(str::to_string))
        .collect();
    assert_eq!(ids, vec![job_a.to_string()]);

    let (st, _) = call(&app, "GET", &format!("/v1/member/jobs/{job_b}"), Some(m.as_str()), None).await;
    assert_eq!(st, StatusCode::NOT_FOUND, "other jobs are invisible to the member");
    let (st, detail) = call(&app, "GET", &format!("/v1/member/jobs/{job_a}"), Some(m.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{detail}");
    assert!(detail.get("payout").is_none(), "members never see payouts");
    assert!(detail["booking"]["address"].is_object(), "full address once assigned");

    // Completion needs a visit that has started: move the visit to today (KST).
    sqlx::query("UPDATE bookings SET visit_date = (now() AT TIME ZONE 'Asia/Seoul')::date WHERE id = $1")
        .bind(job_a)
        .execute(&pool)
        .await
        .expect("visit today");
    common::register_photo(&pool, member_id.parse().expect("member uuid")).await;
    let done_body = json!({ "before_photos": [PHOTO], "after_photos": [PHOTO], "checklist": [true, true, true, true] });
    let (st, done) = call(&app, "POST", &format!("/v1/member/jobs/{job_a}/complete"), Some(m.as_str()), Some(done_body.clone())).await;
    assert_eq!(st, StatusCode::OK, "{done}");
    assert!(done.get("net").is_none(), "no payout in the member response");
    let (status,): (i16,) = sqlx::query_as("SELECT status FROM bookings WHERE id = $1")
        .bind(job_a)
        .fetch_one(&pool)
        .await
        .expect("status");
    assert_eq!(status, 3, "job completed");
    // A retried completion (the first response was lost) gets the same answer and writes nothing new.
    let (st, again) = call(&app, "POST", &format!("/v1/member/jobs/{job_a}/complete"), Some(m.as_str()), Some(done_body)).await;
    assert_eq!(st, StatusCode::OK, "{again}");

    // Owner-only routes stay closed to members.
    let (st, _) = call(&app, "GET", "/v1/partner/me", Some(m.as_str()), None).await;
    assert_eq!(st, StatusCode::FORBIDDEN);
}

#[sqlx::test(migrations = "../../migrations")]
async fn consultant_cannot_edit_content(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let hash = auth::hash_password("consultant-pass-123").expect("hash");
    let id: Uuid = sqlx::query_scalar(
        "INSERT INTO staff (email, name, password_hash, role) VALUES ('consultant@test.local', 'Consultant', $1, 'consultant') RETURNING id",
    )
    .bind(hash)
    .fetch_one(&pool)
    .await
    .expect("staff row");
    let token = auth::issue_access(SECRET, id, Role::StaffConsultant).expect("token");
    let (st, body) = call(&app, "POST", "/v1/admin/content", Some(token.as_str()), Some(json!({}))).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "{body}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn partner_cannot_delete_with_an_assigned_job_but_can_once_free(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let (free, free_id) = verified_pro(&app, &pool, "010-5000-0301").await;
    let (st, b) = call(&app, "DELETE", "/v1/partner/me", Some(free.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let phone: Option<String> = sqlx::query_scalar("SELECT phone FROM pros WHERE id = $1")
        .bind(free_id)
        .fetch_one(&pool)
        .await
        .unwrap();
    assert!(phone.is_none(), "personal data wiped");

    let c = customer(&app, &pool, "010-5000-0302").await;
    let (job, _) = book(&app, &c, 10, None).await;
    let (busy, _) = verified_pro(&app, &pool, "010-5000-0303").await;
    let (st, b) = call(&app, "POST", &format!("/v1/partner/jobs/{job}/accept"), Some(busy.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (st, b) = call(&app, "DELETE", "/v1/partner/me", Some(busy.as_str()), None).await;
    assert_eq!(st, StatusCode::CONFLICT, "{b}");
    assert_eq!(b["error"]["code"], "has_active_jobs");
}

fn move_answers(addons: serde_json::Value) -> serde_json::Value {
    json!({
        "cleaning_type": "standard", "luggage": "empty", "building": "commercial", "layout": "two_rooms",
        "duplex": false, "bathrooms": 1, "balconies": 0, "elevator": true, "floor_3_or_higher": false,
        "ac_addons": addons
    })
}

#[sqlx::test(migrations = "../../migrations")]
async fn estimate_prices_ac_addons_from_the_catalog_with_the_formula_discount(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let (st, plain) = call(&app, "POST", "/v1/quote/estimate", None, Some(move_answers(json!([])))).await;
    assert_eq!(st, StatusCode::OK, "{plain}");
    assert_eq!((plain["addons"].as_i64(), plain["addon_discount_bps"].as_i64()), (Some(0), Some(0)));

    // The owner changes the wall price in the console catalog: the add-on follows it.
    sqlx::query("UPDATE services SET pricing = jsonb_set(pricing, '{units,0,price}', '90000') WHERE code = 'aircon'")
        .execute(&pool)
        .await
        .unwrap();
    let wall2 = move_answers(json!([{"unit": "wall", "count": 2}]));
    let (st, e) = call(&app, "POST", "/v1/quote/estimate", None, Some(wall2)).await;
    assert_eq!(st, StatusCode::OK, "{e}");
    // 2 x 90,000 = 180,000, 10% off by default = 162,000, added on top of the move total.
    assert_eq!(e["addons"], 162_000);
    assert_eq!(e["addon_discount_bps"], 1_000);
    assert_eq!(e["total"].as_i64().unwrap(), plain["total"].as_i64().unwrap() + 162_000);

    let bad = [
        (json!([{"unit": "window", "count": 1}]), "invalid_unit"),
        (json!([{"unit": "wall", "count": 6}]), "out_of_range"),
    ];
    for (addons, code) in bad {
        let (st, b) = call(&app, "POST", "/v1/quote/estimate", None, Some(move_answers(addons))).await;
        assert_eq!(st, StatusCode::UNPROCESSABLE_ENTITY, "{b}");
        assert_eq!(b["error"]["code"], code);
    }
}

#[sqlx::test(migrations = "../../migrations")]
async fn quote_booking_stores_the_addon_estimate_and_rejects_hourly_slots(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5000-0401").await;
    let visit = (Utc::now() + Duration::days(10)).date_naive();
    let answers = move_answers(json!([{"unit": "stand", "count": 1}]));
    let body = |hour: u8| {
        json!({
            "service_code": "move_out", "address_id": c.address, "visit_date": visit,
            "start_hour": hour, "visit_notes": {}, "answers": answers
        })
    };
    let (st, b) = call(&app, "POST", "/v1/bookings", Some(c.token.as_str()), Some(body(9))).await;
    assert_eq!(st, StatusCode::UNPROCESSABLE_ENTITY, "{b}");
    assert_eq!(b["error"]["code"], "invalid_slot");

    let (st, b) = call(&app, "POST", "/v1/bookings", Some(c.token.as_str()), Some(body(8))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (_, e) = call(&app, "POST", "/v1/quote/estimate", None, Some(answers.clone())).await;
    // The booking adds the date's peak surcharge on top; the add-on is priced into it either way.
    let est = b["estimate"].as_i64().unwrap();
    let preview = e["total"].as_i64().unwrap();
    let addons = e["addons"].as_i64().unwrap();
    assert_eq!(addons, 107_100, "119,000 stand, 10% off");
    assert!(est >= preview, "booking {est} vs preview {preview}");
    assert_eq!(b["answers"]["ac_addons"][0]["unit"], "stand");
    assert!(b["thread_id"].is_string(), "the app opens this chat after submit: {b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn studio_at_eleven_pyeong_is_refused_by_the_server(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5000-0402").await;
    let (st, addr) = call(
        &app,
        "POST",
        "/v1/me/addresses",
        Some(c.token.as_str()),
        Some(json!({
            "kind": "home", "label": "부모님댁", "road_address": "서울특별시 강남구 테헤란로 2", "detail": "",
            "district_code": common::DISTRICT, "size_pyeong": 11
        })),
    )
    .await;
    assert_eq!(st, StatusCode::OK, "{addr}");
    let visit = (Utc::now() + Duration::days(10)).date_naive();
    let (st, b) = call(
        &app,
        "POST",
        "/v1/bookings",
        Some(c.token.as_str()),
        Some(json!({
            "service_code": "studio", "address_id": addr["id"], "visit_date": visit,
            "start_hour": 9, "visit_notes": {}, "payment_method_id": c.card
        })),
    )
    .await;
    assert_eq!(st, StatusCode::UNPROCESSABLE_ENTITY, "{b}");
    assert_eq!(b["error"]["code"], "studio_too_large");
}
