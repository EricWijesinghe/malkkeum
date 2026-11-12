-- Signed-in devices: each refresh row is stamped when it is issued, so a family's first and latest rows give
-- "signed in at" and "last refreshed at". Existing rows get the migration time (their true time is unknown).
ALTER TABLE refresh_tokens ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT now();
-- refresh_tokens_live_subject_idx is built concurrently in 0099 (refresh_tokens is a big table).
