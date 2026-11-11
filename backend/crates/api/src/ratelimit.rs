//! Per-IP sliding-window rate limits, held in memory by this process. Three buckets:
//! auth (`/v1/auth/*`), uploads (`/v1/uploads`) and everything else. Also hosts the
//! small quota helper used by per-user daily caps.

use crate::{config::Config, error::ApiError};
use axum::{
    extract::{ConnectInfo, Request, State},
    middleware::Next,
    response::{IntoResponse, Response},
};
use uuid::Uuid;
use std::{
    collections::{HashMap, VecDeque},
    net::{IpAddr, Ipv4Addr, SocketAddr},
    sync::{Arc, Mutex},
    time::{Duration, Instant},
};

const WINDOW: Duration = Duration::from_secs(60);
const SWEEP_EVERY: Duration = Duration::from_secs(60);
const FORWARDED_FOR: &str = "x-forwarded-for";

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Bucket {
    Auth,
    Upload,
    General,
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
pub fn within_quota(used: i64, limit: u32) -> bool {
    used < i64::from(limit)
}

/// Shared middleware state: the limiter plus the proxy setting.
pub struct Gate {
    trusted_proxy: bool,
    limiter: Mutex<Limiter>,
}

impl Gate {
    pub fn new(cfg: &Config, now: Instant) -> Self {
        let limits = Limits {
            auth: usize::try_from(cfg.rate_auth_per_min).unwrap_or(usize::MAX),
            upload: usize::try_from(cfg.rate_upload_per_min).unwrap_or(usize::MAX),
            general: usize::try_from(cfg.rate_general_per_min).unwrap_or(usize::MAX),
        };
        Self {
            trusted_proxy: cfg.trusted_proxy,
            limiter: Mutex::new(Limiter::new(limits, now)),
        }
    }
}

/// Axum middleware: 429 `rate_limited` once a client exceeds its bucket.
pub async fn limit(State(gate): State<Arc<Gate>>, req: Request, next: Next) -> Response {
    let peer = req.extensions().get::<ConnectInfo<SocketAddr>>().map(|c| c.0.ip());
    let forwarded = req.headers().get(FORWARDED_FOR).and_then(|v| v.to_str().ok());
    let ip = client_ip(peer, forwarded, gate.trusted_proxy);
    let bucket = bucket_for(req.uri().path());
    // A poisoned lock only means another request panicked mid-update: keep limiting.
    let allowed = gate
        .limiter
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
        .check(bucket, ip, Instant::now());
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
