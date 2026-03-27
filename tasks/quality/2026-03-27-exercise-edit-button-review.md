# Quality Gate — Exercise-Edit-Button in StrengthDetailView

**Datum:** 2026-03-27
**Task:** ellipsis.circle-Button öffnet ExerciseFormView für Muscle-Korrekturen

---

## Findings

### [MITTEL] Löschen-Button in ExerciseFormView ist im Sheet aktiv

**Datei:** `Views/Training/Exercises/View/ExerciseFormView.swift` — Zeilen 159–169

`ExerciseFormView` im `.edit`-Modus zeigt immer einen Trash-Button. Tippt der User auf Löschen, wird die `Exercise`-Instanz aus dem SwiftData-Kontext entfernt (`context.delete(exercise)`). Die Relationship zu `ExerciseSet` ist als `.nullify` konfiguriert — kein Crash, aber alle `ExerciseSet`-Instanzen verlieren ihre `exercise`-Referenz dauerhaft.

Aus dem "Muskeln korrigieren"-Sheet heraus ist das destruktiv und unerwartet.

**Empfehlung:** Entweder `ExerciseFormView` um `showDeleteButton: Bool = true` erweitern und aus `StrengthDetailView` mit `false` übergeben, oder einen schlanken separaten Edit-Sheet verwenden. Produktentscheidung notwendig.

---

### [GERING] `firstSet.exerciseName` statt `exerciseNameSnapshot` (pre-existing)

**Datei:** `Views/Workouts/Components/StrengthDetailView.swift` — Zeile 318

CLAUDE.md schreibt vor: "Prefer `ExerciseSet.exerciseNameSnapshot` over `.exerciseName`". Die Zeile existierte bereits vor dieser Änderung. Kein Blocker, aber beim nächsten Anfassen dieser Zeile beheben.

---

### [INFO] Pre-existing TODO in `repeatWorkout()` (Zeile 565)

`repeatWorkout()` erstellt eine neue Session, navigiert aber nicht zur `ActiveWorkoutView`. Nicht durch diese Änderung eingeführt. Separater Task.

---

## Positives

- `Exercise` ist `Identifiable` (SwiftData `@Model`) — `sheet(item:)` korrekt
- `@Bindable var exercise: Exercise` passt zur `ExerciseFormView`-Signatur
- `NavigationStack`-Wrapper korrekt und notwendig
- `.environmentObject(appSettings)` korrekt weitergereicht
- Kein Force-Unwrap — `if let exercise` Guard korrekt
- Genau eine Aufrufstelle von `exerciseDetailCard` — vollständig und konsistent angepasst
- Keine Business-Logik im View — Button setzt nur `exerciseToEdit = exercise`
- Button-Styling (`.font(.title3)`, `.foregroundStyle(.secondary)`) passt zum Projekt-Stil

---

## Static Checks

- [x] Keine offensichtlichen Compiler-Risiken in den neuen Zeilen
- [x] `exerciseDetailCard`-Signatur an allen Aufrufstellen korrekt
- [x] Kein `sorted/filter/map` in neuen View-Zeilen
- [x] Kein Force-Unwrap

---

## Manual Verification

- [ ] Xcode Build (`Cmd+B`)
- [ ] Edit-Button sichtbar je Übung mit Exercise-Referenz
- [ ] ExerciseFormView öffnet als Sheet mit Muscle-Feldern (Primary/Secondary sichtbar und editierbar)
- [ ] Muscles ändern und speichern — kein Crash, Sheet schließt korrekt
- [ ] Übungen ohne Exercise-Referenz (alte Daten) — kein Button sichtbar
- [ ] Löschen-Button in ExerciseFormView — Verhalten dokumentieren / Feature-Entscheidung treffen

---

## Overall Assessment

Mechanisch korrekt implementiert. Das einzige echte Problem ist konzeptionell: Der Löschen-Button in `ExerciseFormView` ist aus diesem Kontext destruktiv und unerwartet. Produktentscheidung notwendig, bevor die Funktion als vollständig gilt.
