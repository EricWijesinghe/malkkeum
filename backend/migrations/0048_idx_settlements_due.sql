-- no-transaction
-- Payout run: pending settlements due by date that are not yet in a payout.
-- One CREATE INDEX CONCURRENTLY per file (see 0041). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS settlements_due_idx ON settlements (payout_date, pro_id) WHERE state = 'pending' AND payout_id IS NULL;
