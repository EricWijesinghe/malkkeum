-- Fixed-window request counters for the auth and upload buckets (ratelimit.rs), shared by every replica and
-- kept across restarts. UNLOGGED: a crash may drop the counters, which only relaxes the limit for one window.
CREATE UNLOGGED TABLE rate_limits (
    key          TEXT PRIMARY KEY,
    window_start TIMESTAMPTZ NOT NULL,
    hits         INT NOT NULL
);
CREATE INDEX rate_limits_window_idx ON rate_limits (window_start);
