-- PIPA consent evidence: append-only log, the newest row per (user, kind) is the current state.
CREATE TABLE user_consents (
    id          BIGSERIAL PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind        TEXT NOT NULL CHECK (kind IN ('terms','privacy','overseas_transfer','marketing')),
    version     TEXT NOT NULL,
    granted     BOOLEAN NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX user_consents_latest_idx ON user_consents (user_id, kind, created_at DESC);
