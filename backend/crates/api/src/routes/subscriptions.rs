//! Regular cleaning subscriptions. Customer: create, manage, skip or move one visit. Partner: the recurring
//! customers they serve (district only, no contact details). Owner: list, edit or pause on behalf of a customer,
//! the discount policy, and recurring metrics (MRR, churn, prorated revenue).
//! Visit charging and planning run in `subscription_engine`.

use super::{
    audit,
    booking_core::{BookingBody, prepare},
    bookings::cancel_owned,
    catalog::load_service,
    subscription_engine::plan_subscription,
};
use crate::{
    auth::{Admin, Customer, Pro},
    error::{ApiError, ApiResult},
    state::AppState,
    util::{KST_TODAY, lock_and_count_slot, today_kst},
};
use axum::{
    Json, Router,
    extract::{Path, Query, State},
    routing::{get, post},
};
use chrono::{DateTime, Duration, NaiveDate, Utc};
use domain::{
    pricing::{price_booking, price_booking_with},
    schedule::{check_capacity, check_date, check_slot},
    subscription::{Cadence, Policy, active_days, churn_bps, first_visit, monthly_equivalent, prorate, visit_price, weekday_from_index},
};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use sqlx::PgPool;
use uuid::Uuid;

const POLICY_KEY: &str = "subscription_policy";

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/subscriptions", crate::idempotency::replayable(get(list).post(create)))
        .route("/subscriptions/{id}", get(detail))
        .route("/subscriptions/{id}/pause", post(pause))
        .route("/subscriptions/{id}/resume", post(resume))
        .route("/subscriptions/{id}/cancel", post(cancel))
        .route("/subscriptions/{id}/visits/{visit}/skip", post(skip))
        .route("/subscriptions/{id}/visits/{visit}/reschedule", post(reschedule_visit))
}

pub fn public_routes() -> Router<AppState> {
    Router::new().route("/policy/subscription", get(public_policy))
}

pub fn partner_routes() -> Router<AppState> {
    Router::new().route("/subscriptions", get(partner_list))
}

pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/subscriptions", get(admin_list))
        .route("/subscriptions/policy", get(admin_policy).put(admin_set_policy))
        .route("/subscriptions/metrics", get(admin_metrics))
        .route("/subscriptions/{id}", get(admin_detail).put(admin_edit))
        .route("/subscriptions/{id}/pause", post(admin_pause))
        .route("/subscriptions/{id}/resume", post(admin_resume))
}

const SUB_COLS: &str = "s.id, s.user_id, s.service_code, s.unit_index, s.address_id, s.payment_method_id, s.preferred_pro_id,
    s.cadence_weeks, s.weekday, s.start_hour, s.anchor_date, s.status, s.paused_reason, s.discount_percent,
    s.consecutive_failures, s.created_at, s.cancelled_at";

#[derive(Serialize, sqlx::FromRow)]
pub struct SubView {
    pub id: Uuid,
    pub user_id: Uuid,
    pub service_code: String,
    pub unit_index: Option<i16>,
    pub address_id: Uuid,
    pub payment_method_id: Uuid,
    pub preferred_pro_id: Option<Uuid>,
    pub cadence_weeks: i16,
    pub weekday: i16,
    pub start_hour: i16,
    pub anchor_date: NaiveDate,
    pub status: String,
    pub paused_reason: Option<String>,
    pub discount_percent: i16,
    pub consecutive_failures: i32,
    pub created_at: DateTime<Utc>,
    pub cancelled_at: Option<DateTime<Utc>>,
}

#[derive(Serialize, sqlx::FromRow)]
pub struct VisitView {
    pub id: Uuid,
    pub visit_date: NaiveDate,
    pub start_hour: i16,
    pub state: String,
    pub booking_id: Option<Uuid>,
    pub charge_attempts: i32,
}

/// The owner's subscription settings and whether they are still the built-in default.
pub async fn load_policy(db: &PgPool) -> ApiResult<(Policy, bool)> {
    let v: Option<Value> = sqlx::query_scalar("SELECT value FROM settings WHERE key = $1")
        .bind(POLICY_KEY)
        .fetch_optional(db)
        .await?;
    match v {
        None => Ok((Policy::default(), true)),
        Some(v) => Ok((
            serde_json::from_value(v).map_err(|_| ApiError::Internal("bad setting subscription_policy".into()))?,
            false,
        )),
    }
}

async fn fetch(db: &PgPool, id: Uuid) -> ApiResult<SubView> {
    sqlx::query_as(&format!("SELECT {SUB_COLS} FROM subscriptions s WHERE s.id = $1"))
        .bind(id)
        .fetch_optional(db)
        .await?
        .ok_or(ApiError::NotFound)
}

/// The customer's own subscription; anyone else gets 404.
async fn owned_sub(db: &PgPool, user: Uuid, id: Uuid) -> ApiResult<SubView> {
    let sub = fetch(db, id).await?;
    if sub.user_id == user { Ok(sub) } else { Err(ApiError::NotFound) }
}

/// Subscription plus its visits from one week ago on. Callers check ownership first.
async fn view(db: &PgPool, id: Uuid) -> ApiResult<Value> {
    let sub = fetch(db, id).await?;
    let visits: Vec<VisitView> = sqlx::query_as(&format!(
        "SELECT id, visit_date, start_hour, state, booking_id, charge_attempts FROM subscription_visits
         WHERE subscription_id = $1 AND visit_date >= {KST_TODAY} - 7 ORDER BY visit_date LIMIT 40"
    ))
    .bind(id)
    .fetch_all(db)
    .await?;
    Ok(json!({ "subscription": sub, "visits": visits }))
}

/// A visit is charged the day before it (KST), so anything up to tomorrow is out of reach for the customer.
fn charge_due(date: NaiveDate) -> bool {
    date <= today_kst() + Duration::days(1)
}

async fn check_card(db: &PgPool, user: Uuid, method: Uuid) -> ApiResult<()> {
    let owned: bool = sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM payment_methods WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL)")
        .bind(method)
        .bind(user)
        .fetch_one(db)
        .await?;
    if owned {
        Ok(())
    } else {
        Err(ApiError::BadRequest("payment_method_required"))
    }
}

async fn list(State(s): State<AppState>, Customer(a): Customer) -> ApiResult<Json<Vec<SubView>>> {
    let rows: Vec<SubView> = sqlx::query_as(&format!(
        "SELECT {SUB_COLS} FROM subscriptions s WHERE s.user_id = $1 ORDER BY s.created_at DESC LIMIT 50"
    ))
    .bind(a.id)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}

async fn detail(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    owned_sub(&s.db, a.id, id).await?;
    Ok(Json(view(&s.db, id).await?))
}

#[derive(Deserialize)]
struct CreateSub {
    service_code: String,
    unit_index: Option<usize>,
    address_id: Uuid,
    payment_method_id: Uuid,
    cadence_weeks: i64,
    /// 0 = Monday.
    weekday: u8,
    start_hour: u8,
    preferred_pro_id: Option<Uuid>,
}

/// Validates the request like a booking would (address, unit, slot, card), then plans the first visits.
async fn create(State(s): State<AppState>, Customer(a): Customer, Json(req): Json<CreateSub>) -> ApiResult<Json<Value>> {
    let cadence = Cadence::from_weeks(req.cadence_weeks)?;
    let weekday = weekday_from_index(req.weekday)?;
    let first = first_visit(today_kst() + Duration::days(1), weekday);
    let body = BookingBody {
        service_code: req.service_code.clone(),
        unit_index: req.unit_index,
        counts: Vec::new(),
        address_id: req.address_id,
        visit_date: first,
        start_hour: req.start_hour,
        coupon_id: None,
        answers: None,
        visit_notes: Value::Null,
        household: None,
    };
    let prep = prepare(&s.db, a.id, &body).await?;
    if prep.service.is_quote() {
        return Err(ApiError::BadRequest("subscription_not_supported"));
    }
    price_booking(&prep.service, req.unit_index, None, Utc::now())?;
    check_card(&s.db, a.id, req.payment_method_id).await?;
    if let Some(pro) = req.preferred_pro_id {
        let exists: bool = sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM pros WHERE id = $1)")
            .bind(pro)
            .fetch_one(&s.db)
            .await?;
        if !exists {
            return Err(ApiError::BadRequest("pro_not_found"));
        }
    }
    let (policy, _) = load_policy(&s.db).await?;
    let id = Uuid::now_v7();
    sqlx::query(
        "INSERT INTO subscriptions (id, user_id, service_code, unit_index, address_id, payment_method_id, preferred_pro_id,
           cadence_weeks, weekday, start_hour, anchor_date, discount_percent)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)",
    )
    .bind(id)
    .bind(a.id)
    .bind(&req.service_code)
    .bind(req.unit_index.map(|u| u as i16))
    .bind(req.address_id)
    .bind(req.payment_method_id)
    .bind(req.preferred_pro_id)
    .bind(cadence.weeks() as i16)
    .bind(i16::from(req.weekday))
    .bind(i16::from(req.start_hour))
    .bind(first)
    .bind(i16::from(policy.discount_percent))
    .execute(&s.db)
    .await?;
    plan_subscription(&s.db, id).await?;
    audit(
        &s.db,
        "customer",
        Some(a.id),
        "subscription.create",
        &id.to_string(),
        json!({ "cadence_weeks": cadence.weeks() }),
    )
    .await?;
    Ok(Json(view(&s.db, id).await?))
}

/// Moves a subscription from `from` to `to`. Anything else is a conflict (the state changed under the caller).
async fn transition(db: &PgPool, id: Uuid, from: &str, to: &str, reason: Option<&str>) -> ApiResult<()> {
    let n = sqlx::query(
        "UPDATE subscriptions SET status = $3, paused_reason = $4,
           consecutive_failures = CASE WHEN $3::text = 'active' THEN 0 ELSE consecutive_failures END, updated_at = now()
         WHERE id = $1 AND status = $2",
    )
    .bind(id)
    .bind(from)
    .bind(to)
    .bind(reason)
    .execute(db)
    .await?
    .rows_affected();
    if n == 0 {
        Err(ApiError::Conflict("invalid_subscription_state"))
    } else {
        Ok(())
    }
}

async fn pause(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    owned_sub(&s.db, a.id, id).await?;
    transition(&s.db, id, "active", "paused", Some("customer")).await?;
    audit(&s.db, "customer", Some(a.id), "subscription.pause", &id.to_string(), json!({})).await?;
    Ok(Json(view(&s.db, id).await?))
}

#[derive(Deserialize, Default)]
struct ResumeBody {
    /// Replaces the card, usually after a payment failure.
    payment_method_id: Option<Uuid>,
}

async fn resume(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>, body: Option<Json<ResumeBody>>) -> ApiResult<Json<Value>> {
    owned_sub(&s.db, a.id, id).await?;
    let method = body.and_then(|Json(b)| b.payment_method_id);
    if let Some(m) = method {
        check_card(&s.db, a.id, m).await?;
    }
    let n = sqlx::query(
        "UPDATE subscriptions SET status = 'active', paused_reason = NULL, consecutive_failures = 0,
           payment_method_id = COALESCE($2, payment_method_id), updated_at = now()
         WHERE id = $1 AND status = 'paused'",
    )
    .bind(id)
    .bind(method)
    .execute(&s.db)
    .await?
    .rows_affected();
    if n == 0 {
        return Err(ApiError::Conflict("invalid_subscription_state"));
    }
    audit(&s.db, "customer", Some(a.id), "subscription.resume", &id.to_string(), json!({})).await?;
    Ok(Json(view(&s.db, id).await?))
}

/// Ends the subscription. Planned visits are cancelled; booked upcoming visits stay until the customer cancels
/// each one, which applies the per-visit cancel fee. Their booking ids come back as `booked_visits`.
async fn cancel(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    let sub = owned_sub(&s.db, a.id, id).await?;
    if sub.status == "cancelled" {
        return Err(ApiError::Conflict("invalid_subscription_state"));
    }
    let mut tx = s.db.begin().await?;
    sqlx::query("UPDATE subscriptions SET status = 'cancelled', paused_reason = NULL, cancelled_at = now(), updated_at = now() WHERE id = $1")
        .bind(id)
        .execute(&mut *tx)
        .await?;
    sqlx::query("UPDATE subscription_visits SET state = 'cancelled', updated_at = now() WHERE subscription_id = $1 AND state = 'planned'")
        .bind(id)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    let booked: Vec<Option<Uuid>> = sqlx::query_scalar(&format!(
        "SELECT v.booking_id FROM subscription_visits v JOIN bookings b ON b.id = v.booking_id
         WHERE v.subscription_id = $1 AND v.state = 'booked' AND b.status >= 0 AND v.visit_date >= {KST_TODAY} ORDER BY v.visit_date"
    ))
    .bind(id)
    .fetch_all(&s.db)
    .await?;
    audit(&s.db, "customer", Some(a.id), "subscription.cancel", &id.to_string(), json!({})).await?;
    let mut out = view(&s.db, id).await?;
    out["booked_visits"] = json!(booked.into_iter().flatten().collect::<Vec<Uuid>>());
    Ok(Json(out))
}

#[derive(sqlx::FromRow)]
struct VisitRow {
    state: String,
    visit_date: NaiveDate,
    booking_id: Option<Uuid>,
}

async fn visit_of(db: &PgPool, sub: Uuid, visit: Uuid) -> ApiResult<VisitRow> {
    sqlx::query_as("SELECT state, visit_date, booking_id FROM subscription_visits WHERE id = $1 AND subscription_id = $2")
        .bind(visit)
        .bind(sub)
        .fetch_optional(db)
        .await?
        .ok_or(ApiError::NotFound)
}

async fn set_visit_state(db: &PgPool, visit: Uuid, from: &str, to: &str) -> ApiResult<()> {
    let n = sqlx::query("UPDATE subscription_visits SET state = $3, updated_at = now() WHERE id = $1 AND state = $2")
        .bind(visit)
        .bind(from)
        .bind(to)
        .execute(db)
        .await?
        .rows_affected();
    if n == 0 { Err(ApiError::Conflict("invalid_visit_state")) } else { Ok(()) }
}

#[derive(Deserialize, Default)]
struct SkipBody {
    /// The cancel fee the customer saw in the booking preview, for a visit that is already booked.
    accepted_fee: Option<i64>,
}

/// Skips one visit. Planned: no money has moved, so it is just dropped. Booked: the booking is cancelled
/// with the per-visit cancel-fee policy (same rules and `accepted_fee` check as a booking cancel).
async fn skip(State(s): State<AppState>, Customer(a): Customer, Path((id, visit)): Path<(Uuid, Uuid)>, body: Option<Json<SkipBody>>) -> ApiResult<Json<Value>> {
    owned_sub(&s.db, a.id, id).await?;
    let v = visit_of(&s.db, id, visit).await?;
    match v.state.as_str() {
        "planned" => {
            if charge_due(v.visit_date) {
                return Err(ApiError::Conflict("visit_charge_due"));
            }
            set_visit_state(&s.db, visit, "planned", "skipped").await?;
        }
        "booked" => {
            let booking = v.booking_id.ok_or_else(|| ApiError::Internal("booked visit without booking".into()))?;
            let accepted = body.and_then(|Json(b)| b.accepted_fee);
            cancel_owned(&s, a.id, booking, accepted).await?;
            set_visit_state(&s.db, visit, "booked", "skipped").await?;
        }
        _ => return Err(ApiError::Conflict("visit_not_skippable")),
    }
    Ok(Json(view(&s.db, id).await?))
}

#[derive(Deserialize)]
struct VisitMove {
    visit_date: NaiveDate,
    start_hour: u8,
}

/// Moves one planned visit. A booked visit moves through the booking reschedule route instead.
async fn reschedule_visit(
    State(s): State<AppState>,
    Customer(a): Customer,
    Path((id, visit)): Path<(Uuid, Uuid)>,
    Json(m): Json<VisitMove>,
) -> ApiResult<Json<Value>> {
    owned_sub(&s.db, a.id, id).await?;
    let v = visit_of(&s.db, id, visit).await?;
    match v.state.as_str() {
        "planned" => {}
        "booked" => return Err(ApiError::Conflict("use_booking_reschedule")),
        _ => return Err(ApiError::Conflict("visit_not_reschedulable")),
    }
    if charge_due(v.visit_date) || charge_due(m.visit_date) {
        return Err(ApiError::Conflict("visit_charge_due"));
    }
    check_date(today_kst(), m.visit_date)?;
    check_slot(false, m.start_hour)?;
    let mut tx = s.db.begin().await?;
    let (used, cap) = lock_and_count_slot(&mut tx, m.visit_date, m.start_hour, None).await?;
    check_capacity(used, cap)?;
    let moved = sqlx::query(
        "UPDATE subscription_visits SET visit_date = $3, start_hour = $4, updated_at = now()
         WHERE id = $1 AND state = 'planned'
           AND NOT EXISTS (SELECT 1 FROM subscription_visits x WHERE x.subscription_id = $2 AND x.visit_date = $3 AND x.id <> $1)",
    )
    .bind(visit)
    .bind(id)
    .bind(m.visit_date)
    .bind(i16::from(m.start_hour))
    .execute(&mut *tx)
    .await?
    .rows_affected();
    if moved == 0 {
        return Err(ApiError::Conflict("visit_exists"));
    }
    tx.commit().await?;
    Ok(Json(view(&s.db, id).await?))
}

#[derive(Serialize, sqlx::FromRow)]
struct PartnerRow {
    id: Uuid,
    service_code: String,
    cadence_weeks: i16,
    weekday: i16,
    start_hour: i16,
    status: String,
    district_code: String,
    next_visit_date: Option<NaiveDate>,
}

/// Recurring customers this partner serves: preferred, or holding a subscription booking. District only.
async fn partner_list(State(s): State<AppState>, Pro(a): Pro) -> ApiResult<Json<Vec<PartnerRow>>> {
    let rows: Vec<PartnerRow> = sqlx::query_as(&format!(
        "SELECT s.id, s.service_code, s.cadence_weeks, s.weekday, s.start_hour, s.status, ad.district_code,
           (SELECT min(v.visit_date) FROM subscription_visits v
             WHERE v.subscription_id = s.id AND v.state IN ('planned', 'booked') AND v.visit_date >= {KST_TODAY}) AS next_visit_date
         FROM subscriptions s JOIN addresses ad ON ad.id = s.address_id
         WHERE s.status <> 'cancelled'
           AND (s.preferred_pro_id = $1 OR EXISTS (SELECT 1 FROM bookings b WHERE b.subscription_id = s.id AND b.pro_id = $1))
         ORDER BY next_visit_date NULLS LAST, s.id LIMIT 200"
    ))
    .bind(a.id)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}

#[derive(Deserialize)]
struct StatusQuery {
    status: Option<String>,
}

async fn admin_list(State(s): State<AppState>, Admin(_): Admin, Query(q): Query<StatusQuery>) -> ApiResult<Json<Vec<SubView>>> {
    let rows: Vec<SubView> = sqlx::query_as(&format!(
        "SELECT {SUB_COLS} FROM subscriptions s WHERE ($1::text IS NULL OR s.status = $1) ORDER BY s.created_at DESC LIMIT 200"
    ))
    .bind(q.status)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}

async fn admin_detail(State(s): State<AppState>, Admin(_): Admin, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    Ok(Json(view(&s.db, id).await?))
}

async fn admin_pause(State(s): State<AppState>, Admin(a): Admin, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    transition(&s.db, id, "active", "paused", Some("staff")).await?;
    audit(&s.db, "staff", Some(a.id), "subscription.pause", &id.to_string(), json!({})).await?;
    Ok(Json(view(&s.db, id).await?))
}

async fn admin_resume(State(s): State<AppState>, Admin(a): Admin, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    transition(&s.db, id, "paused", "active", None).await?;
    audit(&s.db, "staff", Some(a.id), "subscription.resume", &id.to_string(), json!({})).await?;
    Ok(Json(view(&s.db, id).await?))
}

#[derive(Deserialize)]
struct EditSub {
    cadence_weeks: Option<i64>,
    weekday: Option<u8>,
    start_hour: Option<u8>,
    preferred_pro_id: Option<Uuid>,
}

/// Edits a subscription on the customer's behalf. Planned visits after tomorrow are re-planned on the new schedule;
/// tomorrow's visit keeps its charge. Every change is audited with the before and after values.
async fn admin_edit(State(s): State<AppState>, Admin(a): Admin, Path(id): Path<Uuid>, Json(e): Json<EditSub>) -> ApiResult<Json<Value>> {
    let before = fetch(&s.db, id).await?;
    if before.status == "cancelled" {
        return Err(ApiError::Conflict("invalid_subscription_state"));
    }
    let cadence = Cadence::from_weeks(e.cadence_weeks.unwrap_or(i64::from(before.cadence_weeks)))?;
    let weekday_index = e.weekday.unwrap_or(before.weekday as u8);
    let weekday = weekday_from_index(weekday_index)?;
    let hour = e.start_hour.unwrap_or(before.start_hour as u8);
    check_slot(false, hour)?;
    let anchor = if i16::from(weekday_index) == before.weekday {
        before.anchor_date
    } else {
        first_visit(today_kst() + Duration::days(1), weekday)
    };
    let mut tx = s.db.begin().await?;
    sqlx::query(
        "UPDATE subscriptions SET cadence_weeks = $2, weekday = $3, start_hour = $4, anchor_date = $5,
           preferred_pro_id = COALESCE($6, preferred_pro_id), updated_at = now()
         WHERE id = $1",
    )
    .bind(id)
    .bind(cadence.weeks() as i16)
    .bind(i16::from(weekday_index))
    .bind(i16::from(hour))
    .bind(anchor)
    .bind(e.preferred_pro_id)
    .execute(&mut *tx)
    .await?;
    sqlx::query(&format!(
        "DELETE FROM subscription_visits WHERE subscription_id = $1 AND state = 'planned' AND visit_date > {KST_TODAY} + 1"
    ))
    .bind(id)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    plan_subscription(&s.db, id).await?;
    let after = fetch(&s.db, id).await?;
    audit(
        &s.db,
        "staff",
        Some(a.id),
        "subscription.edit",
        &id.to_string(),
        json!({
            "before": { "cadence_weeks": before.cadence_weeks, "weekday": before.weekday, "start_hour": before.start_hour },
            "after": { "cadence_weeks": after.cadence_weeks, "weekday": after.weekday, "start_hour": after.start_hour, "preferred_pro_id": after.preferred_pro_id },
        }),
    )
    .await?;
    Ok(Json(view(&s.db, id).await?))
}

async fn public_policy(State(s): State<AppState>) -> ApiResult<Json<Value>> {
    let (policy, is_default) = load_policy(&s.db).await?;
    Ok(Json(json!({ "discount_percent": policy.discount_percent, "is_default": is_default })))
}

async fn admin_policy(State(s): State<AppState>, Admin(_): Admin) -> ApiResult<Json<Value>> {
    let (policy, is_default) = load_policy(&s.db).await?;
    Ok(Json(json!({ "policy": policy, "is_default": is_default })))
}

async fn admin_set_policy(State(s): State<AppState>, Admin(a): Admin, Json(p): Json<Policy>) -> ApiResult<Json<Value>> {
    p.validate()?;
    sqlx::query("INSERT INTO settings (key, value) VALUES ($1, $2) ON CONFLICT (key) DO UPDATE SET value = $2")
        .bind(POLICY_KEY)
        .bind(json!(p))
        .execute(&s.db)
        .await?;
    audit(&s.db, "staff", Some(a.id), "subscription_policy.update", POLICY_KEY, json!(p)).await?;
    Ok(Json(json!({ "policy": p, "is_default": false })))
}

#[derive(Deserialize)]
struct MetricsQuery {
    from: Option<NaiveDate>,
    to: Option<NaiveDate>,
}

async fn admin_metrics(State(s): State<AppState>, Admin(_): Admin, Query(q): Query<MetricsQuery>) -> ApiResult<Json<Value>> {
    let to = q.to.unwrap_or_else(today_kst);
    let from = q.from.unwrap_or(to - Duration::days(29));
    if from > to {
        return Err(ApiError::BadRequest("invalid_period"));
    }
    Ok(Json(recurring_metrics(&s.db, from, to).await?))
}

/// Recurring revenue over `[from, to]` (KST dates). MRR and `active` are as of now (active subscriptions only).
/// `started` and `cancelled` count events in the period; `churn_bps` is cancellations over the base active at `from`.
/// `recognized` is each subscription's monthly amount prorated to its live days in the period; it is exact when the
/// period is one calendar month. Prices are today's list prices less each subscription's discount snapshot.
pub async fn recurring_metrics(db: &PgPool, from: NaiveDate, to: NaiveDate) -> ApiResult<Value> {
    #[derive(sqlx::FromRow)]
    struct Row {
        status: String,
        service_code: String,
        unit_index: Option<i16>,
        unit_counts: Option<Vec<i16>>,
        cadence_weeks: i16,
        discount_percent: i16,
        started: NaiveDate,
        ended: Option<NaiveDate>,
    }
    let rows: Vec<Row> = sqlx::query_as(
        "SELECT s.status, s.service_code, s.unit_index, s.unit_counts, s.cadence_weeks, s.discount_percent,
           (s.created_at AT TIME ZONE 'Asia/Seoul')::date AS started,
           (s.cancelled_at AT TIME ZONE 'Asia/Seoul')::date AS ended
         FROM subscriptions s
         WHERE s.status <> 'cancelled' OR (s.cancelled_at AT TIME ZONE 'Asia/Seoul')::date >= $1",
    )
    .bind(from)
    .fetch_all(db)
    .await?;
    let period_days = u32::try_from((to - from).num_days() + 1).unwrap_or(0);
    let (mut mrr, mut recognized) = (0i64, 0i64);
    let (mut active, mut at_start, mut started_in, mut cancelled_in) = (0u32, 0u32, 0u32, 0u32);
    for r in &rows {
        let service = load_service(db, &r.service_code).await?;
        let counts = super::booking_core::counts_from_row(r.unit_counts.clone());
        let list = price_booking_with(&service, r.unit_index.map(|u| u as usize), &counts, None, Utc::now())?.list_price;
        let total = visit_price(list.0, u8::try_from(r.discount_percent).unwrap_or(0))?.total;
        let monthly = monthly_equivalent(total, Cadence::from_weeks(i64::from(r.cadence_weeks))?);
        recognized += prorate(monthly, active_days(r.started, r.ended, from, to), period_days);
        if r.status == "active" {
            active += 1;
            mrr += monthly;
        }
        if r.started < from && r.ended.is_none_or(|e| e >= from) {
            at_start += 1;
        }
        if r.started >= from && r.started <= to {
            started_in += 1;
        }
        if r.ended.is_some_and(|e| e >= from && e <= to) {
            cancelled_in += 1;
        }
    }
    Ok(json!({
        "from": from,
        "to": to,
        "active": active,
        "mrr": mrr,
        "recognized": recognized,
        "started": started_in,
        "cancelled": cancelled_in,
        "active_at_start": at_start,
        "churn_bps": churn_bps(at_start, cancelled_in),
    }))
}
