//! Growth: welcome and referral offers, referral codes and rewards, review moderation, and the
//! public social-proof numbers. Rewards are coupons; every price is still computed in booking_core.

use super::audit;
use crate::{
    auth::{Admin, Customer, Staff},
    error::{ApiError, ApiResult},
    state::AppState,
    util::is_own_upload,
};
use axum::{
    Json, Router,
    extract::{Path, State},
    routing::{get, post, put},
};
use chrono::{DateTime, Duration, Utc};
use domain::{
    coupon::COUPON_LIFETIME_DAYS,
    growth::{ReferralOffer, WelcomeOffer, check_claim, check_reward, mask_name, paid_in_full, proof_count},
};
use rand::{RngCore, rngs::OsRng};
use serde::{Deserialize, Serialize, de::DeserializeOwned};
use serde_json::{Value, json};
use sqlx::{PgConnection, PgExecutor, PgPool};
use uuid::Uuid;

const WELCOME_KEY: &str = "welcome_offer";
const REFERRAL_KEY: &str = "referral_offer";
const CODE_LEN: usize = 6;
/// 32 symbols (no 0/O, 1/I) so a byte modulo 32 is unbiased.
const CODE_ALPHABET: &[u8] = b"ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const MAX_PHOTOS: usize = 5;
const RECENT_REVIEWS: i64 = 3;
const REVIEW_LIST_LIMIT: i64 = 200;
const PROOF_BODY_CHARS: i32 = 120;

pub fn public_routes() -> Router<AppState> {
    Router::new().route("/public/proof", get(proof))
}

pub fn customer_routes() -> Router<AppState> {
    Router::new().route("/me/referral", get(my_referral)).route("/me/referral/claim", post(claim_referral))
}

pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/growth", get(overview))
        .route("/growth/welcome", put(put_welcome))
        .route("/growth/referral", put(put_referral))
        .route("/reviews", get(list_reviews))
        .route("/reviews/{booking_id}", put(moderate_review))
}

async fn load_setting<'e, T: DeserializeOwned + Default>(ex: impl PgExecutor<'e>, key: &str) -> ApiResult<T> {
    let v: Option<Value> = sqlx::query_scalar("SELECT value FROM settings WHERE key = $1").bind(key).fetch_optional(ex).await?;
    match v {
        None => Ok(T::default()),
        Some(v) => serde_json::from_value(v).map_err(|_| ApiError::Internal(format!("bad setting {key}"))),
    }
}

async fn save_setting<T: Serialize>(db: &PgPool, key: &str, value: &T) -> ApiResult<()> {
    sqlx::query("INSERT INTO settings (key, value) VALUES ($1, $2) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()")
        .bind(key)
        .bind(sqlx::types::Json(value))
        .execute(db)
        .await?;
    Ok(())
}

/// Read by booking pricing inside the booking transaction.
pub async fn load_welcome(conn: &mut PgConnection) -> ApiResult<WelcomeOffer> {
    load_setting(&mut *conn, WELCOME_KEY).await
}

async fn load_referral(db: &PgPool) -> ApiResult<ReferralOffer> {
    load_setting(db, REFERRAL_KEY).await
}

fn new_code() -> String {
    let mut bytes = [0u8; CODE_LEN];
    OsRng.fill_bytes(&mut bytes);
    bytes.iter().map(|b| char::from(CODE_ALPHABET[usize::from(*b) % CODE_ALPHABET.len()])).collect()
}

/// Gives the customer a referral code on first use and keeps it stable afterwards.
async fn ensure_code(db: &PgPool, user: Uuid) -> ApiResult<String> {
    let code: Option<String> = sqlx::query_scalar("UPDATE users SET referral_code = COALESCE(referral_code, $2) WHERE id = $1 RETURNING referral_code")
        .bind(user)
        .bind(new_code())
        .fetch_optional(db)
        .await?
        .ok_or(ApiError::NotFound)?;
    code.ok_or_else(|| ApiError::Internal("referral code not set".into()))
}

async fn my_referral(State(s): State<AppState>, Customer(a): Customer) -> ApiResult<Json<Value>> {
    let code = ensure_code(&s.db, a.id).await?;
    let offer = load_referral(&s.db).await?;
    let (invited, rewarded): (i64, i64) =
        sqlx::query_as("SELECT count(*), count(*) FILTER (WHERE state = 'rewarded') FROM referrals WHERE referrer_id = $1")
            .bind(a.id)
            .fetch_one(&s.db)
            .await?;
    Ok(Json(json!({ "code": code, "enabled": offer.enabled, "amount": offer.amount, "invited": invited, "rewarded": rewarded })))
}

#[derive(Deserialize)]
struct ClaimInput {
    code: String,
}

/// A friend enters a referral code once, before their first booking, with their own phone.
async fn claim_referral(State(s): State<AppState>, Customer(a): Customer, Json(c): Json<ClaimInput>) -> ApiResult<Json<Value>> {
    if !load_referral(&s.db).await?.enabled {
        return Err(ApiError::Conflict("referral_disabled"));
    }
    let code = c.code.trim().to_ascii_uppercase();
    let (referrer, referrer_phone): (Uuid, String) = sqlx::query_as("SELECT id, phone FROM users WHERE referral_code = $1 AND deleted_at IS NULL")
        .bind(&code)
        .fetch_optional(&s.db)
        .await?
        .ok_or(ApiError::BadRequest("invalid_referral_code"))?;
    let (friend_phone, friend_bookings): (String, i64) = sqlx::query_as(
        "SELECT u.phone, (SELECT count(*) FROM bookings b WHERE b.user_id = u.id) FROM users u WHERE u.id = $1",
    )
    .bind(a.id)
    .fetch_optional(&s.db)
    .await?
    .ok_or(ApiError::NotFound)?;
    if referrer == a.id {
        return Err(ApiError::BadRequest("self_referral"));
    }
    check_claim(&referrer_phone, &friend_phone, friend_bookings).map_err(|e| ApiError::BadRequest(e.code()))?;
    // One row per friend and per phone (see migration 0010); a second claim changes nothing.
    let inserted = sqlx::query("INSERT INTO referrals (referred_user_id, referrer_id, referred_phone) VALUES ($1,$2,$3) ON CONFLICT DO NOTHING")
        .bind(a.id)
        .bind(referrer)
        .bind(&friend_phone)
        .execute(&s.db)
        .await?;
    if inserted.rows_affected() == 0 {
        return Err(ApiError::Conflict("already_referred"));
    }
    Ok(Json(json!({ "ok": true })))
}

/// Admin completion has no job transaction of its own, so the reward gets one.
pub(crate) async fn reward_in_own_tx(db: &PgPool, booking: Uuid) -> ApiResult<()> {
    let mut tx = db.begin().await?;
    reward_on_paid_completion(&mut tx, booking).await?;
    tx.commit().await?;
    Ok(())
}

/// Pays both sides once a referred friend's booking is paid in full. Call inside the completion
/// transaction; a no-op until the friend's booking is paid, and never twice (row lock + state).
pub(crate) async fn reward_on_paid_completion(conn: &mut PgConnection, booking: Uuid) -> ApiResult<()> {
    let (friend, paid, final_price): (Uuid, i64, Option<i64>) = sqlx::query_as("SELECT user_id, paid_amount, COALESCE(final_price, list_price) FROM bookings WHERE id = $1")
        .bind(booking)
        .fetch_one(&mut *conn)
        .await?;
    let Some((referrer, state)) = sqlx::query_as::<_, (Uuid, String)>("SELECT referrer_id, state FROM referrals WHERE referred_user_id = $1 FOR UPDATE")
        .bind(friend)
        .fetch_optional(&mut *conn)
        .await?
    else {
        return Ok(());
    };
    let offer = load_setting::<ReferralOffer>(&mut *conn, REFERRAL_KEY).await?;
    if !offer.enabled || check_reward(state == "rewarded", paid_in_full(paid, final_price)).is_err() {
        // Not eligible yet (or switched off): nothing is owed, so nothing is paid.
        return Ok(());
    }
    let now = Utc::now();
    let expires: DateTime<Utc> = now + Duration::days(COUPON_LIFETIME_DAYS);
    for (who, name) in [(friend, "referral_friend"), (referrer, "referral_reward")] {
        sqlx::query("INSERT INTO coupons (user_id, name, amount, campaign, issued_at, expires_at) VALUES ($1,$2,$3,'referral',$4,$5)")
            .bind(who)
            .bind(name)
            .bind(offer.amount)
            .bind(now)
            .bind(expires)
            .execute(&mut *conn)
            .await?;
    }
    sqlx::query("UPDATE referrals SET state = 'rewarded', rewarded_at = now() WHERE referred_user_id = $1")
        .bind(friend)
        .execute(&mut *conn)
        .await?;
    Ok(())
}

#[derive(Serialize)]
struct PublicReview {
    rating: i16,
    body: String,
    name: String,
}

/// Public, real numbers only. Counts under MIN_PROOF_COUNT come back null so the apps hide them.
async fn proof(State(s): State<AppState>) -> ApiResult<Json<Value>> {
    let (homes, rated, avg): (i64, i64, Option<f64>) = sqlx::query_as(
        "SELECT
           (SELECT count(*) FROM bookings WHERE status = 3 AND completed_at >= date_trunc('month', now() AT TIME ZONE 'Asia/Seoul') AT TIME ZONE 'Asia/Seoul'),
           (SELECT count(*) FROM reviews WHERE NOT hidden),
           (SELECT avg(rating)::float8 FROM reviews WHERE NOT hidden)",
    )
    .fetch_one(&s.db)
    .await?;
    let recent: Vec<(i16, String, String)> = sqlx::query_as(
        "SELECT r.rating, left(r.body, $2), u.name FROM reviews r JOIN users u ON u.id = r.user_id
         WHERE NOT r.hidden AND r.rating >= 4 AND r.body <> '' ORDER BY r.created_at DESC LIMIT $1",
    )
    .bind(RECENT_REVIEWS)
    .bind(PROOF_BODY_CHARS)
    .fetch_all(&s.db)
    .await?;
    let reviews: Vec<PublicReview> = recent.into_iter().map(|(rating, body, name)| PublicReview { rating, body: domain::growth::redact_contacts(&body), name: mask_name(&name) }).collect();
    let rating = proof_count(rated).and(avg).map(round_rating);
    Ok(Json(json!({
        "homes_this_month": proof_count(homes),
        "rating": rating,
        "review_count": proof_count(rated),
        "reviews": reviews,
    })))
}

pub(crate) struct DashboardFigures {
    pub average_rating: Option<f64>,
    pub invited: i64,
    pub rewarded: i64,
}

pub(crate) async fn dashboard_figures(db: &PgPool) -> ApiResult<DashboardFigures> {
    let (avg, invited, rewarded): (Option<f64>, i64, i64) = sqlx::query_as(
        "SELECT (SELECT round(avg(rating)::numeric, 1)::float8 FROM reviews WHERE NOT hidden),
                (SELECT count(*) FROM referrals),
                (SELECT count(*) FROM referrals WHERE state = 'rewarded')",
    )
    .fetch_one(db)
    .await?;
    Ok(DashboardFigures { average_rating: avg, invited, rewarded })
}

async fn overview(State(s): State<AppState>, _st: Staff) -> ApiResult<Json<Value>> {
    let welcome: WelcomeOffer = load_setting(&s.db, WELCOME_KEY).await?;
    let referral = load_referral(&s.db).await?;
    let (rated, avg): (i64, Option<f64>) = sqlx::query_as("SELECT count(*), avg(rating)::float8 FROM reviews WHERE NOT hidden").fetch_one(&s.db).await?;
    let (invited, rewarded): (i64, i64) = sqlx::query_as("SELECT count(*), count(*) FILTER (WHERE state = 'rewarded') FROM referrals")
        .fetch_one(&s.db)
        .await?;
    Ok(Json(json!({
        "welcome": welcome,
        "referral": referral,
        "rating": avg.map(round_rating),
        "review_count": rated,
        "referrals": { "invited": invited, "rewarded": rewarded },
    })))
}

async fn put_welcome(State(s): State<AppState>, Admin(a): Admin, Json(o): Json<WelcomeOffer>) -> ApiResult<Json<Value>> {
    o.validate()?;
    save_setting(&s.db, WELCOME_KEY, &o).await?;
    audit(&s.db, "staff", Some(a.id), "growth.welcome", WELCOME_KEY, json!(o)).await?;
    Ok(Json(json!(o)))
}

async fn put_referral(State(s): State<AppState>, Admin(a): Admin, Json(o): Json<ReferralOffer>) -> ApiResult<Json<Value>> {
    o.validate()?;
    save_setting(&s.db, REFERRAL_KEY, &o).await?;
    audit(&s.db, "staff", Some(a.id), "growth.referral", REFERRAL_KEY, json!(o)).await?;
    Ok(Json(json!(o)))
}

#[derive(sqlx::FromRow, Serialize)]
struct ReviewRow {
    booking_id: Uuid,
    number: String,
    service_code: String,
    pro_name: Option<String>,
    rating: i16,
    body: String,
    photos: Value,
    hidden: bool,
    created_at: DateTime<Utc>,
    customer_name: String,
}

async fn list_reviews(State(s): State<AppState>, _st: Staff) -> ApiResult<Json<Vec<ReviewRow>>> {
    let mut rows: Vec<ReviewRow> = sqlx::query_as(
        "SELECT r.booking_id, b.number, b.service_code, p.name AS pro_name, r.rating, r.body, r.photos, r.hidden, r.created_at, u.name AS customer_name
         FROM reviews r JOIN bookings b ON b.id = r.booking_id JOIN users u ON u.id = r.user_id LEFT JOIN pros p ON p.id = r.pro_id
         ORDER BY r.created_at DESC LIMIT $1",
    )
    .bind(REVIEW_LIST_LIMIT)
    .fetch_all(&s.db)
    .await?;
    for r in &mut rows {
        r.customer_name = mask_name(&r.customer_name);
    }
    Ok(Json(rows))
}

#[derive(Deserialize)]
struct Moderation {
    hidden: bool,
}

async fn moderate_review(State(s): State<AppState>, Admin(a): Admin, Path(booking): Path<Uuid>, Json(m): Json<Moderation>) -> ApiResult<Json<Value>> {
    let changed = sqlx::query("UPDATE reviews SET hidden = $2 WHERE booking_id = $1").bind(booking).bind(m.hidden).execute(&s.db).await?;
    if changed.rows_affected() == 0 {
        return Err(ApiError::NotFound);
    }
    audit(&s.db, "staff", Some(a.id), "review.moderate", &booking.to_string(), json!({ "hidden": m.hidden })).await?;
    Ok(Json(json!({ "ok": true, "hidden": m.hidden })))
}

/// Review photos: only our own uploads, bounded in count (no foreign URLs stored).
pub(crate) fn check_photos(base: &str, photos: &[String]) -> ApiResult<()> {
    if photos.len() > MAX_PHOTOS || !photos.iter().all(|p| is_own_upload(base, p)) {
        return Err(ApiError::BadRequest("invalid_photos"));
    }
    Ok(())
}

/// One decimal place for the public rating.
fn round_rating(avg: f64) -> f64 {
    (avg * 10.0).round() / 10.0
}
