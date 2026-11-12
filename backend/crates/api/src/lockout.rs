//! Login and OTP lockout with exponential backoff, counted on two keys per attempt:
//! - the (IP, account) pair locks one client after a few failures, so the account stays usable for others;
//! - the account alone has a wider free budget and locks it against a distributed guesser. Login refuses
//!   while it is locked; a staff account lock only delays (see `delay`). OTP has no account key: the
//!   per-code attempt cap and the send rate limit already bound guessing.
//!
//! A successful step clears both. State is per process; the database lockout on staff stays the backstop.

use crate::{error::ApiError, state::AppState};
use axum::http::HeaderMap;
use std::{
    collections::HashMap,
    net::{IpAddr, SocketAddr},
    sync::Mutex,
    time::{Duration, Instant},
};

/// Failures a client pair may make before its first lock.
pub const PAIR_FREE_FAILURES: u32 = 5;
/// Failures an account may take from any mix of clients before its first lock.
pub const ACCOUNT_FREE_FAILURES: u32 = 15;
const BASE_LOCK: Duration = Duration::from_secs(30);
const MAX_LOCK: Duration = Duration::from_secs(60 * 60);
/// A delayed (non-refusing) lock holds a request at most this long, so one account cannot tie up connections for an hour.
/// shortcut: delay is capped at 5s and not queued per account, upgrade to a per-account queue if slow-guess attacks show up.
pub const MAX_DELAY: Duration = Duration::from_secs(5);
/// Above this many tracked keys, expired locks are dropped on the next failure.
const SWEEP_AT: usize = 10_000;

/// One lockout counter: its name and the failures allowed before it locks.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Key {
    pub name: String,
    pub free: u32,
    /// A locked refusing key answers 429; a non-refusing one only delays the request.
    pub refuse: bool,
}

#[derive(Clone, Copy)]
struct Entry {
    fails: u32,
    locked_until: Instant,
}

#[derive(Default)]
pub struct Lockout {
    entries: Mutex<HashMap<String, Entry>>,
}

/// Lock length after `fails` consecutive failures: none inside `free`, then 30s doubling, capped at 1h.
pub fn backoff(fails: u32, free: u32) -> Duration {
    let Some(over) = fails.checked_sub(free) else {
        return Duration::ZERO;
    };
    let shift = over.min(20);
    BASE_LOCK.checked_mul(1 << shift).map_or(MAX_LOCK, |d| d.min(MAX_LOCK))
}

/// Keys for one attempt. `kind` separates login from OTP and staff from members.
pub fn keys(kind: &str, ip: IpAddr, account: &str) -> Vec<Key> {
    let account = account.trim().to_lowercase();
    let pair = Key { name: format!("{kind}-ip:{ip}|{account}"), free: PAIR_FREE_FAILURES, refuse: true };
    if kind == "otp" {
        return vec![pair];
    }
    vec![pair, Key { name: format!("{kind}:{account}"), free: ACCOUNT_FREE_FAILURES, refuse: kind != "staff" }]
}

/// Client address for lockout keys: forwarded headers count only behind a trusted proxy (as in ratelimit).
pub fn request_ip(trusted_proxy: bool, peer: Option<IpAddr>, forwarded_for: Option<&str>) -> IpAddr {
    crate::ratelimit::client_ip(peer, forwarded_for, trusted_proxy)
}

/// Client address of a request (the peer comes from `ConnectInfo`, as in the rate limiter).
pub fn ip_of(s: &AppState, peer: SocketAddr, headers: &HeaderMap) -> IpAddr {
    let fwd = headers.get("x-forwarded-for").and_then(|v| v.to_str().ok());
    request_ip(s.config.trusted_proxy, Some(peer.ip()), fwd)
}

impl Lockout {
    fn map(&self) -> std::sync::MutexGuard<'_, HashMap<String, Entry>> {
        // A poisoned lock only means another request panicked mid-update: keep counting.
        self.entries.lock().unwrap_or_else(|p| p.into_inner())
    }

    /// Longest remaining lock across the keys that match `pick`, if any is still active.
    fn longest(&self, keys: &[Key], now: Instant, pick: impl Fn(&Key) -> bool) -> Option<Duration> {
        let map = self.map();
        keys.iter()
            .filter(|k| pick(k))
            .filter_map(|k| map.get(&k.name))
            .map(|e| e.locked_until.saturating_duration_since(now))
            .filter(|d| !d.is_zero())
            .max()
    }

    /// Longest remaining lock across all keys, if any is still active.
    pub fn locked_for(&self, keys: &[Key], now: Instant) -> Option<Duration> {
        self.longest(keys, now, |_| true)
    }

    /// Refuses with 429 while a refusing key is locked.
    pub fn check(&self, keys: &[Key], now: Instant) -> Result<(), ApiError> {
        match self.longest(keys, now, |k| k.refuse) {
            Some(_) => Err(ApiError::RateLimited),
            None => Ok(()),
        }
    }

    /// Holds the request while a non-refusing key (a staff account lock) is still active, up to `MAX_DELAY`.
    pub async fn delay(&self, keys: &[Key], now: Instant) {
        if let Some(d) = self.longest(keys, now, |k| !k.refuse) {
            tokio::time::sleep(d.min(MAX_DELAY)).await;
        }
    }

    /// Counts one failure on each key and extends its lock per `backoff`. Returns true when this failure
    /// set a lock, which is the signal the owner's suspicious-activity alert counts.
    pub fn failure(&self, keys: &[Key], now: Instant) -> bool {
        let mut map = self.map();
        if map.len() > SWEEP_AT {
            map.retain(|_, e| e.locked_until > now);
        }
        let mut locked = false;
        for k in keys {
            let e = map.entry(k.name.clone()).or_insert(Entry { fails: 0, locked_until: now });
            e.fails = e.fails.saturating_add(1);
            let lock = backoff(e.fails, k.free);
            if !lock.is_zero() {
                e.locked_until = now + lock;
                locked = true;
            }
        }
        locked
    }

    /// Clears the counters for these keys after a step that proved the caller.
    pub fn success(&self, keys: &[Key]) {
        let mut map = self.map();
        for k in keys {
            map.remove(&k.name);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::net::Ipv4Addr;

    const IP: IpAddr = IpAddr::V4(Ipv4Addr::new(10, 0, 0, 1));
    const OTHER: IpAddr = IpAddr::V4(Ipv4Addr::new(10, 0, 0, 2));

    fn fail_n(lo: &Lockout, ks: &[Key], n: u32, now: Instant) {
        for _ in 0..n {
            lo.failure(ks, now);
        }
    }

    #[test]
    fn backoff_is_free_then_doubles_and_caps() {
        assert_eq!(backoff(4, 5), Duration::ZERO, "no lock inside the free budget");
        assert_eq!(backoff(5, 5), Duration::from_secs(30));
        assert_eq!(backoff(6, 5), Duration::from_secs(60));
        assert_eq!(backoff(7, 5), Duration::from_secs(120));
        assert_eq!(backoff(200, 5), MAX_LOCK, "capped at one hour");
        assert_eq!(backoff(u32::MAX, 0), MAX_LOCK, "no overflow");
    }

    #[test]
    fn pair_locks_after_its_budget_and_unlocks_when_the_lock_expires() {
        let lo = Lockout::default();
        let ks = keys("staff", IP, "a@x.test");
        let t0 = Instant::now();
        fail_n(&lo, &ks, PAIR_FREE_FAILURES, t0);
        assert_eq!(lo.locked_for(&ks, t0), Some(Duration::from_secs(30)));
        assert!(lo.check(&ks, t0 + Duration::from_secs(29)).is_err());
        assert!(lo.check(&ks, t0 + Duration::from_secs(30)).is_ok(), "lock expired");
    }

    #[test]
    fn one_client_is_locked_but_the_account_is_not_for_other_clients() {
        let lo = Lockout::default();
        let t0 = Instant::now();
        fail_n(&lo, &keys("staff", IP, "a@x.test"), PAIR_FREE_FAILURES, t0);
        assert!(lo.check(&keys("staff", IP, "a@x.test"), t0).is_err(), "same client locked");
        assert!(lo.check(&keys("staff", OTHER, "a@x.test"), t0).is_ok(), "other client still gets a try");
    }

    #[test]
    fn account_locks_for_every_ip_once_its_wider_budget_is_spent() {
        let lo = Lockout::default();
        let t0 = Instant::now();
        for i in 0..ACCOUNT_FREE_FAILURES {
            // Spread the guesses across clients so no single pair reaches its own budget.
            let ip = IpAddr::V4(Ipv4Addr::new(10, 1, 0, u8::try_from(i).unwrap_or(0)));
            lo.failure(&keys("staff", ip, "a@x.test"), t0);
        }
        let fresh = IpAddr::V4(Ipv4Addr::new(10, 9, 9, 9));
        let ks = keys("staff", fresh, "a@x.test");
        assert!(lo.check(&ks, t0).is_ok(), "a staff account lock delays, it does not refuse");
        assert!(lo.locked_for(&ks, t0).is_some(), "but the account is still locked for a new client");
        assert!(lo.check(&keys("staff", fresh, "b@x.test"), t0).is_ok(), "other accounts unaffected");
    }

    #[test]
    fn otp_has_no_account_key() {
        assert_eq!(keys("otp", IP, "010-1234-5678").len(), 1);
    }

    #[test]
    fn success_clears_both_keys_so_the_budgets_return() {
        let lo = Lockout::default();
        let ks = keys("login", IP, "a@x.test");
        let t0 = Instant::now();
        fail_n(&lo, &ks, PAIR_FREE_FAILURES - 1, t0);
        lo.success(&ks);
        fail_n(&lo, &ks, 1, t0);
        assert!(lo.check(&ks, t0).is_ok(), "counter was reset");
    }

    #[test]
    fn keys_normalise_the_account_and_carry_the_kind() {
        let ks = keys("staff", IP, "  Mixed@X.test ");
        let (pair, account) = (&ks[0], &ks[1]);
        assert_eq!(pair.name, "staff-ip:10.0.0.1|mixed@x.test");
        assert_eq!(account.name, "staff:mixed@x.test");
        assert_eq!((pair.free, account.free), (PAIR_FREE_FAILURES, ACCOUNT_FREE_FAILURES));
        assert!(pair.refuse && !account.refuse, "staff account key delays instead of refusing");
    }

    #[test]
    fn request_ip_ignores_forwarded_header_unless_trusted() {
        let fwd = Some("203.0.113.9");
        assert_eq!(request_ip(false, Some(IP), fwd), IP);
        assert_eq!(request_ip(true, Some(IP), fwd), IpAddr::V4(Ipv4Addr::new(203, 0, 113, 9)));
    }
}
