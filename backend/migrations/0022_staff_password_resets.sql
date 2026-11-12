-- Owner-issued staff password reset tokens. Only the SHA-256 is stored; a token works once and expires.
CREATE TABLE staff_password_resets (
    token_hash TEXT PRIMARY KEY,
    staff_id   UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX staff_password_resets_staff_idx ON staff_password_resets (staff_id);
