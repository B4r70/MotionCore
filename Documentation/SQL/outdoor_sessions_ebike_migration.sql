-- ---------------------------------------------------------------------------------
-- E-Bike Outdoor Feature (Phase 1) — Schema-Erweiterung outdoor_sessions
-- ---------------------------------------------------------------------------------
-- Datum       : 2026-03-30
-- Beschreibung: Neue Spalten fuer GPS-Koordinaten, strukturierte Adressfelder
--               und Gesundheitsdaten (Herzfrequenz, Koerpergewicht).
-- Ausfuehren  : Vor dem ersten App-Release mit E-Bike-Feature ausfuehren.
-- ---------------------------------------------------------------------------------

-- GPS-Koordinaten (nullable – automatische Befuellung erst ab Phase 3)
ALTER TABLE public.outdoor_sessions ADD COLUMN IF NOT EXISTS start_latitude double precision;
ALTER TABLE public.outdoor_sessions ADD COLUMN IF NOT EXISTS start_longitude double precision;
ALTER TABLE public.outdoor_sessions ADD COLUMN IF NOT EXISTS end_latitude double precision;
ALTER TABLE public.outdoor_sessions ADD COLUMN IF NOT EXISTS end_longitude double precision;

-- Strukturierte Adressfelder (leer = kein Adress-Lookup erfolgt)
ALTER TABLE public.outdoor_sessions ADD COLUMN IF NOT EXISTS start_street text DEFAULT '';
ALTER TABLE public.outdoor_sessions ADD COLUMN IF NOT EXISTS start_postal_code text DEFAULT '';
ALTER TABLE public.outdoor_sessions ADD COLUMN IF NOT EXISTS start_city text DEFAULT '';
ALTER TABLE public.outdoor_sessions ADD COLUMN IF NOT EXISTS end_street text DEFAULT '';
ALTER TABLE public.outdoor_sessions ADD COLUMN IF NOT EXISTS end_postal_code text DEFAULT '';
ALTER TABLE public.outdoor_sessions ADD COLUMN IF NOT EXISTS end_city text DEFAULT '';

-- Gesundheitsdaten (waren im alten DTO nicht enthalten, sind im SwiftData-Model vorhanden)
-- HINWEIS: Diese Spalten sind neu – im alten SupabaseOutdoorSessionDTO fehlten sie.
--          heart_rate / max_heart_rate / body_weight waren bisher nur in
--          strength_sessions und cardio_sessions vorhanden.
ALTER TABLE public.outdoor_sessions ADD COLUMN IF NOT EXISTS heart_rate integer DEFAULT 0;
ALTER TABLE public.outdoor_sessions ADD COLUMN IF NOT EXISTS max_heart_rate integer DEFAULT 0;
ALTER TABLE public.outdoor_sessions ADD COLUMN IF NOT EXISTS body_weight double precision DEFAULT 0;
