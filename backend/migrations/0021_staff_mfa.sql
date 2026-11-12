-- Staff TOTP 2FA. The secret is encrypted at rest (crypto::encrypt); totp_last_step blocks code replay.
ALTER TABLE staff ADD COLUMN totp_secret TEXT;
ALTER TABLE staff ADD COLUMN totp_enabled_at TIMESTAMPTZ;
ALTER TABLE staff ADD COLUMN totp_last_step BIGINT;

-- One-time recovery codes, stored as SHA-256 hashes only.
CREATE TABLE staff_recovery_codes (
    id        BIGSERIAL PRIMARY KEY,
    staff_id  UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
    code_hash TEXT NOT NULL,
    used_at   TIMESTAMPTZ
);
CREATE INDEX staff_recovery_codes_staff_idx ON staff_recovery_codes (staff_id);
