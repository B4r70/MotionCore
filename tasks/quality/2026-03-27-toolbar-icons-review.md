# Quality Gate — Toolbar-Icons Vereinheitlichung

**Datum:** 2026-03-27
**Task:** Toolbar Text-Buttons durch Icons ersetzen (10 Dateien, 12 Stellen)

## Findings

### [MITTEL] SetConfigurationSheet — abweichender Bestätigungs-Button-Stil

**Datei:** `Views/Training/Plans/Components/SetConfigurationSheet.swift`, Zeilen 200–204

Der `confirmationAction`-Button verwendet `IconType(...).glassButton(...)` statt `Image(systemName: "checkmark").foregroundStyle(.blue)`. Als einzige der 10 geänderten Dateien nicht auf den neuen Standard migriert.

**Empfehlung:** Entweder angleichen oder explizit als Grenze zwischen Sheet-Typ und Form-View dokumentieren.

---

### [GERING] PlanUpdateSheet — `.fontWeight(.semibold)` auf Image wirkungslos

**Datei:** `Views/Training/PlanUpdate/PlanUpdateSheet.swift`, Zeilen 82–86

`.fontWeight(.semibold)` ist am `ToolbarItem` gesetzt, hat aber auf einem `Image`-Label keine visuelle Wirkung — toter Code.

**Empfehlung:** `.fontWeight(.semibold)` entfernen.

---

### [INFO] `checkmark` für reine Dismiss-Buttons (kein Speichern)

**Dateien:** `WorkoutAnalyseView.swift`, `ExerciseProgressionView.swift`, `ProgressionDetailView.swift`

Diese Buttons führen nur `dismiss()` aus — kein Speichern. `checkmark` signalisiert üblicherweise eine Bestätigung. Falls `checkmark` als einheitliches "Fertig"-Signal gewollt ist, ist das vertretbar.

---

### [INFO] Verbleibende Stellen außerhalb des Task-Scopes

`ExerciseFilterSheet.swift`, `ExerciseSearchView.swift`, `ActiveWorkoutView.swift` (Zeile 1329) verwenden noch Text-Buttons. Für einen Folge-Task.

---

## Positives

- 11 von 12 Stellen korrekt und einheitlich umgesetzt
- `Button { action } label: { Image(...) }` Schreibweise korrekt und konsistent
- `.foregroundStyle(.blue)` auf allen `checkmark`-Icons gesetzt
- Alle originalen Actions erhalten (`saveChanges()`, `applyChanges()`)
- Kein Code außerhalb der Toolbar-Blöcke geändert
- `cancellationAction`/`confirmationAction`-Placements korrekt

## Manual Verification

- [ ] Xcode Build (`Cmd+B`)
- [ ] SetEditSheet: `chevron.left` + `checkmark` blau, Speichern-Aktion korrekt
- [ ] PlanUpdateSheet: Bestätigen-Button bei 0 Änderungen deaktiviert
- [ ] ExerciseProgressionView: `checkmark` blau sichtbar, Sheet schließt
- [ ] PlanPickerSheet: `chevron.left` sichtbar
