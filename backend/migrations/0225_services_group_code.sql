-- Each service belongs to at most one home group. NULL means no tile (studio stays in the catalogue but hidden from home).
ALTER TABLE services ADD COLUMN group_code TEXT REFERENCES service_groups(code) ON UPDATE CASCADE;

UPDATE services SET group_code = CASE
    WHEN code IN ('move_in', 'move_out') THEN 'moving'
    WHEN code IN ('bathroom', 'kitchen', 'whole_home', 'window') THEN 'living'
    WHEN code IN ('aircon', 'mattress', 'sofa') THEN 'appliance'
    WHEN code = 'disinfection' THEN 'disinfection'
    ELSE NULL
END;

CREATE INDEX services_group_code_idx ON services (group_code);
