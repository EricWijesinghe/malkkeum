-- Text messages (SMS and AlimTalk) go through the outbox too. A push row has an owner and channel 'push'.
-- A text row has a phone and channel 'sms' or 'alimtalk'; its owner is set when the phone belongs to a
-- customer, so account deletion still clears it. dead_at marks a text that used up its attempts.
ALTER TABLE notification_outbox
    ALTER COLUMN owner_role DROP NOT NULL,
    ALTER COLUMN owner_id DROP NOT NULL,
    ADD COLUMN channel TEXT NOT NULL DEFAULT 'push' CHECK (channel IN ('push', 'sms', 'alimtalk')),
    ADD COLUMN phone TEXT,
    ADD COLUMN dead_at TIMESTAMPTZ,
    ADD CONSTRAINT notification_outbox_target CHECK (
        (channel = 'push' AND owner_role IS NOT NULL AND owner_id IS NOT NULL)
        OR (channel <> 'push' AND phone IS NOT NULL)
    );
CREATE INDEX notification_outbox_text_due_idx ON notification_outbox (next_attempt_at)
    WHERE channel <> 'push' AND dead_at IS NULL;
CREATE INDEX notification_outbox_dead_idx ON notification_outbox (dead_at) WHERE dead_at IS NOT NULL;
