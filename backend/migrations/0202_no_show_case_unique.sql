-- One no-show case per booking, enforced by the database. Two scans that raced before the advisory lock
-- could each open one. The later duplicate is removed when nobody has touched it (still open, no
-- assignee, no photos, no outcome). A touched duplicate keeps its record and is re-filed as a complaint,
-- so the index always builds: the owner has no terminal to repair a failed migration.
DELETE FROM cases d
USING cases k
WHERE d.kind = 'no_show' AND k.kind = 'no_show'
  AND d.booking_id = k.booking_id
  AND (k.created_at, k.id) < (d.created_at, d.id)
  AND d.status = 'open' AND d.assignee_id IS NULL AND d.outcome IS NULL AND d.photos = '[]'::jsonb;

UPDATE cases d
SET kind = 'complaint', summary = left('[중복 노쇼 접수] ' || d.summary, 2000)
FROM cases k
WHERE d.kind = 'no_show' AND k.kind = 'no_show'
  AND d.booking_id = k.booking_id
  AND (k.created_at, k.id) < (d.created_at, d.id);

CREATE UNIQUE INDEX cases_one_no_show_idx ON cases (booking_id) WHERE kind = 'no_show';
