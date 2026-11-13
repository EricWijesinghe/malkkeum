//! Login and OTP lockout with exponential backoff, counted on two keys per attempt:
//! - the (IP, account) pair locks one client after a few failures, so the account stays usable for others;
//! - the account alone has a wider free budget and locks it against a distributed guesser. Login refuses
//!   while it is locked; a staff account lock only delays (see `delay`). OTP has no account key: the
//!   per-code attempt cap and the send rate limit already bound guessing.
//!
//! A successful step clears both. Counters live in Postgres (`auth_lockouts`), so a restart or another
//! replica does not reset them. The database lockout on staff stays a second backstop.

use crate::{
    error::{ApiError, ApiResult},
    state::AppState,
};
use axum::http::HeaderMap;
use sqlx::PgPool;
use std::{
    net::{IpAddr, SocketAddr},
    time::Duration,
};

/// Failures a client pair may make before its first lock.
pub const PAIR_FREE_FAILURES: u32 = 5;
/// Failures an account may take from any mix of clients before its first lock.
pub const ACCOUNT_FREE_FAILURES: u32 = 15;
const BASE_LOCK: Duration = Duration::from_secs(30);
const MAX_LOCK: Duration = Duration::from_secs(60 * 60);
/// A quiet period this long after the last failure (or the end of a lock) gives the free budget back.
const FAIL_MEMORY: Duration = Duration::from_secs(60 * 60);
/// A delayed (non-refusing) lock holds a request at most this long, so one account cannot tie up connections for an hour.
/// shortcut: delay is capped at 5s and not queued per account, upgrade to a per-account queue if slow-guess attacks show up.
pub const MAX_DELAY: Duration = Duration::from_secs(5);

/// One lockout counter: its name and the failures allowed before it locks.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Key {
    pub name: String,
    pub free: u32,
    /// A locked refusing key answers 429; a non-refusing one only delays the request.
    pub refuse: bool,
}

pub struct Lockout {
    db: PgPool,
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
    let pair = Key {
        name: format!("{kind}-ip:{ip}|{account}"),
        free: PAIR_FREE_FAILURES,
        refuse: true,
    };
    if kind == "otp" {
        return vec![pair];
    }
    vec![
        pair,
        Key {
            name: format!("{kind}:{account}"),
            free: ACCOUNT_FREE_FAILURES,
            refuse: kind != "staff",
        },
    ]
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
    pub fn new(db: PgPool) -> Self {
        Self { db }
    }

    /// Longest remaining lock across the keys that match `pick`, if any is still active.
    async fn remaining(&self, keys: &[Key], pick: impl Fn(&Key) -> bool) -> ApiResult<Option<Duration>> {
        let names: Vec<&str> = keys.iter().filter(|k| pick(k)).map(|k| k.name.as_str()).collect();
        let secs: Option<f64> =
            sqlx::query_scalar("SELECT max(EXTRACT(EPOCH FROM locked_until - now()))::float8 FROM auth_lockouts WHERE key = ANY($1) AND locked_until > now()")
                .bind(&names)
                .fetch_one(&self.db)
                .await?;
        Ok(secs.map(Duration::from_secs_f64))
    }

    /// Longest remaining lock across all keys, if any is still active.
    pub async fn locked_for(&self, keys: &[Key]) -> ApiResult<Option<Duration>> {
        self.remaining(keys, |_| true).await
    }

    /// Refuses with 429 while a refusing key is locked.
    pub async fn check(&self, keys: &[Key]) -> ApiResult<()> {
        match self.remaining(keys, |k| k.refuse).await? {
            Some(_) => Err(ApiError::RateLimited),
            None => Ok(()),
        }
    }

    /// Holds the request while a non-refusing key (a staff account lock) is still active, up to `MAX_DELAY`.
    pub async fn delay(&self, keys: &[Key]) -> ApiResult<()> {
        if let Some(d) = self.remaining(keys, |k| !k.refuse).await? {
            tokio::time::sleep(d.min(MAX_DELAY)).await;
        }
        Ok(())
    }

    /// Counts one failure on each key and extends its lock per `backoff`. Returns true when this failure
    /// set a lock, which is the signal the owner's suspicious-activity alert counts.
    pub async fn failure(&self, keys: &[Key]) -> ApiResult<bool> {
        sqlx::query("DELETE FROM auth_lockouts WHERE expires_at < now()").execute(&self.db).await?;
        let mut locked = false;
        for k in keys {
            let fails: i32 = sqlx::query_scalar(
                "INSERT INTO auth_lockouts (key, fails, locked_until, expires_at) VALUES ($1, 1, now(), now() + make_interval(secs => $2))
                 ON CONFLICT (key) DO UPDATE SET
                   fails = CASE WHEN auth_lockouts.expires_at < now() THEN 1 ELSE auth_lockouts.fails + 1 END,
                   expires_at = greatest(auth_lockouts.locked_until, now()) + make_interval(secs => $2)
                 RETURNING fails",
            )
            .bind(&k.name)
            .bind(FAIL_MEMORY.as_secs_f64())
            .fetch_one(&self.db)
            .await?;
            let lock = backoff(u32::try_from(fails).unwrap_or(u32::MAX), k.free);
            if !lock.is_zero() {
                sqlx::query(
                    "UPDATE auth_lockouts SET locked_until = now() + make_interval(secs => $2),
                       expires_at = now() + make_interval(secs => $2 + $3) WHERE key = $1",
                )
                .bind(&k.name)
                .bind(lock.as_secs_f64())
                .bind(FAIL_MEMORY.as_secs_f64())
                .execute(&self.db)
                .await?;
                locked = true;
            }
        }
        Ok(locked)
    }

    /// Clears the counters for these keys after a step that proved the caller.
    pub async fn success(&self, keys: &[Key]) -> ApiResult<()> {
        let names: Vec<&str> = keys.iter().map(|k| k.name.as_str()).collect();
        sqlx::query("DELETE FROM auth_lockouts WHERE key = ANY($1)")
            .bind(&names)
            .execute(&self.db)
            .await?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::net::Ipv4Addr;

    const IP: IpAddr = IpAddr::V4(Ipv4Addr::new(10, 0, 0, 1));

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
    fn otp_has_no_account_key() {
        assert_eq!(keys("otp", IP, "010-1234-5678").len(), 1);
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
