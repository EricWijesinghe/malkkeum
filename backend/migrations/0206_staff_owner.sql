-- Staff owner (소유자). At most one row may hold the flag. The migration leaves it unset for every existing
-- staff member: the setup wizard marks its first admin, and an admin may claim it only while no owner exists.
ALTER TABLE staff ADD COLUMN is_owner BOOLEAN NOT NULL DEFAULT FALSE;
CREATE UNIQUE INDEX staff_single_owner ON staff (is_owner) WHERE is_owner;
-- Bumped to end every session of one staff member. Access tokens carry the epoch they were issued in.
ALTER TABLE staff ADD COLUMN session_epoch INT NOT NULL DEFAULT 0;
-- Number for owner alerts by SMS. Changed only with the owner's second factor; the old number is told.
ALTER TABLE staff ADD COLUMN alert_phone TEXT;
-- Set when the owner confirms the recovery codes were saved. Owner-only requests need it.
ALTER TABLE staff ADD COLUMN recovery_confirmed_at TIMESTAMPTZ;
