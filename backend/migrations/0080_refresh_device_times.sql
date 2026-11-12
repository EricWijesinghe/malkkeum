-- Signed-in devices: each refresh row is stamped when it is issued, so a family's first and latest rows give
-- "signed in at" and "last refreshed at". Existing rows get the migration time (their true time is unknown).
ALTER TABLE refresh_tokens ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT now();
CREATE INDEX refresh_tokens_live_subject_idx ON refresh_tokens (subject) WHERE revoked_at IS NULL AND rotated_at IS NULL;
