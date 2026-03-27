# Quality Gate — DetailedMuscle-Bearbeitung in ExerciseFormView

**Datum:** 2026-03-27
**Status:** ✅ Alle Findings behoben

## Findings (alle behoben)

### [Medium] ExerciseImportManager — Setter-Contract umgangen ✅ behoben
- **Datei:** `ExerciseImportManager.swift` Zeile 238–241
- **Problem:** Direktzugriff auf `detailedPrimaryMusclesRaw` umging den neuen Setter, der auch `primaryMusclesRaw` synchronisiert.
- **Fix:** Setter `local.detailedPrimaryMuscles = ...` / `local.detailedSecondaryMuscles = ...` verwendet.

### [Low] ScrollView-Touch-Konflikt im NavigationLink-Label ✅ behoben
- **Datei:** `FormViewSection.swift` Zeilen 685 + 738
- **Problem:** Horizontaler ScrollView innerhalb NavigationLink-Label kann Tap absorbieren.
- **Fix:** `.allowsHitTesting(false)` auf beide ScrollViews.

### [Low] Nicht-deterministisches Array(Set(...)) ✅ behoben
- **Datei:** `Exercise.swift` — `primaryMuscles`-Getter, `secondaryMuscles`-Getter, `detailedPrimaryMuscles`-Setter, `detailedSecondaryMuscles`-Setter
- **Fix:** `.sorted { $0.rawValue < $1.rawValue }` / `.sorted()` nach `Array(Set(...))`.

### [Low] `orderedGroups` + `muscles(for:)` — wiederholte Berechnung im body ✅ behoben
- **Datei:** `DetailedMusclePicker.swift`
- **Fix:** Als `private static let musclesByGroup: [(group:muscles:)]` vorberechnet (einmalig beim ersten Zugriff).

### [Info] Neue Datei `DetailedMusclePicker.swift` — Xcode Target
- Xcode 16 erkennt neue Dateien automatisch via `PBXFileSystemSynchronizedBuildFileExceptionSet`. Falls Build schlägt: manuell hinzufügen.

## Positives

- Setter-Synchronisation zirkelfrisch (kein rekursiver Aufruf)
- `@Bindable` auf `@Model`-computed-property korrekt
- Kein `@Query` im falschen Layer
- Konsistentes Primary/Secondary-Pattern (blau/lila)
- Alle 42 `DetailedMuscle`-Cases vollständig abgedeckt

## Manual Verification

- [ ] Xcode Build (`Cmd+B`)
- [ ] ExerciseFormView ohne DetailedMuscles — "Keine ausgewählt"
- [ ] ExerciseFormView mit Supabase-Exercise — Capsule-Tags sichtbar
- [ ] DetailedMusclePicker — 9 Gruppen-Sektionen, Checkmarks toggeln korrekt
- [ ] DetailedMuscles setzen → Heatmap zeigt feingranulare Daten
- [ ] MuscleGroup (grob) ändern → DetailedMuscles werden geleert
- [ ] Tap auf Tag-Zeile öffnet den Picker (kein Touch-Konflikt)
