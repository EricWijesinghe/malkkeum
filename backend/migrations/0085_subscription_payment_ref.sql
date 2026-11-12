-- The PortOne payment id sent for the visit's current charge try. Saved before the call, cleared on booking or confirmed decline.
ALTER TABLE subscription_visits ADD COLUMN payment_ref TEXT;
