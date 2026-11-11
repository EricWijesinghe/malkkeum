-- Household profile saved per address and copied into each booking (customer may edit per booking).
ALTER TABLE addresses ADD COLUMN household JSONB NOT NULL DEFAULT '{}';
ALTER TABLE bookings ADD COLUMN household JSONB NOT NULL DEFAULT '{}';
