//! Idempotency-Key replay holds across access-token refreshes: the key belongs to the user, not
//! to one token, so a retry after the app refreshed its token never books or charges twice.

mod common;

use api::auth::{Role, issue_access};
use axum::http::StatusCode;
use common::{SECRET, call_keyed, customer, seed_catalog};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

/// A second access token for the same user. Tokens differ only by `iat` (seconds), so wait for the next second.
async fn fresh_token(user: Uuid, old: &str) -> String {
    loop {
        let t = issue_access(SECRET, user, Role::Customer).expect("token");
        if t != old {
            return t;
        }
        tokio::time::sleep(std::time::Duration::from_millis(200)).await;
    }
}

#[sqlx::test(migrations = "../../migrations")]
async fn retry_with_a_refreshed_token_replays_the_booking_instead_of_charging_again(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-5000-0950").await;
    let visit = api::util::today_kst() + chrono::Duration::days(3);
    let body = json!({
        "service_code": "studio",
        "address_id": c.address,
        "visit_date": visit,
        "start_hour": 9,
        "visit_notes": {},
        "payment_method_id": c.card
    });
    let (s1, b1) = call_keyed(&app, "POST", "/v1/bookings", Some(&c.token), Some(body.clone()), Some("k-refresh-1")).await;
    assert_eq!(s1, StatusCode::OK, "first booking: {b1}");

    // The reply was lost; meanwhile the app refreshed its access token and the customer taps Pay again.
    let token2 = fresh_token(c.user, &c.token).await;
    let (s2, b2) = call_keyed(&app, "POST", "/v1/bookings", Some(&token2), Some(body), Some("k-refresh-1")).await;
    assert_eq!(s2, StatusCode::OK, "replayed: {b2}");
    assert_eq!(b2["id"], b1["id"], "the same booking comes back");

    let bookings: i64 = sqlx::query_scalar("SELECT count(*) FROM bookings WHERE user_id = $1")
        .bind(c.user)
        .fetch_one(&pool)
        .await
        .expect("count bookings");
    let charges: i64 = sqlx::query_scalar("SELECT count(*) FROM payments p JOIN bookings b ON b.id = p.booking_id WHERE b.user_id = $1")
        .bind(c.user)
        .fetch_one(&pool)
        .await
        .expect("count payments");
    assert_eq!((bookings, charges), (1, 1), "one booking, one charge");
}

#[sqlx::test(migrations = "../../migrations")]
async fn another_user_with_the_same_key_gets_its_own_answer(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let a = customer(&app, &pool, "010-5000-0951").await;
    let b = customer(&app, &pool, "010-5000-0952").await;
    let uri = format!("/v1/checkouts/{}/confirm", Uuid::now_v7());
    let body = json!({ "payment_id": "pay_missing" });
    let (sa, _) = call_keyed(&app, "POST", &uri, Some(&a.token), Some(body.clone()), Some("k-shared")).await;
    assert_eq!(sa, StatusCode::NOT_FOUND);
    // Same key and body from another customer: never A's stored answer, and never "key reused".
    let (sb, bb) = call_keyed(&app, "POST", &uri, Some(&b.token), Some(body), Some("k-shared")).await;
    assert_eq!(sb, StatusCode::NOT_FOUND, "{bb}");
    let scopes: i64 = sqlx::query_scalar("SELECT count(DISTINCT scope) FROM idempotency_keys WHERE key = 'k-shared'")
        .fetch_one(&pool)
        .await
        .expect("scopes");
    assert_eq!(scopes, 2);
}
