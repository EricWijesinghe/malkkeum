-- Renewal calendar (갱신 일정): domains, old-domain aliases, hosting, store and SMS accounts, storage.
-- The yearly keys test is not a row; it is derived from key_bundle_checks.verified_at.
CREATE TABLE renewals (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kind       TEXT NOT NULL CHECK (kind IN ('domain', 'domain_alias', 'hosting', 'apple', 'solapi', 'storage', 'other')),
    name       TEXT NOT NULL CHECK (char_length(name) BETWEEN 1 AND 80),
    due_on     DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One row per reminder sent: the item (a renewal id, or 'keys_test'), its due date and the threshold in days.
-- Keyed by due date, so moving a due date re-arms its reminders without any reset.
CREATE TABLE renewal_reminders (
    item     TEXT NOT NULL,
    due_on   DATE NOT NULL,
    days     SMALLINT NOT NULL CHECK (days IN (7, 30)),
    sent_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (item, due_on, days)
);
