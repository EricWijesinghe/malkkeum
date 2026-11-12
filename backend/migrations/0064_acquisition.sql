-- First-touch acquisition (UTM / referral) captured at customer signup. Written on insert only; never overwritten.
ALTER TABLE users ADD COLUMN acquisition JSONB;
