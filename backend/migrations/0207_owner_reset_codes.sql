-- One-time owner reset codes, issued on the server by `api owner-reset` and valid for one hour. Only the hash is kept.
CREATE TABLE owner_reset_codes (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id   UUID NOT NULL REFERENCES staff (id),
    code_hash  TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX owner_reset_codes_staff_idx ON owner_reset_codes (staff_id);
