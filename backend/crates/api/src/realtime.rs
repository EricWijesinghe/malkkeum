//! Live events over WebSocket plus durable notifications and push fallback.

use crate::{
    auth::{Role, verify_access},
    error::ApiResult,
    state::AppState,
};
use axum::{
    extract::{
        Query, State, WebSocketUpgrade,
        ws::{Message, WebSocket},
    },
    response::Response,
};
use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use std::time::Duration;
use tokio::sync::broadcast;
use uuid::Uuid;

const HUB_CAPACITY: usize = 1024;
const PING_EVERY: Duration = Duration::from_secs(25);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
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
    pub kind: &'static str,
    pub data: Value,
}

/// shortcut: in-process broadcast works for one API node; switch to Postgres
/// LISTEN/NOTIFY or NATS when running more than one replica.
#[derive(Clone)]
pub struct Hub {
    tx: broadcast::Sender<Event>,
}

impl Default for Hub {
    fn default() -> Self {
        Self {
            tx: broadcast::channel(HUB_CAPACITY).0,
        }
    }
}

impl Hub {
    pub fn send(&self, to: Recipient, kind: &'static str, data: Value) {
        // No receivers is normal (nobody online); push covers that case.
        let _ = self.tx.send(Event { to, kind, data });
    }
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
    let rx = state.hub.tx.subscribe();
    Ok(ws.on_upgrade(move |socket| pump(socket, rx, auth.id, auth.role)))
}

async fn pump(socket: WebSocket, mut rx: broadcast::Receiver<Event>, id: Uuid, role: Role) {
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
            ev = rx.recv() => match ev {
                Ok(ev) if matches(ev.to, id, role) => {
                    let Ok(text) = serde_json::to_string(&ev) else { continue };
                    if sink.send(Message::Text(text.into())).await.is_err() { break; }
                }
                Ok(_) => {}
                Err(broadcast::error::RecvError::Lagged(_)) => {
                    // Client fell behind: tell it to refetch instead of silently dropping.
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
