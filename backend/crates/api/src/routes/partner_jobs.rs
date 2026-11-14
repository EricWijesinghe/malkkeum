//! Partner jobs: feed, preview, atomic accept, quotes, schedule, assignment, memo, completion, reschedule replies.

use super::{
    booking_core::{CompletionBody, complete_job},
    bookings::{BOOKING_COLS, BookingRow, load_booking},
    chat,
};
use crate::{
    auth::{Pro, mask_name},
    contract::{PageQuery, json_row_cursor, page_limit, paged, ts_id_cursor},
    error::{ApiError, ApiResult},
    realtime::{Recipient, deliver, enqueue, notify},
    state::AppState,
    util::{KST_TODAY, best_effort, today_kst},
};
use axum::{
    Json, Router,
    extract::{Path, Query, State},
    response::Response,
    routing::{get, post, put},
};
use chrono::NaiveDate;
use domain::{Won, partner::payout};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use uuid::Uuid;

const FEED_LIMIT: i64 = 100;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/jobs", get(feed))
        .route("/jobs/{id}", get(job))
        .route("/jobs/{id}/accept", post(accept))
        .route("/jobs/{id}/quote", post(submit_quote).put(edit_quote).delete(withdraw_quote))
        .route("/jobs/{id}/assign", post(assign))
        .route("/jobs/{id}/memo", put(memo))
        .route("/jobs/{id}/complete", post(complete))
        .route("/jobs/{id}/reschedule", post(reply_reschedule))
        .route("/quotes", get(my_quotes))
        .route("/schedule", get(schedule))
}

/// Same rule as `domain::partner::is_visible`, expressed in SQL for the feed.
pub const VISIBLE: &str = "p.status = 'verified'
    AND b.service_code = ANY(pp.services) AND b.district_code = ANY(pp.districts)
    AND (EXTRACT(ISODOW FROM b.visit_date)::int - 1)::smallint = ANY(pp.weekdays)
    AND (CASE WHEN b.start_hour < 12 THEN 'morning' ELSE 'afternoon' END) = ANY(pp.day_parts)
    AND NOT (b.visit_date = ANY(pp.days_off))";

#[derive(Serialize, sqlx::FromRow)]
struct JobCard {
    id: Uuid,
    service_code: String,
    unit_index: Option<i16>,
    district_code: String,
    road_area: Option<String>,
    visit_date: NaiveDate,
    start_hour: i16,
    minutes: Option<i32>,
    size_pyeong: Option<i32>,
    building: Option<String>,
    answers: Option<Value>,
    customer_price: Option<i64>,
    estimate: Option<i64>,
    fee_bps: i32,
    my_quote: Option<i64>,
    is_open: bool,
    created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Deserialize)]
struct FeedQuery {
    kind: String,
    #[serde(default)]
    include_closed: bool,
    sort: Option<String>,
}

async fn feed(State(s): State<AppState>, Pro(a): Pro, Query(q): Query<FeedQuery>) -> ApiResult<Json<Vec<JobCard>>> {
    let kind_filter = match q.kind.as_str() {
        "direct" => {
            format!("b.answers IS NULL AND (b.status = 1 AND b.pro_id IS NULL AND b.team_name IS NULL OR $2 AND b.status >= 1 AND b.visit_date >= {KST_TODAY})")
        }
        "quote" => format!("b.answers IS NOT NULL AND (b.status = 0 OR $2 AND b.visit_date >= {KST_TODAY})"),
        _ => return Err(ApiError::BadRequest("invalid_kind")),
    };
    let order = match q.sort.as_deref() {
        Some("visit") => "b.visit_date, b.start_hour",
        Some("amount") => "COALESCE(b.list_price, b.estimate) DESC",
        _ => "b.created_at DESC",
    };
    // Only the neighbourhood (dong) part of the road address is exposed before commitment.
    let rows = sqlx::query_as(&format!(
        "SELECT b.id, b.service_code, b.unit_index, b.district_code, split_part(b.address->>'road_address', ' ', 2) AS road_area, b.visit_date, b.start_hour, b.minutes,
           (b.address->>'size_pyeong')::int AS size_pyeong, b.answers->>'building' AS building, b.answers, b.list_price AS customer_price, b.estimate, p.fee_bps,
           (SELECT amount FROM quotes q WHERE q.booking_id = b.id AND q.pro_id = p.id AND q.state <> 'withdrawn') AS my_quote,
           (b.pro_id IS NULL AND b.status IN (0, 1)) AS is_open, b.created_at
         FROM bookings b, pros p JOIN partner_prefs pp ON pp.pro_id = p.id
         WHERE p.id = $1 AND b.visit_date > {KST_TODAY} AND {VISIBLE} AND ({kind_filter})
         ORDER BY {order} LIMIT $3"
    ))
    .bind(a.id)
    .bind(q.include_closed)
    .bind(FEED_LIMIT)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}

#[derive(Serialize)]
struct JobDetail {
    booking: Value,
    committed: bool,
    payout: Value,
    customer_name: Option<String>,
    assignee: Option<Value>,
    team_memo: Option<String>,
    can_call: bool,
}

fn gross(b: &BookingRow) -> Option<i64> {
    b.final_price.or(b.list_price)
}

/// Before commitment only space facts are returned; after, address, notes and masked name.
async fn job(State(s): State<AppState>, Pro(a): Pro, Path(id): Path<Uuid>) -> ApiResult<Json<JobDetail>> {
    let b = load_booking(&s.db, id).await?;
    let fee_bps: i32 = sqlx::query_scalar("SELECT fee_bps FROM pros WHERE id = $1").bind(a.id).fetch_one(&s.db).await?;
    let committed = b.pro_id == Some(a.id);
    // Pros see a job only if it matches their prefs (same rule as the feed) or it is theirs.
    if !committed && !visible_to(&s, id, a.id).await? {
        return Err(ApiError::NotFound);
    }
    let pay = gross(&b).map(|g| payout(Won(g), i64::from(fee_bps)));
    let mut view = json!({
        "id": b.id, "number": b.number, "service_code": b.service_code, "unit_index": b.unit_index, "district_code": b.district_code,
        "visit_date": b.visit_date, "start_hour": b.start_hour, "minutes": b.minutes, "status": b.status, "answers": b.answers,
        "estimate": b.estimate, "size_pyeong": b.address.get("size_pyeong"), "kind": b.address.get("kind"),
        "reschedule": b.reschedule, "cancelled": b.status == -1, "is_quote": b.answers.is_some(), "balance_paid": b.balance_paid,
    });
    view["emergency"] = crate::safety::emergency_contacts(&s.db).await?;
    view["entry_code_set"] = json!(b.entry_code_set);
    view["checked_in_at"] = json!(b.checked_in_at);
    view["checked_out_at"] = json!(b.checked_out_at);
    let (mut name, mut assignee, mut memo) = (None, None, None);
    if committed {
        view["address"] = b.address.clone();
        view["visit_notes"] = b.visit_notes.clone();
        view["household"] = b.household.clone();
        let raw: String = sqlx::query_scalar("SELECT name FROM users WHERE id = $1")
            .bind(b.user_id)
            .fetch_one(&s.db)
            .await?;
        name = Some(mask_name(&raw));
        assignee = sqlx::query_scalar(
            "SELECT jsonb_build_object('id', m.id, 'name', m.name) FROM bookings b JOIN team_members m ON m.id = b.assignee_id WHERE b.id = $1",
        )
        .bind(id)
        .fetch_optional(&s.db)
        .await?;
        memo = Some(
            sqlx::query_scalar("SELECT team_memo FROM bookings WHERE id = $1")
                .bind(id)
                .fetch_one(&s.db)
                .await?,
        );
    }
    // Masked-number calls allowed until 3 days after the visit (provider wiring: decision #4).
    let can_call = committed && (today_kst() - b.visit_date).num_days() <= 3 && b.status >= 2;
    Ok(Json(JobDetail {
        booking: view,
        committed,
        payout: json!(pay),
        customer_name: name,
        assignee,
        team_memo: memo,
        can_call,
    }))
}

async fn visible_to(s: &AppState, booking: Uuid, pro: Uuid) -> ApiResult<bool> {
    Ok(sqlx::query_scalar(&format!(
        "SELECT EXISTS (SELECT 1 FROM bookings b, pros p JOIN partner_prefs pp ON pp.pro_id = p.id WHERE b.id = $1 AND p.id = $2 AND {VISIBLE})"
    ))
    .bind(booking)
    .bind(pro)
    .fetch_one(&s.db)
    .await?)
}

/// First-come accept. The UPDATE's WHERE clause is the lock: exactly one pro wins.
/// Pros must have a verified phone (bound by OTP) before they take jobs, quote or finish them.
/// Social sign-ups have none until they bind one. Viewing the feed stays open.
pub(crate) async fn require_phone(s: &AppState, pro: Uuid) -> ApiResult<()> {
    let has_phone: bool = sqlx::query_scalar("SELECT phone IS NOT NULL FROM pros WHERE id = $1")
        .bind(pro)
        .fetch_one(&s.db)
        .await?;
    if has_phone { Ok(()) } else { Err(ApiError::Conflict("phone_required")) }
}

async fn accept(State(s): State<AppState>, Pro(a): Pro, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    require_phone(&s, a.id).await?;
    crate::quality::check_offer_gate(&s.db, a.id).await?;
    if !visible_to(&s, id, a.id).await? {
        return Err(ApiError::NotFound);
    }
    // Claim and default assignee in one statement: no half-accepted jobs.
    let mut tx = s.db.begin().await?;
    let won: Option<(Uuid, String)> = sqlx::query_as(
        "UPDATE bookings SET pro_id = $2, status = 2, accepted_at = now(), updated_at = now(),
           assignee_id = (SELECT id FROM team_members WHERE pro_id = $2 AND role = 'owner')
         WHERE id = $1 AND pro_id IS NULL AND team_name IS NULL AND status = 1 AND answers IS NULL RETURNING user_id, number",
    )
    .bind(id)
    .bind(a.id)
    .fetch_optional(&mut *tx)
    .await?;
    let (user, number) = won.ok_or(ApiError::Conflict("already_taken"))?;
    // Queued with the claim. After the commit nothing can fail the request: a 5xx here would make the
    // app retry and get `already_taken` for a job it won.
    let notice = enqueue(
        &mut *tx,
        Recipient::User(user),
        "booking.status",
        "청소팀이 배정됐어요",
        &number,
        json!({ "booking_id": id, "status": 2 }),
    )
    .await?;
    tx.commit().await?;
    deliver(&s, notice).await;
    s.hub.send(Recipient::Staff, "booking.updated", json!({ "booking_id": id }));
    Ok(Json(json!({ "ok": true, "booking_id": id })))
}

#[derive(Deserialize)]
struct QuoteInput {
    amount: i64,
    #[serde(default)]
    note: String,
}

const MAX_QUOTE: i64 = 50_000_000;
const MAX_NOTE: usize = 500;

impl QuoteInput {
    fn validate(&self) -> ApiResult<i64> {
        if (1..=MAX_QUOTE).contains(&self.amount) && self.note.chars().count() <= MAX_NOTE {
            Ok(Won(self.amount).round100().0)
        } else {
            Err(ApiError::BadRequest("invalid_quote"))
        }
    }
}

async fn submit_quote(State(s): State<AppState>, Pro(a): Pro, Path(id): Path<Uuid>, Json(q): Json<QuoteInput>) -> ApiResult<Json<Value>> {
    require_phone(&s, a.id).await?;
    let amount = q.validate()?;
    let open: bool = sqlx::query_scalar(&format!("SELECT EXISTS (SELECT 1 FROM bookings b, pros p JOIN partner_prefs pp ON pp.pro_id = p.id WHERE b.id = $1 AND p.id = $2 AND b.status = 0 AND b.answers IS NOT NULL AND {VISIBLE})"))
        .bind(id)
        .bind(a.id)
        .fetch_one(&s.db)
        .await?;
    if !open {
        return Err(ApiError::Conflict("request_closed"));
    }
    sqlx::query("INSERT INTO quotes (booking_id, pro_id, amount, note) VALUES ($1,$2,$3,$4) ON CONFLICT (booking_id, pro_id) DO UPDATE SET amount = $3, note = $4, state = 'waiting', updated_at = now() WHERE quotes.state = 'withdrawn'")
        .bind(id)
        .bind(a.id)
        .bind(amount)
        .bind(q.note.trim())
        .execute(&s.db)
        .await?;
    s.hub.send(Recipient::Staff, "quote.submitted", json!({ "booking_id": id }));
    Ok(Json(json!({ "ok": true })))
}

async fn edit_quote(State(s): State<AppState>, Pro(a): Pro, Path(id): Path<Uuid>, Json(q): Json<QuoteInput>) -> ApiResult<Json<Value>> {
    let amount = q.validate()?;
    let r = sqlx::query("UPDATE quotes SET amount = $3, note = $4, updated_at = now() WHERE booking_id = $1 AND pro_id = $2 AND state = 'waiting'")
        .bind(id)
        .bind(a.id)
        .bind(amount)
        .bind(q.note.trim())
        .execute(&s.db)
        .await?;
    if r.rows_affected() == 0 {
        return Err(ApiError::Conflict("quote_locked"));
    }
    s.hub.send(Recipient::Staff, "quote.submitted", json!({ "booking_id": id }));
    Ok(Json(json!({ "ok": true })))
}

async fn withdraw_quote(State(s): State<AppState>, Pro(a): Pro, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    let r = sqlx::query("UPDATE quotes SET state = 'withdrawn', updated_at = now() WHERE booking_id = $1 AND pro_id = $2 AND state = 'waiting'")
        .bind(id)
        .bind(a.id)
        .execute(&s.db)
        .await?;
    if r.rows_affected() == 0 {
        return Err(ApiError::Conflict("quote_locked"));
    }
    Ok(Json(json!({ "ok": true })))
}

/// Latest activity first; keyset cursor over (updated_at, id). Only the quotes on the page are marked seen.
async fn my_quotes(State(s): State<AppState>, Pro(a): Pro, Query(q): Query<PageQuery>) -> ApiResult<Response> {
    let limit = page_limit(q.limit)?;
    let (ts, id) = ts_id_cursor(q.cursor.as_deref())?;
    // Closing stale requests lazily keeps the state right without a scheduler.
    sqlx::query(&format!(
        "UPDATE quotes q SET state = 'closed' FROM bookings b WHERE q.booking_id = b.id AND q.pro_id = $1 AND q.state = 'waiting' AND (b.visit_date <= {KST_TODAY} OR b.status = -1)"
    ))
    .bind(a.id)
    .execute(&s.db)
    .await?;
    let rows: Vec<Value> = sqlx::query_scalar(
        "SELECT to_jsonb(x) FROM (SELECT q.id, q.booking_id, q.amount, q.note, q.state, q.seen_by_pro, q.created_at, q.updated_at,
           b.service_code, b.visit_date, b.start_hour, b.estimate, b.district_code, b.answers FROM quotes q JOIN bookings b ON b.id = q.booking_id
           WHERE q.pro_id = $1 AND q.state <> 'withdrawn' AND ($2::timestamptz IS NULL OR (q.updated_at, q.id) < ($2, $3))
           ORDER BY q.updated_at DESC, q.id DESC LIMIT $4) x ORDER BY x.updated_at DESC, x.id DESC",
    )
    .bind(a.id)
    .bind(ts)
    .bind(id)
    .bind(limit)
    .fetch_all(&s.db)
    .await?;
    let shown: Vec<Uuid> = rows.iter().filter_map(|r| r["id"].as_str()?.parse().ok()).collect();
    sqlx::query("UPDATE quotes SET seen_by_pro = TRUE WHERE pro_id = $1 AND NOT seen_by_pro AND id = ANY($2)")
        .bind(a.id)
        .bind(&shown)
        .execute(&s.db)
        .await?;
    Ok(paged(rows, limit, |r| json_row_cursor(r, "updated_at", "id")))
}

#[derive(Deserialize)]
struct Month {
    from: NaiveDate,
    to: NaiveDate,
}

async fn schedule(State(s): State<AppState>, Pro(a): Pro, Query(m): Query<Month>) -> ApiResult<Json<Vec<BookingRow>>> {
    if (m.to - m.from).num_days() > 62 {
        return Err(ApiError::BadRequest("range_too_large"));
    }
    let rows = sqlx::query_as(&format!(
        "SELECT {BOOKING_COLS} FROM bookings b WHERE b.pro_id = $1 AND b.visit_date BETWEEN $2 AND $3 ORDER BY b.visit_date, b.start_hour"
    ))
    .bind(a.id)
    .bind(m.from)
    .bind(m.to)
    .fetch_all(&s.db)
    .await?;
    Ok(Json(rows))
}

#[derive(Deserialize)]
struct Assign {
    member_id: Uuid,
}

async fn assign(State(s): State<AppState>, Pro(a): Pro, Path(id): Path<Uuid>, Json(x): Json<Assign>) -> ApiResult<Json<Value>> {
    let r = sqlx::query(
        "UPDATE bookings SET assignee_id = $3, updated_at = now() WHERE id = $1 AND pro_id = $2 AND status = 2
           AND EXISTS (SELECT 1 FROM team_members m WHERE m.id = $3 AND m.pro_id = $2 AND m.invite_status <> 'removed')",
    )
    .bind(id)
    .bind(a.id)
    .bind(x.member_id)
    .execute(&s.db)
    .await?;
    if r.rows_affected() == 0 {
        return Err(ApiError::NotFound);
    }
    let phone: String = sqlx::query_scalar("SELECT phone FROM team_members WHERE id = $1")
        .bind(x.member_id)
        .fetch_one(&s.db)
        .await?;
    // Member app: in-app notification + push + live event. The SMS stays for members without the app.
    best_effort(
        "member_assigned",
        notify(
            &s,
            Recipient::Member(x.member_id),
            "job.assigned",
            "새 작업이 배정됐어요",
            "앱에서 일정과 주소를 확인하세요",
            json!({ "booking_id": id }),
        ),
    )
    .await;
    let locale = crate::i18n::locale_of(&s.db, Recipient::Member(x.member_id)).await;
    let text = crate::i18n::tr(&locale, "새 작업이 배정됐어요");
    if let Err(e) = crate::sms_outbox::send(&s, None, &phone, "job.assigned", crate::sms_outbox::Message::Sms(&text)).await {
        tracing::warn!(error = %e, "assignment text not queued");
    }
    Ok(Json(json!({ "ok": true })))
}

#[derive(Deserialize)]
struct Memo {
    memo: String,
}

async fn memo(State(s): State<AppState>, Pro(a): Pro, Path(id): Path<Uuid>, Json(m): Json<Memo>) -> ApiResult<Json<Value>> {
    if m.memo.chars().count() > 1000 {
        return Err(ApiError::BadRequest("memo_too_long"));
    }
    let r = sqlx::query("UPDATE bookings SET team_memo = $3 WHERE id = $1 AND pro_id = $2")
        .bind(id)
        .bind(a.id)
        .bind(m.memo)
        .execute(&s.db)
        .await?;
    if r.rows_affected() == 0 {
        return Err(ApiError::NotFound);
    }
    Ok(Json(json!({ "ok": true })))
}

/// A completion that already landed (the app retried after a lost response): the first result, no second write.
pub(crate) async fn settled_once(db: &sqlx::PgPool, booking: Uuid, pro: Uuid) -> ApiResult<Option<(i64, Option<NaiveDate>)>> {
    Ok(sqlx::query_as("SELECT net, payout_date FROM settlements WHERE booking_id = $1 AND pro_id = $2")
        .bind(booking)
        .bind(pro)
        .fetch_optional(db)
        .await?)
}

/// The owner's completion. The rules and writes are `booking_core::complete_job`, shared with the team member's.
async fn complete(State(s): State<AppState>, Pro(a): Pro, Path(id): Path<Uuid>, Json(c): Json<CompletionBody>) -> ApiResult<Json<Value>> {
    let b = load_booking(&s.db, id).await?;
    if b.pro_id != Some(a.id) {
        return Err(ApiError::NotFound);
    }
    let done = complete_job(&s, &b, a.id, None, &c).await?;
    Ok(Json(json!({ "ok": true, "payout_date": done.payout_date, "net": done.net })))
}

#[derive(Deserialize)]
struct RescheduleReply {
    accept: bool,
}

async fn reply_reschedule(State(s): State<AppState>, Pro(a): Pro, Path(id): Path<Uuid>, Json(r): Json<RescheduleReply>) -> ApiResult<Json<Value>> {
    let b = load_booking(&s.db, id).await?;
    if b.pro_id != Some(a.id) || b.reschedule.is_none() {
        return Err(ApiError::NotFound);
    }
    if r.accept {
        sqlx::query("UPDATE bookings SET reschedule = NULL WHERE id = $1")
            .bind(id)
            .execute(&s.db)
            .await?;
        notify(
            &s,
            Recipient::User(b.user_id),
            "booking.reschedule_confirmed",
            "변경된 일정이 확정됐어요",
            &b.number,
            json!({ "booking_id": id }),
        )
        .await?;
    } else {
        let mut conn = s.db.acquire().await?;
        let thread = chat::booking_thread(&mut conn, "partner", a.id, id, &b.service_code).await?;
        let msg = chat::insert_message(&mut conn, thread, "partner", Some(a.id), "system", json!({ "code": "reschedule_declined" })).await?;
        drop(conn);
        chat::broadcast_message(&s, &msg).await?;
    }
    Ok(Json(json!({ "ok": true })))
}
