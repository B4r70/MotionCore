# Bug-Analyse: Nicht abgeschlossene Sets erscheinen in StrengthDetail

## Symptom

Nach dem vorzeitigen Beenden einer Session (via "Beenden"-Button) zeigt `StrengthDetailView` alle Sets aller Übungen an — auch jene, die der User nie abgeschlossen hat. Nur ein einziger Satz wurde tatsächlich completiert. Alle anderen sind mit `isCompleted = false` in der Datenbank verblieben.

---

## Root Cause

`finishWorkout()` in `ActiveWorkoutView.swift` ruft lediglich `session.complete()` auf — was nur `session.isCompleted = true` und `completedAt = Date()` setzt. Nicht-abgeschlossene `ExerciseSet`-Objekte (`isCompleted == false`) werden dabei **weder gelöscht noch gefiltert**. Sie verbleiben vollständig in `session.exerciseSets`.

`StrengthDetailView` zeigt dann `session.groupedSets` an — eine berechnete Property auf `StrengthSession`, die `safeExerciseSets` **ohne jeglichen `isCompleted`-Filter** iteriert. Alle Session-Sets, ob abgeschlossen oder nicht, landen in der View.

---

## Evidenz

- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift`, Zeile 910–974 — `finishWorkout()` ruft `session.complete()`, `context.save()` und `dismiss()` auf. Kein `removeSets(where: { !$0.isCompleted })`, kein Lösch-Loop für unvollständige Sets.

- `/Users/bartosz/Developments/MotionCore/MotionCore/Models/Core/StrengthSession.swift`, Zeile 254–262 — `func complete()` setzt nur `completedAt` und `isCompleted = true`. Keine Set-Filterung.

- `/Users/bartosz/Developments/MotionCore/MotionCore/Models/Core/StrengthSession.swift`, Zeile 173–198 — `var groupedSets: [[ExerciseSet]]` operiert direkt auf `safeExerciseSets` ohne `isCompleted`-Filter:
  ```swift
  let grouped = Dictionary(grouping: safeExerciseSets) { $0.groupKey }
  ```

- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Workouts/Components/StrengthDetailView.swift`, Zeile 344 — `exercisesDetailSection` iteriert `session.groupedSets` und übergibt die Roh-Sets ohne Filter an `exerciseDetailCard(sets:)`.

- `/Users/bartosz/Developments/MotionCore/MotionCore/Models/Core/ExerciseSet.swift`, Zeile 287 — `cloneForSession()` setzt `isCompleted: false` korrekt. Das Flag existiert und wird auch genutzt — aber nur nie beim Abschluss ausgewertet.

**Gegencheck:** CalcEngines (z.B. `ProgressionCalcEngine`, `TrendCalcEngine`, `MuscleHeatmapCalcEngine`) filtern konsequent nach `isCompleted == true`. Die Statistik-Berechnungen sind korrekt. Nur die direkte Set-Anzeige in `StrengthDetailView` filtert nicht.

---

## Betroffene Komponenten

- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — `finishWorkout()` fehlt Bereinigung nicht-abgeschlossener Sets
- `/Users/bartosz/Developments/MotionCore/MotionCore/Models/Core/StrengthSession.swift` — `complete()` bereinigt keine Sets; `groupedSets` filtert nicht nach `isCompleted`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Workouts/Components/StrengthDetailView.swift` — `exercisesDetailSection` rendert alle Sets ohne Filter

---

## Fix-Optionen

### Option A — Löschen beim Session-Abschluss (in `finishWorkout()`)
Vor `context.save()` alle Sets mit `isCompleted == false` aus der Session entfernen und aus dem Context löschen:
```
session.removeSets(where: { !$0.isCompleted })
// anschliessend context.save()
```
**Vorteile:** Datenmodell ist sauber, keine Phantom-Sets in der DB. Statistiken und Supabase-Upload enthalten nur echte Daten.
**Risiken:** Destruktiv — wenn ein Bug das `isCompleted`-Flag nicht setzt, gehen Daten verloren. Kein Undo. Außerdem: WarmUp-Sets müssen ausgenommen werden, falls sie per Convention nie `isCompleted` werden.

### Option B — Filter in `groupedSets` (in `StrengthSession`)
`groupedSets` auf `safeExerciseSets.filter { $0.isCompleted }` einschränken, statt alle Sets zu liefern.
**Vorteile:** Single Point of Truth — alle Konsumenten von `groupedSets` profitieren automatisch. Minimale Änderung.
**Risiken:** `groupedSets` wird auch in `ActiveWorkoutView` während des laufenden Trainings genutzt (`cachedGroupedSets = session.groupedSets`). Dort müssen noch-offene Sets sichtbar sein. Eine Änderung an `groupedSets` bricht die Live-Workout-Ansicht.

### Option C — Filter in `StrengthDetailView` (View-seitig)
`exercisesDetailSection` filtert die Sets vor der Übergabe an `exerciseDetailCard`:
```swift
ForEach(session.groupedSets) { sets in
    let completedSets = sets.filter { $0.isCompleted }
    guard !completedSets.isEmpty else { return }
    exerciseDetailCard(..., sets: completedSets, ...)
}
```
**Vorteile:** Kein Impact auf das Datenmodell oder die Live-Workout-View. Sicherer Workaround.
**Risiken:** Phantom-Sets bleiben in der DB. Andere Views die direkt `safeExerciseSets` nutzen (z.B. `StrengthEditView`) könnten ebenfalls betroffen sein. Löst das Symptom, nicht die Ursache.

---

## Empfehlung

**Option A (Löschen beim Abschluss)** kombiniert mit dem `isCompleted`-Check aus Option C als Sicherheitsnetz.

In `finishWorkout()` vor `context.save()`:
```
session.removeSets(where: { !$0.isCompleted })
```
Zusätzlich in `StrengthDetailView.exercisesDetailSection` defensiv filtern — damit auch bei bereits korrumpierten historischen Sessions nichts angezeigt wird.

Option A ist die sauberste Lösung: Eine abgeschlossene Session sollte ausschließlich durchgeführte Sätze enthalten. Nicht-abgeschlossene Sets sind semantisch wertlos sobald die Session beendet ist.

---

## Risiken / Seiteneffekte eines Fixes

- **WarmUp-Sets:** Falls WarmUp-Sets in der Praxis nie `isCompleted = true` gesetzt werden (z.B. weil der User sie überspringt), werden sie durch Option A ebenfalls gelöscht. Das muss vor dem Fix geprüft werden — `completeSet()` in `ActiveWorkoutView` setzt `isCompleted = true` für jeden Set-Typ identisch, also sollte es kein Problem sein.
- **Supabase-Upload:** Der Upload in `finishWorkout()` passiert nach `context.save()` in einem `Task`. Wenn die Sets vor dem Save gelöscht werden, enthält der Upload nur abgeschlossene Sets — korrekt. Die Reihenfolge des Löschens muss vor `context.save()` erfolgen.
- **`StrengthEditView`:** Auch diese View arbeitet mit `session.safeExerciseSets`. Bei Option A sind dort keine Phantom-Sets mehr vorhanden, was korrekt ist.
- **`PlanUpdateCalcEngine`:** Filtert bereits nach `isCompleted == true` (Zeile 31). Kein Seiteneffekt.
- **Historische Sessions (bereits gespeichert):** Bereits korrumpierte Sessions in der Datenbank werden durch einen Fix in `finishWorkout()` nicht bereinigt. Option C als View-Filter schützt diese retrospektiv.
