-- Owner-edited push and inbox text per notification kind and language. A missing row means the built-in text.
CREATE TABLE notify_templates (
    kind       TEXT NOT NULL,
    locale     TEXT NOT NULL CHECK (locale IN ('ko', 'en')),
    title      TEXT NOT NULL CHECK (char_length(title) BETWEEN 1 AND 40),
    body       TEXT NOT NULL CHECK (char_length(body) BETWEEN 1 AND 120),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (kind, locale)
);
