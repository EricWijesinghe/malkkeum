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
use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use sqlx::PgPool;
use std::{
    borrow::Cow,
    sync::{
        Arc,
        atomic::{AtomicBool, AtomicUsize, Ordering},
    },
    time::Duration,
};
use tokio::{
    sync::{broadcast, mpsc, watch},
    task::JoinHandle,
};
use uuid::Uuid;

const HUB_CAPACITY: usize = 1024;
const PUBLISH_QUEUE: usize = 1024;
const PING_EVERY: Duration = Duration::from_secs(25);
const CHANNEL: &str = "malkkeum_events";
/// Postgres rejects NOTIFY payloads of 8000 bytes or more; keep a margin.
const NOTIFY_INLINE_MAX: usize = 7000;
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
    pub fn send(&self, to: Recipient, kind: &'static str, data: Value) {
        let event = Event { to, kind: Cow::Borrowed(kind), data };
        // No receivers is normal (nobody online); push covers that case.
        let _ = self.tx.send(Frame::Event(event.clone()));
        if self.publish.try_send(event).is_err() {
            tracing::warn!(kind, "realtime publish queue full; other nodes miss this event");
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
    let auth = verify_access(&state.config.jwt_secret, &q.token)?;
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

/// Stores a notification, emits it live, and pushes to the owner's devices.
pub async fn notify(state: &AppState, to: Recipient, kind: &'static str, title: &str, body: &str, data: Value) -> ApiResult<()> {
    if let Recipient::User(user) = to
        && crate::privacy::is_marketing(kind)
        && !crate::privacy::marketing_allowed(&state.db, user).await?
    {
        // 정보통신망법: advertising goes out only while the customer's marketing consent stands.
        return Ok(());
    }
    let (role, owner) = match to {
        Recipient::User(id) => ("customer", Some(id)),
        Recipient::Pro(id) => ("pro", Some(id)),
        Recipient::Member(id) => ("member", Some(id)),
        Recipient::Staff => ("staff", None),
    };
    if let Some(owner) = owner {
        // Inbox and push in the recipient's language; AlimTalk below keeps the approved Korean text.
        let locale = crate::i18n::locale_of(&state.db, to).await;
        let (ko_title, ko_body) = (title, body);
        let (title, body) = (crate::i18n::tr(&locale, title), crate::i18n::tr(&locale, body));
        let (title, body) = (title.as_str(), body.as_str());
        sqlx::query("INSERT INTO notifications (owner_role, owner_id, kind, data) VALUES ($1, $2, $3, $4)")
            .bind(role)
            .bind(owner)
            .bind(kind)
            .bind(json!({ "title": title, "body": body, "data": data }))
            .execute(&state.db)
            .await?;
        let tokens: Vec<String> = sqlx::query_scalar("SELECT token FROM push_tokens WHERE owner_role = $1 AND owner_id = $2")
            .bind(role)
            .bind(owner)
            .fetch_all(&state.db)
            .await?;
        match state.providers.push_collect(&tokens, title, body, &data).await {
            Ok(dead) => prune_push_tokens(state, role, owner, &dead).await,
            Err(e) => tracing::warn!(error = %e, "push failed; notification kept in inbox"),
        }
        if let Recipient::User(user) = to {
            kakao_to_customer(state, user, kind, ko_title, ko_body);
        }
    }
    state.hub.send(to, kind, data);
    Ok(())
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

/// AlimTalk (or SMS fallback) to a customer for kinds that have a template. Runs off the request path;
/// failures only log, so a provider outage never fails the business action that triggered it.
fn kakao_to_customer(state: &AppState, user: Uuid, kind: &'static str, title: &str, body: &str) {
    if !state.providers.integ().solapi.as_ref().is_some_and(|c| c.templates.contains_key(kind)) {
        return;
    }
    let state = state.clone();
    let (title, body) = (title.to_string(), body.to_string());
    tokio::spawn(async move {
        let found = sqlx::query_scalar::<_, Option<String>>("SELECT phone FROM users WHERE id = $1")
            .bind(user)
            .fetch_optional(&state.db)
            .await;
        let phone = match found {
            Ok(row) => row.flatten(),
            Err(e) => {
                tracing::warn!(error = %e, kind, "customer phone lookup failed");
                return;
            }
        };
        let Some(phone) = phone else {
            return;
        };
        if let Err(e) = state.providers.send_customer_message(&phone, kind, &title, &body).await {
            tracing::warn!(error = %e, kind, "customer message failed");
        }
    });
}
