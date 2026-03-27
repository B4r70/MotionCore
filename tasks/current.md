# Muscle Heatmap Bug + Exercise-Edit Absicherung

**Complexity:** Medium
**Datum:** 2026-03-27

## Summary

Die Muscles Heatmap zeigt falsche Muskeln (Quadrizeps statt Brust/Arme) aus zwei Gründen:
1. **Setter-Bug im Exercise-Modell**: Der `primaryMuscles`-Setter leert `detailedPrimaryMusclesRaw` nicht — nach einer manuellen Korrektur in ExerciseFormView werden die alten (falschen) Detailed-Daten weiterhin bevorzugt.
2. **Sekundär-Faktor zu hoch**: `0.5` überschätzt den sekundären Stimulus systematisch → auf `0.3` senken.

Zusätzlich: ExerciseFormView zeigt aus StrengthDetailView heraus einen unerwünschten Löschen-Button (Quality Gate Finding aus vorheriger Session).

ExerciseSets brauchen **keine** Muscle-Snapshots — die Engine liest Muskeln live von `Exercise`.

## Affected Files

- `MotionCore/Models/Core/Exercise.swift` — Setter-Fix für primary + secondary muscles
- `MotionCore/Services/Calculation/MuscleHeatmapCalcEngine.swift` — Sekundär-Faktor 0.5 → 0.3
- `MotionCore/Views/Training/Exercises/View/ExerciseFormView.swift` — `showDeleteButton`-Parameter
- `MotionCore/Views/Workouts/Components/StrengthDetailView.swift` — `showDeleteButton: false` übergeben

## Implementation Steps

- [x] **Exercise.swift — `primaryMuscles` Setter fixen**: Im Setter zusätzlich `detailedPrimaryMusclesRaw = []` setzen
- [x] **Exercise.swift — `secondaryMuscles` Setter fixen**: Analog `detailedSecondaryMusclesRaw = []` im Setter
- [x] **MuscleHeatmapCalcEngine.swift — Sekundär-Faktor**: `volume * 0.5` → `volume * 0.3`
- [x] **ExerciseFormView.swift — `showDeleteButton: Bool = true` hinzufügen**: Property + Condition `if mode == .edit && showDeleteButton`
- [x] **StrengthDetailView.swift — `showDeleteButton: false` übergeben**: Im bestehenden `sheet(item: $exerciseToEdit)` Aufruf

---

## Fortschritt

**Datum:** 2026-03-27
**Abgeschlossene Steps:** alle 5 Implementation Steps

**Geänderte Dateien:**
- `MotionCore/Models/Core/Exercise.swift` — Setter `primaryMuscles` und `secondaryMuscles` leeren jetzt `detailedPrimaryMusclesRaw` bzw. `detailedSecondaryMusclesRaw`
- `MotionCore/Services/Calculation/MuscleHeatmapCalcEngine.swift` — Sekundär-Faktor 0.5 → 0.3
- `MotionCore/Views/Training/Exercises/View/ExerciseFormView.swift` — `showDeleteButton: Bool = true` Property + Condition `mode == .edit && showDeleteButton`
- `MotionCore/Views/Workouts/Components/StrengthDetailView.swift` — `showDeleteButton: false` im Sheet-Aufruf

**Offene Punkte:** keine — bereit für Xcode Build und Manual Verification

---

## Manual Verification

- [ ] Xcode Build (`Cmd+B`)
- [ ] Exercise mit falschen Muskeln via `ellipsis.circle` in StrengthDetailView öffnen
- [ ] Primary Muscles korrigieren (z.B. Chest statt Legs), speichern
- [ ] Heatmap in StrengthDetailView zeigt jetzt korrekte Muskeln
- [ ] Heatmap in MuscleHeatmapView (Analyse-Tab) zeigt korrekte Muskeln
- [ ] ExerciseFormView aus StrengthDetailView — kein Löschen-Button sichtbar
- [ ] ExerciseFormView aus ExerciseListView — Löschen-Button weiterhin sichtbar
