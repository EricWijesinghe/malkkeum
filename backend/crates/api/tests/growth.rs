//! Growth flows over the real router: review permissions, public social proof, referral rewards,
//! the welcome offer and honest seat counts. Same DB and fakes as flows.rs.

mod common;

use api::auth::{self, Role};
use axum::http::StatusCode;
use chrono::{Duration, Utc};
use common::{Customer, PHOTO, SECRET, book, call, customer, seed_catalog, verified_pro};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

async fn set_setting(pool: &PgPool, key: &str, value: Value) {
    sqlx::query("INSERT INTO settings (key, value) VALUES ($1, $2) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value")
        .bind(key)
        .bind(value)
        .execute(pool)
        .await
        .expect("setting");
}

/// Pro accepts the job, the visit is moved to today (KST), and the pro completes it with photos.
async fn complete_job(app: &axum::Router, pool: &PgPool, id: Uuid, pro: &str) {
    let (st, b) = call(app, "POST", &format!("/v1/partner/jobs/{id}/accept"), Some(pro), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    sqlx::query("UPDATE bookings SET visit_date = (now() AT TIME ZONE 'Asia/Seoul')::date WHERE id = $1")
        .bind(id)
        .execute(pool)
        .await
        .expect("visit today");
    let pro_id: Uuid = sqlx::query_scalar("SELECT pro_id FROM bookings WHERE id = $1").bind(id).fetch_one(pool).await.expect("pro");
    common::register_photo(pool, pro_id).await;
    let done = json!({ "before_photos": [PHOTO], "after_photos": [PHOTO], "checklist": [true, true, true, true] });
    let (st, b) = call(app, "POST", &format!("/v1/partner/jobs/{id}/complete"), Some(pro), Some(done)).await;
    assert_eq!(st, StatusCode::OK, "{b}");
}

async fn coupons_from_referral(pool: &PgPool, user: Uuid) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM coupons WHERE user_id = $1 AND campaign = 'referral'")
        .bind(user)
        .fetch_one(pool)
        .await
        .expect("coupons")
}

#[sqlx::test(migrations = "../../migrations")]
async fn only_the_customer_reviews_a_completed_booking_once_with_own_photos(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5100-0001").await;
    let stranger = customer(&app, &pool, "010-5100-0002").await;
    let (pro, _) = verified_pro(&app, &pool, "010-5100-0101").await;
    let (id, _) = book(&app, &c, 10, None).await;
    let uri = format!("/v1/bookings/{id}/review");
    common::register_photo(&pool, c.user).await;
    let ok = json!({ "rating": 5, "body": "꼼꼼해요", "photos": [PHOTO] });

    let (st, b) = call(&app, "POST", &uri, Some(c.token.as_str()), Some(ok.clone())).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::CONFLICT, Some("not_completed")), "{b}");

    complete_job(&app, &pool, id, pro.as_str()).await;

    let (st, _) = call(&app, "POST", &uri, Some(stranger.token.as_str()), Some(ok.clone())).await;
    assert_eq!(st, StatusCode::NOT_FOUND, "only the booking's customer may review");
    let (st, _) = call(&app, "POST", &uri, Some(c.token.as_str()), Some(json!({ "rating": 6, "body": "", "photos": [] }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "rating is 1..=5");
    let foreign = json!({ "rating": 5, "body": "", "photos": ["https://evil.example/files/0123456789abcdef0123456789abcdef.jpg"] });
    let (st, _) = call(&app, "POST", &uri, Some(c.token.as_str()), Some(foreign)).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "photos must be our own uploads");

    let (st, b) = call(&app, "POST", &uri, Some(c.token.as_str()), Some(ok.clone())).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (st, b) = call(&app, "POST", &uri, Some(c.token.as_str()), Some(ok)).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::CONFLICT, Some("already_reviewed")), "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn public_proof_hides_small_counts_masks_names_and_respects_moderation(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5100-0003").await;
    sqlx::query("UPDATE users SET name = '김민수' WHERE id = $1").bind(c.user).execute(&pool).await.expect("name");
    let (pro, _) = verified_pro(&app, &pool, "010-5100-0102").await;
    let (id, _) = book(&app, &c, 10, None).await;
    complete_job(&app, &pool, id, pro.as_str()).await;
    let (st, b) = call(&app, "POST", &format!("/v1/bookings/{id}/review"), Some(c.token.as_str()), Some(json!({ "rating": 5, "body": "다음에도 부를게요", "photos": [] }))).await;
    assert_eq!(st, StatusCode::OK, "{b}");

    let (st, proof) = call(&app, "GET", "/v1/public/proof", None, None).await;
    assert_eq!(st, StatusCode::OK, "{proof}");
    assert!(proof["review_count"].is_null(), "one review is too few to show: {proof}");
    assert!(proof["rating"].is_null());
    assert_eq!(proof["reviews"][0]["name"], "김*수", "masked name");

    let admin = auth::issue_access(SECRET, Uuid::now_v7(), Role::StaffAdmin).expect("token");
    let (st, b) = call(&app, "PUT", &format!("/v1/admin/reviews/{id}"), Some(admin.as_str()), Some(json!({ "hidden": true }))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (_, proof) = call(&app, "GET", "/v1/public/proof", None, None).await;
    assert_eq!(proof["reviews"].as_array().map(Vec::len), Some(0), "hidden reviews leave the public page");

    let consultant = auth::issue_access(SECRET, Uuid::now_v7(), Role::StaffConsultant).expect("token");
    let (st, _) = call(&app, "PUT", &format!("/v1/admin/reviews/{id}"), Some(consultant.as_str()), Some(json!({ "hidden": false }))).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "moderation is owner-only");
}

#[sqlx::test(migrations = "../../migrations")]
async fn referral_pays_both_sides_once_after_the_friend_pays_and_completes(pool: PgPool) {
    seed_catalog(&pool).await;
    set_setting(&pool, "referral_offer", json!({ "enabled": true, "amount": 3000 })).await;
    let app = common::app(pool.clone());
    let referrer: Customer = customer(&app, &pool, "010-5200-0001").await;
    let (st, mine) = call(&app, "GET", "/v1/me/referral", Some(referrer.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{mine}");
    let code = mine["code"].as_str().expect("code").to_string();
    let (_, again) = call(&app, "GET", "/v1/me/referral", Some(referrer.token.as_str()), None).await;
    assert_eq!(again["code"], code, "the code is stable");

    let (st, b) = call(&app, "POST", "/v1/me/referral/claim", Some(referrer.token.as_str()), Some(json!({ "code": code }))).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::BAD_REQUEST, Some("self_referral")), "{b}");

    let friend = customer(&app, &pool, "010-5200-0002").await;
    let (st, b) = call(&app, "POST", "/v1/me/referral/claim", Some(friend.token.as_str()), Some(json!({ "code": "NOSUCH12" }))).await;
    assert_eq!(st, StatusCode::BAD_REQUEST, "{b}");
    let (st, b) = call(&app, "POST", "/v1/me/referral/claim", Some(friend.token.as_str()), Some(json!({ "code": code }))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let (st, b) = call(&app, "POST", "/v1/me/referral/claim", Some(friend.token.as_str()), Some(json!({ "code": code }))).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::CONFLICT, Some("already_referred")), "{b}");

    let (pro, _) = verified_pro(&app, &pool, "010-5200-0101").await;
    let (first, _) = book(&app, &friend, 10, None).await;
    assert_eq!(coupons_from_referral(&pool, friend.user).await, 0, "not before completion");
    complete_job(&app, &pool, first, pro.as_str()).await;
    assert_eq!(coupons_from_referral(&pool, friend.user).await, 1, "friend gets the reward");
    assert_eq!(coupons_from_referral(&pool, referrer.user).await, 1, "referrer gets the reward");

    let (second, _) = book(&app, &friend, 11, None).await;
    complete_job(&app, &pool, second, pro.as_str()).await;
    assert_eq!(coupons_from_referral(&pool, friend.user).await, 1, "one reward per referral");
    assert_eq!(coupons_from_referral(&pool, referrer.user).await, 1, "one reward per referral");

    let (_, stats) = call(&app, "GET", "/v1/me/referral", Some(referrer.token.as_str()), None).await;
    assert_eq!((stats["invited"].as_i64(), stats["rewarded"].as_i64()), (Some(1), Some(1)), "{stats}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn referral_is_refused_after_the_friend_has_booked(pool: PgPool) {
    seed_catalog(&pool).await;
    set_setting(&pool, "referral_offer", json!({ "enabled": true, "amount": 3000 })).await;
    let app = common::app(pool.clone());
    let referrer = customer(&app, &pool, "010-5300-0001").await;
    let (_, mine) = call(&app, "GET", "/v1/me/referral", Some(referrer.token.as_str()), None).await;
    let friend = customer(&app, &pool, "010-5300-0002").await;
    book(&app, &friend, 10, None).await;
    let (st, b) = call(&app, "POST", "/v1/me/referral/claim", Some(friend.token.as_str()), Some(json!({ "code": mine["code"] }))).await;
    assert_eq!((st, b["error"]["code"].as_str()), (StatusCode::BAD_REQUEST, Some("referee_already_booked")), "{b}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn welcome_offer_applies_once_to_the_first_booking_and_not_on_top_of_a_coupon(pool: PgPool) {
    seed_catalog(&pool).await;
    set_setting(&pool, "welcome_offer", json!({ "enabled": true, "kind": "amount", "value": 5000 })).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5400-0001").await;
    let (first, _) = book(&app, &c, 10, None).await;
    let (second, _) = book(&app, &c, 11, None).await;
    let discounts: Vec<(Uuid, i64)> = sqlx::query_as("SELECT id, discount FROM bookings WHERE user_id = $1")
        .bind(c.user)
        .fetch_all(&pool)
        .await
        .expect("discounts");
    let of = |id: Uuid| discounts.iter().find(|(i, _)| *i == id).map(|(_, d)| *d);
    assert_eq!(of(first), Some(5_000), "first booking gets the welcome offer");
    assert_eq!(of(second), Some(0), "only the first booking");

    let fresh = customer(&app, &pool, "010-5400-0002").await;
    let coupon: Uuid = sqlx::query_scalar("INSERT INTO coupons (user_id, name, amount, expires_at) VALUES ($1, 'manual', 2000, now() + interval '30 days') RETURNING id")
        .bind(fresh.user)
        .fetch_one(&pool)
        .await
        .expect("coupon");
    let (with_coupon, _) = book(&app, &fresh, 12, Some(coupon)).await;
    let (d,): (i64,) = sqlx::query_as("SELECT discount FROM bookings WHERE id = $1").bind(with_coupon).fetch_one(&pool).await.expect("discount");
    assert_eq!(d, 2_000, "a coupon is never stacked with the welcome offer");
}

#[sqlx::test(migrations = "../../migrations")]
async fn slot_shows_seats_left_only_when_two_or_fewer_remain(pool: PgPool) {
    seed_catalog(&pool).await;
    sqlx::query("UPDATE slot_capacity SET capacity = 3 WHERE start_hour = 9").execute(&pool).await.expect("capacity");
    let app = common::app(pool.clone());
    let date = (Utc::now() + Duration::days(10)).date_naive();
    let uri = format!("/v1/slots?date={date}");
    let hour9 = |v: &Value| v.as_array().and_then(|a| a.iter().find(|s| s["start_hour"] == 9)).cloned().expect("hour 9");

    let (_, empty) = call(&app, "GET", &uri, None, None).await;
    assert!(hour9(&empty)["seats_left"].is_null(), "plenty left: no scarcity claim");

    let c = customer(&app, &pool, "010-5500-0001").await;
    book(&app, &c, 10, None).await;
    let (_, one) = call(&app, "GET", &uri, None, None).await;
    assert_eq!(hour9(&one)["seats_left"], 2, "two of three left: honest count");

    let d = customer(&app, &pool, "010-5500-0002").await;
    book(&app, &d, 10, None).await;
    let (_, two) = call(&app, "GET", &uri, None, None).await;
    assert_eq!(hour9(&two)["seats_left"], 1);
    assert_eq!(hour9(&two)["available"], true);
}

// ---- Sign-up welcome coupons (setting `welcome_pack`) ----

async fn staff_token(pool: &PgPool, email: &str, role: &str, as_role: Role) -> String {
    let id: Uuid = sqlx::query_scalar("INSERT INTO staff (email, name, password_hash, role) VALUES ($1, 'Staff', 'unused', $2) RETURNING id")
        .bind(email)
        .bind(role)
        .fetch_one(pool)
        .await
        .expect("staff row");
    auth::issue_access(SECRET, id, as_role).expect("token")
}

/// Completes sign-up (first name) and returns the account's welcome coupons as (name, amount, service).
async fn sign_up(app: &axum::Router, pool: &PgPool, phone: &str) -> Vec<(String, i64, Option<String>)> {
    let (token, subject) = common::login(app, phone, "customer").await;
    for _ in 0..2 {
        let (st, b) = call(app, "PATCH", "/v1/me", Some(token.as_str()), Some(json!({ "name": "지민" }))).await;
        assert_eq!(st, StatusCode::OK, "{b}");
    }
    let user: Uuid = subject.parse().expect("user id");
    sqlx::query_as("SELECT name, amount::bigint, service_code FROM coupons WHERE user_id = $1 AND campaign = 'welcome' ORDER BY amount DESC")
        .bind(user)
        .fetch_all(pool)
        .await
        .expect("coupons")
}

#[sqlx::test(migrations = "../../migrations")]
async fn a_stored_pack_over_the_caps_issues_at_most_three_coupons_and_50000(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    // Written straight to the setting (as the old 5 x 100,000 limit allowed), bypassing the PUT validation.
    let pack = json!([{ "amount": 20000 }, { "amount": 20000 }, { "amount": 5000 }, { "amount": 5000 }, { "amount": 5000 }]);
    sqlx::query("INSERT INTO settings (key, value) VALUES ('welcome_pack', $1) ON CONFLICT (key) DO UPDATE SET value = $1")
        .bind(pack)
        .execute(&pool)
        .await
        .expect("pack");
    let coupons = sign_up(&app, &pool, "010-5600-0009").await;
    let amounts: Vec<i64> = coupons.iter().map(|c| c.1).collect();
    assert_eq!(amounts, vec![20_000, 20_000, 5_000], "three coupons, 45,000 in total");
}

#[sqlx::test(migrations = "../../migrations")]
async fn sign_up_issues_one_15000_welcome_coupon_by_default_and_only_once(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    // sign_up saves the name twice: the second save must not issue again.
    let coupons = sign_up(&app, &pool, "010-5600-0001").await;
    assert_eq!(coupons, vec![("welcome_any".to_string(), 15_000, None)]);
}

#[sqlx::test(migrations = "../../migrations")]
async fn admin_edits_the_welcome_pack_and_new_sign_ups_get_it(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let admin = staff_token(&pool, "owner@test.local", "admin", Role::StaffAdmin).await;
    let consultant = staff_token(&pool, "consult@test.local", "consultant", Role::StaffConsultant).await;
    let uri = "/v1/admin/growth/welcome-pack";

    let (_, overview) = call(&app, "GET", "/v1/admin/growth", Some(admin.as_str()), None).await;
    assert_eq!(overview["welcome_pack"], json!([{ "amount": 15000, "service_code": null }]), "default");

    let pack = json!([{ "amount": 7000, "service_code": "studio" }, { "amount": 3000 }]);
    let (st, b) = call(&app, "PUT", uri, Some(consultant.as_str()), Some(pack.clone())).await;
    assert_eq!(st, StatusCode::FORBIDDEN, "{b}");
    for (bad, code) in [
        (json!([{ "amount": 15050 }]), "out_of_range"),
        (json!([{ "amount": 0 }]), "out_of_range"),
        (json!([{ "amount": 200000 }]), "out_of_range"),
        (json!([{ "amount": 1000 }, { "amount": 1000 }, { "amount": 1000 }, { "amount": 1000 }]), "out_of_range"),
        (json!([{ "amount": 30000 }, { "amount": 25000 }]), "out_of_range"),
        (json!([{ "amount": 5000, "service_code": "no_such_service" }]), "invalid_service"),
    ] {
        let (st, b) = call(&app, "PUT", uri, Some(admin.as_str()), Some(bad.clone())).await;
        assert!(st.is_client_error(), "{bad}: {st} {b}");
        assert_eq!(b["error"]["code"], code, "{bad}");
    }
    let (st, b) = call(&app, "PUT", uri, Some(admin.as_str()), Some(pack)).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    let audited: i64 = sqlx::query_scalar("SELECT count(*) FROM audit_log WHERE action = 'growth.welcome_pack'").fetch_one(&pool).await.expect("audit");
    assert_eq!(audited, 1);

    let coupons = sign_up(&app, &pool, "010-5600-0002").await;
    assert_eq!(coupons, vec![("welcome_studio".to_string(), 7_000, Some("studio".to_string())), ("welcome_any".to_string(), 3_000, None)]);

    // An empty pack switches the coupons off.
    let (st, b) = call(&app, "PUT", uri, Some(admin.as_str()), Some(json!([]))).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    assert!(sign_up(&app, &pool, "010-5600-0003").await.is_empty());
}
