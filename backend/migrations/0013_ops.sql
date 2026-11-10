-- Operations: last success/failure per external integration, failure log for alert windows,
-- hourly 5xx counter, and alert cooldown stamps. Only error codes are stored, never messages.
CREATE TABLE ops_health (
    integration   text PRIMARY KEY,
    last_ok_at    timestamptz,
    last_fail_at  timestamptz,
    last_error    text
);

CREATE TABLE ops_failures (
    id            bigserial PRIMARY KEY,
    integration   text NOT NULL,
    code          text NOT NULL,
    at            timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ops_failures_idx ON ops_failures (integration, at DESC);

CREATE TABLE ops_http_errors (
    hour          timestamptz PRIMARY KEY,
    count         bigint NOT NULL DEFAULT 0
);

CREATE TABLE ops_alerts (
    alert_key     text PRIMARY KEY,
    last_sent_at  timestamptz NOT NULL
);
