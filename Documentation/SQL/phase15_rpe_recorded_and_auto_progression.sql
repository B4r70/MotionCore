-- Phase 1.5 — Smart Progression Refinements
-- rpe_recorded + Auto-Progression-Felder

ALTER TABLE public.exercise_sets
    ADD COLUMN IF NOT EXISTS rpe_recorded BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE public.exercise_progression_states
    ADD COLUMN IF NOT EXISTS last_auto_progression_date  TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS last_auto_progression_amount DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS auto_progression_undoable   BOOLEAN NOT NULL DEFAULT FALSE;
