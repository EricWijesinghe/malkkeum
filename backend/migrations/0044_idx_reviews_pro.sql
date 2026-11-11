-- no-transaction
-- Pro rating and review list: visible reviews by pro (also FK support for reviews.pro_id).
-- One CREATE INDEX CONCURRENTLY per file (see 0041). Failed run: DROP INDEX CONCURRENTLY IF EXISTS, restart.
CREATE INDEX CONCURRENTLY IF NOT EXISTS reviews_pro_idx ON reviews (pro_id, created_at DESC) WHERE NOT hidden;
