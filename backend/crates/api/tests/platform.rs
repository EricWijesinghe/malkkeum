//! Operations plumbing over the real router and a migrated database: cross-node realtime through
//! Postgres LISTEN/NOTIFY, request ids, readiness, and the metrics endpoint.

mod common;

use api::{
    build_state,
    realtime::{Event, Frame, Recipient},
    routes,
};
use axum::{
    Router,
    body::Body,
    extract::ConnectInfo,
    http::{HeaderMap, Request, StatusCode},
};
use serde_json::{Value, json};
use sqlx::PgPool;
use std::{net::SocketAddr, time::Duration};
use tokio::sync::broadcast::{Receiver, error::TryRecvError};
use tower::ServiceExt;
use uuid::Uuid;

const METRICS_TOKEN: &str = "metrics-test-token-0123456789-abcdef";
const WAIT: Duration = Duration::from_secs(5);

/// One request with extra headers from a chosen peer address. Returns status, headers and body text.
async fn raw(app: &Router, method: &str, uri: &str, headers: &[(&str, &str)], peer: [u8; 4]) -> (StatusCode, HeaderMap, String) {
    let mut req = Request::builder().method(method).uri(uri);
    for (k, v) in headers {
        req = req.header(*k, *v);
    }
    let mut request = req.body(Body::empty()).expect("request");
    request.extensions_mut().insert(ConnectInfo(SocketAddr::from((peer, 40_000))));
    let resp = app.clone().oneshot(request).await.expect("router is infallible");
    let status = resp.status();
    let resp_headers = resp.headers().clone();
    let bytes = axum::body::to_bytes(resp.into_body(), usize::MAX).await.expect("body");
    (status, resp_headers, String::from_utf8_lossy(&bytes).into_owned())
}

async fn wait_listening(hub: &api::realtime::Hub) {
    let deadline = tokio::time::Instant::now() + WAIT;
    while !hub.is_listening() {
        assert!(tokio::time::Instant::now() < deadline, "listener never came up");
        tokio::time::sleep(Duration::from_millis(20)).await;
    }
}

/// Waits for the next event of `kind` on a subscriber, skipping other frames.
async fn expect_event(rx: &mut Receiver<Frame>, kind: &str) -> Event {
    tokio::time::timeout(WAIT, async {
        loop {
            match rx.recv().await {
                Ok(Frame::Event(ev)) if ev.kind == kind => return ev,
                Ok(_) => {}
                Err(e) => panic!("subscriber failed: {e}"),
            }
        }
    })
    .await
    .unwrap_or_else(|_| panic!("no `{kind}` event within {WAIT:?}"))
}

async fn expect_resync(rx: &mut Receiver<Frame>) {
    tokio::time::timeout(WAIT, async {
        loop {
            if matches!(rx.recv().await, Ok(Frame::Resync)) {
                return;
            }
        }
    })
    .await
    .expect("resync frame after the listener reconnected");
}

#[sqlx::test(migrations = "../../migrations")]
async fn events_reach_sockets_on_other_nodes_once(pool: PgPool) {
    let a = build_state(pool.clone(), common::test_config()).expect("node a");
    let b = build_state(pool.clone(), common::test_config()).expect("node b");
    let _la = a.hub.spawn_listener();
    let _lb = b.hub.spawn_listener();
    wait_listening(&a.hub).await;
    wait_listening(&b.hub).await;
    let mut rx_a = a.hub.subscribe();
    let mut rx_b = b.hub.subscribe();

    let pro = Uuid::now_v7();
    a.hub.send(Recipient::Pro(pro), "job.updated", json!({ "booking_id": "small" }));
    let ev = expect_event(&mut rx_b, "job.updated").await;
    assert_eq!(ev.to, Recipient::Pro(pro));
    assert_eq!(ev.data["booking_id"], "small");
    expect_event(&mut rx_a, "job.updated").await;
    tokio::time::sleep(Duration::from_millis(300)).await;
    assert!(matches!(rx_a.try_recv(), Err(TryRecvError::Empty)), "own event must not be echoed back");

    // Over the NOTIFY limit: only the stored id travels, and the receiver reads the row back.
    let big = "가".repeat(6_000);
    b.hub.send(Recipient::Staff, "chat.message", json!({ "body": big }));
    let ev = expect_event(&mut rx_a, "chat.message").await;
    assert_eq!(ev.data["body"].as_str().map(str::len), Some(big.len()));
    let stored: i64 = sqlx::query_scalar("SELECT count(*) FROM realtime_events").fetch_one(&pool).await.expect("count");
    assert_eq!(stored, 1, "the large payload went through the table");
}

#[sqlx::test(migrations = "../../migrations")]
async fn listener_reconnects_and_tells_sockets_to_resync(pool: PgPool) {
    let a = build_state(pool.clone(), common::test_config()).expect("node a");
    let b = build_state(pool.clone(), common::test_config()).expect("node b");
    let _la = a.hub.spawn_listener();
    let _lb = b.hub.spawn_listener();
    wait_listening(&a.hub).await;
    wait_listening(&b.hub).await;
    let mut rx_b = b.hub.subscribe();

    // Drop every LISTEN connection, as a database failover or restart would.
    let killed: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM (SELECT pg_terminate_backend(pid) FROM pg_stat_activity
         WHERE datname = current_database() AND query = 'LISTEN \"malkkeum_events\"') t",
    )
    .fetch_one(&pool)
    .await
    .expect("terminate listeners");
    assert!(killed >= 2, "both listeners were connected: {killed}");

    expect_resync(&mut rx_b).await;
    wait_listening(&b.hub).await;
    a.hub.send(Recipient::Staff, "booking.updated", json!({ "booking_id": "after" }));
    let ev = expect_event(&mut rx_b, "booking.updated").await;
    assert_eq!(ev.data["booking_id"], "after", "events flow again after the reconnect");
}

#[sqlx::test(migrations = "../../migrations")]
async fn request_ids_are_kept_generated_and_echoed(pool: PgPool) {
    let app = common::app(pool);
    let (_, headers, _) = raw(&app, "GET", "/health", &[("x-request-id", "trace-123")], [127, 0, 0, 1]).await;
    assert_eq!(headers.get("x-request-id").and_then(|v| v.to_str().ok()), Some("trace-123"));

    let (_, headers, _) = raw(&app, "GET", "/health", &[], [127, 0, 0, 1]).await;
    let generated = headers.get("x-request-id").and_then(|v| v.to_str().ok()).expect("generated id").to_string();
    assert_eq!(generated.len(), 36, "uuid");

    let (_, headers, _) = raw(&app, "GET", "/health", &[("x-request-id", "bad id with spaces")], [127, 0, 0, 1]).await;
    let replaced = headers.get("x-request-id").and_then(|v| v.to_str().ok()).expect("id").to_string();
    assert_ne!(replaced, "bad id with spaces");
}

#[sqlx::test(migrations = "../../migrations")]
async fn error_bodies_carry_only_the_request_id(pool: PgPool) {
    let app = common::app(pool);
    let (status, headers, body) = raw(&app, "GET", "/v1/admin/ops/status", &[("x-request-id", "req-42")], [127, 0, 0, 1]).await;
    assert_eq!(status, StatusCode::UNAUTHORIZED);
    let parsed: Value = serde_json::from_str(&body).expect("json error");
    assert_eq!(parsed, json!({ "error": { "code": "unauthorized", "request_id": "req-42" } }));
    assert_eq!(headers.get("x-request-id").and_then(|v| v.to_str().ok()), Some("req-42"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn readiness_checks_the_database_and_migrations(pool: PgPool) {
    let app = common::app(pool.clone());
    let (status, _, body) = raw(&app, "GET", "/ready", &[], [127, 0, 0, 1]).await;
    assert_eq!(status, StatusCode::OK, "{body}");
    assert_eq!(serde_json::from_str::<Value>(&body).expect("json")["ready"], true);

    sqlx::query("UPDATE _sqlx_migrations SET success = false WHERE version = (SELECT MAX(version) FROM _sqlx_migrations)")
        .execute(&pool)
        .await
        .expect("simulate an unapplied migration");
    let (status, _, body) = raw(&app, "GET", "/ready", &[], [127, 0, 0, 1]).await;
    assert_eq!(status, StatusCode::SERVICE_UNAVAILABLE);
    assert_eq!(serde_json::from_str::<Value>(&body).expect("json")["migrations"], false);

    // Liveness does not depend on the database.
    let (status, _, _) = raw(&app, "GET", "/health", &[], [127, 0, 0, 1]).await;
    assert_eq!(status, StatusCode::OK);
}

#[sqlx::test(migrations = "../../migrations")]
async fn metrics_need_loopback_or_the_scrape_token(pool: PgPool) {
    let app = common::app(pool.clone());
    let (status, _, _) = raw(&app, "GET", "/metrics", &[], [203, 0, 113, 9]).await;
    assert_eq!(status, StatusCode::UNAUTHORIZED, "remote peer without a token");
    let (status, _, body) = raw(&app, "GET", "/metrics", &[], [127, 0, 0, 1]).await;
    assert_eq!(status, StatusCode::OK);
    assert!(body.contains("malkkeum_db_pool_connections{state=\"open\"}"), "pool gauge: {body}");

    let mut cfg = common::test_config();
    cfg.metrics_token = Some(METRICS_TOKEN.into());
    let tokened = routes::router(build_state(pool, cfg).expect("state"));
    let bearer = format!("Bearer {METRICS_TOKEN}");
    let (status, _, _) = raw(&tokened, "GET", "/metrics", &[], [127, 0, 0, 1]).await;
    assert_eq!(status, StatusCode::UNAUTHORIZED, "loopback is not enough once a token is set");
    let (status, _, _) = raw(&tokened, "GET", "/metrics", &[("authorization", "Bearer nope")], [127, 0, 0, 1]).await;
    assert_eq!(status, StatusCode::UNAUTHORIZED);
    let (status, _, body) = raw(&tokened, "GET", "/metrics", &[("authorization", &bearer)], [203, 0, 113, 9]).await;
    assert_eq!(status, StatusCode::OK);
    assert!(body.contains("malkkeum_http_requests_total"), "{body}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn request_metrics_use_route_templates_not_raw_paths(pool: PgPool) {
    let app = common::app(pool);
    let id = Uuid::now_v7();
    raw(&app, "GET", "/health", &[], [127, 0, 0, 1]).await;
    raw(&app, "GET", &format!("/v1/bookings/{id}/nope-{id}"), &[], [127, 0, 0, 1]).await;
    let (_, _, body) = raw(&app, "GET", "/metrics", &[], [127, 0, 0, 1]).await;
    assert!(body.contains("route=\"/health\",status=\"200\""), "health series: {body}");
    assert!(body.contains("route=\"unmatched\""), "unknown paths share one label: {body}");
    assert!(!body.contains(&id.to_string()), "raw ids never become labels");
    assert!(body.contains("malkkeum_http_request_duration_seconds_bucket{method=\"GET\",route=\"/health\""), "histogram buckets");
}

#[sqlx::test(migrations = "../../migrations")]
async fn draining_closes_listeners_and_jobs(pool: PgPool) {
    let state = build_state(pool, common::test_config()).expect("state");
    let mut stop = state.hub.drain_signal();
    assert!(!*stop.borrow());
    state.hub.drain();
    tokio::time::timeout(WAIT, api::lifecycle::drained(&mut stop)).await.expect("drain observed");
}
