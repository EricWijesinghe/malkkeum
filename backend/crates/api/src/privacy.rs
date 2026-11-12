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

/// Version of the policy texts the customer agrees to (privacy, terms, overseas transfer notice, marketing, location terms).
/// Bump when any of them changes: every stored consent with another version stops counting.
pub const CONSENT_VERSION: &str = "2026-11-19";

/// Kind and whether the service cannot run without it. Marketing and location are optional and withdrawable.
pub const CONSENTS: [(&str, bool); 5] = [("terms", true), ("privacy", true), ("overseas_transfer", true), ("marketing", false), (LOCATION, false)];

/// 위치기반서비스 이용약관 (위치정보법): asked in the app before the first "use my current location".
pub const LOCATION: &str = "location";

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
    ConsentState {
        version: CONSENT_VERSION,
        items,
        reconsent_required,
    }
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
        rows.push(Latest {
            kind: c.kind.clone(),
            version: c.version.clone(),
            granted: c.granted,
            created_at: Utc::now(),
        });
    }
    // The location terms are their own agreement under 위치정보법: recording them alone never depends on the PIPA consents.
    let location_only = update.consents.iter().all(|c| c.kind == LOCATION);
    if !location_only && CONSENTS.iter().any(|(k, required)| *required && !effective(&rows, k)) {
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

pub async fn put_consents(
    State(s): State<AppState>,
    crate::auth::Customer(a): crate::auth::Customer,
    Json(u): Json<ConsentUpdate>,
) -> ApiResult<Json<ConsentState>> {
    Ok(Json(update_consents(&s.db, a.id, u).await?))
}

/// 열람 요구: everything the service holds about the customer, without credentials or gateway keys.
pub async fn export(State(s): State<AppState>, crate::auth::Customer(a): crate::auth::Customer) -> ApiResult<Json<Value>> {
    let doc: Value = sqlx::query_scalar(
        "SELECT jsonb_build_object(
          'exported_at', now(),
          'profile', (SELECT jsonb_build_object('phone', phone, 'name', name, 'email', email, 'locale', locale, 'created_at', created_at, 'identity_verified_at', identity_verified_at) FROM users WHERE id = $1),
          'consents', (SELECT COALESCE(jsonb_agg(jsonb_build_object('kind', kind, 'version', version, 'granted', granted, 'at', created_at) ORDER BY created_at), '[]'::jsonb) FROM user_consents WHERE user_id = $1),
          'addresses', (SELECT COALESCE(jsonb_agg(jsonb_build_object('kind', kind, 'label', label, 'road_address', road_address, 'detail', detail, 'district_code', district_code, 'size_pyeong', size_pyeong, 'household', household, 'created_at', created_at) ORDER BY created_at), '[]'::jsonb) FROM addresses WHERE user_id = $1 AND deleted_at IS NULL),
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
        portone::delete_billing_key(&s.providers, key)
            .await
            .map_err(|_| ApiError::Unavailable("billing_key_delete_failed"))?;
    }
    Ok(())
}

/// Account deletion (PIPA 파기). Anonymises the user row and removes contact data, sign-in identities (then
/// disconnects them at the provider), addresses, devices, notifications, uploads, gateway keys, review text and
/// photos, waitlist and unpaid-checkout snapshots; ends subscriptions (no further charge or visit is planned) and
/// waitlist places. Kept for legal retention, linked only to the anonymised row: bookings, payments, paid
/// checkouts, tips, cash receipts, tax invoice requests and payouts (전자상거래법 5년, 부가가치세법), review ratings,
/// the consent log (proof of consent), chat text with the sender unlinked (분쟁 처리), and a referral's phone only
/// as a keyed digest (`crypto::phone_digest`) so the one-reward-per-phone rule still holds. Safe to run twice.
pub async fn delete_account(s: &AppState, user: Uuid) -> ApiResult<()> {
    delete_billing_keys(s, user).await?;
    let mut tx = s.db.begin().await?;
    let links = crate::providers::social::links(&mut tx, &s.config.data_key, "customer", user).await?;
    // Login codes are keyed by phone, so they go before the phone is wiped.
    sqlx::query("DELETE FROM otp_codes WHERE phone = (SELECT phone FROM users WHERE id = $1)")
        .bind(user)
        .execute(&mut *tx)
        .await?;
    sqlx::query(
        "UPDATE users SET deleted_at = now(), name = '', email = NULL, phone = 'deleted:' || id::text, ci_hash = NULL,
         identity_verified_at = NULL, referral_code = NULL, acquisition = NULL WHERE id = $1 AND deleted_at IS NULL",
    )
    .bind(user)
    .execute(&mut *tx)
    .await?;
    let referral_phone: Option<String> =
        sqlx::query_scalar("SELECT referred_phone FROM referrals WHERE referred_user_id = $1 AND referred_phone NOT LIKE 'hmac:%' FOR UPDATE")
            .bind(user)
            .fetch_optional(&mut *tx)
            .await?;
    if let Some(phone) = referral_phone {
        sqlx::query("UPDATE referrals SET referred_phone = $2 WHERE referred_user_id = $1")
            .bind(user)
            .bind(crate::crypto::phone_digest(&s.config.data_key, &phone))
            .execute(&mut *tx)
            .await?;
    }
    // Provider ids and emails; their stored refresh tokens go with them (ON DELETE CASCADE).
    sqlx::query("DELETE FROM user_identities WHERE role = 'customer' AND subject_id = $1")
        .bind(user)
        .execute(&mut *tx)
        .await?;
    sqlx::query(
        "UPDATE subscriptions SET status = 'cancelled', paused_reason = NULL, cancelled_at = now(), updated_at = now()
         WHERE user_id = $1 AND status <> 'cancelled'",
    )
    .bind(user)
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        "UPDATE subscription_visits SET state = 'cancelled', updated_at = now()
         WHERE state = 'planned' AND subscription_id IN (SELECT id FROM subscriptions WHERE user_id = $1)",
    )
    .bind(user)
    .execute(&mut *tx)
    .await?;
    let offered: Vec<(chrono::NaiveDate, i16)> = sqlx::query_as(
        "UPDATE waitlist_entries SET status = 'cancelled' WHERE user_id = $1 AND status = 'offered' RETURNING visit_date, start_hour",
    )
    .bind(user)
    .fetch_all(&mut *tx)
    .await?;
    sqlx::query("UPDATE waitlist_entries SET status = 'cancelled' WHERE user_id = $1 AND status = 'waiting'")
        .bind(user)
        .execute(&mut *tx)
        .await?;
    // The booking request snapshot holds the address and notes.
    sqlx::query("UPDATE waitlist_entries SET body = '{}'::jsonb WHERE user_id = $1").bind(user).execute(&mut *tx).await?;
    // Unsettled checkouts may still be paid (late deposit), so their draft stays until retention clears it.
    sqlx::query(
        "UPDATE checkouts SET draft = NULL, virtual_account = NULL
         WHERE user_id = $1 AND status IN ('failed','cancelled','refunded') AND (draft IS NOT NULL OR virtual_account IS NOT NULL)",
    )
    .bind(user)
    .execute(&mut *tx)
    .await?;
    // Ratings stay for the partner's score; the customer's words and photos go.
    sqlx::query("UPDATE reviews SET body = '', photos = '[]'::jsonb WHERE user_id = $1").bind(user).execute(&mut *tx).await?;
    // A subscription references its address, so that row is emptied instead of deleted.
    sqlx::query("UPDATE addresses SET label = '', road_address = '', detail = '', deleted_at = COALESCE(deleted_at, now()) WHERE user_id = $1")
        .bind(user)
        .execute(&mut *tx)
        .await?;
    sqlx::query("DELETE FROM addresses a WHERE a.user_id = $1 AND NOT EXISTS (SELECT 1 FROM subscriptions s WHERE s.address_id = a.id)")
        .bind(user)
        .execute(&mut *tx)
        .await?;
    sqlx::query("UPDATE payment_methods SET deleted_at = COALESCE(deleted_at, now()), billing_key = '', display_name = '' WHERE user_id = $1")
        .bind(user)
        .execute(&mut *tx)
        .await?;
    sqlx::query("DELETE FROM identity_sessions WHERE user_id = $1").bind(user).execute(&mut *tx).await?;
    sqlx::query("DELETE FROM billing_issues WHERE user_id = $1").bind(user).execute(&mut *tx).await?;
    sqlx::query("DELETE FROM push_tokens WHERE owner_role = 'customer' AND owner_id = $1")
        .bind(user)
        .execute(&mut *tx)
        .await?;
    sqlx::query("DELETE FROM notifications WHERE owner_role = 'customer' AND owner_id = $1")
        .bind(user)
        .execute(&mut *tx)
        .await?;
    sqlx::query("UPDATE refresh_tokens SET revoked_at = now() WHERE subject = $1 AND revoked_at IS NULL")
        .bind(user)
        .execute(&mut *tx)
        .await?;
    // Threads keep their user_id: chat_threads_check requires it for customer threads, and the anonymised user row holds no contact data.
    sqlx::query("UPDATE chat_messages SET sender_id = NULL WHERE sender = 'customer' AND sender_id = $1")
        .bind(user)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    // Network and disk work after commit: no row lock is held across it.
    crate::providers::social::unlink(&s.providers, "customer", user, links).await;
    delete_uploads(s, user).await?;
    // An offered waitlist seat was being held for this customer: offer it to the next waiter.
    for (date, hour) in offered {
        crate::util::best_effort("waitlist offer on account deletion", crate::routes::waitlist::offer_for_slot(s, date, hour as u8)).await;
    }
    Ok(())
}

/// The customer's uploaded photos (review, chat, booking): file first, then its row, so a failed removal
/// leaves the row and a second deletion run retries it.
async fn delete_uploads(s: &AppState, user: Uuid) -> ApiResult<()> {
    let files: Vec<(Uuid, String)> = sqlx::query_as("SELECT id, file FROM uploads WHERE owner_role = 'customer' AND owner_id = $1")
        .bind(user)
        .fetch_all(&s.db)
        .await?;
    for (id, file) in files {
        match tokio::fs::remove_file(s.config.upload_dir.join(&file)).await {
            Ok(()) => {}
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => {}
            Err(e) => {
                tracing::warn!(%user, error = %e, "upload not removed on account deletion");
                continue;
            }
        }
        sqlx::query("DELETE FROM uploads WHERE id = $1").bind(id).execute(&s.db).await?;
    }
    Ok(())
}

/// Retention step: partners whose Apple ID was deleted while a job or payout was open are deleted once that
/// clears. Still blocked ones wait for the next run. Returns how many were deleted.
pub async fn finish_pending_partner_deletions(s: &AppState) -> ApiResult<u64> {
    let pending: Vec<Uuid> = sqlx::query_scalar("SELECT id FROM pros WHERE deletion_requested_at IS NOT NULL AND deleted_at IS NULL")
        .fetch_all(&s.db)
        .await?;
    let mut done = 0;
    for id in pending {
        match crate::routes::partner::delete_pro(s, id).await {
            Ok(()) => done += 1,
            Err(ApiError::Conflict(_)) => {}
            Err(e) => return Err(e),
        }
    }
    Ok(done)
}

async fn end_sessions(db: &PgPool, subject: Uuid) -> sqlx::Result<()> {
    sqlx::query("UPDATE refresh_tokens SET revoked_at = now() WHERE subject = $1 AND revoked_at IS NULL")
        .bind(subject)
        .execute(db)
        .await
        .map(|_| ())
}

/// Acts on a verified Apple server-to-server notification, once per `jti` (Apple may deliver it again).
/// `account-delete`: the Apple ID is gone, so the accounts signed in with it are deleted. A partner whose
/// deletion is blocked by an open job or payout is marked and deleted by the retention job once that clears.
/// `consent-revoked`: the user stopped using Apple sign-in here, so their sessions end and the stored Apple
/// token is dropped; the link stays so signing in again reaches the same account. Email relay changes need
/// nothing from us. On any error the `jti` is released so Apple's retry is handled.
pub async fn apple_notification(s: &AppState, n: &crate::providers::apple::Notification) -> ApiResult<()> {
    let claimed: Option<String> = sqlx::query_scalar("INSERT INTO apple_notifications (jti, event_type) VALUES ($1, $2) ON CONFLICT DO NOTHING RETURNING jti")
        .bind(&n.jti)
        .bind(&n.kind)
        .fetch_optional(&s.db)
        .await?;
    if claimed.is_none() {
        return Ok(());
    }
    let handled = handle_apple_event(s, n).await;
    if handled.is_err() {
        sqlx::query("DELETE FROM apple_notifications WHERE jti = $1").bind(&n.jti).execute(&s.db).await?;
    }
    handled
}

async fn handle_apple_event(s: &AppState, n: &crate::providers::apple::Notification) -> ApiResult<()> {
    let accounts: Vec<(Uuid, String, Uuid)> =
        sqlx::query_as("SELECT id, role, subject_id FROM user_identities WHERE provider = 'apple' AND provider_user_id = $1")
            .bind(&n.sub)
            .fetch_all(&s.db)
            .await?;
    for (identity, role, subject) in accounts {
        match (n.kind.as_str(), role.as_str()) {
            ("account-delete" | "account-deleted", "customer") => delete_account(s, subject).await?,
            ("account-delete" | "account-deleted", _) => match crate::routes::partner::delete_pro(s, subject).await {
                Ok(()) => {}
                Err(ApiError::Conflict(reason)) => {
                    tracing::warn!(%subject, reason, "apple account-delete: partner deletion waits for open work to clear");
                    sqlx::query("UPDATE pros SET deletion_requested_at = COALESCE(deletion_requested_at, now()) WHERE id = $1")
                        .bind(subject)
                        .execute(&s.db)
                        .await?;
                }
                Err(e) => return Err(e),
            },
            ("consent-revoked", _) => {
                sqlx::query("DELETE FROM social_tokens WHERE identity_id = $1").bind(identity).execute(&s.db).await?;
                end_sessions(&s.db, subject).await?;
            }
            _ => {}
        }
    }
    Ok(())
}
