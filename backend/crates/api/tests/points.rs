//! Points ledger over the real router and DB: earn, spend, refund-returns-points, expiry and
//! the append-only guarantee. Same DB and fakes as flows.rs (needs DATABASE_URL, sqlx::test).

mod common;

use api::points;
use axum::http::StatusCode;
use common::{Customer, book, call, customer, seed_catalog};
use domain::Won;
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

async fn enable_points(pool: &PgPool) {
    let policy = json!({ "enabled": true, "earn_bps": 1000, "welcome_points": 0, "referral_points": 0,
                         "expiry_days": 365, "notify_days": 30, "max_use_bps": 10000 });
    sqlx::query("INSERT INTO settings (key, value) VALUES ('points_policy', $1) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value")
        .bind(policy)
        .execute(pool)
        .await
        .expect("policy");
}

async fn balance(app: &axum::Router, c: &Customer) -> i64 {
    let (st, b) = call(app, "GET", "/v1/me/points", Some(c.token.as_str()), None).await;
    assert_eq!(st, StatusCode::OK, "{b}");
    b["balance"].as_i64().expect("balance")
}

async fn grant(pool: &PgPool, user: Uuid, amount: i64, key: &str) {
    let mut conn = pool.acquire().await.expect("conn");
    points::grant(&mut conn, user, "grant", amount, key.to_string()).await.expect("grant");
}

#[sqlx::test(migrations = "../../migrations")]
async fn earn_then_spend_takes_points_before_the_pg(pool: PgPool) {
    seed_catalog(&pool).await;
    enable_points(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6100-0001").await;
    let (id, _) = book(&app, &c, 10, None).await;
    sqlx::query("UPDATE bookings SET paid_amount = 52000, list_price = 52000 WHERE id = $1").bind(id).execute(&pool).await.expect("paid");

    let mut conn = pool.acquire().await.expect("conn");
    points::on_completed(&mut conn, id).await.expect("noop: not completed yet");
    assert_eq!(balance(&app, &c).await, 0, "no earn before completion is paid");

    grant(&pool, c.user, 20_000, "seed:1").await;
    let split = points::spend(&mut conn, c.user, id, Won(52_000), 10_000).await.expect("spend");
    assert_eq!((split.points, split.pg), (10_000, Won(42_000)));
    assert_eq!(balance(&app, &c).await, 10_000);

    let again = points::spend(&mut conn, c.user, id, Won(52_000), 5_000).await;
    assert!(again.is_err(), "a booking can be paid with points only once");
    assert_eq!(balance(&app, &c).await, 10_000);
}

#[sqlx::test(migrations = "../../migrations")]
async fn refund_returns_spent_points_once(pool: PgPool) {
    seed_catalog(&pool).await;
    enable_points(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6100-0002").await;
    let (id, _) = book(&app, &c, 10, None).await;
    grant(&pool, c.user, 8_000, "seed:2").await;
    let mut conn = pool.acquire().await.expect("conn");
    points::spend(&mut conn, c.user, id, Won(52_000), 8_000).await.expect("spend");
    assert_eq!(balance(&app, &c).await, 0);

    assert_eq!(points::reverse_spend(&mut conn, id).await.expect("refund"), 8_000);
    assert_eq!(points::reverse_spend(&mut conn, id).await.expect("retry"), 8_000, "same refund key, no second lot");
    assert_eq!(balance(&app, &c).await, 8_000);
}

#[sqlx::test(migrations = "../../migrations")]
async fn lapsed_lots_expire_once_and_stop_counting(pool: PgPool) {
    seed_catalog(&pool).await;
    enable_points(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6100-0003").await;
    sqlx::query(
        "INSERT INTO points_ledger (id, user_id, kind, amount, lot_id, expires_at, idempotency_key)
         VALUES ($1, $2, 'earn', 3000, $1, now() - interval '1 day', 'test:old')",
    )
    .bind(Uuid::now_v7())
    .bind(c.user)
    .execute(&pool)
    .await
    .expect("old lot");
    grant(&pool, c.user, 1_000, "test:fresh").await;
    assert_eq!(balance(&app, &c).await, 1_000, "lapsed lot is not spendable even before the sweep");

    assert_eq!(points::expire_lapsed(&pool).await.expect("sweep"), 1);
    assert_eq!(points::expire_lapsed(&pool).await.expect("again"), 0, "idempotent");
    assert_eq!(balance(&app, &c).await, 1_000);
}

#[sqlx::test(migrations = "../../migrations")]
async fn ledger_rows_are_append_only(pool: PgPool) {
    seed_catalog(&pool).await;
    let app = common::app(pool.clone());
    let c = customer(&app, &pool, "010-6100-0004").await;
    grant(&pool, c.user, 500, "test:immutable").await;
    let edit = sqlx::query("UPDATE points_ledger SET amount = 999999").execute(&pool).await;
    assert!(edit.is_err(), "UPDATE must be refused");
    let wipe = sqlx::query("DELETE FROM points_ledger").execute(&pool).await;
    assert!(wipe.is_err(), "DELETE must be refused");
    let (st, body): (StatusCode, Value) = call(&app, "GET", "/v1/me/points", Some(c.token.as_str()), None).await;
    assert_eq!((st, body["balance"].as_i64()), (StatusCode::OK, Some(500)));
}
