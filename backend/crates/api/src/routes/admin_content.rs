//! Console: catalogue, pricing settings, coupons, content, pros, settlements, staff, customers.

use super::{audit, uploads};
use crate::{
    auth::{Admin, Staff, hash_password, normalize_phone},
    contract,
    error::{ApiError, ApiResult},
    realtime::{Recipient, notify},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Path, Query, State},
    routing::{get, post, put},
};
use chrono::{DateTime, Duration, Utc};
use domain::{catalog::Pricing, coupon::COUPON_LIFETIME_DAYS, quote::QuoteFormula};
use serde::Deserialize;
use serde_json::{Value, json};
use uuid::Uuid;

const LIST_LIMIT: i64 = 200;
const MIN_STAFF_PASSWORD: usize = 12;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/services", get(list_services))
        .route("/services/{code}", put(update_service))
        .route("/slot-capacity", get(get_capacity).put(put_capacity))
        .route("/quote-formula", get(get_formula).put(put_formula))
        .route("/coupons", post(issue_coupons))
        .route("/content", get(list_content).post(create_content))
        .route("/content/{id}", put(update_content).delete(delete_content))
        .route("/customers", get(customers))
        .route("/pros", get(list_pros))
        .route("/pros/{id}/status", post(set_pro_status))
        .route("/settlements", get(list_settlements))
        .route("/settlements/payouts", get(super::payouts::list_payouts))
        .route("/settlements/run-payouts", post(super::payouts::run_payouts))
        .route("/settlements/toss-sellers/{pro_id}", post(super::payouts::register_seller))
        .route("/settlements/payouts/{id}/account", get(super::payouts::reveal_account))
        .route("/settlements/partners/{pro_id}/tax-type", post(super::payouts::set_tax_type))
        .route("/settlements/payouts/{id}/{action}", crate::idempotency::replayable(post(super::payouts::act)))
        .route("/settlements/{id}/hold", post(hold_settlement))
        .route("/staff", get(list_staff).post(create_staff))
        .route("/staff/{id}/active", post(set_staff_active))
}

async fn list_services(State(s): State<AppState>, _st: Staff) -> ApiResult<Json<Value>> {
    let v: Value = sqlx::query_scalar("SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.sort_order), '[]') FROM (SELECT code, pricing, needs_preparation, max_pyeong, content, active, sort_order FROM services) x")
        .fetch_one(&s.db)
        .await?;
    Ok(Json(v))
}

#[derive(Deserialize)]
struct ServiceUpdate {
    pricing: Pricing,
    needs_preparation: bool,
    max_pyeong: Option<i16>,
    content: Value,
    active: bool,
    sort_order: i32,
}

async fn update_service(State(s): State<AppState>, Admin(a): Admin, Path(code): Path<String>, Json(u): Json<ServiceUpdate>) -> ApiResult<Json<Value>> {
    let valid_prices = match &u.pricing {
        Pricing::Fixed { price, minutes } => price.0 > 0 && *minutes > 0,
        Pricing::Unit { units } => !units.is_empty() && units.iter().all(|x| x.price.0 > 0 && x.minutes > 0),
        Pricing::Quote => true,
    };
    if !valid_prices || !u.content.is_object() {
        return Err(ApiError::BadRequest("invalid_service"));
    }
    let r = sqlx::query(
        "UPDATE services SET pricing=$2, needs_preparation=$3, max_pyeong=$4, content=$5, active=$6, sort_order=$7, updated_at=now() WHERE code=$1",
    )
    .bind(&code)
    .bind(sqlx::types::Json(&u.pricing))
    .bind(u.needs_preparation)
    .bind(u.max_pyeong)
    .bind(&u.content)
    .bind(u.active)
    .bind(u.sort_order)
    .execute(&s.db)
    .await?;
    if r.rows_affected() == 0 {
        return Err(ApiError::NotFound);
    }
    audit(&s.db, "staff", Some(a.id), "service.update", &code, json!({ "pricing": u.pricing })).await?;
    Ok(Json(json!({ "ok": true })))
}

async fn get_capacity(State(s): State<AppState>, _st: Staff) -> ApiResult<Json<Vec<(i16, Option<i32>)>>> {
    Ok(Json(
        sqlx::query_as("SELECT start_hour, capacity FROM slot_capacity ORDER BY start_hour")
            .fetch_all(&s.db)
            .await?,
    ))
}

async fn put_capacity(State(s): State<AppState>, Admin(a): Admin, Json(rows): Json<Vec<(i16, Option<i32>)>>) -> ApiResult<Json<Value>> {
    for (h, cap) in &rows {
        if !(0..24).contains(h) || cap.is_some_and(|c| c < 0) {
            return Err(ApiError::BadRequest("invalid_capacity"));
        }
        sqlx::query("INSERT INTO slot_capacity (start_hour, capacity) VALUES ($1,$2) ON CONFLICT (start_hour) DO UPDATE SET capacity = $2")
            .bind(h)
            .bind(cap)
            .execute(&s.db)
            .await?;
    }
    audit(&s.db, "staff", Some(a.id), "capacity.update", "slots", json!(rows)).await?;
    Ok(Json(json!({ "ok": true })))
}

async fn get_formula(State(s): State<AppState>, _st: Staff) -> ApiResult<Json<QuoteFormula>> {
    Ok(Json(super::catalog::load_formula(&s.db).await?))
}

async fn put_formula(State(s): State<AppState>, Admin(a): Admin, Json(f): Json<QuoteFormula>) -> ApiResult<Json<Value>> {
    if f.vat_bps < 0 || f.deposit_bps <= 0 || f.deposit_bps > 10_000 || f.base_studio.0 <= 0 {
        return Err(ApiError::BadRequest("invalid_formula"));
    }
    sqlx::query("INSERT INTO settings (key, value) VALUES ('quote_formula', $1) ON CONFLICT (key) DO UPDATE SET value = $1, updated_at = now()")
        .bind(sqlx::types::Json(&f))
        .execute(&s.db)
        .await?;
    audit(&s.db, "staff", Some(a.id), "formula.update", "quote_formula", json!(f)).await?;
    Ok(Json(json!({ "ok": true })))
}

#[derive(Deserialize)]
struct IssueCoupons {
    name: String,
    amount: i64,
    service_code: Option<String>,
    campaign: Option<String>,
    /// Specific customers by phone; empty + `all_customers` sends to everyone.
    #[serde(default)]
    phones: Vec<String>,
    #[serde(default)]
    all_customers: bool,
}

async fn issue_coupons(State(s): State<AppState>, Admin(a): Admin, Json(c): Json<IssueCoupons>) -> ApiResult<Json<Value>> {
    if c.amount <= 0 || c.name.trim().is_empty() || (c.phones.is_empty() && !c.all_customers) {
        return Err(ApiError::BadRequest("invalid_coupon"));
    }
    let phones: Vec<String> = c.phones.iter().filter_map(|p| normalize_phone(p)).collect();
    let now = Utc::now();
    let issued = sqlx::query(
        "INSERT INTO coupons (user_id, name, amount, service_code, campaign, issued_at, expires_at)
         SELECT id, $1, $2, $3, $4, $5, $6 FROM users WHERE deleted_at IS NULL AND ($7 OR phone = ANY($8))",
    )
    .bind(c.name.trim())
    .bind(c.amount)
    .bind(&c.service_code)
    .bind(&c.campaign)
    .bind(now)
    .bind(now + Duration::days(COUPON_LIFETIME_DAYS))
    .bind(c.all_customers)
    .bind(&phones)
    .execute(&s.db)
    .await?
    .rows_affected();
    audit(
        &s.db,
        "staff",
        Some(a.id),
        "coupon.issue",
        &c.name,
        json!({ "amount": c.amount, "count": issued }),
    )
    .await?;
    Ok(Json(json!({ "issued": issued })))
}

#[derive(Deserialize)]
struct ContentKind {
    kind: Option<String>,
}

async fn list_content(State(s): State<AppState>, _st: Staff, Query(q): Query<ContentKind>) -> ApiResult<Json<Value>> {
    let v: Value = sqlx::query_scalar(
        "SELECT COALESCE(jsonb_agg(to_jsonb(c) ORDER BY c.kind, c.sort_order), '[]') FROM content_items c WHERE $1::text IS NULL OR c.kind = $1",
    )
    .bind(q.kind)
    .fetch_one(&s.db)
    .await?;
    Ok(Json(v))
}

#[derive(Deserialize)]
struct ContentInput {
    kind: String,
    slug: Option<String>,
    title: Value,
    body: Value,
    image_url: Option<String>,
    link: Option<String>,
    sort_order: i32,
    starts_at: Option<DateTime<Utc>>,
    ends_at: Option<DateTime<Utc>>,
    active: bool,
}

impl ContentInput {
    /// Our uploads are stored as plain `/files/<name>` paths, never as expiring signed links.
    fn stored_image(&self, base: &str) -> Option<String> {
        self.image_url.as_deref().map(|u| crate::util::own_upload(base, u).unwrap_or_else(|| u.to_string()))
    }

    async fn validate(&self, s: &AppState) -> ApiResult<()> {
        // Links and images end up in customer apps: allow only https or in-app routes, and our own uploads.
        let safe_link = self
            .link
            .as_deref()
            .is_none_or(|l| l.starts_with("https://") || l.chars().all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '/'));
        let safe_image = self.image_url.as_deref().is_none_or(|u| u.starts_with("https://") || crate::util::own_upload(&s.config.public_base_url, u).is_some());
        let ok = matches!(self.kind.as_str(), "notice" | "tip" | "faq" | "banner" | "legal")
            && self.title.is_object()
            && self.body.is_object()
            && safe_link
            && safe_image;
        if !ok {
            return Err(ApiError::BadRequest("invalid_content"));
        }
        // A stored image must be a real upload (any uploader: staff may pick any photo).
        if let Some(path) = self.stored_image(&s.config.public_base_url).filter(|p| p.starts_with("/files/"))
            && !uploads::owned(&s.db, None, &[path]).await?
        {
            return Err(ApiError::BadRequest("invalid_content"));
        }
        Ok(())
    }
}

async fn create_content(State(s): State<AppState>, Admin(st): Admin, Json(c): Json<ContentInput>) -> ApiResult<Json<Value>> {
    c.validate(&s).await?;
    let id: Uuid = sqlx::query_scalar("INSERT INTO content_items (kind, slug, title, body, image_url, link, sort_order, starts_at, ends_at, active) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING id")
        .bind(&c.kind).bind(&c.slug).bind(&c.title).bind(&c.body).bind(c.stored_image(&s.config.public_base_url)).bind(&c.link).bind(c.sort_order).bind(c.starts_at).bind(c.ends_at).bind(c.active)
        .fetch_one(&s.db)
        .await?;
    audit(&s.db, "staff", Some(st.id), "content.create", &id.to_string(), json!({ "kind": c.kind })).await?;
    Ok(Json(json!({ "id": id })))
}

async fn update_content(State(s): State<AppState>, Admin(st): Admin, Path(id): Path<Uuid>, Json(c): Json<ContentInput>) -> ApiResult<Json<Value>> {
    c.validate(&s).await?;
    sqlx::query(
        "UPDATE content_items SET kind=$2, slug=$3, title=$4, body=$5, image_url=$6, link=$7, sort_order=$8, starts_at=$9, ends_at=$10, active=$11 WHERE id=$1",
    )
    .bind(id)
    .bind(&c.kind)
    .bind(&c.slug)
    .bind(&c.title)
    .bind(&c.body)
    .bind(c.stored_image(&s.config.public_base_url))
    .bind(&c.link)
    .bind(c.sort_order)
    .bind(c.starts_at)
    .bind(c.ends_at)
    .bind(c.active)
    .execute(&s.db)
    .await?;
    audit(&s.db, "staff", Some(st.id), "content.update", &id.to_string(), json!({})).await?;
    Ok(Json(json!({ "ok": true })))
}

async fn delete_content(State(s): State<AppState>, Admin(st): Admin, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    sqlx::query("DELETE FROM content_items WHERE id = $1").bind(id).execute(&s.db).await?;
    audit(&s.db, "staff", Some(st.id), "content.delete", &id.to_string(), json!({})).await?;
    Ok(Json(json!({ "ok": true })))
}

#[derive(Deserialize)]
struct Search {
    q: Option<String>,
}

async fn customers(State(s): State<AppState>, Staff(st): Staff, Query(q): Query<Search>) -> ApiResult<Json<Value>> {
    let like = q.q.map(|x| format!("%{}%", x.replace(['%', '_'], "")));
    audit(&s.db, "staff", Some(st.id), "customer.pii_list", "users", json!({ "searched": like.is_some() })).await?;
    let v: Value = sqlx::query_scalar(
        "SELECT COALESCE(jsonb_agg(x), '[]') FROM (SELECT u.id, u.name, u.phone, u.created_at, (SELECT count(*) FROM bookings b WHERE b.user_id = u.id) AS bookings
         FROM users u WHERE u.deleted_at IS NULL AND ($1::text IS NULL OR u.phone LIKE $1 OR u.name ILIKE $1) ORDER BY u.created_at DESC LIMIT $2) x",
    )
    .bind(like)
    .bind(LIST_LIMIT)
    .fetch_one(&s.db)
    .await?;
    Ok(Json(v))
}

async fn list_pros(State(s): State<AppState>, _st: Staff) -> ApiResult<Json<Value>> {
    let v: Value = sqlx::query_scalar(
        "SELECT COALESCE(jsonb_agg(x), '[]') FROM (SELECT p.id, p.name, p.team_name, p.phone, p.status, p.fee_bps, p.created_at,
           (SELECT count(*) FROM bookings b WHERE b.pro_id = p.id AND b.status = 3) AS completed,
           (SELECT count(*) FROM bookings b WHERE b.pro_id = p.id AND b.status = -1) AS cancelled,
           (SELECT round(avg(rating)::numeric, 2) FROM reviews r WHERE r.pro_id = p.id AND NOT r.hidden) AS rating
         FROM pros p ORDER BY p.status, p.created_at DESC LIMIT $1) x",
    )
    .bind(LIST_LIMIT)
    .fetch_one(&s.db)
    .await?;
    Ok(Json(v))
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct ProStatus {
    status: String,
    fee_bps: Option<i32>,
}

async fn set_pro_status(State(s): State<AppState>, Admin(a): Admin, Path(id): Path<Uuid>, Json(p): Json<ProStatus>) -> ApiResult<Json<Value>> {
    if !matches!(p.status.as_str(), "pending" | "verified" | "suspended") || p.fee_bps.is_some_and(|f| !(0..=5_000).contains(&f)) {
        return Err(ApiError::BadRequest("invalid_status"));
    }
    sqlx::query("UPDATE pros SET status = $2, fee_bps = COALESCE($3, fee_bps) WHERE id = $1")
        .bind(id)
        .bind(&p.status)
        .bind(p.fee_bps)
        .execute(&s.db)
        .await?;
    audit(
        &s.db,
        "staff",
        Some(a.id),
        "pro.status",
        &id.to_string(),
        json!({ "status": p.status, "fee_bps": p.fee_bps }),
    )
    .await?;
    notify(&s, Recipient::Pro(id), "pro.status", "계정 상태", &p.status, json!({ "status": p.status })).await?;
    Ok(Json(json!({ "ok": true })))
}

#[derive(Deserialize)]
struct SettlementFilter {
    state: Option<String>,
}

async fn list_settlements(State(s): State<AppState>, _st: Staff, Query(f): Query<SettlementFilter>) -> ApiResult<Json<Value>> {
    let v: Value = sqlx::query_scalar(
        "SELECT COALESCE(jsonb_agg(x), '[]') FROM (SELECT st.*, p.name AS pro_name, p.team_name, b.number FROM settlements st JOIN pros p ON p.id = st.pro_id JOIN bookings b ON b.id = st.booking_id
         WHERE $1::text IS NULL OR st.state = $1 ORDER BY st.payout_date NULLS LAST, st.created_at LIMIT $2) x",
    )
    .bind(f.state)
    .bind(LIST_LIMIT)
    .fetch_one(&s.db)
    .await?;
    Ok(Json(v))
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct Hold {
    hold: bool,
}

async fn hold_settlement(State(s): State<AppState>, Admin(a): Admin, Path(id): Path<Uuid>, Json(h): Json<Hold>) -> ApiResult<Json<Value>> {
    let (from, to) = if h.hold { ("pending", "held") } else { ("held", "pending") };
    let r = sqlx::query("UPDATE settlements SET state = $3 WHERE id = $1 AND state = $2 AND payout_id IS NULL")
        .bind(id)
        .bind(from)
        .bind(to)
        .execute(&s.db)
        .await?;
    if r.rows_affected() == 0 {
        return Err(ApiError::Conflict("settlement_state"));
    }
    audit(&s.db, "staff", Some(a.id), "settlement.hold", &id.to_string(), json!({ "hold": h.hold })).await?;
    Ok(Json(json!({ "ok": true })))
}

async fn list_staff(State(s): State<AppState>, _a: Admin) -> ApiResult<Json<Value>> {
    let v: Value = sqlx::query_scalar("SELECT COALESCE(jsonb_agg(jsonb_build_object('id', id, 'email', email, 'name', name, 'role', role, 'active', active) ORDER BY created_at), '[]') FROM staff")
        .fetch_one(&s.db)
        .await?;
    Ok(Json(v))
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct NewStaff {
    email: String,
    name: String,
    role: String,
    password: String,
}

async fn create_staff(State(s): State<AppState>, Admin(a): Admin, Json(n): Json<NewStaff>) -> ApiResult<Json<Value>> {
    let too_long = n.email.len() > contract::MAX_EMAIL_BYTES
        || n.name.chars().count() > contract::MAX_TEXT_CHARS
        || n.password.len() > contract::MAX_PASSWORD_BYTES;
    if too_long || !n.email.contains('@') || n.name.trim().is_empty() || !matches!(n.role.as_str(), "admin" | "consultant") || n.password.len() < MIN_STAFF_PASSWORD {
        return Err(ApiError::BadRequest("invalid_staff"));
    }
    let id: Uuid = sqlx::query_scalar("INSERT INTO staff (email, name, role, password_hash) VALUES ($1,$2,$3,$4) RETURNING id")
        .bind(n.email.trim().to_lowercase())
        .bind(n.name.trim())
        .bind(&n.role)
        .bind(hash_password(&n.password)?)
        .fetch_one(&s.db)
        .await
        .map_err(|e| {
            if matches!(&e, sqlx::Error::Database(d) if d.is_unique_violation()) {
                ApiError::Conflict("email_taken")
            } else {
                e.into()
            }
        })?;
    audit(&s.db, "staff", Some(a.id), "staff.create", &id.to_string(), json!({ "role": n.role })).await?;
    Ok(Json(json!({ "id": id })))
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct Active {
    active: bool,
}

async fn set_staff_active(State(s): State<AppState>, Admin(a): Admin, Path(id): Path<Uuid>, Json(x): Json<Active>) -> ApiResult<Json<Value>> {
    if id == a.id && !x.active {
        return Err(ApiError::BadRequest("cannot_deactivate_self"));
    }
    sqlx::query("UPDATE staff SET active = $2 WHERE id = $1")
        .bind(id)
        .bind(x.active)
        .execute(&s.db)
        .await?;
    if !x.active {
        sqlx::query("UPDATE refresh_tokens SET revoked_at = now() WHERE subject = $1")
            .bind(id)
            .execute(&s.db)
            .await?;
    }
    audit(&s.db, "staff", Some(a.id), "staff.active", &id.to_string(), json!({ "active": x.active })).await?;
    Ok(Json(json!({ "ok": true })))
}
