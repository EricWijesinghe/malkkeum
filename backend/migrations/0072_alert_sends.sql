-- Once-only transactional alerts that no request triggers (the day-before reminder). The key is claimed before sending.
CREATE TABLE alert_sends (
    dedupe_key TEXT PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
