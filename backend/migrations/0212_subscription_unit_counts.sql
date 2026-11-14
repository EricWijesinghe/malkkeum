-- Counts pricing for subscriptions: legacy rows keep unit_index; migrated mattress rows carry their count here.
ALTER TABLE subscriptions ADD COLUMN unit_counts SMALLINT[];
