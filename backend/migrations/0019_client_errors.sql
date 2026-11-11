-- Client-side error reports from web, Windows and console (mobile crashes go to Crashlytics).
-- Text is capped and PII-scrubbed on write; rows older than 14 days are purged by retention.
CREATE TABLE client_errors (
    id          bigserial PRIMARY KEY,
    at          timestamptz NOT NULL DEFAULT now(),
    app         text NOT NULL,
    version     text NOT NULL,
    message     text NOT NULL,
    stack       text NOT NULL DEFAULT ''
);
CREATE INDEX client_errors_at_idx ON client_errors (at DESC);
