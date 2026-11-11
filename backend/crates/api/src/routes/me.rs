//! Customer account: profile, addresses, coupons, payment methods, devices, notifications.

use super::auth::{PhoneBind, conflict_on_unique, consume_otp};
use crate::{
    auth::{Auth, Customer, normalize_phone, sha256_hex},
    contract::{PageQuery, cursor_part, decode_cursor, encode_cursor, page_limit, paged, ts_key},
    error::{ApiError, ApiResult},
    providers::{ProviderError, portone},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Path, Query, State},
    response::Response,
    routing::{delete, get, post, put},
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use uuid::Uuid;

pub const SUPPORTED_LOCALES: [&str; 14] = ["ko", "en", "zh", "vi", "ja", "ru", "ne", "si", "th", "id", "mn", "uz", "fil", "km"];
const MAX_NAME_LEN: usize = 40;
const MAX_ADDRESS_LEN: usize = 200;


pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/me", get(profile).patch(update_profile).delete(delete_account))
        .route("/me/phone", post(bind_phone))
        .route("/me/identity", post(verify_identity))
        .route("/me/identity/setup", get(identity_setup))
        .route("/me/identity/session", post(identity_session))
        .route("/me/addresses", get(list_addresses).post(create_address))
        .route("/me/addresses/{id}", put(update_address).delete(delete_address))
        .route("/me/coupons", get(list_coupons))
        .route("/me/payment-methods", get(list_methods).post(register_method))
        .route("/me/payment-methods/setup", get(billing_setup))
        .route("/me/payment-methods/{id}", delete(delete_method))
        .route("/me/push-token", post(register_push).delete(unregister_push))
        .route("/me/notifications", get(list_notifications))
        .route("/me/notifications/read", post(read_notifications))
        .route("/me/consents", get(crate::privacy::get_consents).put(crate::privacy::put_consents))
        .route("/me/export", get(crate::privacy::export))
}

#[derive(Serialize, sqlx::FromRow)]
struct Profile {
    id: Uuid,
    phone: Option<String>,
    phone_verified: bool,
    name: String,
    email: Option<String>,
    locale: String,
    created_at: DateTime<Utc>,
}

async fn profile(State(s): State<AppState>, Customer(a): Customer) -> ApiResult<Json<Profile>> {
    let p = sqlx::query_as(
        "SELECT id, phone, phone IS NOT NULL AS phone_verified, name, email, locale, created_at FROM users WHERE id = $1 AND deleted_at IS NULL",
    )
    .bind(a.id)
    .fetch_one(&s.db)
    .await?;
    Ok(Json(p))
}

/// Binds a phone number proven by a login code. A number held by another account is a conflict.
async fn bind_phone(State(s): State<AppState>, Customer(a): Customer, Json(b): Json<PhoneBind>) -> ApiResult<Json<Profile>> {
    let phone = normalize_phone(&b.phone).ok_or(ApiError::BadRequest("invalid_phone"))?;
    consume_otp(&s, &phone, &b.code).await?;
    sqlx::query("UPDATE users SET phone = $2 WHERE id = $1 AND deleted_at IS NULL")
        .bind(a.id)
        .bind(&phone)
        .execute(&s.db)
        .await
        .map_err(|e| conflict_on_unique(e, "phone_taken"))?;
    profile(State(s), Customer(a)).await
}

#[derive(Deserialize)]
struct IdentityInput {
    identity_verification_id: String,
}

/// Whether PASS can run here: dev mode always, otherwise a store id and an `identity` channel key.
fn identity_enabled(s: &AppState) -> bool {
    s.config.dev_mode || (s.config.portone.store_id.is_some() && s.config.portone.channel_keys.contains_key("identity"))
}

#[derive(Serialize)]
struct IdentitySetup {
    enabled: bool,
}

async fn identity_setup(State(s): State<AppState>, Customer(_): Customer) -> Json<IdentitySetup> {
    Json(IdentitySetup { enabled: identity_enabled(&s) })
}

#[derive(Serialize)]
struct IdentitySession {
    store_id: String,
    channel_key: String,
    identity_verification_id: String,
}

/// Issues a single-use verification id bound to this customer, before the PASS page opens.
async fn identity_session(State(s): State<AppState>, Customer(a): Customer) -> ApiResult<Json<IdentitySession>> {
    if !identity_enabled(&s) {
        return Err(ApiError::Unavailable("provider_not_configured"));
    }
    // Dev ids keep the `dev:` prefix the dev provider accepts; live ids are opaque.
    let id = if s.config.dev_mode { format!("dev:{}", Uuid::now_v7().simple()) } else { format!("idv-{}", Uuid::now_v7().simple()) };
    sqlx::query("INSERT INTO identity_sessions (id, user_id) VALUES ($1, $2)").bind(&id).bind(a.id).execute(&s.db).await?;
    Ok(Json(IdentitySession {
        store_id: s.config.portone.store_id.clone().unwrap_or_default(),
        channel_key: s.config.portone.channel_keys.get("identity").cloned().unwrap_or_default(),
        identity_verification_id: id,
    }))
}

/// PASS / 본인인증: only an id issued to this customer and still unused is checked with PortOne.
/// The id is burnt on success; only a hash of the CI is kept.
async fn verify_identity(State(s): State<AppState>, Customer(a): Customer, Json(i): Json<IdentityInput>) -> ApiResult<Json<Profile>> {
    let id = i.identity_verification_id;
    let issued: Option<String> = sqlx::query_scalar("SELECT id FROM identity_sessions WHERE id = $1 AND user_id = $2 AND used_at IS NULL")
        .bind(&id)
        .bind(a.id)
        .fetch_optional(&s.db)
        .await?;
    if issued.is_none() {
        return Err(ApiError::BadRequest("identity_not_found"));
    }
    let info = s.providers.identity(&id).await.map_err(|e| match e {
        ProviderError::NotFound => ApiError::BadRequest("identity_not_found"),
        other => other.into(),
    })?;
    let ci = match (info.status.as_str(), info.id == id, info.ci) {
        ("VERIFIED", true, Some(ci)) => ci,
        _ => return Err(ApiError::BadRequest("identity_not_verified")),
    };
    let mut tx = s.db.begin().await?;
    let burnt = sqlx::query("UPDATE identity_sessions SET used_at = now() WHERE id = $1 AND used_at IS NULL")
        .bind(&id)
        .execute(&mut *tx)
        .await?;
    if burnt.rows_affected() == 0 {
        return Err(ApiError::BadRequest("identity_not_found"));
    }
    sqlx::query("UPDATE users SET identity_verified_at = now(), ci_hash = $2, name = CASE WHEN name = '' THEN COALESCE($3, '') ELSE name END WHERE id = $1 AND deleted_at IS NULL")
        .bind(a.id)
        .bind(sha256_hex(ci.as_bytes()))
        .bind(info.name)
        .execute(&mut *tx)
        .await
        .map_err(|e| conflict_on_unique(e, "identity_taken"))?;
    tx.commit().await?;
    profile(State(s), Customer(a)).await
}

#[derive(Deserialize)]
struct ProfilePatch {
    name: Option<String>,
    email: Option<String>,
    locale: Option<String>,
}

async fn update_profile(State(s): State<AppState>, Customer(a): Customer, Json(p): Json<ProfilePatch>) -> ApiResult<Json<Profile>> {
    if p.name.as_ref().is_some_and(|n| n.chars().count() > MAX_NAME_LEN) {
        return Err(ApiError::BadRequest("name_too_long"));
    }
    if p.email.as_ref().is_some_and(|e| !e.is_empty() && !e.contains('@')) {
        return Err(ApiError::BadRequest("invalid_email"));
    }
    if p.locale.as_ref().is_some_and(|l| !SUPPORTED_LOCALES.contains(&l.as_str())) {
        return Err(ApiError::BadRequest("invalid_locale"));
    }
    let welcome_first_time = p.name.as_ref().is_some_and(|n| !n.trim().is_empty());
    sqlx::query("UPDATE users SET name = COALESCE($2, name), email = COALESCE($3, email), locale = COALESCE($4, locale) WHERE id = $1")
        .bind(a.id)
        .bind(p.name.map(|n| n.trim().to_string()))
        .bind(p.email)
        .bind(p.locale)
        .execute(&s.db)
        .await?;
    if welcome_first_time {
        issue_welcome_pack(&s, a.id).await?;
    }
    profile(State(s), Customer(a)).await
}

/// Spec rule 5: welcome pack once per account, issued when sign-up completes.
async fn issue_welcome_pack(s: &AppState, user: Uuid) -> ApiResult<()> {
    let mut tx = s.db.begin().await?;
    let claimed = sqlx::query("UPDATE users SET welcome_issued = TRUE WHERE id = $1 AND NOT welcome_issued")
        .bind(user)
        .execute(&mut *tx)
        .await?;
    if claimed.rows_affected() == 1 {
        for c in domain::coupon::welcome_pack(Utc::now()) {
            let name = if c.service_code.is_some() { "welcome_studio" } else { "welcome_any" };
            sqlx::query("INSERT INTO coupons (user_id, name, amount, service_code, campaign, issued_at, expires_at) VALUES ($1,$2,$3,$4,'welcome',$5,$6)")
                .bind(user)
                .bind(name)
                .bind(c.amount.0)
                .bind(c.service_code)
                .bind(c.issued_at)
                .bind(c.expires_at)
                .execute(&mut *tx)
                .await?;
        }
    }
    tx.commit().await?;
    Ok(())
}

/// PIPA: account deletion anonymises personal data; bookings are kept for accounting.
async fn delete_account(State(s): State<AppState>, Customer(a): Customer) -> ApiResult<Json<Value>> {
    crate::privacy::delete_account(&s, a.id).await?;
    Ok(Json(json!({ "ok": true })))
}

#[derive(Serialize, sqlx::FromRow)]
pub struct Address {
    pub id: Uuid,
    pub kind: String,
    pub label: String,
    pub road_address: String,
    pub detail: String,
    pub district_code: String,
    pub size_pyeong: i16,
}

#[derive(Deserialize)]
struct AddressInput {
    kind: String,
    label: String,
    road_address: String,
    detail: String,
    district_code: String,
    size_pyeong: i16,
}

impl AddressInput {
    fn validate(&self) -> ApiResult<()> {
        let ok = matches!(self.kind.as_str(), "home" | "office")
            && !self.label.trim().is_empty()
            && self.label.chars().count() <= MAX_NAME_LEN
            && !self.road_address.trim().is_empty()
            && self.road_address.len() <= MAX_ADDRESS_LEN
            && self.detail.len() <= MAX_ADDRESS_LEN
            && self.district_code.len() == 5
            && self.district_code.chars().all(|c| c.is_ascii_digit())
            && (1..=500).contains(&self.size_pyeong);
        if ok { Ok(()) } else { Err(ApiError::BadRequest("invalid_address")) }
    }
}

const ADDRESS_COLS: &str = "id, kind, label, road_address, detail, district_code, size_pyeong";

async fn list_addresses(State(s): State<AppState>, Customer(a): Customer) -> ApiResult<Json<Vec<Address>>> {
    let rows = sqlx::query_as(&format!(
        "SELECT {ADDRESS_COLS} FROM addresses WHERE user_id = $1 AND deleted_at IS NULL ORDER BY created_at"
    ))
    .bind(a.id)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}

async fn create_address(State(s): State<AppState>, Customer(a): Customer, Json(i): Json<AddressInput>) -> ApiResult<Json<Address>> {
    i.validate()?;
    let row = sqlx::query_as(&format!(
        "INSERT INTO addresses (user_id, kind, label, road_address, detail, district_code, size_pyeong) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING {ADDRESS_COLS}"
    ))
    .bind(a.id)
    .bind(&i.kind)
    .bind(i.label.trim())
    .bind(i.road_address.trim())
    .bind(i.detail.trim())
    .bind(&i.district_code)
    .bind(i.size_pyeong)
    .fetch_one(&s.db)
    .await?;
    Ok(Json(row))
}

async fn update_address(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>, Json(i): Json<AddressInput>) -> ApiResult<Json<Address>> {
    i.validate()?;
    // Bookings keep an address snapshot, so editing never rewrites history.
    let row = sqlx::query_as(&format!(
        "UPDATE addresses SET kind=$3, label=$4, road_address=$5, detail=$6, district_code=$7, size_pyeong=$8 WHERE id=$1 AND user_id=$2 AND deleted_at IS NULL RETURNING {ADDRESS_COLS}"
    ))
    .bind(id)
    .bind(a.id)
    .bind(&i.kind)
    .bind(i.label.trim())
    .bind(i.road_address.trim())
    .bind(i.detail.trim())
    .bind(&i.district_code)
    .bind(i.size_pyeong)
    .fetch_optional(&s.db)
    .await?
    .ok_or(ApiError::NotFound)?;
    Ok(Json(row))
}

async fn delete_address(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    let r = sqlx::query("UPDATE addresses SET deleted_at = now() WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL")
        .bind(id)
        .bind(a.id)
        .execute(&s.db)
        .await?;
    if r.rows_affected() == 0 {
        return Err(ApiError::NotFound);
    }
    Ok(Json(json!({ "ok": true })))
}

#[derive(Serialize, sqlx::FromRow)]
struct CouponRow {
    id: Uuid,
    name: String,
    amount: i64,
    service_code: Option<String>,
    issued_at: DateTime<Utc>,
    expires_at: DateTime<Utc>,
    used_booking_id: Option<Uuid>,
}

async fn list_coupons(State(s): State<AppState>, Customer(a): Customer) -> ApiResult<Json<Vec<CouponRow>>> {
    let rows = sqlx::query_as("SELECT id, name, amount, service_code, issued_at, expires_at, used_booking_id FROM coupons WHERE user_id = $1 ORDER BY (used_booking_id IS NULL AND expires_at > now()) DESC, expires_at")
        .bind(a.id)
        .fetch_all(&s.db)
        .await?;
    Ok(Json(rows))
}

#[derive(Serialize, sqlx::FromRow)]
struct MethodRow {
    id: Uuid,
    provider: String,
    display_name: String,
    created_at: DateTime<Utc>,
}

/// What the app needs to open PortOne's card registration page. Hidden (`enabled: false`) until PortOne is configured.
async fn billing_setup(State(s): State<AppState>, Customer(a): Customer) -> ApiResult<Json<Value>> {
    let integ = s.providers.integ();
    let p = &integ.portone;
    if !portone::billing_ready(p) {
        return Ok(Json(json!({ "enabled": false })));
    }
    // The ticket is stored so register_method can require it (single use, 30 minutes).
    let issue: Uuid = sqlx::query_scalar("INSERT INTO billing_issues (id, user_id, expires_at) VALUES ($1, $2, now() + interval '30 minutes') RETURNING id")
        .bind(Uuid::now_v7())
        .bind(a.id)
        .fetch_one(&s.db)
        .await?;
    Ok(Json(json!({
        "enabled": true,
        "store_id": p.store_id,
        "channels": p.channel_keys,
        "issue_id": issue,
        "customer_id": a.id,
    })))
}

async fn list_methods(State(s): State<AppState>, Customer(a): Customer) -> ApiResult<Json<Vec<MethodRow>>> {
    let rows =
        sqlx::query_as("SELECT id, provider, display_name, created_at FROM payment_methods WHERE user_id = $1 AND deleted_at IS NULL ORDER BY created_at")
            .bind(a.id)
            .fetch_all(&s.db)
            .await?;
    Ok(Json(rows))
}

#[derive(Deserialize)]
struct RegisterMethod {
    provider: String,
    /// Result of the gateway's card-registration UI; never a card number.
    auth_key: String,
    display_name: String,
}

async fn register_method(State(s): State<AppState>, Customer(a): Customer, Json(r): Json<RegisterMethod>) -> ApiResult<Json<MethodRow>> {
    if !matches!(r.provider.as_str(), "card" | "kakaopay" | "naverpay" | "tosspay" | "payco") || r.display_name.chars().count() > MAX_NAME_LEN {
        return Err(ApiError::BadRequest("invalid_payment_method"));
    }
    // Newest open ticket of this customer. Locked and consumed in the same transaction as the insert.
    let mut tx = s.db.begin().await?;
    let issue: Uuid = sqlx::query_scalar(
        "SELECT id FROM billing_issues WHERE user_id = $1 AND consumed_at IS NULL AND expires_at > now() ORDER BY created_at DESC LIMIT 1 FOR UPDATE",
    )
    .bind(a.id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or(ApiError::BadRequest("billing_issue_expired"))?;
    let key = s
        .providers
        .issue_billing_key(&r.auth_key, &a.id.to_string(), &issue.to_string())
        .await
        .map_err(|e| ApiError::PaymentFailed(e.to_string()))?;
    sqlx::query("UPDATE billing_issues SET consumed_at = now() WHERE id = $1").bind(issue).execute(&mut *tx).await?;
    let row = sqlx::query_as(
        "INSERT INTO payment_methods (user_id, provider, billing_key, display_name) VALUES ($1,$2,$3,$4) RETURNING id, provider, display_name, created_at",
    )
    .bind(a.id)
    .bind(&r.provider)
    .bind(key)
    .bind(&r.display_name)
    .fetch_one(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(Json(row))
}

async fn delete_method(State(s): State<AppState>, Customer(a): Customer, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    sqlx::query("UPDATE payment_methods SET deleted_at = now(), billing_key = '' WHERE id = $1 AND user_id = $2")
        .bind(id)
        .bind(a.id)
        .execute(&s.db)
        .await?;
    Ok(Json(json!({ "ok": true })))
}

#[derive(Deserialize)]
struct PushToken {
    token: String,
    platform: String,
}

/// Shared by customers, pros and staff.
async fn register_push(State(s): State<AppState>, a: Auth, Json(p): Json<PushToken>) -> ApiResult<Json<Value>> {
    if p.token.is_empty() || p.token.len() > 4096 || !matches!(p.platform.as_str(), "android" | "ios" | "windows" | "web") {
        return Err(ApiError::BadRequest("invalid_push_token"));
    }
    let role = if a.role.is_staff() { "staff" } else { a.role.as_str() };
    sqlx::query("INSERT INTO push_tokens (token, owner_role, owner_id, platform) VALUES ($1,$2,$3,$4) ON CONFLICT (token) DO UPDATE SET owner_role=$2, owner_id=$3, platform=$4, updated_at=now()")
        .bind(p.token)
        .bind(role)
        .bind(a.id)
        .bind(p.platform)
        .execute(&s.db)
        .await?;
    Ok(Json(json!({ "ok": true })))
}

#[derive(Deserialize)]
struct PushTokenRemoval {
    token: String,
}

/// Sign-out: drops one device token, and only if it belongs to the caller.
async fn unregister_push(State(s): State<AppState>, a: Auth, Json(p): Json<PushTokenRemoval>) -> ApiResult<Json<Value>> {
    if p.token.is_empty() || p.token.len() > 4096 {
        return Err(ApiError::BadRequest("invalid_push_token"));
    }
    sqlx::query("DELETE FROM push_tokens WHERE token = $1 AND owner_id = $2")
        .bind(p.token)
        .bind(a.id)
        .execute(&s.db)
        .await?;
    Ok(Json(json!({ "ok": true })))
}

#[derive(Serialize, sqlx::FromRow)]
struct NotificationRow {
    id: Uuid,
    kind: String,
    data: Value,
    read_at: Option<DateTime<Utc>>,
    created_at: DateTime<Utc>,
}

/// Newest first; keyset cursor over (created_at, id).
async fn list_notifications(State(s): State<AppState>, a: Auth, Query(q): Query<PageQuery>) -> ApiResult<Response> {
    let limit = page_limit(q.limit)?;
    let (ts, id) = match decode_cursor(q.cursor.as_deref(), 2)? {
        Some(p) => (Some(cursor_part::<DateTime<Utc>>(&p[0])?), Some(cursor_part::<Uuid>(&p[1])?)),
        None => (None, None),
    };
    let rows: Vec<NotificationRow> = sqlx::query_as(
        "SELECT id, kind, data, read_at, created_at FROM notifications
         WHERE owner_role = $1 AND owner_id = $2 AND ($3::timestamptz IS NULL OR (created_at, id) < ($3, $4))
         ORDER BY created_at DESC, id DESC LIMIT $5",
    )
    .bind(a.role.as_str())
    .bind(a.id)
    .bind(ts)
    .bind(id)
    .bind(limit)
    .fetch_all(&s.db)
    .await?;
    Ok(paged(rows, limit, |r| encode_cursor(&[&ts_key(r.created_at), &r.id.to_string()])))
}

async fn read_notifications(State(s): State<AppState>, a: Auth) -> ApiResult<Json<Value>> {
    sqlx::query("UPDATE notifications SET read_at = now() WHERE owner_role = $1 AND owner_id = $2 AND read_at IS NULL")
        .bind(a.role.as_str())
        .bind(a.id)
        .execute(&s.db)
        .await?;
    Ok(Json(json!({ "ok": true })))
}
