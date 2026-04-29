# 3 Bugs in ActiveWorkoutView

**Komplexität:** Small (drei isolierte Fixes)
**Status:** Implementiert — wartet auf manuelle Verifikation

## Bugs

1. **Pausen-Timer beim letzten Satz des Trainings** → soll entfallen, direkt `WorkoutCompletedCard` zeigen.
2. **Übungsbewertung erscheint erst nach Pausen-Timer** → soll parallel laufen (Timer + Bewertungs-Card sichtbar gleichzeitig).
3. **TabView manchmal sichtbar in ActiveWorkoutView** → Ursache: `ListView` öffnet via `NavigationLink` (Push), TabView wird nicht ausgeblendet. Andere Aufrufer nutzen `fullScreenCover` (TabView weg).

## Affected Files

- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — `completeSet` (Bug 1), `heroCard` (Bug 2), body-Modifier (Bug 3)

## Implementation Steps

- [x] **Bug 1:** In `completeSet` (Nicht-Superset-Pfad, Zeile 900–906): Vor `restTimerManager.start(...)` prüfen ob `session.allSetsCompleted`. Wenn ja → return (kein Timer, kein RIR-Sheet). `WorkoutCompletedCard` wird automatisch via `heroCard`-Logik gezeigt. Superset-Pfad braucht keine Änderung — `handleSupersetRotation` startet Timer nur wenn `anyOpenInGroup == true`, also Workout per Definition nicht fertig.

- [x] **Bug 2:** `heroCard` umstellen: Wenn `restTimerManager.isResting && cachedLastCompletedSet != nil && isSelectedExerciseComplete && !session.allSetsCompleted`, dann **beide Cards** in VStack: RestTimerCardContainer oben, ExerciseCompletedCard darunter. Sonst bestehende `if/else if/else`-Kette.

- [x] **Bug 3:** `.toolbar(.hidden, for: .tabBar)` am body des `ActiveWorkoutView` ergänzen. iOS 16+, no-op bei fullScreenCover-Aufruf, blendet TabView aus bei NavigationLink-Aufruf aus `ListView`.

## Manual Verification

- [ ] Xcode build grün
- [ ] Letzten Satz des Workouts abschließen → kein Timer, sofort `WorkoutCompletedCard` ("Alle Sätze abgeschlossen!")
- [ ] Letzten Satz einer Übung (nicht der letzten Übung) abschließen → RestTimer + ExerciseCompletedCard parallel sichtbar
- [ ] Aus "Workouts"-Tab eine laufende Session via NavigationLink öffnen → TabView nicht mehr sichtbar
- [ ] Neue Session via Plus-Button starten → TabView weg (fullScreenCover, war schon ok)
- [ ] Aus TrainingDetailView Session starten → TabView weg (fullScreenCover, war schon ok)

## Open Questions

Keine. Layout-Entscheidung für Bug 2 (RestTimer oben, Bewertungs-Card darunter) folgt Lese-Reihenfolge top-down.

---

## Progress

**2026-04-29**

Modified file: `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift`

- Bug 1: `completeSet` — `if session.allSetsCompleted { return }` vor `restTimerManager.start(...)`
- Bug 2: `heroCard` — bei aktivem RestTimer **und** abgeschlossener Übung (nicht letzter Übung) → VStack mit `RestTimerCardContainer` oben + `ExerciseCompletedCard` darunter
- Bug 3: `.toolbar(.hidden, for: .tabBar)` am body, blendet TabView aus (für `NavigationLink`-Aufruf aus `ListView`; no-op für die zwei `fullScreenCover`-Aufrufer)

Build: BUILD SUCCEEDED
