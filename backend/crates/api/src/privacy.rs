//! PIPA (개인정보 보호법) customer rights: consent records, the data export (열람), and the account
//! deletion cascade. Consent rows are append-only evidence; the newest row per kind is the current state.

use crate::{
    error::{ApiError, ApiResult},
    providers::portone,
    state::AppState,
};
use axum::{Json, extract::State};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sqlx::PgPool;
use uuid::Uuid;

/// Version of the policy texts the customer agrees to (privacy, terms, overseas transfer notice, marketing).
/// Bump when any of them changes: every stored consent with another version stops counting.
pub const CONSENT_VERSION: &str = "2026-11-17";

/// Kind and whether the service cannot run without it. Marketing is optional and withdrawable.
pub const CONSENTS: [(&str, bool); 4] = [("terms", true), ("privacy", true), ("overseas_transfer", true), ("marketing", false)];

/// Messages that are advertising under 정보통신망법: sent only while `marketing` is granted.
/// Transactional kinds (booking, payment, chat) never match.
pub fn is_marketing(kind: &str) -> bool {
    kind == "marketing" || kind.starts_with("marketing.")
}

#[derive(Serialize, sqlx::FromRow)]
struct Latest {
    kind: String,
    version: String,
    granted: bool,
    created_at: DateTime<Utc>,
}

/// Latest row of each consent kind for a customer.
async fn latest(db: &PgPool, user: Uuid) -> sqlx::Result<Vec<Latest>> {
    sqlx::query_as("SELECT DISTINCT ON (kind) kind, version, granted, created_at FROM user_consents WHERE user_id = $1 ORDER BY kind, created_at DESC, id DESC")
        .bind(user)
        .fetch_all(db)
        .await
}

/// A consent counts only if it was given for the current policy version.
fn effective(rows: &[Latest], kind: &str) -> bool {
    rows.iter().any(|r| r.kind == kind && r.granted && r.version == CONSENT_VERSION)
}

/// Whether a marketing message may go to this customer now.
pub async fn marketing_allowed(db: &PgPool, user: Uuid) -> sqlx::Result<bool> {
    Ok(effective(&latest(db, user).await?, "marketing"))
}

#[derive(Serialize)]
pub struct ConsentItem {
    kind: &'static str,
    required: bool,
    granted: bool,
    granted_at: Option<DateTime<Utc>>,
}

#[derive(Serialize)]
pub struct ConsentState {
    version: &'static str,
    items: Vec<ConsentItem>,
    /// True while a required consent is missing or was given for an older policy version.
    reconsent_required: bool,
}

fn state_of(rows: &[Latest]) -> ConsentState {
    let items: Vec<ConsentItem> = CONSENTS
        .iter()
        .map(|&(kind, required)| ConsentItem {
            kind,
            required,
            granted: effective(rows, kind),
            granted_at: rows.iter().find(|r| r.kind == kind).map(|r| r.created_at),
        })
        .collect();
    let reconsent_required = items.iter().any(|i| i.required && !i.granted);
    ConsentState { version: CONSENT_VERSION, items, reconsent_required }
}

pub async fn consent_state(db: &PgPool, user: Uuid) -> ApiResult<ConsentState> {
    Ok(state_of(&latest(db, user).await?))
}

#[derive(Deserialize)]
pub struct ConsentChange {
    kind: String,
    granted: bool,
    version: String,
}

#[derive(Deserialize)]
pub struct ConsentUpdate {
    consents: Vec<ConsentChange>,
}

/// Records the customer's choices. Each change must name the current policy version, so a consent is
/// always tied to the text the customer saw. The required consents must still be granted afterwards.
pub async fn update_consents(db: &PgPool, user: Uuid, update: ConsentUpdate) -> ApiResult<ConsentState> {
    if update.consents.is_empty() || update.consents.len() > CONSENTS.len() {
        return Err(ApiError::BadRequest("invalid_consents"));
    }
    for c in &update.consents {
        if !CONSENTS.iter().any(|(k, _)| *k == c.kind) {
            return Err(ApiError::BadRequest("invalid_consent_kind"));
        }
        if c.version != CONSENT_VERSION {
            return Err(ApiError::BadRequest("stale_consent_version"));
        }
    }
    let mut rows = latest(db, user).await?;
    for c in &update.consents {
        rows.retain(|r| r.kind != c.kind);
        rows.push(Latest { kind: c.kind.clone(), version: c.version.clone(), granted: c.granted, created_at: Utc::now() });
    }
    if CONSENTS.iter().any(|(k, required)| *required && !effective(&rows, k)) {
        return Err(ApiError::BadRequest("required_consent"));
    }
    let mut tx = db.begin().await?;
    for c in &update.consents {
        sqlx::query("INSERT INTO user_consents (user_id, kind, version, granted) VALUES ($1,$2,$3,$4)")
            .bind(user)
            .bind(&c.kind)
            .bind(&c.version)
            .bind(c.granted)
            .execute(&mut *tx)
            .await?;
    }
    tx.commit().await?;
    consent_state(db, user).await
}

pub async fn get_consents(State(s): State<AppState>, crate::auth::Customer(a): crate::auth::Customer) -> ApiResult<Json<ConsentState>> {
    Ok(Json(consent_state(&s.db, a.id).await?))
}

pub async fn put_consents(State(s): State<AppState>, crate::auth::Customer(a): crate::auth::Customer, Json(u): Json<ConsentUpdate>) -> ApiResult<Json<ConsentState>> {
    Ok(Json(update_consents(&s.db, a.id, u).await?))
}

/// 열람 요구: everything the service holds about the customer, without credentials or gateway keys.
pub async fn export(State(s): State<AppState>, crate::auth::Customer(a): crate::auth::Customer) -> ApiResult<Json<Value>> {
    let doc: Value = sqlx::query_scalar(
        "SELECT jsonb_build_object(
          'exported_at', now(),
          'profile', (SELECT jsonb_build_object('phone', phone, 'name', name, 'email', email, 'locale', locale, 'created_at', created_at, 'identity_verified_at', identity_verified_at) FROM users WHERE id = $1),
          'consents', (SELECT COALESCE(jsonb_agg(jsonb_build_object('kind', kind, 'version', version, 'granted', granted, 'at', created_at) ORDER BY created_at), '[]'::jsonb) FROM user_consents WHERE user_id = $1),
          'addresses', (SELECT COALESCE(jsonb_agg(jsonb_build_object('kind', kind, 'label', label, 'road_address', road_address, 'detail', detail, 'district_code', district_code, 'size_pyeong', size_pyeong, 'created_at', created_at) ORDER BY created_at), '[]'::jsonb) FROM addresses WHERE user_id = $1 AND deleted_at IS NULL),
          'payment_methods', (SELECT COALESCE(jsonb_agg(jsonb_build_object('provider', provider, 'display_name', display_name, 'created_at', created_at) ORDER BY created_at), '[]'::jsonb) FROM payment_methods WHERE user_id = $1 AND deleted_at IS NULL),
          'coupons', (SELECT COALESCE(jsonb_agg(jsonb_build_object('name', name, 'amount', amount, 'service_code', service_code, 'issued_at', issued_at, 'expires_at', expires_at, 'used', used_booking_id IS NOT NULL) ORDER BY issued_at), '[]'::jsonb) FROM coupons WHERE user_id = $1),
          'bookings', (SELECT COALESCE(jsonb_agg(jsonb_build_object('number', number, 'service_code', service_code, 'visit_date', visit_date, 'start_hour', start_hour, 'status', status, 'address', address, 'answers', answers, 'final_price', final_price, 'paid_amount', paid_amount, 'created_at', created_at) ORDER BY created_at), '[]'::jsonb) FROM bookings WHERE user_id = $1),
          'notifications', (SELECT COALESCE(jsonb_agg(jsonb_build_object('kind', kind, 'data', data, 'created_at', created_at) ORDER BY created_at DESC), '[]'::jsonb) FROM (SELECT kind, data, created_at FROM notifications WHERE owner_role = 'customer' AND owner_id = $1 ORDER BY created_at DESC LIMIT 500) n)
        )",
    )
    .bind(a.id)
    .fetch_one(&s.db)
    .await?;
    Ok(Json(doc))
}

/// Deletes the customer's gateway keys (saved cards) before personal data is removed. Fails closed:
/// if the gateway refuses, nothing is anonymised and the customer can retry.
async fn delete_billing_keys(s: &AppState, user: Uuid) -> ApiResult<()> {
    let keys: Vec<String> = sqlx::query_scalar("SELECT billing_key FROM payment_methods WHERE user_id = $1 AND billing_key <> ''")
        .bind(user)
        .fetch_all(&s.db)
        .await?;
    if keys.is_empty() {
        return Ok(());
    }
    if !portone::billing_ready(&s.providers.integ().portone) {
        tracing::warn!(%user, count = keys.len(), "billing keys cannot be deleted: gateway not configured");
        return Ok(());
    }
    for key in &keys {
        portone::delete_billing_key(&s.providers, key).await.map_err(|_| ApiError::Unavailable("billing_key_delete_failed"))?;
    }
    Ok(())
}

/// Account deletion (PIPA 파기). Anonymises the user row and removes contact data, addresses, devices,
/// notifications and gateway keys. Kept for legal retention: bookings and payments (전자상거래법 5년), the
/// consent log (proof of consent) and chat text with the sender unlinked (분쟁 처리).
pub async fn delete_account(s: &AppState, user: Uuid) -> ApiResult<()> {
    delete_billing_keys(s, user).await?;
    let mut tx = s.db.begin().await?;
    sqlx::query("UPDATE users SET deleted_at = now(), name = '', email = NULL, phone = 'deleted:' || id::text, ci_hash = NULL, identity_verified_at = NULL WHERE id = $1 AND deleted_at IS NULL")
        .bind(user)
        .execute(&mut *tx)
        .await?;
    sqlx::query("DELETE FROM addresses WHERE user_id = $1").bind(user).execute(&mut *tx).await?;
    sqlx::query("UPDATE payment_methods SET deleted_at = now(), billing_key = '' WHERE user_id = $1").bind(user).execute(&mut *tx).await?;
    sqlx::query("DELETE FROM push_tokens WHERE owner_role = 'customer' AND owner_id = $1").bind(user).execute(&mut *tx).await?;
    sqlx::query("DELETE FROM notifications WHERE owner_role = 'customer' AND owner_id = $1").bind(user).execute(&mut *tx).await?;
    sqlx::query("UPDATE refresh_tokens SET revoked_at = now() WHERE subject = $1 AND revoked_at IS NULL").bind(user).execute(&mut *tx).await?;
    // Threads keep their user_id: chat_threads_check requires it for customer threads, and the anonymised user row holds no contact data.
    sqlx::query("UPDATE chat_messages SET sender_id = NULL WHERE sender = 'customer' AND sender_id = $1").bind(user).execute(&mut *tx).await?;
    tx.commit().await?;
    Ok(())
}
