-- Counts pricing: one count per option of a counts service (catalogue order). NULL for other bookings.
ALTER TABLE bookings ADD COLUMN unit_counts SMALLINT[];
