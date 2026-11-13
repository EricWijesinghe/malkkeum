//! Prometheus text exposition at `GET /metrics`. Label values are bounded on purpose: routes are
//! matched route templates (`/v1/bookings/{id}`, never raw paths), unknown methods collapse to
//! `OTHER`, and unmatched requests share one `unmatched` route. Scrapes need `METRICS_TOKEN` as a
//! bearer token, or a loopback peer when no token is set.

use crate::{error::ApiError, state::AppState};
use axum::{
    extract::{ConnectInfo, Request, State},
    http::{HeaderMap, Method, header},
    middleware::Next,
    response::{IntoResponse, Response},
};
use std::{
    collections::BTreeMap,
    fmt::Write,
    net::{IpAddr, SocketAddr},
    sync::Mutex,
    time::{Instant, SystemTime, UNIX_EPOCH},
};
use axum::extract::MatchedPath;
use subtle::ConstantTimeEq;

/// Request latency buckets in seconds.
const BUCKETS: [f64; 11] = [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0];
const UNMATCHED: &str = "unmatched";

#[derive(Default, Clone)]
struct Latency {
    count: u64,
    sum: f64,
    /// Per-bucket (non-cumulative) counts; values above the last bucket only reach `count`.
    buckets: [u64; BUCKETS.len()],
}

/// (method, route template, status) -> latency series.
type RouteKey = (&'static str, String, u16);

static HTTP: Mutex<BTreeMap<RouteKey, Latency>> = Mutex::new(BTreeMap::new());
static JOBS: Mutex<BTreeMap<&'static str, Job>> = Mutex::new(BTreeMap::new());

#[derive(Default, Clone, Copy)]
pub struct Job {
    pub last_run_unix: f64,
    /// Unix time of the last pass that succeeded (0 = never in this process).
    pub last_ok_unix: f64,
    pub errors: u64,
}

/// Locks a metrics map; a panic in another request must not stop metrics for the rest of the process.
fn locked<T>(m: &Mutex<T>) -> std::sync::MutexGuard<'_, T> {
    m.lock().unwrap_or_else(|e| e.into_inner())
}

fn unix_now() -> f64 {
    SystemTime::now().duration_since(UNIX_EPOCH).map_or(0.0, |d| d.as_secs_f64())
}

fn method_label(m: &Method) -> &'static str {
    match *m {
        Method::GET => "GET",
        Method::POST => "POST",
        Method::PUT => "PUT",
        Method::PATCH => "PATCH",
        Method::DELETE => "DELETE",
        Method::HEAD => "HEAD",
        Method::OPTIONS => "OPTIONS",
        _ => "OTHER",
    }
}

/// Records every request by route template and status. Sits outside routing, so `MatchedPath` is read per route.
pub async fn track(req: Request, next: Next) -> Response {
    let method = method_label(req.method());
    let route = req.extensions().get::<MatchedPath>().map_or_else(|| UNMATCHED.to_string(), |m| m.as_str().to_string());
    let started = Instant::now();
    let resp = next.run(req).await;
    let elapsed = started.elapsed().as_secs_f64();
    let mut http = locked(&HTTP);
    let series = http.entry((method, route, resp.status().as_u16())).or_default();
    series.count += 1;
    series.sum += elapsed;
    if let Some(i) = BUCKETS.iter().position(|le| elapsed <= *le) {
        series.buckets[i] += 1;
    }
    resp
}

/// Called by each background pass: stamps the last run and counts failed passes.
pub fn job_pass(job: &'static str, ok: bool) {
    let mut jobs = locked(&JOBS);
    let entry = jobs.entry(job).or_default();
    entry.last_run_unix = unix_now();
    if ok {
        entry.last_ok_unix = entry.last_run_unix;
    } else {
        entry.errors += 1;
    }
}

/// Every known job with its last pass in this process. A job that has not run yet is listed with
/// zeros, so the scrape and the status page always show the full set.
pub fn jobs() -> BTreeMap<&'static str, Job> {
    let mut jobs = locked(&JOBS).clone();
    for (job, _) in crate::jobs::ALL {
        jobs.entry(job).or_default();
    }
    jobs
}

/// Values the exposition reads from outside this module (pool, payouts table, realtime listener).
pub struct Snapshot {
    pub pool_open: u32,
    pub pool_idle: usize,
    /// None when the database could not be asked; the gauge is then left out.
    pub payouts_pending: Option<i64>,
    pub realtime_listening: bool,
    pub version: &'static str,
    pub uptime_secs: u64,
}

fn escape(v: &str) -> String {
    v.replace('\\', "\\\\").replace('"', "\\\"").replace('\n', "\\n")
}

/// Renders the Prometheus text format (version 0.0.4).
pub fn render(snap: &Snapshot) -> String {
    let mut out = String::new();
    let http = locked(&HTTP).clone();
    let jobs = jobs();
    let _ = writeln!(out, "# HELP malkkeum_build_info Build version of this API process.");
    let _ = writeln!(out, "# TYPE malkkeum_build_info gauge");
    let _ = writeln!(out, "malkkeum_build_info{{version=\"{}\"}} 1", escape(snap.version));
    let _ = writeln!(out, "# HELP malkkeum_uptime_seconds Seconds since the process started.");
    let _ = writeln!(out, "# TYPE malkkeum_uptime_seconds gauge");
    let _ = writeln!(out, "malkkeum_uptime_seconds {}", snap.uptime_secs);

    let _ = writeln!(out, "# HELP malkkeum_http_requests_total HTTP requests by method, route template and status.");
    let _ = writeln!(out, "# TYPE malkkeum_http_requests_total counter");
    for ((method, route, status), s) in &http {
        let labels = format!("method=\"{method}\",route=\"{}\",status=\"{status}\"", escape(route));
        let _ = writeln!(out, "malkkeum_http_requests_total{{{labels}}} {}", s.count);
    }

    let _ = writeln!(out, "# HELP malkkeum_http_request_duration_seconds Request latency by method, route template and status.");
    let _ = writeln!(out, "# TYPE malkkeum_http_request_duration_seconds histogram");
    for ((method, route, status), s) in &http {
        let labels = format!("method=\"{method}\",route=\"{}\",status=\"{status}\"", escape(route));
        let mut cumulative = 0;
        for (le, n) in BUCKETS.iter().zip(s.buckets) {
            cumulative += n;
            let _ = writeln!(out, "malkkeum_http_request_duration_seconds_bucket{{{labels},le=\"{le}\"}} {cumulative}");
        }
        let _ = writeln!(out, "malkkeum_http_request_duration_seconds_bucket{{{labels},le=\"+Inf\"}} {}", s.count);
        let _ = writeln!(out, "malkkeum_http_request_duration_seconds_sum{{{labels}}} {}", s.sum);
        let _ = writeln!(out, "malkkeum_http_request_duration_seconds_count{{{labels}}} {}", s.count);
    }

    let _ = writeln!(out, "# HELP malkkeum_db_pool_connections Database pool connections by state.");
    let _ = writeln!(out, "# TYPE malkkeum_db_pool_connections gauge");
    let _ = writeln!(out, "malkkeum_db_pool_connections{{state=\"open\"}} {}", snap.pool_open);
    let _ = writeln!(out, "malkkeum_db_pool_connections{{state=\"idle\"}} {}", snap.pool_idle);

    if let Some(pending) = snap.payouts_pending {
        let _ = writeln!(out, "# HELP malkkeum_payouts_pending Payouts requested or sent and not yet settled.");
        let _ = writeln!(out, "# TYPE malkkeum_payouts_pending gauge");
        let _ = writeln!(out, "malkkeum_payouts_pending {pending}");
    }

    let _ = writeln!(out, "# HELP malkkeum_realtime_listening 1 when this node is subscribed to cross-node events.");
    let _ = writeln!(out, "# TYPE malkkeum_realtime_listening gauge");
    let _ = writeln!(out, "malkkeum_realtime_listening {}", u8::from(snap.realtime_listening));

    let _ = writeln!(out, "# HELP malkkeum_job_last_run_timestamp_seconds Unix time of the last pass of a background job (0 = never).");
    let _ = writeln!(out, "# TYPE malkkeum_job_last_run_timestamp_seconds gauge");
    for (job, j) in &jobs {
        let _ = writeln!(out, "malkkeum_job_last_run_timestamp_seconds{{job=\"{job}\"}} {}", j.last_run_unix);
    }
    let _ = writeln!(
        out,
        "# HELP malkkeum_job_last_success_timestamp_seconds Unix time of the last successful pass of a background job (0 = never)."
    );
    let _ = writeln!(out, "# TYPE malkkeum_job_last_success_timestamp_seconds gauge");
    for (job, j) in &jobs {
        let _ = writeln!(out, "malkkeum_job_last_success_timestamp_seconds{{job=\"{job}\"}} {}", j.last_ok_unix);
    }
    let _ = writeln!(out, "# HELP malkkeum_job_errors_total Failed passes of a background job.");
    let _ = writeln!(out, "# TYPE malkkeum_job_errors_total counter");
    for (job, j) in &jobs {
        let _ = writeln!(out, "malkkeum_job_errors_total{{job=\"{job}\"}} {}", j.errors);
    }
    out
}

/// Scrape access: the bearer token when one is configured, otherwise loopback peers only.
fn allowed(token: Option<&str>, peer: Option<IpAddr>, headers: &HeaderMap) -> bool {
    match token {
        Some(expected) => headers
            .get(header::AUTHORIZATION)
            .and_then(|v| v.to_str().ok())
            .and_then(|v| v.strip_prefix("Bearer "))
            .is_some_and(|given| bool::from(given.as_bytes().ct_eq(expected.as_bytes()))),
        None => peer.is_some_and(|ip| ip.is_loopback()),
    }
}

pub async fn handler(State(s): State<AppState>, ConnectInfo(peer): ConnectInfo<SocketAddr>, headers: HeaderMap) -> Response {
    if !allowed(s.config.metrics_token.as_deref(), Some(peer.ip()), &headers) {
        return ApiError::Unauthorized.into_response();
    }
    let payouts_pending = sqlx::query_scalar::<_, i64>("SELECT count(*) FROM payouts WHERE state IN ('requested', 'sent')")
        .fetch_one(&s.db)
        .await
        .ok();
    let snap = Snapshot {
        pool_open: s.db.size(),
        pool_idle: s.db.num_idle(),
        payouts_pending,
        realtime_listening: s.hub.is_listening(),
        version: crate::routes::APP_VERSION,
        uptime_secs: crate::ops::uptime_secs(),
    };
    ([(header::CONTENT_TYPE, "text/plain; version=0.0.4; charset=utf-8")], render(&snap)).into_response()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn token_or_loopback_guards_the_scrape() {
        let mut h = HeaderMap::new();
        let lan: IpAddr = "10.0.0.5".parse().expect("ip");
        let local: IpAddr = "127.0.0.1".parse().expect("ip");
        assert!(allowed(None, Some(local), &h));
        assert!(!allowed(None, Some(lan), &h), "no token: remote peers refused");
        assert!(!allowed(Some("s3cret-token-0123456789-0123456789"), Some(local), &h), "token wins over loopback");
        h.insert(header::AUTHORIZATION, "Bearer s3cret-token-0123456789-0123456789".parse().expect("hv"));
        assert!(allowed(Some("s3cret-token-0123456789-0123456789"), Some(lan), &h));
        h.insert(header::AUTHORIZATION, "Bearer wrong".parse().expect("hv"));
        assert!(!allowed(Some("s3cret-token-0123456789-0123456789"), Some(lan), &h));
    }

    #[test]
    fn histogram_is_cumulative_and_labels_are_escaped() {
        job_pass("unit_test_job", false);
        let snap = Snapshot { pool_open: 2, pool_idle: 1, payouts_pending: Some(3), realtime_listening: true, version: "t", uptime_secs: 9 };
        let text = render(&snap);
        assert!(text.contains("malkkeum_payouts_pending 3"));
        assert!(text.contains("malkkeum_job_errors_total{job=\"unit_test_job\"} 1"));
        assert_eq!(escape("a\"b\\c"), "a\\\"b\\\\c");
    }
}
