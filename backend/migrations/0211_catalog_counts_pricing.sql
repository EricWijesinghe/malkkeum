-- Catalogue update for databases seeded before counts pricing (CR Appendix A). The seed only inserts
-- missing rows, so these UPDATEs carry the new placeholder prices over. Each one applies only while the
-- row still holds the old seeded pricing (and sort order), so owner edits made in the console are kept.
-- The seed inserts whole_home, window and disinfection on start (this migration runs before it).

UPDATE services SET pricing = '{"type":"counts","units":[{"label_key":"mattress","minutes":60,"price":59000}],"multi_discount_bps":1500}'::jsonb
 WHERE code = 'mattress' AND pricing = '{"type":"unit","units":[{"label_key":"count_1","minutes":60,"price":59000},{"label_key":"count_2","minutes":90,"price":99000},{"label_key":"count_3","minutes":120,"price":139000},{"label_key":"count_4","minutes":150,"price":175000}]}'::jsonb;

UPDATE services SET pricing = '{"type":"counts","units":[{"label_key":"wall","minutes":90,"price":79000},{"label_key":"stand","minutes":120,"price":119000},{"label_key":"two_in_one","minutes":180,"price":179000},{"label_key":"ceiling","minutes":120,"price":139000}],"multi_discount_bps":1000}'::jsonb
 WHERE code = 'aircon' AND pricing = '{"type":"unit","units":[{"label_key":"wall","minutes":90,"price":79000},{"label_key":"stand","minutes":120,"price":119000},{"label_key":"two_in_one","minutes":180,"price":179000},{"label_key":"ceiling","minutes":120,"price":139000}]}'::jsonb;

UPDATE services SET pricing = '{"type":"counts","units":[{"label_key":"seat_1_2","minutes":60,"price":59000},{"label_key":"seat_3","minutes":90,"price":79000},{"label_key":"seat_4_plus","minutes":120,"price":99000},{"label_key":"l_shape","minutes":150,"price":119000}],"multi_discount_bps":1000}'::jsonb
 WHERE code = 'sofa' AND pricing = '{"type":"unit","units":[{"label_key":"seat_1_2","minutes":60,"price":59000},{"label_key":"seat_3","minutes":90,"price":79000},{"label_key":"seat_4_plus","minutes":120,"price":99000},{"label_key":"l_shape","minutes":150,"price":119000}]}'::jsonb;

-- Catalogue order by home group. Only rows still at the old seeded position move.
UPDATE services s SET sort_order = o.new_n FROM (VALUES ('mattress', 5, 7), ('aircon', 6, 8), ('sofa', 7, 9)) AS o(code, old_n, new_n)
 WHERE s.code = o.code AND s.sort_order = o.old_n;
