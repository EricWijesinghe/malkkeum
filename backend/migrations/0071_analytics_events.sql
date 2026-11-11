-- First-party product events from the apps, only after the user consents in the app.
-- Anonymous by design: a random per-install id, no user id, no free text. Purged after 90 days (retention.rs).
CREATE TABLE analytics_events (
    id         BIGSERIAL PRIMARY KEY,
    anon_id    UUID NOT NULL,
    name       TEXT NOT NULL CHECK (name IN ('app_open', 'signup_start', 'signup_done', 'quote_view', 'booking_start', 'booking_done', 'payment_done', 'review_done')),
    screen     TEXT CHECK (screen ~ '^[a-z_]{1,40}$'),
    platform   TEXT CHECK (platform IN ('android', 'ios', 'web')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX analytics_events_created_idx ON analytics_events (created_at);
CREATE INDEX analytics_events_name_idx ON analytics_events (name, created_at);
