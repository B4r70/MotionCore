-- =============================================================================
-- MotionCore Smart Progression Phase 1 — Supabase-Schema
-- =============================================================================
-- Datum: 2026-04-18
-- Scope: 5 neue Tabellen + 3 ALTER TABLEs + 5 Indizes + 5 Trigger
-- Kein RLS (UNRESTRICTED gemaess MotionCore-Policy)
-- Schema:
--   public.*    — App-Daten (strength_sessions, exercise_sets, studios, ...)
--   motioncore.* — Read-Only-Referenzdaten (nur exercises wird ALTERt)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. NEUE TABELLEN (public)
-- -----------------------------------------------------------------------------

-- studios
CREATE TABLE IF NOT EXISTS public.studios (
    id          UUID PRIMARY KEY,
    name        TEXT NOT NULL DEFAULT '',
    is_primary  BOOLEAN NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- studio_equipment
CREATE TABLE IF NOT EXISTS public.studio_equipment (
    id                       UUID PRIMARY KEY,
    studio_id                UUID REFERENCES public.studios(id) ON DELETE CASCADE,
    name                     TEXT NOT NULL DEFAULT '',
    equipment_type           TEXT NOT NULL DEFAULT 'machine',
    start_weight             DOUBLE PRECISION NOT NULL DEFAULT 0,
    increment                DOUBLE PRECISION NOT NULL DEFAULT 2.5,
    min_weight               DOUBLE PRECISION NOT NULL DEFAULT 0,
    max_weight               DOUBLE PRECISION,
    intermediate_increments  DOUBLE PRECISION[] NOT NULL DEFAULT '{}',
    notes                    TEXT NOT NULL DEFAULT '',
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_studio_equipment_studio_id ON public.studio_equipment(studio_id);

-- exercise_progression_states
CREATE TABLE IF NOT EXISTS public.exercise_progression_states (
    id                        UUID PRIMARY KEY,
    exercise_group_key        TEXT NOT NULL DEFAULT '',
    working_weight            DOUBLE PRECISION NOT NULL DEFAULT 0,
    previous_working_weight   DOUBLE PRECISION,
    target_reps               INTEGER NOT NULL DEFAULT 10,
    min_target_reps           INTEGER NOT NULL DEFAULT 8,
    max_target_reps           INTEGER NOT NULL DEFAULT 12,
    progression_mode          TEXT NOT NULL DEFAULT 'smart',
    last_progression_date     TIMESTAMPTZ,
    last_rollback_date        TIMESTAMPTZ,
    consecutive_success_count INTEGER NOT NULL DEFAULT 0,
    consecutive_fail_count    INTEGER NOT NULL DEFAULT 0,
    is_active                 BOOLEAN NOT NULL DEFAULT true,
    created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_progression_states_group_key ON public.exercise_progression_states(exercise_group_key);

-- session_readiness
CREATE TABLE IF NOT EXISTS public.session_readiness (
    id                   UUID PRIMARY KEY,
    session_uuid         TEXT,
    captured_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    hrv_score            DOUBLE PRECISION,
    sleep_score          DOUBLE PRECISION,
    resting_hr_score     DOUBLE PRECISION,
    activity_score       DOUBLE PRECISION,
    user_energy_level    INTEGER,
    user_stress_level    TEXT,
    overall_score        INTEGER NOT NULL DEFAULT 50,
    is_calibrating       BOOLEAN NOT NULL DEFAULT false,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_session_readiness_session_uuid ON public.session_readiness(session_uuid);

-- health_baselines
CREATE TABLE IF NOT EXISTS public.health_baselines (
    id              UUID PRIMARY KEY,
    metric_type     TEXT NOT NULL DEFAULT '',
    rolling_mean    DOUBLE PRECISION NOT NULL DEFAULT 0,
    rolling_std_dev DOUBLE PRECISION NOT NULL DEFAULT 0,
    sample_count    INTEGER NOT NULL DEFAULT 0,
    last_updated    TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_health_baselines_metric_type ON public.health_baselines(metric_type);

-- -----------------------------------------------------------------------------
-- 2. ALTER BESTEHENDE TABELLEN
-- -----------------------------------------------------------------------------

-- motioncore.exercises: 4 neue Spalten (Legacy-Spalten bleiben als historische Daten)
ALTER TABLE motioncore.exercises ADD COLUMN IF NOT EXISTS studio_equipment_id UUID;
ALTER TABLE motioncore.exercises ADD COLUMN IF NOT EXISTS custom_target_reps INTEGER;
ALTER TABLE motioncore.exercises ADD COLUMN IF NOT EXISTS progression_mode_raw TEXT DEFAULT 'smart';
ALTER TABLE motioncore.exercises ADD COLUMN IF NOT EXISTS config_notes TEXT DEFAULT '';

-- public.exercise_sets
ALTER TABLE public.exercise_sets ADD COLUMN IF NOT EXISTS is_last_set_of_exercise BOOLEAN DEFAULT false;

-- public.strength_sessions
ALTER TABLE public.strength_sessions ADD COLUMN IF NOT EXISTS session_quality_score INTEGER;
ALTER TABLE public.strength_sessions ADD COLUMN IF NOT EXISTS session_readiness_id UUID;

-- -----------------------------------------------------------------------------
-- 3. TRIGGER updated_at (Funktion update_updated_at_column existiert bereits
--    aus exercise_ratings_migration.sql)
-- -----------------------------------------------------------------------------

DROP TRIGGER IF EXISTS studios_updated_at ON public.studios;
CREATE TRIGGER studios_updated_at BEFORE UPDATE ON public.studios
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS studio_equipment_updated_at ON public.studio_equipment;
CREATE TRIGGER studio_equipment_updated_at BEFORE UPDATE ON public.studio_equipment
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS exercise_progression_states_updated_at ON public.exercise_progression_states;
CREATE TRIGGER exercise_progression_states_updated_at BEFORE UPDATE ON public.exercise_progression_states
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS session_readiness_updated_at ON public.session_readiness;
CREATE TRIGGER session_readiness_updated_at BEFORE UPDATE ON public.session_readiness
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS health_baselines_updated_at ON public.health_baselines;
CREATE TRIGGER health_baselines_updated_at BEFORE UPDATE ON public.health_baselines
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- =============================================================================
-- Ende Migration
-- =============================================================================
