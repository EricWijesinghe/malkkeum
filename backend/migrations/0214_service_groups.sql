-- Home categories (CR-8.1). The owner manages the four groups, their order and chooser config in the console.
-- services.group_code links a service to its group. Fresh databases have no services yet, so the seed
-- files new rows by group (domain::service_group::default_group_of); the UPDATE below only reaches rows that exist.
CREATE TABLE service_groups (
    code       TEXT PRIMARY KEY CHECK (code ~ '^[a-z][a-z_]{1,39}$'),
    title      JSONB NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
    active     BOOLEAN NOT NULL DEFAULT TRUE,
    chooser    TEXT NOT NULL CHECK (chooser IN ('move', 'list', 'direct')),
    icon       TEXT NOT NULL,
    config     JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO service_groups (code, title, sort_order, chooser, icon, config) VALUES
    ('moving', '{"ko": "이사·입주 청소", "en": "Move-in / move-out cleaning"}', 0, 'move', 'svc_move',
     '{"build_age": {"new": "move_in", "old": "move_out"}, "home_types": ["one_two_room", "apartment", "villa_house"]}'),
    ('living', '{"ko": "거주 청소", "en": "Living-space cleaning"}', 1, 'list', 'svc_bathroom', '{}'),
    ('appliance', '{"ko": "가전·가구 청소", "en": "Appliance and furniture cleaning"}', 2, 'list', 'svc_aircon', '{}'),
    ('disinfection', '{"ko": "방역·소독", "en": "Pest control and disinfection"}', 3, 'direct', 'svc_disinfection', '{}')
ON CONFLICT (code) DO NOTHING;

ALTER TABLE services ADD COLUMN group_code TEXT REFERENCES service_groups (code);

UPDATE services SET group_code = v.grp
FROM (VALUES
    ('move_in', 'moving'), ('move_out', 'moving'), ('studio', 'moving'),
    ('bathroom', 'living'), ('kitchen', 'living'), ('whole_home', 'living'), ('window', 'living'),
    ('aircon', 'appliance'), ('mattress', 'appliance'), ('sofa', 'appliance'),
    ('disinfection', 'disinfection')
) AS v (code, grp)
WHERE services.code = v.code;

-- Studio stays in its group and in admin, but the public home list leaves it out (content.hidden_from_home).
UPDATE services SET content = content || '{"hidden_from_home": true}'::jsonb WHERE code = 'studio';

CREATE INDEX services_group_code_idx ON services (group_code);
