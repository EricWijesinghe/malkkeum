-- Partner quality score snapshots, owner thresholds, and onboarding training (modules, progress).
-- Scores are recomputed by a job from bookings, check-ins, ratings and cases; this table keeps the latest.
CREATE TABLE quality_settings (
    id              SMALLINT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    warning_below   SMALLINT NOT NULL DEFAULT 75 CHECK (warning_below BETWEEN 0 AND 100),
    pause_below     SMALLINT NOT NULL DEFAULT 60 CHECK (pause_below BETWEEN 0 AND 100),
    CHECK (pause_below <= warning_below)
);
INSERT INTO quality_settings (id) VALUES (1);

CREATE TABLE partner_quality (
    pro_id          UUID PRIMARY KEY REFERENCES pros(id) ON DELETE CASCADE,
    score           SMALLINT NOT NULL CHECK (score BETWEEN 0 AND 100),
    status          TEXT NOT NULL CHECK (status IN ('ok','warning','paused','overridden_by_owner')),
    lift_pause      BOOLEAN NOT NULL DEFAULT FALSE,
    inputs          JSONB NOT NULL,
    computed_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE training_modules (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           JSONB NOT NULL,
    body            JSONB NOT NULL,
    checklist       JSONB NOT NULL,
    quiz            JSONB NOT NULL,
    required        BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order      INT NOT NULL DEFAULT 0,
    published       BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE training_progress (
    pro_id          UUID NOT NULL REFERENCES pros(id) ON DELETE CASCADE,
    module_id       UUID NOT NULL REFERENCES training_modules(id) ON DELETE CASCADE,
    checklist_ticked JSONB NOT NULL DEFAULT '[]',
    quiz_passed     BOOLEAN NOT NULL DEFAULT FALSE,
    quiz_best_percent SMALLINT NOT NULL DEFAULT 0,
    completed_at    TIMESTAMPTZ,
    PRIMARY KEY (pro_id, module_id)
);
