-- Home-screen service groups (서비스 묶음): the four tiles, their titles, order, icon and move-chooser config.
-- The owner edits these in the console; the customer app reads them from GET /v1/service-groups.
-- Member services are listed in `services` (order matters) and each service's services.group_code points back here.
CREATE TABLE service_groups (
    code       TEXT PRIMARY KEY CHECK (code IN ('moving', 'living', 'appliance', 'disinfection')),
    title_ko   TEXT NOT NULL CHECK (char_length(title_ko) BETWEEN 1 AND 40),
    title_en   TEXT NOT NULL CHECK (char_length(title_en) BETWEEN 1 AND 40),
    sort_order INTEGER NOT NULL DEFAULT 0,
    active     BOOLEAN NOT NULL DEFAULT TRUE,
    icon       TEXT NOT NULL CHECK (char_length(icon) BETWEEN 1 AND 40),
    chooser    TEXT NOT NULL CHECK (chooser IN ('move', 'list', 'direct')),
    services   TEXT[] NOT NULL DEFAULT '{}',
    config     JSONB NOT NULL DEFAULT '{}',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO service_groups (code, title_ko, title_en, sort_order, icon, chooser, services, config) VALUES
    ('moving', '이사·입주 청소', 'Move-in and move-out cleaning', 0, 'svc_move', 'move',
        ARRAY['move_in', 'move_out'],
        '{"build_age": {"new": "move_in", "old": "move_out"}, "home_types": ["one_two_room", "apartment", "villa_house"]}'),
    ('living', '거주 청소', 'Home cleaning', 1, 'svc_bathroom', 'list',
        ARRAY['bathroom', 'kitchen', 'whole_home', 'window'], '{}'),
    ('appliance', '가전·가구 청소', 'Appliance and furniture cleaning', 2, 'svc_aircon', 'list',
        ARRAY['aircon', 'mattress', 'sofa'], '{}'),
    ('disinfection', '방역·소독', 'Pest control and disinfection', 3, 'svc_disinfection', 'list',
        ARRAY['disinfection'], '{}');
