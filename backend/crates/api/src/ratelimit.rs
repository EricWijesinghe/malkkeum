//! Per-IP request limits. Three buckets: auth (`/v1/auth/*`), uploads (`/v1/uploads`) and everything else.
//! Every bucket has an in-memory sliding window (fast path, per process); auth and upload also keep a
//! fixed-window counter in Postgres so a restart or a second replica cannot reset the budget. Also hosts
//! the small quota helper used by per-user daily caps.

use crate::{config::Config, error::ApiError};
use axum::{
    extract::{ConnectInfo, Request, State},
    middleware::Next,
    response::{IntoResponse, Response},
};
use sqlx::PgPool;
use std::{
    collections::{HashMap, VecDeque},
    net::{IpAddr, Ipv4Addr, SocketAddr},
    sync::{Arc, Mutex},
    time::{Duration, Instant},
};
use uuid::Uuid;

const WINDOW: Duration = Duration::from_secs(60);
const SWEEP_EVERY: Duration = Duration::from_secs(60);
const FORWARDED_FOR: &str = "x-forwarded-for";

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Bucket {
    Auth,
    Upload,
    General,
}

impl Bucket {
    fn name(self) -> &'static str {
        match self {
            Self::Auth => "auth",
            Self::Upload => "upload",
            Self::General => "general",
        }
    }
}

/// Which bucket a request path counts against.
pub fn bucket_for(path: &str) -> Bucket {
    if path == "/v1/auth" || path.starts_with("/v1/auth/") {
        Bucket::Auth
    } else if path == "/v1/uploads" {
        Bucket::Upload
    } else {
        Bucket::General
    }
}

/// Requests per minute for each bucket.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Limits {
    pub auth: usize,
    pub upload: usize,
    pub general: usize,
}

impl Limits {
    fn of(self, bucket: Bucket) -> usize {
        match bucket {
            Bucket::Auth => self.auth,
            Bucket::Upload => self.upload,
            Bucket::General => self.general,
        }
    }
}

/// Hit times for one key, pruned to the last `WINDOW`.
#[derive(Debug, Default)]
struct Log {
    hits: VecDeque<Instant>,
}

impl Log {
    fn admit(&mut self, now: Instant, limit: usize) -> bool {
        self.prune(now);
        if self.hits.len() >= limit {
            return false;
        }
        self.hits.push_back(now);
        true
    }

    fn prune(&mut self, now: Instant) {
        while self.hits.front().is_some_and(|t| now.saturating_duration_since(*t) >= WINDOW) {
            self.hits.pop_front();
        }
    }

    fn is_idle(&self, now: Instant) -> bool {
        self.hits.back().is_none_or(|t| now.saturating_duration_since(*t) >= WINDOW)
    }
}

/// Window bookkeeping with the clock injected, so tests never sleep.
#[derive(Debug)]
pub struct Limiter {
    limits: Limits,
    logs: HashMap<(Bucket, IpAddr), Log>,
    last_sweep: Instant,
}

impl Limiter {
    pub fn new(limits: Limits, now: Instant) -> Self {
        Self {
            limits,
            logs: HashMap::new(),
            last_sweep: now,
        }
    }

    /// True if the request may pass. Also drops idle keys about once a minute.
    pub fn check(&mut self, bucket: Bucket, ip: IpAddr, now: Instant) -> bool {
        self.sweep(now);
        let limit = self.limits.of(bucket);
        self.logs.entry((bucket, ip)).or_default().admit(now, limit)
    }

    fn sweep(&mut self, now: Instant) {
        if now.saturating_duration_since(self.last_sweep) < SWEEP_EVERY {
            return;
        }
        self.logs.retain(|_, log| !log.is_idle(now));
        self.last_sweep = now;
    }

    #[cfg(test)]
    fn tracked_keys(&self) -> usize {
        self.logs.len()
    }
}

/// Per-user sliding window for one costly endpoint. Same hit log as the per-IP buckets; idle users are dropped on each check.
#[derive(Debug, Default)]
pub struct UserLimiter {
    logs: Mutex<HashMap<Uuid, Log>>,
}

impl UserLimiter {
    pub fn admit(&self, user: Uuid, limit: usize, now: Instant) -> bool {
        let mut logs = self.logs.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
        logs.retain(|_, log| !log.is_idle(now));
        logs.entry(user).or_default().admit(now, limit)
    }
}

/// The right-most X-Forwarded-For entry: the address the nearest trusted proxy saw.
pub fn forwarded_ip(header: &str) -> Option<IpAddr> {
    header.rsplit(',').next()?.trim().parse().ok()
}

/// Client address for rate limiting. Forwarded headers count only behind a trusted proxy.
pub fn client_ip(peer: Option<IpAddr>, forwarded_for: Option<&str>, trusted_proxy: bool) -> IpAddr {
    let forwarded = if trusted_proxy { forwarded_for.and_then(forwarded_ip) } else { None };
    forwarded.or(peer).unwrap_or(IpAddr::V4(Ipv4Addr::UNSPECIFIED))
}

/// A quota is spent while `used` is below `limit`.
pub fn within_quota(used: i64, limit: i64) -> bool {
    used < limit
}

/// Shared middleware state: the in-memory limiter, the proxy setting and the database that holds the
/// durable counters of the auth and upload buckets.
pub struct Gate {
    trusted_proxy: bool,
    limits: Limits,
    limiter: Mutex<Limiter>,
    db: PgPool,
    last_sweep: Mutex<Instant>,
}

impl Gate {
    pub fn new(cfg: &Config, db: PgPool, now: Instant) -> Self {
        let limits = Limits {
            auth: usize::try_from(cfg.rate_auth_per_min).unwrap_or(usize::MAX),
            upload: usize::try_from(cfg.rate_upload_per_min).unwrap_or(usize::MAX),
            general: usize::try_from(cfg.rate_general_per_min).unwrap_or(usize::MAX),
        };
        Self {
            trusted_proxy: cfg.trusted_proxy,
            limits,
            limiter: Mutex::new(Limiter::new(limits, now)),
            db,
            last_sweep: Mutex::new(now),
        }
    }

    /// Fixed-window counter in Postgres, shared by every replica and kept across restarts. A database
    /// error lets the request through: the in-memory verdict already passed.
    async fn shared_admit(&self, bucket: Bucket, ip: IpAddr) -> bool {
        let limit = i32::try_from(self.limits.of(bucket)).unwrap_or(i32::MAX);
        let key = format!("{}:{ip}", bucket.name());
        let hits = sqlx::query_scalar::<_, i32>(
            "INSERT INTO rate_limits (key, window_start, hits) VALUES ($1, now(), 1)
             ON CONFLICT (key) DO UPDATE SET
               hits = CASE WHEN rate_limits.window_start <= now() - make_interval(secs => $2) THEN 1 ELSE rate_limits.hits + 1 END,
               window_start = CASE WHEN rate_limits.window_start <= now() - make_interval(secs => $2) THEN now() ELSE rate_limits.window_start END
             RETURNING hits",
        )
        .bind(key)
        .bind(WINDOW.as_secs_f64())
        .fetch_one(&self.db)
        .await;
        match hits {
            Ok(h) => h <= limit,
            Err(e) => {
                tracing::warn!(error = ?e, "shared rate limit unavailable, using the in-memory verdict");
                true
            }
        }
    }

    /// Drops windows that ended long ago, about once a minute.
    async fn sweep_shared(&self, now: Instant) {
        let due = {
            let mut last = self.last_sweep.lock().unwrap_or_else(|p| p.into_inner());
            let due = now.saturating_duration_since(*last) >= SWEEP_EVERY;
            if due {
                *last = now;
            }
            due
        };
        if due
            && let Err(e) = sqlx::query("DELETE FROM rate_limits WHERE window_start < now() - make_interval(secs => $1)")
                .bind(WINDOW.as_secs_f64() * 2.0)
                .execute(&self.db)
                .await
        {
            tracing::warn!(error = ?e, "rate limit sweep failed");
        }
    }
}

/// Axum middleware: 429 `rate_limited` once a client exceeds its bucket.
pub async fn limit(State(gate): State<Arc<Gate>>, req: Request, next: Next) -> Response {
    let peer = req.extensions().get::<ConnectInfo<SocketAddr>>().map(|c| c.0.ip());
    let forwarded = req.headers().get(FORWARDED_FOR).and_then(|v| v.to_str().ok());
    let ip = client_ip(peer, forwarded, gate.trusted_proxy);
    let bucket = bucket_for(req.uri().path());
    let now = Instant::now();
    // A poisoned lock only means another request panicked mid-update: keep limiting.
    let mut allowed = gate.limiter.lock().unwrap_or_else(|poisoned| poisoned.into_inner()).check(bucket, ip, now);
    // Auth and uploads are the abuse targets: their budget is also counted durably across restarts and replicas.
    if allowed && bucket != Bucket::General {
        gate.sweep_shared(now).await;
        allowed = gate.shared_admit(bucket, ip).await;
    }
    if allowed {
        next.run(req).await
    } else {
        ApiError::RateLimited.into_response()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const T0: Duration = Duration::from_secs(0);

    fn ip(last: u8) -> IpAddr {
        IpAddr::V4(Ipv4Addr::new(10, 0, 0, last))
    }

    fn limiter(auth: usize) -> (Limiter, Instant) {
        let now = Instant::now();
        (Limiter::new(Limits { auth, upload: 2, general: 3 }, now), now)
    }

    #[test]
    fn window_admits_up_to_limit_then_refuses() {
        let (mut l, now) = limiter(2);
        assert!(l.check(Bucket::Auth, ip(1), now));
        assert!(l.check(Bucket::Auth, ip(1), now + T0));
        assert!(!l.check(Bucket::Auth, ip(1), now + Duration::from_secs(1)));
    }

    #[test]
    fn hits_free_up_one_by_one_as_they_age_out() {
        let (mut l, now) = limiter(2);
        assert!(l.check(Bucket::Auth, ip(1), now));
        assert!(l.check(Bucket::Auth, ip(1), now + Duration::from_secs(30)));
        assert!(!l.check(Bucket::Auth, ip(1), now + Duration::from_secs(59)));
        // The first hit is 60 s old: exactly one slot is back, the second still counts.
        assert!(l.check(Bucket::Auth, ip(1), now + Duration::from_secs(60)));
        assert!(!l.check(Bucket::Auth, ip(1), now + Duration::from_secs(60)));
    }

    #[test]
    fn keys_are_isolated_per_ip_and_per_bucket() {
        let (mut l, now) = limiter(1);
        assert!(l.check(Bucket::Auth, ip(1), now));
        assert!(!l.check(Bucket::Auth, ip(1), now));
        assert!(l.check(Bucket::Auth, ip(2), now));
        assert!(l.check(Bucket::Upload, ip(1), now));
        assert!(l.check(Bucket::General, ip(1), now));
    }

    #[test]
    fn idle_keys_are_swept_periodically() {
        let (mut l, now) = limiter(5);
        assert!(l.check(Bucket::General, ip(1), now));
        assert!(l.check(Bucket::General, ip(2), now));
        assert_eq!(l.tracked_keys(), 2);
        // Within a minute nothing is swept; after the window and a sweep tick, idle keys go.
        let later = now + Duration::from_secs(61);
        assert!(l.check(Bucket::General, ip(3), later));
        assert_eq!(l.tracked_keys(), 1);
    }

    #[test]
    fn buckets_map_paths() {
        assert_eq!(bucket_for("/v1/auth/otp"), Bucket::Auth);
        assert_eq!(bucket_for("/v1/auth/social"), Bucket::Auth);
        assert_eq!(bucket_for("/v1/auth"), Bucket::Auth);
        assert_eq!(bucket_for("/v1/authors"), Bucket::General);
        assert_eq!(bucket_for("/v1/uploads"), Bucket::Upload);
        assert_eq!(bucket_for("/v1/uploads/extra"), Bucket::General);
        assert_eq!(bucket_for("/v1/bookings"), Bucket::General);
        assert_eq!(bucket_for("/health"), Bucket::General);
    }

    #[test]
    fn forwarded_header_uses_right_most_entry() {
        assert_eq!(forwarded_ip("203.0.113.9"), Some(IpAddr::V4(Ipv4Addr::new(203, 0, 113, 9))));
        // A client can prepend anything; only the entry the proxy appended is trusted.
        assert_eq!(forwarded_ip("1.1.1.1, 10.2.3.4"), Some(IpAddr::V4(Ipv4Addr::new(10, 2, 3, 4))));
        assert_eq!(forwarded_ip("2001:db8::1"), Some("2001:db8::1".parse::<IpAddr>().unwrap()));
        assert_eq!(forwarded_ip("1.1.1.1, not-an-ip"), None);
        assert_eq!(forwarded_ip(""), None);
    }

    #[test]
    fn client_ip_ignores_forwarded_header_unless_trusted() {
        let peer = Some(ip(7));
        let xff = Some("198.51.100.4");
        assert_eq!(client_ip(peer, xff, true), IpAddr::V4(Ipv4Addr::new(198, 51, 100, 4)));
        assert_eq!(client_ip(peer, xff, false), ip(7));
        assert_eq!(client_ip(peer, Some("junk"), true), ip(7));
        assert_eq!(client_ip(None, None, true), IpAddr::V4(Ipv4Addr::UNSPECIFIED));
    }

    #[test]
    fn quota_is_spent_below_the_limit() {
        assert!(within_quota(0, 3));
        assert!(within_quota(2, 3));
        assert!(!within_quota(3, 3));
        assert!(!within_quota(4, 3));
        assert!(!within_quota(0, 0));
    }
}
