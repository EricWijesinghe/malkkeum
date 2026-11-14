-- One no-show case per booking, enforced by the database. Two scans that raced before the advisory lock
-- could each open one. The later duplicate is removed only when nobody has touched it (still open, no
-- assignee, no photos, no outcome). A touched duplicate makes the index fail, so the migration stops for review.
DELETE FROM cases d
USING cases k
WHERE d.kind = 'no_show' AND k.kind = 'no_show'
  AND d.booking_id = k.booking_id
  AND (k.created_at, k.id) < (d.created_at, d.id)
  AND d.status = 'open' AND d.assignee_id IS NULL AND d.outcome IS NULL AND d.photos = '[]'::jsonb;

CREATE UNIQUE INDEX cases_one_no_show_idx ON cases (booking_id) WHERE kind = 'no_show';
