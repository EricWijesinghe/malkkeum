-- no-transaction
-- Team member assignment lookups and FK support for bookings.assignee_id.
-- One CREATE INDEX CONCURRENTLY per file (see 0020). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS bookings_assignee_idx ON bookings (assignee_id) WHERE assignee_id IS NOT NULL;
