-- =============================================================================
-- MotionCore — exercise_ratings Tabelle
-- =============================================================================
-- Erstellt am : 2026-04-05
-- Beschreibung: Subjektive Qualitätsbewertungen pro Übung nach Abschluss
--               Verknüpft mit strength_sessions via session_id (Foreign Key)
-- =============================================================================

-- Tabelle anlegen
CREATE TABLE IF NOT EXISTS exercise_ratings (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id              UUID NOT NULL REFERENCES strength_sessions(id) ON DELETE CASCADE,
    exercise_group_key      TEXT NOT NULL,
    exercise_name_snapshot  TEXT NOT NULL DEFAULT '',
    rating                  TEXT NOT NULL DEFAULT 'neutral',
    rated_at                TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Timestamps
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indizes für Performance
CREATE INDEX IF NOT EXISTS idx_exercise_ratings_session_id
    ON exercise_ratings (session_id);

CREATE INDEX IF NOT EXISTS idx_exercise_ratings_group_key
    ON exercise_ratings (exercise_group_key);

CREATE INDEX IF NOT EXISTS idx_exercise_ratings_rated_at
    ON exercise_ratings (rated_at DESC);

-- Composite-Index für Insight-Abfragen (nach Übung chronologisch)
CREATE INDEX IF NOT EXISTS idx_exercise_ratings_group_key_rated_at
    ON exercise_ratings (exercise_group_key, rated_at DESC);

-- Updated-at Trigger (analog zu bestehenden Tabellen)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER exercise_ratings_updated_at
    BEFORE UPDATE ON exercise_ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Constraint: Rating muss einer der drei gültigen Werte sein
ALTER TABLE exercise_ratings
    ADD CONSTRAINT exercise_ratings_rating_check
    CHECK (rating IN ('poor', 'neutral', 'good'));
