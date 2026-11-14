-- When the staff member last proved a TOTP code for a sensitive action (customer export, deletion, payouts).
-- Those actions need it within five minutes; sign-in alone does not count.
ALTER TABLE staff ADD COLUMN stepup_at timestamptz;
