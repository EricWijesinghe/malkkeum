-- Staff login lockout and query support found in review.
ALTER TABLE staff ADD COLUMN failed_logins INT NOT NULL DEFAULT 0;
ALTER TABLE staff ADD COLUMN locked_until TIMESTAMPTZ;

CREATE INDEX quotes_pro_idx ON quotes (pro_id, state);
CREATE INDEX otp_codes_created_idx ON otp_codes (created_at);
