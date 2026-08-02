-- ---------------------------------------------------------------------------------
-- MotionCore — Pace-Erfassung für zeitbasierte Übungen
-- Datum: 2026-08-02
--
-- Neue Spalten auf exercise_sets:
--   pace_tracking_enabled : Config-Flag (Pace-Sheet nach Übungsabschluss)
--   pace_unit             : "minPer500m" | "minPerKm" | "kmh"
--   pace_value            : Sekunden pro Einheit (min/500m, min/km) bzw. km/h; 0 = nicht erfasst
--
-- WICHTIG: Vor dem ersten App-Start mit diesem Feature ausführen — der
-- Session-Upload (Upsert) sendet die Felder immer mit.
-- Projekt-Regel: Tabellen bleiben UNRESTRICTED — kein ENABLE ROW LEVEL SECURITY.
-- ---------------------------------------------------------------------------------

ALTER TABLE exercise_sets
    ADD COLUMN IF NOT EXISTS pace_tracking_enabled boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS pace_unit text NOT NULL DEFAULT 'minPer500m',
    ADD COLUMN IF NOT EXISTS pace_value double precision NOT NULL DEFAULT 0;
