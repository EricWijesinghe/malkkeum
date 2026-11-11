//! Partner account: profile, preferences (services/areas/schedule), team, payout account, settlements, reviews.

use super::auth::{PhoneBind, conflict_on_unique, consume_otp};
use crate::{
    auth::{Pro, normalize_phone},
    crypto,
    error::{ApiError, ApiResult},
    state::AppState,
};
use axum::{
    Json, Router,
    extract::{Path, State},
    routing::{delete, get, post},
};
use chrono::NaiveDate;
use serde::Deserialize;
use serde_json::{Value, json};
use uuid::Uuid;

const MAX_TEAM: i64 = 30;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/me", get(profile).patch(update_profile).delete(delete_account))
        .route("/me/phone", post(bind_phone))
        .route("/prefs", get(get_prefs).put(put_prefs))
        .route("/team", get(team).post(invite))
        .route("/team/{id}", delete(remove_member))
        .route("/payout-account", get(get_account).put(put_account))
        .route("/settlements", get(settlements))
        .route("/reviews", get(reviews))
        .route("/threads", get(threads))
}

/// Deletes the partner's account: refused while a job is assigned or money is still owed to them,
/// so nobody loses a visit or a payout. History rows stay; personal data is wiped.
async fn delete_account(State(s): State<AppState>, Pro(a): Pro) -> ApiResult<Json<Value>> {
    let mut tx = s.db.begin().await?;
    sqlx::query("SELECT id FROM pros WHERE id = $1 FOR UPDATE").bind(a.id).execute(&mut *tx).await?;
    let (jobs, owed): (bool, bool) = sqlx::query_as(
        "SELECT EXISTS (SELECT 1 FROM bookings WHERE pro_id = $1 AND status = 2),
                EXISTS (SELECT 1 FROM settlements WHERE pro_id = $1 AND state IN ('waiting_balance','pending','held'))",
    )
    .bind(a.id)
    .fetch_one(&mut *tx)
    .await?;
    if jobs {
        return Err(ApiError::Conflict("has_active_jobs"));
    }
    if owed {
        return Err(ApiError::Conflict("pending_payouts"));
    }
    sqlx::query("UPDATE pros SET deleted_at = now(), status = 'suspended', name = '', team_name = '', phone = NULL WHERE id = $1")
        .bind(a.id)
        .execute(&mut *tx)
        .await?;
    sqlx::query("DELETE FROM payout_accounts WHERE pro_id = $1")
        .bind(a.id)
        .execute(&mut *tx)
        .await?;
    sqlx::query("DELETE FROM user_identities WHERE role = 'pro' AND subject_id = $1")
        .bind(a.id)
        .execute(&mut *tx)
        .await?;
    sqlx::query(
        "UPDATE refresh_tokens SET revoked_at = now()
         WHERE revoked_at IS NULL AND (subject = $1 OR subject IN (SELECT id FROM team_members WHERE pro_id = $1))",
    )
    .bind(a.id)
    .execute(&mut *tx)
    .await?;
    sqlx::query("DELETE FROM push_tokens WHERE owner_id = $1 OR owner_id IN (SELECT id FROM team_members WHERE pro_id = $1)")
        .bind(a.id)
        .execute(&mut *tx)
        .await?;
    sqlx::query("UPDATE team_members SET invite_status = 'removed', name = '', phone = '' WHERE pro_id = $1")
        .bind(a.id)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    Ok(Json(json!({ "ok": true })))
}

async fn profile(State(s): State<AppState>, Pro(a): Pro) -> ApiResult<Json<Value>> {
    let v: Value = sqlx::query_scalar(
        "SELECT jsonb_build_object('id', p.id, 'name', p.name, 'team_name', p.team_name, 'phone', p.phone, 'phone_verified', (p.phone IS NOT NULL), 'status', p.status, 'fee_bps', p.fee_bps, 'locale', p.locale,
           'pending_payout', (SELECT COALESCE(sum(net), 0) FROM settlements WHERE pro_id = p.id AND state IN ('pending','waiting_balance')),
           'rating', (SELECT round(avg(rating)::numeric, 2) FROM reviews WHERE pro_id = p.id AND NOT hidden),
           'review_count', (SELECT count(*) FROM reviews WHERE pro_id = p.id AND NOT hidden)) FROM pros p WHERE p.id = $1",
    )
    .bind(a.id)
    .fetch_one(&s.db)
    .await?;
    Ok(Json(v))
}

/// Binds a phone proven by a login code to the pro and to their owner team row.
async fn bind_phone(State(s): State<AppState>, Pro(a): Pro, Json(b): Json<PhoneBind>) -> ApiResult<Json<Value>> {
    let phone = normalize_phone(&b.phone).ok_or(ApiError::BadRequest("invalid_phone"))?;
    consume_otp(&s, &phone, &b.code).await?;
    let mut tx = s.db.begin().await?;
    sqlx::query("UPDATE pros SET phone = $2 WHERE id = $1")
        .bind(a.id)
        .bind(&phone)
        .execute(&mut *tx)
        .await
        .map_err(|e| conflict_on_unique(e, "phone_taken"))?;
    sqlx::query("UPDATE team_members SET phone = $2 WHERE pro_id = $1 AND role = 'owner'")
        .bind(a.id)
        .bind(&phone)
        .execute(&mut *tx)
        .await
        .map_err(|e| conflict_on_unique(e, "phone_taken"))?;
    tx.commit().await?;
    profile(State(s), Pro(a)).await
}

#[derive(Deserialize)]
struct ProfilePatch {
    name: Option<String>,
    team_name: Option<String>,
    locale: Option<String>,
}

async fn update_profile(State(s): State<AppState>, Pro(a): Pro, Json(p): Json<ProfilePatch>) -> ApiResult<Json<Value>> {
    let too_long = |v: &Option<String>| v.as_ref().is_some_and(|x| x.chars().count() > 40);
    if too_long(&p.name) || too_long(&p.team_name) || p.locale.as_ref().is_some_and(|l| !super::me::SUPPORTED_LOCALES.contains(&l.as_str())) {
        return Err(ApiError::BadRequest("invalid_profile"));
    }
    sqlx::query("UPDATE pros SET name = COALESCE($2, name), team_name = COALESCE($3, team_name), locale = COALESCE($4, locale) WHERE id = $1")
        .bind(a.id)
        .bind(&p.name)
        .bind(&p.team_name)
        .bind(&p.locale)
        .execute(&s.db)
        .await?;
    if let Some(n) = &p.name {
        sqlx::query("UPDATE team_members SET name = $2 WHERE pro_id = $1 AND role = 'owner'")
            .bind(a.id)
            .bind(n)
            .execute(&s.db)
            .await?;
    }
    profile(State(s), Pro(a)).await
}

async fn get_prefs(State(s): State<AppState>, Pro(a): Pro) -> ApiResult<Json<Value>> {
    let v: Value = sqlx::query_scalar("SELECT to_jsonb(pp) - 'pro_id' FROM partner_prefs pp WHERE pro_id = $1")
        .bind(a.id)
        .fetch_one(&s.db)
        .await?;
    Ok(Json(v))
}

#[derive(Deserialize)]
struct Prefs {
    services: Vec<String>,
    districts: Vec<String>,
    weekdays: Vec<i16>,
    day_parts: Vec<String>,
    days_off: Vec<NaiveDate>,
    notify: Value,
}

async fn put_prefs(State(s): State<AppState>, Pro(a): Pro, Json(p): Json<Prefs>) -> ApiResult<Json<Value>> {
    let ok = p.weekdays.iter().all(|d| (0..7).contains(d))
        && p.day_parts.iter().all(|d| d == "morning" || d == "afternoon")
        && p.districts.iter().all(|d| d.len() == 5 && d.chars().all(|c| c.is_ascii_digit()))
        && p.services.len() <= 20
        && p.notify.is_object();
    if !ok {
        return Err(ApiError::BadRequest("invalid_prefs"));
    }
    sqlx::query("UPDATE partner_prefs SET services=$2, districts=$3, weekdays=$4, day_parts=$5, days_off=$6, notify=$7 WHERE pro_id=$1")
        .bind(a.id)
        .bind(&p.services)
        .bind(&p.districts)
        .bind(&p.weekdays)
        .bind(&p.day_parts)
        .bind(&p.days_off)
        .bind(&p.notify)
        .execute(&s.db)
        .await?;
    get_prefs(State(s), Pro(a)).await
}

async fn team(State(s): State<AppState>, Pro(a): Pro) -> ApiResult<Json<Value>> {
    let v: Value = sqlx::query_scalar("SELECT COALESCE(jsonb_agg(jsonb_build_object('id', id, 'name', name, 'phone', phone, 'role', role, 'invite_status', invite_status) ORDER BY role DESC, created_at), '[]') FROM team_members WHERE pro_id = $1 AND invite_status <> 'removed'")
        .bind(a.id)
        .fetch_one(&s.db)
        .await?;
    Ok(Json(v))
}

#[derive(Deserialize)]
struct Invite {
    name: String,
    phone: String,
}

async fn invite(State(s): State<AppState>, Pro(a): Pro, Json(i): Json<Invite>) -> ApiResult<Json<Value>> {
    let phone = normalize_phone(&i.phone).ok_or(ApiError::BadRequest("invalid_phone"))?;
    if i.name.trim().is_empty() || i.name.chars().count() > 40 {
        return Err(ApiError::BadRequest("invalid_name"));
    }
    let count: i64 = sqlx::query_scalar("SELECT count(*) FROM team_members WHERE pro_id = $1 AND invite_status <> 'removed'")
        .bind(a.id)
        .fetch_one(&s.db)
        .await?;
    if count >= MAX_TEAM {
        return Err(ApiError::Conflict("team_full"));
    }
    let id: Uuid = sqlx::query_scalar("INSERT INTO team_members (pro_id, name, phone, role) VALUES ($1,$2,$3,'member') ON CONFLICT (pro_id, phone) DO UPDATE SET name = $2, invite_status = 'invited' RETURNING id")
        .bind(a.id).bind(i.name.trim()).bind(&phone).fetch_one(&s.db).await?;
    let locale = crate::i18n::locale_of(&s.db, crate::realtime::Recipient::Pro(a.id)).await;
    let _ = s.providers.send_sms(&phone, &crate::i18n::tr(&locale, "팀원으로 초대됐어요. 파트너 앱을 설치해 주세요.")).await;
    Ok(Json(json!({ "id": id })))
}

async fn remove_member(State(s): State<AppState>, Pro(a): Pro, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    let r = sqlx::query("UPDATE team_members SET invite_status = 'removed' WHERE id = $1 AND pro_id = $2 AND role = 'member'")
        .bind(id)
        .bind(a.id)
        .execute(&s.db)
        .await?;
    if r.rows_affected() == 0 {
        return Err(ApiError::NotFound);
    }
    sqlx::query("UPDATE bookings SET assignee_id = (SELECT id FROM team_members WHERE pro_id = $2 AND role = 'owner') WHERE assignee_id = $1 AND status = 2")
        .bind(id)
        .bind(a.id)
        .execute(&s.db)
        .await?;
    Ok(Json(json!({ "ok": true })))
}

async fn get_account(State(s): State<AppState>, Pro(a): Pro) -> ApiResult<Json<Value>> {
    let v: Option<Value> = sqlx::query_scalar("SELECT jsonb_build_object('bank', bank, 'account_last4', account_last4, 'holder', holder, 'verified_at', verified_at) FROM payout_accounts WHERE pro_id = $1")
        .bind(a.id)
        .fetch_optional(&s.db)
        .await?;
    Ok(Json(v.unwrap_or(Value::Null)))
}

#[derive(Deserialize)]
struct Account {
    bank: String,
    account_number: String,
    holder: String,
}

/// Changing the account clears verification until staff (or a bank API) re-verify it.
async fn put_account(State(s): State<AppState>, Pro(a): Pro, Json(x): Json<Account>) -> ApiResult<Json<Value>> {
    let digits: String = x.account_number.chars().filter(|c| c.is_ascii_digit()).collect();
    if !(8..=20).contains(&digits.len()) || x.bank.trim().is_empty() || x.holder.trim().is_empty() {
        return Err(ApiError::BadRequest("invalid_account"));
    }
    let last4 = digits[digits.len() - 4..].to_string();
    let verified = s.config.dev_mode.then(chrono::Utc::now);
    sqlx::query(
        "INSERT INTO payout_accounts (pro_id, bank, account_enc, account_last4, holder, verified_at) VALUES ($1,$2,$3,$4,$5,$6)
                 ON CONFLICT (pro_id) DO UPDATE SET bank=$2, account_enc=$3, account_last4=$4, holder=$5, verified_at=$6",
    )
    .bind(a.id)
    .bind(x.bank.trim())
    .bind(crypto::encrypt(&s.config.data_key, &digits))
    .bind(last4)
    .bind(x.holder.trim())
    .bind(verified)
    .execute(&s.db)
    .await?;
    get_account(State(s), Pro(a)).await
}

async fn settlements(State(s): State<AppState>, Pro(a): Pro) -> ApiResult<Json<Value>> {
    let v: Value = sqlx::query_scalar(
        "SELECT COALESCE(jsonb_agg(x ORDER BY x.created_at DESC), '[]') FROM (SELECT st.id, st.booking_id, st.gross, st.fee, st.net, st.payout_date, st.state, st.paid_at, st.created_at, b.service_code, b.visit_date, b.number
         FROM settlements st JOIN bookings b ON b.id = st.booking_id WHERE st.pro_id = $1) x",
    )
    .bind(a.id)
    .fetch_one(&s.db)
    .await?;
    Ok(Json(v))
}

async fn reviews(State(s): State<AppState>, Pro(a): Pro) -> ApiResult<Json<Value>> {
    let v: Value = sqlx::query_scalar(
        "SELECT COALESCE(jsonb_agg(x ORDER BY x.created_at DESC), '[]') FROM (SELECT r.booking_id, r.rating, r.body, r.created_at, b.service_code FROM reviews r JOIN bookings b ON b.id = r.booking_id WHERE r.pro_id = $1 AND NOT r.hidden) x",
    )
    .bind(a.id)
    .fetch_one(&s.db)
    .await?;
    Ok(Json(v))
}

async fn threads(State(s): State<AppState>, Pro(a): Pro) -> ApiResult<Json<Vec<super::chat::ThreadRow>>> {
    Ok(Json(super::chat::list_threads_for(&s.db, "partner", "pro_id", a.id).await?))
}
