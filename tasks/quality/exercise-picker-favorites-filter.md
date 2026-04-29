# Quality Gate — Favoriten-Filter im ExercisePickerSheet

**Datum:** 2026-04-29
**Status:** Approved (mit kleinen Anmerkungen, kein Blocker)

## Geänderte Dateien

- `MotionCore/Views/Training/Exercises/Sheets/ExercisePickerSheet.swift`
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` (`AddExerciseDuringWorkoutSheet` — paralleler Picker-Flow im aktiven Workout)

## Findings

### Low — `count: 1` beim Favoriten-Chip semantisch redundant
Zeile ~153. `FilterChip.count` zeigt bei den anderen Chips die Anzahl gewählter Werte (effektiv immer 1, da Single-Select). Beim Favoriten-Toggle ist das Badge "1" redundant zum `isSelected`-State. Konsistenz mit den anderen Chips ist gegeben — kein Blocker. Optionale Verbesserung: `count: 0`, da binär.

### Low (pre-existing) — `@Query` filtert `isArchived` nicht
Zeile 18. Archivierte Übungen können theoretisch im Picker erscheinen wenn `isFavorite && isArchived`. Existierte bereits vor diesem Change. Out of scope, als Tech-Debt notiert.

### Info — Empty-State bei kombinierten Filtern leicht irreführend
Wenn `showOnlyFavorites && selectedMuscleGroup != nil` und Ergebnis leer, zeigt der Empty-State "Markiere eine Übung mit dem Stern...", obwohl der User möglicherweise Favoriten hat (nur keinen passenden Muskel). Edge case, kein Blocker.

## Positives

- Minimal, sauber, kein Overhead
- AND-Verknüpfung korrekt; restriktivster Filter zuerst
- Default `false` — kein Regression-Risiko
- Keine force-unwraps, keine neue Business-Logik in View
- `LazyVStack` bleibt erhalten — keine Performance-Regression

## Static Checks

- [x] `\.isFavorite` KeyPath auf `Exercise: Bool` valid
- [x] `FilterChip`-Signatur passt
- [x] Keine TODO/FIXME hinterlassen
- [x] Build (`xcodebuild` iPhone 17 Simulator) → SUCCEEDED

## Manual Verification (für User)

- [ ] Sheet öffnen → Favoriten-Chip aktivieren → nur favorisierte Übungen
- [ ] Favoriten + Muskel kombinieren → AND greift
- [ ] 0 Favoriten in Library → kontextspezifischer Empty-State
- [ ] Toggle aus → komplette Liste wieder sichtbar
