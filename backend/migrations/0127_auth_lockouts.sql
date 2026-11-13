-- Login and OTP lockout counters kept in Postgres so a restart or a second replica does not reset them (lockout.rs).
-- expires_at: the row is dead after it, the failure count starts over, and a periodic delete drops it.
CREATE TABLE auth_lockouts (
    key          TEXT PRIMARY KEY,
    fails        INT NOT NULL,
    locked_until TIMESTAMPTZ NOT NULL,
    expires_at   TIMESTAMPTZ NOT NULL
);
CREATE INDEX auth_lockouts_expires_idx ON auth_lockouts (expires_at);
