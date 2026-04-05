# Quality Gate — Exercise Rating Feature

**Datum:** 2026-04-05
**Status:** ✅ Freigegeben (nach 2 Korrekturen)

---

## Findings

### [MITTEL — BEHOBEN] `exerciseName` statt `exerciseNameSnapshot` in `StrengthDetailView`

- **Datei:** `StrengthDetailView.swift`, `exercisesDetailSection`, Zeile 350
- **Problem:** `name: firstSet.exerciseName` verletzt CLAUDE.md-Regel „Prefer `ExerciseSet.exerciseNameSnapshot` over `.exerciseName`"
- **Fix:** `firstSet.exerciseNameSnapshot.isEmpty ? firstSet.exerciseName : firstSet.exerciseNameSnapshot`
- **Status:** Behoben

### [NIEDRIG — BEHOBEN] Typo `strugglingsuggestion` → `strugglingSuggestion`

- **Datei:** `RatingInsightCalcEngine.swift`, Zeilen 86 + 105
- **Problem:** Methodenname `strugglingsuggestion` verletzt Swift-Namenskonvention (camelCase)
- **Fix:** Beide Stellen (Aufruf + Definition) korrigiert
- **Status:** Behoben

### [NIEDRIG — OFFEN] SQL-Migration: RLS ohne Policy

- **Datei:** `Documentation/SQL/exercise_ratings_migration.sql`
- **Problem:** `ENABLE ROW LEVEL SECURITY` ohne `CREATE POLICY` → Supabase default deny sperrt alle App-Zugriffe
- **Empfehlung:** Vor erstem Upload im Supabase-Dashboard prüfen ob eine globale Policy existiert. Falls nicht, Policy anlegen oder RLS-Zeile entfernen.
- **Status:** Kein Blocker, manuelle Prüfung bei SQL-Migration erforderlich

### [NIEDRIG — OFFEN] `rateExercise()` löscht+schreibt auch bei identischem Rating neu

- **Datei:** `ActiveWorkoutView.swift`, `rateExercise()`
- **Problem:** Kein Early-Return wenn `cachedExerciseRatings[groupKey] == rating` → unnötige SwiftData-Writes + `ratedAt` verschiebt sich
- **Empfehlung:** Guard am Anfang von `rateExercise()` einfügen. Kein Blocker.
- **Status:** Offen (optionale Optimierung)

---

## Positives

- SwiftData-Model CloudKit-kompatibel: alle Properties mit Defaults, Relationship `.nullify`/`.cascade` korrekt
- `color` in `TypesUI.swift`, `icon`/`label` in `StrengthTypes.swift` — saubere Import-Trennung
- `ExerciseRatingCard`: `@State` korrekt via Custom-Init mit `existingRating` vorbelegt
- 0.5s-Delay via `Task.sleep` in der Card — kein Timer, kein Retain-Problem
- `cachedExerciseRatings` wird in `setupSession()` aus vorhandenen Ratings befüllt — Resume-Szenario korrekt
- UUID-Dedup-Block für `ratingUUID` nach ExerciseSet-Block eingefügt
- `ExerciseRating.self` in `appSchema` aufgenommen
- Inverse Relationship auf `StrengthSession` korrekt (`.cascade` + inverse)
- `RatingInsightCalcEngine`: pure struct, kein SwiftUI-Import, chronologische Sortierung, Threshold-Logik korrekt
- `SummaryRatingInsightCard` zwischen Section 7 und 8 eingefügt
- Alle DTO-CodingKeys snake_case konsistent

---

## Manual Verification Checklist

- [ ] Xcode Build (`Cmd+B`)
- [ ] Simulator: Übung abschließen → Rating-Card erscheint
- [ ] Simulator: Rating auswählen → Haptic, 0.5s Delay, automatisch nächste Übung
- [ ] Simulator: „Überspringen" → kein Rating gespeichert
- [ ] Simulator: Workout resumed → vorheriges Rating pre-selected
- [ ] StrengthDetailView: Rating-Badges und Verteilungszeile sichtbar
- [ ] SummaryView: nach 3+ gleichen Ratings erscheint Insight-Card
- [ ] Supabase: RLS-Policy prüfen vor SQL-Migration
- [ ] Supabase: SQL-Migration ausführen, Upload verifizieren
