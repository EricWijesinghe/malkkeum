-- Booking request snapshot taken when the customer joins a full slot. Accepting an offer replays it
-- through the normal booking create path, so prices and address are recomputed at accept time.
ALTER TABLE waitlist_entries ADD COLUMN body JSONB NOT NULL DEFAULT '{}'::jsonb;
