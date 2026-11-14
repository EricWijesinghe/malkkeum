-- Staff phone numbers (for SMS invites and password resets) and one-time SMS codes. A code works once, lives
-- 24 hours, is burned after too many wrong guesses, and is stored only as a peppered hash.
ALTER TABLE staff ADD COLUMN phone TEXT;
CREATE UNIQUE INDEX staff_phone_unique ON staff (phone) WHERE phone IS NOT NULL;

CREATE TABLE staff_sms_codes (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id   UUID NOT NULL REFERENCES staff (id) ON DELETE CASCADE,
    purpose    TEXT NOT NULL CHECK (purpose IN ('invite', 'reset')),
    code_hash  TEXT NOT NULL,
    attempts   INT NOT NULL DEFAULT 0,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX staff_sms_codes_staff_idx ON staff_sms_codes (staff_id, created_at DESC);
