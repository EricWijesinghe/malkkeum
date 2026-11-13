//! Live events over WebSocket plus durable notifications and push fallback.
//!
//! Fan-out across replicas: `Hub::send` delivers to sockets on this node at once and queues the
//! event for `pg_notify` on [`CHANNEL`]. Every node listens and re-broadcasts what other nodes sent.
//! Payloads that would not fit a NOTIFY are stored in `realtime_events` and only their id is sent.
//! After a listener outage the node broadcasts `resync`, because events sent in the gap were missed.

use crate::{
    auth::{Role, verify_access},
    error::ApiResult,
    lifecycle::drained,
    state::AppState,
};
use axum::{
    extract::{
        Query, State, WebSocketUpgrade,
        ws::{CloseFrame, Message, WebSocket, close_code},
    },
    response::Response,
};
use futures_util::{SinkExt, StreamExt, future::join_all};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use sqlx::{PgExecutor, PgPool};
use std::{
    borrow::Cow,
    sync::{
        Arc,
        atomic::{AtomicBool, AtomicUsize, Ordering},
    },
    time::Duration,
};
use tokio::{
    sync::{Semaphore, broadcast, mpsc, watch},
    task::JoinHandle,
};
use uuid::Uuid;

const HUB_CAPACITY: usize = 1024;
const PUBLISH_QUEUE: usize = 1024;
const PING_EVERY: Duration = Duration::from_secs(25);
const CHANNEL: &str = "malkkeum_events";
/// Postgres rejects NOTIFY payloads of 8000 bytes or more; keep a margin.
const NOTIFY_INLINE_MAX: usize = 7000;
/// How long the `notify_outbox` job leaves a new row to the attempt its own request makes.
const OUTBOX_GRACE_SECS: f64 = 60.0;
/// The job's retries start at this delay and double each time.
pub(crate) const OUTBOX_BACKOFF_SECS: f64 = 60.0;
/// Six retries span about an hour. After that a push is no longer worth sending.
const OUTBOX_MAX_ATTEMPTS: i32 = 6;
/// Rows retried at once; kept under the pool size, since each retry runs a few queries.
pub(crate) const OUTBOX_BATCH: usize = 10;
pub(crate) const OUTBOX_MAX_BATCHES: usize = 100;
const OUTBOX_EVERY: Duration = Duration::from_secs(30);
/// Pushes started straight from requests. A bulk send past this is drained by the job in batches.
static PUSH_SLOTS: Semaphore = Semaphore::const_new(32);
const LISTEN_BACKOFF_MIN: Duration = Duration::from_millis(250);
const LISTEN_BACKOFF_MAX: Duration = Duration::from_secs(30);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "kind", content = "id", rename_all = "snake_case")]
pub enum Recipient {
    User(Uuid),
    Pro(Uuid),
    /// A team member (partner app login); id is `team_members.id`.
    Member(Uuid),
    Staff,
}

#[derive(Debug, Clone, Serialize)]
pub struct Event {
    #[serde(skip)]
    pub to: Recipient,
    #[serde(rename = "type")]
    pub kind: Cow<'static, str>,
    pub data: Value,
}

/// What a socket subscriber receives: an event, or a marker that some events may have been missed.
#[derive(Debug, Clone)]
pub enum Frame {
    Event(Event),
    Resync,
}

/// Channel payload. `Inline` carries the event; `Stored` points at a `realtime_events` row.
#[derive(Debug, Serialize, Deserialize)]
#[serde(untagged)]
enum Wire {
    Inline { origin: Uuid, to: Recipient, kind: String, data: Value },
    Stored { origin: Uuid, stored: Uuid },
}

impl Wire {
    fn origin(&self) -> Uuid {
        match self {
            Self::Inline { origin, .. } | Self::Stored { origin, .. } => *origin,
        }
    }
}

/// Per-process event hub. Clones share the same channels, presence counter and drain signal.
#[derive(Clone)]
pub struct Hub {
    node: Uuid,
    db: PgPool,
    tx: broadcast::Sender<Frame>,
    publish: mpsc::Sender<Event>,
    draining: Arc<watch::Sender<bool>>,
    listening: Arc<AtomicBool>,
    staff: Arc<AtomicUsize>,
}

/// Counts one open staff socket until dropped (the socket's pump owns it).
pub struct StaffPresence(Arc<AtomicUsize>);

impl Drop for StaffPresence {
    fn drop(&mut self) {
        self.0.fetch_sub(1, Ordering::Relaxed);
    }
}

impl Hub {
    /// Starts the publisher task. Cross-node listening starts separately via [`Hub::spawn_listener`].
    pub fn new(db: PgPool) -> Self {
        let node = Uuid::now_v7();
        let (publish, queue) = mpsc::channel(PUBLISH_QUEUE);
        tokio::spawn(publish_loop(db.clone(), node, queue));
        Self {
            node,
            db,
            tx: broadcast::channel(HUB_CAPACITY).0,
            publish,
            draining: Arc::new(watch::channel(false).0),
            listening: Arc::default(),
            staff: Arc::default(),
        }
    }

    /// Delivers to sockets on this node now, and queues the event for the other nodes.
    pub fn send(&self, to: Recipient, kind: impl Into<Cow<'static, str>>, data: Value) {
        let kind = kind.into();
        let event = Event { to, kind: kind.clone(), data };
        // No receivers is normal (nobody online); push covers that case.
        let _ = self.tx.send(Frame::Event(event.clone()));
        if self.publish.try_send(event).is_err() {
            tracing::warn!(%kind, "realtime publish queue full; other nodes miss this event");
        }
    }

    pub fn subscribe(&self) -> broadcast::Receiver<Frame> {
        self.tx.subscribe()
    }

    /// Subscribes this node to the events of every other node. Reconnects with backoff.
    pub fn spawn_listener(&self) -> JoinHandle<()> {
        tokio::spawn(listen_loop(self.db.clone(), self.node, self.tx.clone(), self.listening.clone(), self.drain_signal()))
    }

    /// True while this node holds its LISTEN connection.
    pub fn is_listening(&self) -> bool {
        self.listening.load(Ordering::Relaxed)
    }

    /// Starts shutdown: sockets close with 1012 and background jobs stop after their current pass.
    pub fn drain(&self) {
        self.draining.send_replace(true);
    }

    pub fn drain_signal(&self) -> watch::Receiver<bool> {
        self.draining.subscribe()
    }

    pub fn staff_join(&self) -> StaffPresence {
        self.staff.fetch_add(1, Ordering::Relaxed);
        StaffPresence(self.staff.clone())
    }

    /// Open staff sockets on this node (the AI agent stays quiet while someone is connected).
    pub fn staff_connected(&self) -> usize {
        self.staff.load(Ordering::Relaxed)
    }
}

async fn publish_loop(db: PgPool, node: Uuid, mut queue: mpsc::Receiver<Event>) {
    while let Some(event) = queue.recv().await {
        if let Err(e) = publish(&db, node, &event).await {
            tracing::warn!(error = %e, kind = %event.kind, "realtime publish failed");
        }
    }
}

async fn publish(db: &PgPool, node: Uuid, event: &Event) -> Result<(), sqlx::Error> {
    let wire = Wire::Inline { origin: node, to: event.to, kind: event.kind.to_string(), data: event.data.clone() };
    let mut text = serde_json::to_string(&wire).map_err(|e| sqlx::Error::Encode(Box::new(e)))?;
    if text.len() > NOTIFY_INLINE_MAX {
        let stored = Uuid::now_v7();
        sqlx::query("INSERT INTO realtime_events (id, payload) VALUES ($1, $2)")
            .bind(stored)
            .bind(sqlx::types::Json(&wire))
            .execute(db)
            .await?;
        text = serde_json::to_string(&Wire::Stored { origin: node, stored }).map_err(|e| sqlx::Error::Encode(Box::new(e)))?;
    }
    sqlx::query("SELECT pg_notify($1, $2)").bind(CHANNEL).bind(text).execute(db).await?;
    Ok(())
}

/// Connects, LISTENs, relays until the connection drops, then starts again after a backoff.
async fn listen_loop(db: PgPool, node: Uuid, tx: broadcast::Sender<Frame>, listening: Arc<AtomicBool>, mut stop: watch::Receiver<bool>) {
    let mut backoff = LISTEN_BACKOFF_MIN;
    let mut connected_before = false;
    loop {
        match open_listener(&db).await {
            Ok(mut listener) => {
                listening.store(true, Ordering::Relaxed);
                if connected_before {
                    // Events sent while we were away never reached this node.
                    let _ = tx.send(Frame::Resync);
                }
                connected_before = true;
                backoff = LISTEN_BACKOFF_MIN;
                loop {
                    tokio::select! {
                        () = drained(&mut stop) => {
                            listening.store(false, Ordering::Relaxed);
                            return;
                        }
                        next = listener.try_recv() => match next {
                            Ok(Some(n)) => relay(&db, node, &tx, n.payload()).await,
                            Ok(None) => {
                                tracing::warn!("realtime listener connection lost");
                                break;
                            }
                            Err(e) => {
                                tracing::warn!(error = %e, "realtime listener failed");
                                break;
                            }
                        },
                    }
                }
                listening.store(false, Ordering::Relaxed);
            }
            Err(e) => tracing::warn!(error = %e, "realtime listen failed; retrying"),
        }
        if !pause(&mut stop, backoff).await {
            return;
        }
        backoff = (backoff * 2).min(LISTEN_BACKOFF_MAX);
    }
}

async fn open_listener(db: &PgPool) -> Result<sqlx::postgres::PgListener, sqlx::Error> {
    let mut listener = sqlx::postgres::PgListener::connect_with(db).await?;
    listener.listen(CHANNEL).await?;
    Ok(listener)
}

/// Sleeps for `d`. False when draining started first.
async fn pause(stop: &mut watch::Receiver<bool>, d: Duration) -> bool {
    tokio::select! {
        () = drained(stop) => false,
        () = tokio::time::sleep(d) => true,
    }
}

/// Re-broadcasts another node's event to this node's sockets. Our own echoes are dropped.
async fn relay(db: &PgPool, node: Uuid, tx: &broadcast::Sender<Frame>, payload: &str) {
    let wire: Wire = match serde_json::from_str(payload) {
        Ok(w) => w,
        Err(e) => {
            tracing::warn!(error = %e, "realtime payload unreadable; dropped");
            return;
        }
    };
    if wire.origin() == node {
        return;
    }
    let wire = match wire {
        Wire::Stored { stored, .. } => match fetch_stored(db, stored).await {
            Ok(Some(w)) => w,
            Ok(None) => {
                tracing::warn!(%stored, "realtime payload expired before it was read");
                return;
            }
            Err(e) => {
                tracing::warn!(error = %e, %stored, "realtime payload fetch failed");
                return;
            }
        },
        inline => inline,
    };
    if let Wire::Inline { to, kind, data, .. } = wire {
        let _ = tx.send(Frame::Event(Event { to, kind: Cow::Owned(kind), data }));
    }
}

async fn fetch_stored(db: &PgPool, id: Uuid) -> Result<Option<Wire>, sqlx::Error> {
    let payload: Option<sqlx::types::Json<Wire>> = sqlx::query_scalar("SELECT payload FROM realtime_events WHERE id = $1")
        .bind(id)
        .fetch_optional(db)
        .await?;
    Ok(payload.map(|p| p.0))
}

/// Deletes stored payloads older than a few minutes; listeners read them within moments.
pub async fn prune_stored(db: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::query("DELETE FROM realtime_events WHERE created_at < now() - interval '10 minutes'").execute(db).await.map(|_| ())
}

fn matches(to: Recipient, id: Uuid, role: Role) -> bool {
    match to {
        Recipient::User(u) => role == Role::Customer && u == id,
        Recipient::Pro(p) => role == Role::Pro && p == id,
        Recipient::Member(m) => role == Role::Member && m == id,
        Recipient::Staff => role.is_staff(),
    }
}

#[derive(Deserialize)]
pub struct WsQuery {
    token: String,
}

/// Sockets close when the access token would expire; clients reconnect with a fresh token,
/// so a deactivated account stops receiving events within one token lifetime.
const SOCKET_LIFETIME: Duration = Duration::from_secs(crate::auth::ACCESS_TTL_MIN as u64 * 60);

pub async fn ws_handler(State(state): State<AppState>, Query(q): Query<WsQuery>, ws: WebSocketUpgrade) -> ApiResult<Response> {
    let auth = verify_access(&state.config.jwt_keys(), &q.token)?;
    let rx = state.hub.subscribe();
    let presence = auth.role.is_staff().then(|| state.hub.staff_join());
    let draining = state.hub.drain_signal();
    Ok(ws.on_upgrade(move |socket| pump(socket, rx, draining, auth.id, auth.role, presence)))
}

async fn pump(
    socket: WebSocket,
    mut rx: broadcast::Receiver<Frame>,
    mut draining: watch::Receiver<bool>,
    id: Uuid,
    role: Role,
    _presence: Option<StaffPresence>,
) {
    let (mut sink, mut stream) = socket.split();
    let mut ping = tokio::time::interval(PING_EVERY);
    let expiry = tokio::time::sleep(SOCKET_LIFETIME);
    tokio::pin!(expiry);
    loop {
        tokio::select! {
            () = &mut expiry => {
                let _ = sink.send(Message::Close(None)).await;
                break;
            }
            () = drained(&mut draining) => {
                // 1012: the client should reconnect (to a healthy node) rather than treat this as an error.
                let _ = sink.send(Message::Close(Some(CloseFrame { code: close_code::RESTART, reason: "restarting".into() }))).await;
                break;
            }
            ev = rx.recv() => match ev {
                Ok(Frame::Event(ev)) if matches(ev.to, id, role) => {
                    let Ok(text) = serde_json::to_string(&ev) else { continue };
                    if sink.send(Message::Text(text.into())).await.is_err() { break; }
                }
                Ok(Frame::Event(_)) => {}
                Ok(Frame::Resync) | Err(broadcast::error::RecvError::Lagged(_)) => {
                    // Client fell behind (or events were lost): tell it to refetch instead of silently dropping.
                    if sink.send(Message::Text(json!({"type":"resync"}).to_string().into())).await.is_err() { break; }
                }
                Err(broadcast::error::RecvError::Closed) => break,
            },
            msg = stream.next() => match msg {
                Some(Ok(Message::Close(_))) | None | Some(Err(_)) => break,
                _ => {}
            },
            _ = ping.tick() => {
                if sink.send(Message::Ping(Vec::new().into())).await.is_err() { break; }
            }
        }
    }
}

impl Recipient {
    /// Inbox owner as stored in `notifications` and `push_tokens`. Staff have no inbox: live events only.
    fn owner(self) -> Option<(&'static str, Uuid)> {
        match self {
            Recipient::User(id) => Some(("customer", id)),
            Recipient::Pro(id) => Some(("pro", id)),
            Recipient::Member(id) => Some(("member", id)),
            Recipient::Staff => None,
        }
    }
}

/// A notification on its way out. `id` is its outbox row. None for staff (live events only) and when
/// the row could not be written: then there is one delivery attempt and no retry.
pub struct Queued {
    id: Option<i64>,
    to: Recipient,
    kind: Cow<'static, str>,
    /// Korean source text; each delivery translates it for the recipient.
    title: String,
    body: String,
    data: Value,
    /// The inbox row is written and the live event is out.
    stored: bool,
}

async fn insert_outbox<'e>(db: impl PgExecutor<'e>, q: &Queued) -> sqlx::Result<Option<i64>> {
    let Some((role, owner)) = q.to.owner() else {
        return Ok(None);
    };
    sqlx::query_scalar(
        "INSERT INTO notification_outbox (owner_role, owner_id, kind, title, body, data, next_attempt_at)
         VALUES ($1, $2, $3, $4, $5, $6, now() + make_interval(secs => $7)) RETURNING id",
    )
    .bind(role)
    .bind(owner)
    .bind(q.kind.as_ref())
    .bind(&q.title)
    .bind(&q.body)
    .bind(&q.data)
    .bind(OUTBOX_GRACE_SECS)
    .fetch_one(db)
    .await
    .map(Some)
}

/// Queues a notification on `db`. Pass the business transaction, so the notification commits with the
/// change it reports and survives a crash right after the commit. Hand the result to [`deliver`] once
/// the transaction is committed.
pub async fn enqueue<'e>(db: impl PgExecutor<'e>, to: Recipient, kind: &'static str, title: &str, body: &str, data: Value) -> sqlx::Result<Queued> {
    let mut q = Queued {
        id: None,
        to,
        kind: Cow::Borrowed(kind),
        title: title.to_string(),
        body: body.to_string(),
        data,
        stored: false,
    };
    q.id = insert_outbox(db, &q).await?;
    Ok(q)
}

/// Stores a notification, emits it live, and pushes to the owner's devices. Runs after the business
/// change is committed, so it never fails the caller: a step that fails stays in the outbox and the
/// `notify_outbox` job retries it. Always `Ok`; the `ApiResult` is kept for the call sites.
pub async fn notify(state: &AppState, to: Recipient, kind: &'static str, title: &str, body: &str, data: Value) -> ApiResult<()> {
    let mut q = Queued {
        id: None,
        to,
        kind: Cow::Borrowed(kind),
        title: title.to_string(),
        body: body.to_string(),
        data,
        stored: false,
    };
    match insert_outbox(&state.db, &q).await {
        Ok(id) => q.id = id,
        Err(e) => tracing::warn!(error = %e, kind, "notification not queued: one delivery attempt, no retry"),
    }
    deliver(state, q).await;
    Ok(())
}

/// Delivers a queued notification: inbox row and live event now, the push on a background task, so a
/// slow push service never holds the request. Never fails the caller. What could not be done stays in
/// the outbox for the `notify_outbox` job.
pub async fn deliver(state: &AppState, mut q: Queued) {
    if !store(state, &mut q).await {
        return;
    }
    // No free slot (bulk send): the row waits for the job, which pushes in bounded batches.
    let Ok(slot) = PUSH_SLOTS.try_acquire() else {
        if q.id.is_none() {
            tracing::warn!(kind = %q.kind, "push skipped: not queued and no push slot free");
        }
        return;
    };
    let state = state.clone();
    tokio::spawn(async move {
        push(&state, &q).await;
        drop(slot);
    });
}

/// Stage one: inbox row, live event and the customer's AlimTalk or SMS. True when the push may follow.
async fn store(state: &AppState, q: &mut Queued) -> bool {
    let Some((role, owner)) = q.to.owner() else {
        state.hub.send(q.to, q.kind.clone(), q.data.clone());
        return false;
    };
    if q.stored {
        return true;
    }
    match try_store(state, q, role, owner).await {
        Ok(true) => {
            q.stored = true;
            true
        }
        Ok(false) => {
            settle(state, q, Ok(())).await;
            false
        }
        Err(e) => {
            tracing::warn!(error = %e, kind = %q.kind, "notification not stored");
            settle(state, q, Err("store_failed")).await;
            // A queued row is retried whole. Without a row the push is the only trace left, so it still goes out.
            q.id.is_none()
        }
    }
}

/// False when the notification must not go out at all.
async fn try_store(state: &AppState, q: &Queued, role: &str, owner: Uuid) -> ApiResult<bool> {
    if let Recipient::User(user) = q.to
        && crate::privacy::is_marketing(&q.kind)
        && !crate::privacy::marketing_allowed(&state.db, user).await?
    {
        // 정보통신망법: advertising goes out only while the customer's marketing consent stands.
        return Ok(false);
    }
    // Inbox and push in the recipient's language; AlimTalk below keeps the approved Korean text.
    let locale = crate::i18n::locale_of(&state.db, q.to).await;
    let (title, body) = (crate::i18n::tr(&locale, &q.title), crate::i18n::tr(&locale, &q.body));
    // One statement: the inbox row and the outbox flag commit together, so a retry never stores twice.
    sqlx::query(
        "WITH flagged AS (UPDATE notification_outbox SET stored = true WHERE id = $5)
         INSERT INTO notifications (owner_role, owner_id, kind, data) VALUES ($1, $2, $3, $4)",
    )
    .bind(role)
    .bind(owner)
    .bind(q.kind.as_ref())
    .bind(json!({ "title": title, "body": body, "data": q.data }))
    .bind(q.id)
    .execute(&state.db)
    .await?;
    if let Recipient::User(user) = q.to {
        kakao_to_customer(state, user, &q.kind, &locale, (&q.title, &q.body), (&title, &body), &q.data);
    }
    state.hub.send(q.to, q.kind.clone(), q.data.clone());
    Ok(true)
}

/// Stage two: pushes to the owner's devices, then settles the outbox row.
async fn push(state: &AppState, q: &Queued) {
    let sent = try_push(state, q).await;
    if let (None, Err(code)) = (q.id, sent) {
        tracing::error!(kind = %q.kind, code, "push lost: the notification was not queued");
    }
    settle(state, q, sent).await;
}

async fn try_push(state: &AppState, q: &Queued) -> Result<(), &'static str> {
    let Some((role, owner)) = q.to.owner() else {
        return Ok(());
    };
    let tokens: Vec<String> = sqlx::query_scalar("SELECT token FROM push_tokens WHERE owner_role = $1 AND owner_id = $2")
        .bind(role)
        .bind(owner)
        .fetch_all(&state.db)
        .await
        .map_err(|e| {
            tracing::warn!(error = %e, kind = %q.kind, "push token lookup failed");
            "token_lookup_failed"
        })?;
    if tokens.is_empty() {
        return Ok(());
    }
    let locale = crate::i18n::locale_of(&state.db, q.to).await;
    let (title, body) = (crate::i18n::tr(&locale, &q.title), crate::i18n::tr(&locale, &q.body));
    match state.providers.push_collect(&tokens, &title, &body, &q.data).await {
        Ok(dead) => {
            prune_push_tokens(state, role, owner, &dead).await;
            Ok(())
        }
        Err(e) => {
            tracing::warn!(error = %e, kind = %q.kind, "push failed");
            Err("push_failed")
        }
    }
}

/// Closes an attempt on the outbox row: deleted when delivered, kept with a short code for the retry.
async fn settle(state: &AppState, q: &Queued, outcome: Result<(), &'static str>) {
    let Some(id) = q.id else {
        return;
    };
    let done = match outcome {
        Ok(()) => sqlx::query("DELETE FROM notification_outbox WHERE id = $1").bind(id).execute(&state.db).await,
        Err(code) => {
            sqlx::query("UPDATE notification_outbox SET last_error = $2 WHERE id = $1")
                .bind(id)
                .bind(code)
                .execute(&state.db)
                .await
        }
    };
    if let Err(e) = done {
        tracing::warn!(error = %e, outbox = id, "outbox row not settled; it will be tried again");
    }
}

/// id, owner_role, owner_id, kind, title, body, data, stored, attempts.
type OutboxRow = (i64, String, Uuid, String, String, String, Value, bool, i32);

/// One pass of the `notify_outbox` job: retries what a request could not deliver, pushes and texts alike.
/// Rows are claimed with `FOR UPDATE SKIP LOCKED` and the next-attempt stamp is the lease, so the job runs
/// on every replica and no two work the same row. Returns how many rows were tried.
pub async fn outbox_pass(state: &AppState) -> ApiResult<usize> {
    let pushes = push_pass(state).await?;
    let texts = crate::sms_outbox::pass(state).await?;
    Ok(pushes + texts)
}

async fn push_pass(state: &AppState) -> ApiResult<usize> {
    let mut tried = 0;
    for _ in 0..OUTBOX_MAX_BATCHES {
        let rows: Vec<OutboxRow> = sqlx::query_as(
            "UPDATE notification_outbox SET attempts = attempts + 1, next_attempt_at = now() + make_interval(secs => $1 * power(2, attempts))
             WHERE id IN (SELECT id FROM notification_outbox WHERE channel = 'push' AND next_attempt_at <= now() ORDER BY next_attempt_at LIMIT $2 FOR UPDATE SKIP LOCKED)
             RETURNING id, owner_role, owner_id, kind, title, body, data, stored, attempts",
        )
        .bind(OUTBOX_BACKOFF_SECS)
        .bind(OUTBOX_BATCH as i64)
        .fetch_all(&state.db)
        .await?;
        let claimed = rows.len();
        join_all(rows.into_iter().map(|row| retry(state, row))).await;
        tried += claimed;
        if claimed < OUTBOX_BATCH {
            break;
        }
    }
    Ok(tried)
}

async fn retry(state: &AppState, (id, role, owner, kind, title, body, data, stored, attempts): OutboxRow) {
    let to = match role.as_str() {
        "customer" => Recipient::User(owner),
        "pro" => Recipient::Pro(owner),
        _ => Recipient::Member(owner),
    };
    let mut q = Queued {
        id: Some(id),
        to,
        kind: Cow::Owned(kind),
        title,
        body,
        data,
        stored,
    };
    if attempts > OUTBOX_MAX_ATTEMPTS {
        tracing::error!(kind = %q.kind, stored, retries = OUTBOX_MAX_ATTEMPTS, "notification dropped: retries used up");
        return settle(state, &q, Ok(())).await;
    }
    if store(state, &mut q).await {
        push(state, &q).await;
    }
}

/// Starts the outbox job. Errors are logged and the loop goes on.
pub fn spawn_outbox(state: AppState) -> JoinHandle<()> {
    let mut stop = state.hub.drain_signal();
    tokio::spawn(async move {
        let mut tick = tokio::time::interval(OUTBOX_EVERY);
        while crate::lifecycle::next_tick(&mut tick, &mut stop).await {
            let ok = outbox_pass(&state)
                .await
                .inspect_err(|e| tracing::warn!(error = %e, "notification outbox pass failed"))
                .is_ok();
            crate::metrics::job_pass("notify_outbox", ok);
        }
    })
}

/// Drops device tokens the push service no longer accepts (app removed, token rotated).
async fn prune_push_tokens(state: &AppState, role: &str, owner: Uuid, dead: &[String]) {
    if dead.is_empty() {
        return;
    }
    let pruned = sqlx::query("DELETE FROM push_tokens WHERE token = ANY($1) AND owner_role = $2 AND owner_id = $3")
        .bind(dead.to_vec())
        .bind(role)
        .bind(owner)
        .execute(&state.db)
        .await;
    if let Err(e) = pruned {
        tracing::warn!(error = %e, "failed to prune dead push tokens");
    }
}

/// Transactional alert to a customer by phone. Korean customers get AlimTalk (SMS fallback). Other
/// languages get SMS in their own language, because the approved AlimTalk templates are Korean only.
/// Runs off the request path; failures only log, so a provider outage never fails the business action.
fn kakao_to_customer(state: &AppState, user: Uuid, kind: &str, locale: &str, ko: (&str, &str), translated: (&str, &str), data: &Value) {
    let Some(key) = crate::providers::sms::alert_key(kind, data) else {
        return;
    };
    let kind = kind.to_string();
    if state.providers.integ().solapi.is_none() {
        return;
    }
    let korean = locale == "ko";
    let (ko_title, ko_body) = (ko.0.to_string(), ko.1.to_string());
    let (title, body) = (translated.0.to_string(), translated.1.to_string());
    let state = state.clone();
    tokio::spawn(async move {
        let found = sqlx::query_scalar::<_, Option<String>>("SELECT phone FROM users WHERE id = $1")
            .bind(user)
            .fetch_optional(&state.db)
            .await;
        let phone = match found {
            Ok(row) => row.flatten(),
            Err(e) => {
                tracing::warn!(error = %e, %kind, "customer phone lookup failed");
                return;
            }
        };
        let Some(phone) = phone else {
            return;
        };
        let sent = if korean {
            let brand = crate::routes::setup::brand_name(&state.db).await;
            let msg = crate::sms_outbox::Message::Alimtalk { template: key, brand: &brand, title: &ko_title, body: &ko_body };
            crate::sms_outbox::send(&state, Some(user), &phone, &kind, msg).await
        } else {
            let text = format!("{title}\n{body}");
            crate::sms_outbox::send(&state, Some(user), &phone, &kind, crate::sms_outbox::Message::Sms(&text)).await
        };
        if let Err(e) = sent {
            tracing::warn!(error = %e, %kind, "customer message not queued");
        }
    });
}
