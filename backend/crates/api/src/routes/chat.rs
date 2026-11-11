//! Consultation chat. Customers and pros each talk only to staff (never each other).

use crate::{
    auth::{Auth, Role, Staff},
    error::{ApiError, ApiResult},
    ratelimit::within_quota,
    realtime::{Recipient, notify},
    routes::uploads,
    state::AppState,
    util::own_upload,
};
use axum::{
    Json, Router,
    extract::{Path, Query, State},
    routing::{get, post, put},
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use sqlx::{PgConnection, PgPool};
use uuid::Uuid;

const PAGE: i64 = 50;
const MAX_TEXT: usize = 2000;
const MAX_TOPIC: usize = 60;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/chat/threads", get(my_threads).post(open_thread))
        .route("/chat/threads/{id}/messages", get(messages).post(send))
        .route("/chat/threads/{id}/read", post(mark_read))
}

#[derive(Serialize, sqlx::FromRow)]
pub struct ThreadRow {
    pub id: Uuid,
    pub audience: String,
    pub user_id: Option<Uuid>,
    pub pro_id: Option<Uuid>,
    pub booking_id: Option<Uuid>,
    pub topic: String,
    pub unread_member: i32,
    pub unread_staff: i32,
    pub closed: bool,
    pub ai_paused: bool,
    pub last_message_at: DateTime<Utc>,
    pub last_message: Option<Value>,
}

#[derive(Serialize, sqlx::FromRow, Clone)]
pub struct MessageRow {
    pub id: Uuid,
    pub thread_id: Uuid,
    pub sender: String,
    pub kind: String,
    pub body: Value,
    pub created_at: DateTime<Utc>,
}

pub const THREAD_COLS: &str = "t.id, t.audience, t.user_id, t.pro_id, t.booking_id, t.topic, t.unread_member, t.unread_staff, t.closed, t.ai_paused, t.last_message_at,
    (SELECT jsonb_build_object('kind', m.kind, 'body', m.body, 'sender', m.sender) FROM chat_messages m WHERE m.thread_id = t.id ORDER BY m.created_at DESC LIMIT 1) AS last_message";

/// Finds or creates the thread for a booking (one per booking per audience).
pub async fn booking_thread(conn: &mut PgConnection, audience: &str, owner: Uuid, booking: Uuid, topic: &str) -> Result<Uuid, sqlx::Error> {
    let (user_id, pro_id) = if audience == "customer" { (Some(owner), None) } else { (None, Some(owner)) };
    sqlx::query_scalar(
        "INSERT INTO chat_threads (audience, user_id, pro_id, booking_id, topic) VALUES ($1,$2,$3,$4,$5)
         ON CONFLICT (audience, booking_id) WHERE booking_id IS NOT NULL DO UPDATE SET topic = chat_threads.topic RETURNING id",
    )
    .bind(audience)
    .bind(user_id)
    .bind(pro_id)
    .bind(booking)
    .bind(topic)
    .fetch_one(conn)
    .await
}

/// Inserts a message and bumps unread counters for the other side.
pub async fn insert_message(
    conn: &mut PgConnection,
    thread: Uuid,
    sender: &str,
    sender_id: Option<Uuid>,
    kind: &str,
    body: Value,
) -> Result<MessageRow, sqlx::Error> {
    let msg: MessageRow = sqlx::query_as(
        "INSERT INTO chat_messages (thread_id, sender, sender_id, kind, body) VALUES ($1,$2,$3,$4,$5) RETURNING id, thread_id, sender, kind, body, created_at",
    )
    .bind(thread)
    .bind(sender)
    .bind(sender_id)
    .bind(kind)
    .bind(body)
    .fetch_one(&mut *conn)
    .await?;
    let (member_inc, staff_inc) = match sender {
        "staff" => (1, 0),
        "system" => (1, 1),
        _ => (0, 1),
    };
    sqlx::query("UPDATE chat_threads SET last_message_at = now(), unread_member = unread_member + $2, unread_staff = unread_staff + $3 WHERE id = $1")
        .bind(thread)
        .bind(member_inc)
        .bind(staff_inc)
        .execute(conn)
        .await?;
    Ok(msg)
}

/// Fan-out after commit: live event to both sides, push to the member when staff/system wrote.
pub async fn broadcast_message(s: &AppState, msg: &MessageRow) -> ApiResult<()> {
    let (user_id, pro_id): (Option<Uuid>, Option<Uuid>) = sqlx::query_as("SELECT user_id, pro_id FROM chat_threads WHERE id = $1")
        .bind(msg.thread_id)
        .fetch_one(&s.db)
        .await?;
    let member = user_id.map(Recipient::User).or(pro_id.map(Recipient::Pro)).ok_or(ApiError::NotFound)?;
    let data = json!({ "message": msg });
    // Live sockets get signed photo URLs; the stored notification keeps the plain path.
    let mut live = data.clone();
    uploads::sign_urls(&s.config, &mut live);
    s.hub.send(Recipient::Staff, "chat.message", live.clone());
    if msg.sender == "staff" || msg.sender == "system" {
        let preview = msg.body.get("text").and_then(Value::as_str).unwrap_or("").chars().take(80).collect::<String>();
        notify(s, member, "chat.message", "상담팀", &preview, data).await?;
    } else {
        s.hub.send(member, "chat.message", live);
    }
    Ok(())
}

/// Convenience used by bookings/admin: post a system line in a transaction-free context.
pub async fn post_system(s: &AppState, thread: Uuid, code: &str, params: Value) -> ApiResult<()> {
    let mut conn = s.db.acquire().await?;
    let msg = insert_message(&mut conn, thread, "system", None, "system", json!({ "code": code, "params": params })).await?;
    drop(conn);
    broadcast_message(s, &msg).await
}

fn member_filter(a: &Auth) -> ApiResult<(&'static str, &'static str)> {
    match a.role {
        Role::Customer => Ok(("customer", "user_id")),
        Role::Pro => Ok(("partner", "pro_id")),
        _ => Err(ApiError::Forbidden),
    }
}

pub async fn list_threads_for(db: &PgPool, audience: &str, col: &str, owner: Uuid) -> ApiResult<Vec<ThreadRow>> {
    Ok(sqlx::query_as(&format!(
        "SELECT {THREAD_COLS} FROM chat_threads t WHERE t.audience = $1 AND t.{col} = $2 ORDER BY t.last_message_at DESC"
    ))
    .bind(audience)
    .bind(owner)
    .fetch_all(db)
    .await?)
}

async fn my_threads(State(s): State<AppState>, a: Auth) -> ApiResult<Json<Vec<ThreadRow>>> {
    let (aud, col) = member_filter(&a)?;
    Ok(Json(list_threads_for(&s.db, aud, col, a.id).await?))
}

#[derive(Deserialize)]
struct OpenThread {
    topic: String,
    booking_id: Option<Uuid>,
}

async fn open_thread(State(s): State<AppState>, a: Auth, Json(o): Json<OpenThread>) -> ApiResult<Json<Value>> {
    let (aud, col) = member_filter(&a)?;
    if o.topic.trim().is_empty() || o.topic.chars().count() > MAX_TOPIC {
        return Err(ApiError::BadRequest("invalid_topic"));
    }
    let mut conn = s.db.acquire().await?;
    let id = if let Some(b) = o.booking_id {
        let owner_col = if aud == "customer" { "user_id" } else { "pro_id" };
        let owns: bool = sqlx::query_scalar(&format!("SELECT EXISTS (SELECT 1 FROM bookings WHERE id = $1 AND {owner_col} = $2)"))
            .bind(b)
            .bind(a.id)
            .fetch_one(&mut *conn)
            .await?;
        if !owns {
            return Err(ApiError::NotFound);
        }
        booking_thread(&mut conn, aud, a.id, b, o.topic.trim()).await?
    } else {
        // Customers may open a limited number of free-standing threads per day (spam guard).
        if aud == "customer" {
            let opened: i64 = sqlx::query_scalar(
                "SELECT count(*) FROM chat_threads WHERE audience = 'customer' AND user_id = $1 AND created_at > now() - interval '24 hours'",
            )
            .bind(a.id)
            .fetch_one(&mut *conn)
            .await?;
            if !within_quota(opened, s.config.max_threads_per_day) {
                return Err(ApiError::Quota("thread_quota"));
            }
        }
        sqlx::query_scalar(&format!("INSERT INTO chat_threads (audience, {col}, topic) VALUES ($1, $2, $3) RETURNING id"))
            .bind(aud)
            .bind(a.id)
            .bind(o.topic.trim())
            .fetch_one(&mut *conn)
            .await?
    };
    Ok(Json(json!({ "id": id })))
}

/// Members may only touch their own threads; staff may touch any.
pub async fn authorize_thread(db: &PgPool, a: &Auth, thread: Uuid) -> ApiResult<()> {
    if a.role.is_staff() {
        return Ok(());
    }
    let (_, col) = member_filter(a)?;
    let ok: bool = sqlx::query_scalar(&format!("SELECT EXISTS (SELECT 1 FROM chat_threads WHERE id = $1 AND {col} = $2)"))
        .bind(thread)
        .bind(a.id)
        .fetch_one(db)
        .await?;
    if ok { Ok(()) } else { Err(ApiError::NotFound) }
}

#[derive(Deserialize)]
pub struct Page {
    before: Option<DateTime<Utc>>,
}

pub async fn messages(State(s): State<AppState>, a: Auth, Path(id): Path<Uuid>, Query(p): Query<Page>) -> ApiResult<Json<Vec<MessageRow>>> {
    authorize_thread(&s.db, &a, id).await?;
    let mut rows: Vec<MessageRow> = sqlx::query_as(
        "SELECT id, thread_id, sender, kind, body, created_at FROM chat_messages WHERE thread_id = $1 AND ($2::timestamptz IS NULL OR created_at < $2) ORDER BY created_at DESC LIMIT $3",
    )
    .bind(id)
    .bind(p.before)
    .bind(PAGE)
    .fetch_all(&s.db)
    .await?;
    rows.reverse();
    Ok(Json(rows))
}

#[derive(Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum Outgoing {
    Text { text: String },
    Photo { url: String },
}

pub fn validate_outgoing(o: &Outgoing, public_base: &str) -> ApiResult<(&'static str, Value)> {
    match o {
        Outgoing::Text { text } if !text.trim().is_empty() && text.chars().count() <= MAX_TEXT => Ok(("text", json!({ "text": text.trim() }))),
        // Only our own upload URLs, so chats cannot carry arbitrary links as images.
        Outgoing::Photo { url } => own_upload(public_base, url).map(|p| ("photo", json!({ "url": p }))).ok_or(ApiError::BadRequest("invalid_message")),
        _ => Err(ApiError::BadRequest("invalid_message")),
    }
}

pub async fn send(State(s): State<AppState>, a: Auth, Path(id): Path<Uuid>, Json(o): Json<Outgoing>) -> ApiResult<Json<MessageRow>> {
    authorize_thread(&s.db, &a, id).await?;
    let (kind, body) = validate_outgoing(&o, &s.config.public_base_url)?;
    let sender = match a.role {
        Role::Customer => "customer",
        Role::Pro => "partner",
        _ => "staff",
    };
    let mut conn = s.db.acquire().await?;
    let msg = insert_message(&mut conn, id, sender, Some(a.id), kind, body).await?;
    drop(conn);
    broadcast_message(&s, &msg).await?;
    if sender != "staff" {
        crate::ai::schedule(&s, id);
    }
    Ok(Json(msg))
}

/// Staff-only routes, mounted under /admin: per-thread AI pause and the monthly AI usage line.
pub fn admin_routes() -> Router<AppState> {
    Router::new()
        .route("/threads/{id}/ai", put(set_ai_paused))
        .route("/ai/usage", get(ai_usage))
}

#[derive(Deserialize)]
struct AiPause {
    paused: bool,
}

async fn set_ai_paused(State(s): State<AppState>, Staff(st): Staff, Path(id): Path<Uuid>, Json(p): Json<AiPause>) -> ApiResult<Json<Value>> {
    let changed = sqlx::query("UPDATE chat_threads SET ai_paused = $2 WHERE id = $1")
        .bind(id)
        .bind(p.paused)
        .execute(&s.db)
        .await?
        .rows_affected();
    if changed == 0 {
        return Err(ApiError::NotFound);
    }
    super::audit(&s.db, "staff", Some(st.id), "chat.ai_pause", &id.to_string(), json!({ "paused": p.paused })).await?;
    Ok(Json(json!({ "id": id, "ai_paused": p.paused })))
}

async fn ai_usage(State(s): State<AppState>, Staff(_): Staff) -> ApiResult<Json<Value>> {
    let month = crate::ai::monthly_usage(&s.db).await?;
    let mode = s.providers.integ().ai.as_ref().map(|c| c.mode.code());
    Ok(Json(json!({ "configured": mode.is_some(), "mode": mode, "month": month })))
}

pub async fn mark_read(State(s): State<AppState>, a: Auth, Path(id): Path<Uuid>) -> ApiResult<Json<Value>> {
    authorize_thread(&s.db, &a, id).await?;
    let col = if a.role.is_staff() { "unread_staff" } else { "unread_member" };
    sqlx::query(&format!("UPDATE chat_threads SET {col} = 0 WHERE id = $1"))
        .bind(id)
        .execute(&s.db)
        .await?;
    let to = if a.role.is_staff() { None } else { Some(Recipient::Staff) };
    if let Some(to) = to {
        s.hub.send(to, "chat.read", json!({ "thread_id": id }));
    }
    Ok(Json(json!({ "ok": true })))
}
