-- PASS verification ids issued to a customer before the hosted page opens. Single use, bound to the user.
CREATE TABLE identity_sessions (
    id          TEXT PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    used_at     TIMESTAMPTZ
);
CREATE INDEX identity_sessions_user_idx ON identity_sessions (user_id);
