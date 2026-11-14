//! Socket tickets over the real router and a migrated database: issue, single use, expiry, role binding,
//! and the WebSocket upgrade accepting a ticket (and the deprecated access-token form). Needs DATABASE_URL.

mod common;

use api::{auth::Role, error::ApiError, realtime_ticket::consume_ticket};
use axum::http::StatusCode;
use common::{call, login};
use sqlx::PgPool;
use std::{net::SocketAddr, time::Duration};
use tokio::{
    io::{AsyncReadExt, AsyncWriteExt},
    net::{TcpListener, TcpStream},
    time::timeout,
};
use uuid::Uuid;

/// Issues a ticket through the router as the given access token.
async fn issue(app: &axum::Router, token: &str) -> String {
    let (st, body) = call(app, "POST", "/v1/realtime/ticket", Some(token), None).await;
    assert_eq!(st, StatusCode::OK, "{body}");
    body["ticket"].as_str().expect("ticket").to_string()
}

/// Opens the socket route on a real listener with a raw HTTP/1.1 upgrade; returns the status (101 when accepted).
/// A oneshot request cannot upgrade: axum needs the connection's `OnUpgrade`, which only a live socket provides.
async fn open_socket(app: &axum::Router, query: &str) -> StatusCode {
    let listener = TcpListener::bind("127.0.0.1:0").await.expect("bind");
    let addr = listener.local_addr().expect("local addr");
    let service = app.clone().into_make_service_with_connect_info::<SocketAddr>();
    tokio::spawn(async move { axum::serve(listener, service).await.expect("serves") });
    let mut stream = TcpStream::connect(addr).await.expect("connect");
    let request = format!(
        "GET /v1/ws?{query} HTTP/1.1\r\nHost: localhost\r\nConnection: Upgrade\r\nUpgrade: websocket\r\n\
         Sec-WebSocket-Version: 13\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n\r\n"
    );
    stream.write_all(request.as_bytes()).await.expect("write request");
    let head = timeout(Duration::from_secs(5), read_head(&mut stream)).await.expect("response head in time");
    let code = head.split_whitespace().nth(1).and_then(|c| c.parse::<u16>().ok()).expect("status line");
    StatusCode::from_u16(code).expect("valid status")
}

/// Reads up to the blank line that ends the response head (a 101 keeps the socket open, so no EOF comes).
async fn read_head(stream: &mut TcpStream) -> String {
    let mut buf = Vec::new();
    while !buf.windows(4).any(|w| w == b"\r\n\r\n") {
        let mut chunk = [0u8; 512];
        let n = stream.read(&mut chunk).await.expect("read response");
        assert!(n > 0, "server closed before the response head");
        buf.extend_from_slice(&chunk[..n]);
    }
    String::from_utf8_lossy(&buf).into_owned()
}

#[sqlx::test(migrations = "../../migrations")]
async fn ticket_is_issued_to_the_caller_and_consumed_once(db: PgPool) {
    let app = common::app(db.clone());
    let (token, subject) = login(&app, "010-7000-0001", "customer").await;
    let ticket = issue(&app, &token).await;

    let auth = consume_ticket(&db, &ticket).await.expect("first use accepted");
    assert_eq!(auth.id.to_string(), subject);
    assert_eq!(auth.role, Role::Customer);
    let reused = consume_ticket(&db, &ticket).await;
    assert!(matches!(reused, Err(ApiError::Unauthorized)), "a spent ticket is refused");
}

#[sqlx::test(migrations = "../../migrations")]
async fn ticket_needs_an_access_token(db: PgPool) {
    let app = common::app(db);
    let (st, _) = call(&app, "POST", "/v1/realtime/ticket", None, None).await;
    assert_eq!(st, StatusCode::UNAUTHORIZED);
}

#[sqlx::test(migrations = "../../migrations")]
async fn expired_ticket_is_refused(db: PgPool) {
    let app = common::app(db.clone());
    let (token, _) = login(&app, "010-7000-0002", "customer").await;
    let ticket = issue(&app, &token).await;
    sqlx::query("UPDATE realtime_tickets SET expires_at = now() - interval '1 second'")
        .execute(&db)
        .await
        .expect("age ticket");
    assert!(matches!(consume_ticket(&db, &ticket).await, Err(ApiError::Unauthorized)));
}

#[sqlx::test(migrations = "../../migrations")]
async fn ticket_keeps_the_role_it_was_issued_for(db: PgPool) {
    let (staff, id) = common::staff_token(&db, Role::StaffConsultant).await;
    let app = common::app(db.clone());
    let ticket = issue(&app, &staff).await;
    let auth = consume_ticket(&db, &ticket).await.expect("staff ticket");
    assert_eq!(auth.id, id);
    assert_eq!(auth.role, Role::StaffConsultant, "a staff ticket never grants a customer role");
}

#[sqlx::test(migrations = "../../migrations")]
async fn ticket_with_an_unknown_role_is_refused(db: PgPool) {
    // A row whose role is not a known role must never authenticate, even with the right ticket.
    let plain = "bad-role-ticket";
    sqlx::query("INSERT INTO realtime_tickets (token_hash, subject, role, expires_at) VALUES ($1, $2, 'owner', now() + interval '30 seconds')")
        .bind(api::auth::sha256_hex(plain.as_bytes()))
        .bind(Uuid::now_v7())
        .execute(&db)
        .await
        .expect("insert");
    assert!(matches!(consume_ticket(&db, plain).await, Err(ApiError::Unauthorized)));
}

#[sqlx::test(migrations = "../../migrations")]
async fn socket_upgrade_takes_a_ticket_once_and_still_takes_the_old_token(db: PgPool) {
    let app = common::app(db.clone());
    let (token, _) = login(&app, "010-7000-0003", "customer").await;
    let ticket = issue(&app, &token).await;

    assert_eq!(open_socket(&app, &format!("ticket={ticket}")).await, StatusCode::SWITCHING_PROTOCOLS);
    assert_eq!(open_socket(&app, &format!("ticket={ticket}")).await, StatusCode::UNAUTHORIZED, "reused ticket");
    assert_eq!(
        open_socket(&app, &format!("token={token}")).await,
        StatusCode::SWITCHING_PROTOCOLS,
        "deprecated form"
    );
    assert_eq!(open_socket(&app, "").await, StatusCode::UNAUTHORIZED, "no credential");
}
