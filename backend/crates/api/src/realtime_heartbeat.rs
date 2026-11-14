//! Liveness for WebSocket sockets: a ping cadence and a silence clock that reaps dead peers.

use std::time::Duration;

/// Ping cadence per socket. Any frame from the peer (a pong included) resets its silence clock.
pub(crate) const PING_EVERY: Duration = Duration::from_secs(25);
/// A socket silent this long is dead (half-open after a network switch, or a crashed client). Checked on each ping,
/// so it is reaped at the first ping tick past this mark: at most one interval late.
pub(crate) const PONG_TIMEOUT: Duration = Duration::from_secs(60);

/// Liveness of one socket: pings go out every `PING_EVERY`, and the peer must have sent something within `PONG_TIMEOUT`.
#[derive(Debug)]
pub(crate) struct Heartbeat {
    heard: tokio::time::Instant,
}

/// What a socket does on a ping tick.
#[derive(Debug, PartialEq, Eq)]
pub(crate) enum Beat {
    Ping,
    Reap,
}

impl Heartbeat {
    pub(crate) fn new(now: tokio::time::Instant) -> Self {
        Self { heard: now }
    }

    pub(crate) fn heard(&mut self, now: tokio::time::Instant) {
        self.heard = now;
    }

    pub(crate) fn on_tick(&self, now: tokio::time::Instant) -> Beat {
        if now.duration_since(self.heard) >= PONG_TIMEOUT {
            Beat::Reap
        } else {
            Beat::Ping
        }
    }
}

#[cfg(test)]
mod heartbeat_tests {
    use super::*;
    use tokio::time::Instant;

    #[tokio::test(start_paused = true)]
    async fn silent_peer_is_reaped_on_the_first_tick_past_the_timeout() {
        let start = Instant::now();
        let mut ping = tokio::time::interval(PING_EVERY);
        let hb = Heartbeat::new(start);
        let reaped = loop {
            ping.tick().await;
            if hb.on_tick(Instant::now()) == Beat::Reap {
                break Instant::now().duration_since(start);
            }
        };
        // Ticks at 0, 25 and 50 are within 60s of the last frame; 75 is the first past it.
        assert_eq!(reaped, Duration::from_secs(75));
    }

    #[tokio::test(start_paused = true)]
    async fn peer_that_answers_every_ping_is_never_reaped() {
        let mut ping = tokio::time::interval(PING_EVERY);
        let mut hb = Heartbeat::new(Instant::now());
        for _ in 0..240 {
            ping.tick().await;
            assert_eq!(hb.on_tick(Instant::now()), Beat::Ping);
            hb.heard(Instant::now());
        }
    }

    #[tokio::test(start_paused = true)]
    async fn a_late_frame_resets_the_silence_clock() {
        let mut ping = tokio::time::interval(PING_EVERY);
        let mut hb = Heartbeat::new(Instant::now());
        ping.tick().await; // 0s
        ping.tick().await; // 25s
        hb.heard(Instant::now());
        ping.tick().await; // 50s: 25s of silence
        assert_eq!(hb.on_tick(Instant::now()), Beat::Ping);
        ping.tick().await; // 75s: 50s of silence
        assert_eq!(hb.on_tick(Instant::now()), Beat::Ping);
        ping.tick().await; // 100s: 75s of silence
        assert_eq!(hb.on_tick(Instant::now()), Beat::Reap);
    }
}
