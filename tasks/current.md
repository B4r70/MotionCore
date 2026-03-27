# Toolbar-Buttons vereinheitlichen — Icons statt Text

**Complexity:** Small
**Datum:** 27.03.2026

## Summary

Alle Text-Labels in Toolbar-Buttons (`"Abbrechen"`, `"Fertig"`, `"Speichern"`, `"Übernehmen"`) durch Icons ersetzen:
- "Abbrechen" → `chevron.left`
- "Fertig" / "Speichern" / "Übernehmen" → `checkmark` (blau)

## Affected Files (12)

1. `Views/Workouts/Components/StrengthEditView.swift` — bereits erledigt ✅
2. `Views/Progression/View/WorkoutAnalyseView.swift`
3. `Views/Muscles/View/MuscleHeatmapView.swift`
4. `Views/Progression/View/ExerciseProgressionView.swift`
5. `Views/Progression/View/ProgressionDetailView.swift`
6. `Views/Training/Sheets/PlanPickerSheet.swift`
7. `Views/Training/PlanUpdate/PlanUpdateSheet.swift`
8. `Views/Workouts/Sheets/SetEditSheet.swift`
9. `Views/Workouts/Sheets/ExercisePickerSheet.swift`
10. `Views/Muscles/Components/MuscleGroupPicker.swift`
11. `Views/Workouts/Sheets/SetConfigurationSheet.swift`

## Implementation Steps

- [x] StrengthEditView — bereits erledigt
- [x] Alle verbleibenden 10 Dateien: Text-Buttons durch Icons ersetzen

## Manual Verification

- [ ] Xcode Build (`Cmd+B`)
- [ ] Stichprobe: SetEditSheet, PlanUpdateSheet, ExerciseProgressionView — Icons sichtbar

---

## Fortschritt

**27.03.2026**
Abgeschlossene Steps: alle (10 Dateien, 12 Ersetzungen)

Geänderte Dateien:
- `MotionCore/Views/Progression/View/WorkoutAnalyseView.swift`
- `MotionCore/Views/Progression/View/MuscleHeatmapView.swift` (korrekter Pfad: Views/Progression/View/)
- `MotionCore/Views/Progression/View/ExerciseProgressionView.swift`
- `MotionCore/Views/Progression/View/ProgressionDetailView.swift`
- `MotionCore/Views/Workouts/Sheets/PlanPickerSheet.swift` (korrekter Pfad: Views/Workouts/Sheets/)
- `MotionCore/Views/Training/PlanUpdate/PlanUpdateSheet.swift`
- `MotionCore/Views/Workouts/Components/SetEditSheet.swift` (korrekter Pfad: Views/Workouts/Components/)
- `MotionCore/Views/Training/Exercises/Sheets/ExercisePickerSheet.swift` (korrekter Pfad: Views/Training/Exercises/Sheets/)
- `MotionCore/Views/Training/Exercises/Components/MuscleGroupPicker.swift` (korrekter Pfad: Views/Training/Exercises/Components/)
- `MotionCore/Views/Training/Plans/Components/SetConfigurationSheet.swift` (korrekter Pfad: Views/Training/Plans/Components/)

Offene Punkte: Xcode Build + manuelle Stichprobe ausstehend
