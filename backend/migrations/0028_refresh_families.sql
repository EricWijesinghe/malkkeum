-- Refresh rotation families: a rotated token presented again revokes its whole family (reuse detection).
ALTER TABLE refresh_tokens ADD COLUMN family_id UUID;
UPDATE refresh_tokens SET family_id = gen_random_uuid() WHERE family_id IS NULL;
ALTER TABLE refresh_tokens ALTER COLUMN family_id SET NOT NULL;
-- Set only when rotation consumes the token, so logout (revoked, not rotated) is not treated as theft.
ALTER TABLE refresh_tokens ADD COLUMN rotated_at TIMESTAMPTZ;
CREATE INDEX refresh_tokens_family_idx ON refresh_tokens (family_id);
CREATE INDEX refresh_tokens_subject_idx ON refresh_tokens (subject);
