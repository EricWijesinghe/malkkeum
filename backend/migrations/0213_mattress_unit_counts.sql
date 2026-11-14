-- Mattress legacy data. The old unit_index n meant n+1 mattresses (count_1..count_4). The single
-- mattress option now prices a count, so each open or past row keeps its quantity as unit_counts = {n+1}.
-- Rows already holding unit_counts are left alone.
UPDATE bookings SET unit_counts = ARRAY[(unit_index + 1)::smallint], unit_index = 0
 WHERE service_code = 'mattress' AND unit_index IS NOT NULL AND unit_counts IS NULL;

UPDATE subscriptions SET unit_counts = ARRAY[(unit_index + 1)::smallint], unit_index = 0
 WHERE service_code = 'mattress' AND unit_index IS NOT NULL AND unit_counts IS NULL;
