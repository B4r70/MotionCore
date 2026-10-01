# RIR-Abfrage und Bewertungskarte für die letzte Übung

**Complexity:** Medium

## Summary

Nach dem letzten Satz der letzten Übung erscheint sofort die `WorkoutCompletedCard` — RIR-Abfrage und Bewertungskarte werden übersprungen. Ursache: `session.allSetsCompleted` wird an zwei Stellen zweckentfremdet, um sowohl den Rest-Timer als auch den RIR-Trigger bzw. die `ExerciseCompletedCard` zu unterdrücken. Ziel: Rest-Timer-Unterdrückung bleibt an `allSetsCompleted` gebunden, RIR-Trigger und Bewertungskarte werden davon entkoppelt.

Der Wert geht über UI hinaus: Weil die RIR-Abfrage für die letzte Übung **jedes** Trainings (und für **alle** Superset-Übungen) nie gefeuert hat, liefen diese Sätze mit `rpe == 0` in `finishWorkout()` → `AutoProgressionApplier.apply(...)`. `ProgressionCalcEngine.hasRIRData` guarded auf `rpe > 0`, d. h. Smart Progression hat die jeweils letzte Übung jeder Session systematisch ohne RIR-Daten gerechnet.

## Scope

**Included**
- Entkopplung des RIR-Triggers von `allSetsCompleted` in `SetManager.completeSet`.
- Abdeckung des Superset-Pfads: RIR-Trigger feuert auch, wenn `handleSupersetRotation` läuft.
- Sichtbarkeit der `ExerciseCompletedCard` (inkl. `ExerciseRatingCard`) für die letzte Übung; Sequenzierung RIR → Bewertung → `WorkoutCompletedCard`.
- Unterdrückung des toten Rest-Timer-Rings im `RIRInputSheet`, wenn kein Timer läuft.
- Wording der `ExerciseCompletedCard` für den Fall „letzte Übung".

**Explicitly excluded**
- **Zeitbasierte Übungen bleiben unverändert.** `isLastWorkSet(of:)` (`SetManager.swift:267–275`) gibt für `set.isTimeBased == true` per Guard immer `false` zurück → `isLastSetOfExercise` wird nie gesetzt → kein RIR/RPE. Das ist beabsichtigt (RIR ergibt bei Zeit-Sätzen keinen Sinn) und wird **nicht** angefasst. Der Guard darf weder gelockert noch umgangen werden.
- Rest-Timer-Verhalten am Trainingsende: nach dem allerletzten Satz wird weiterhin **kein** Timer gestartet.
- `RestTimerManager`, `CompactRestTimerView`, `ExerciseRatingCard`, `WorkoutCompletedCard`, `StrengthSession.allSetsCompleted` — keine Änderungen.
- Kein Zwang zur RIR-Erfassung: „Beenden" in der `bottomActionBar` (`ActiveWorkoutView.swift:472–477`) ruft bei `allSetsCompleted` weiterhin direkt `finishWorkout()`. Die Sequenz ist ein weicher Pfad mit permanentem Escape-Hatch, keine Modal-Pflicht.

## Affected Files

- `MotionCore/Views/Workouts/Active/ViewModel/SetManager.swift` — `completeSet` (Z. 125–194): beide `return`-Early-Exits auflösen, RIR-Trigger unbedingt machen.
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — `heroCard` (Z. 929–1005): `!session.allSetsCompleted` aus den Bedingungen in Z. 950 und Z. 987 entfernen; Call-Sites der `ExerciseCompletedCard` um `isFinalExercise` erweitern.
- `MotionCore/Views/Workouts/Active/Components/RIRInputSheet.swift` — `CompactRestTimerView` nur zeigen, wenn beim Öffnen ein Rest-Timer lief; Detent anpassen.
- `MotionCore/Views/Workouts/Active/Components/ExerciseCompletedCard.swift` — neuer Parameter `isFinalExercise: Bool`, Untertitel (Z. 35) und Button-Label (Z. 62) davon abhängig.

## Risks

- **Superset-Verhaltensänderung über den Bugfix hinaus:** Der RIR-Trigger hat für Superset-Sätze **nie** gefeuert (Early-Return in Z. 175–178), nicht nur bei der letzten Übung. Schritt 1 aktiviert ihn dort erstmals. `isLastWorkSet(of:)` begrenzt das auf genau ein Feuern pro Superset-Übung (letzte Runde), aber es ist eine sichtbare Änderung für alle Superset-Trainings. Deshalb als eigener Teilschritt umsetzen (unabhängig revertierbar). Präzedenz im selben File: Das Pace-Sheet wurde in Z. 168–172 bereits bewusst über die Early-Returns gehoben — Kommentar: „VOR den Early-Returns, damit es auch am Trainingsende und in Supersets feuert". Schritt 1 zieht den RIR-Trigger nach demselben Muster nach.
- **Reihenfolge Rest-Timer vs. RIR-Sheet:** Heute wird `restShouldStart` vor `rirSheetShouldShow` gesendet, sodass `restTimerManager.isResting` beim Aufbau des Sheets bereits `true` ist. Diese Reihenfolge **muss** erhalten bleiben — der RIR-Trigger darf nicht nach oben gehoben werden, sondern nur die `return`s müssen verschwinden.
- **Re-Selektion nach Trainingsende:** Nach Schritt 2 zeigt ein Tap auf eine fertige Übung in der `ExercisesOverviewCard` bei bereits komplettem Training die `ExerciseCompletedCard` statt der `WorkoutCompletedCard`. Bewusst akzeptiert: identisch zum bestehenden Verhalten bei nicht-komplettem Training, und kein Dead-End, weil die `bottomActionBar` „Beenden" immer verfügbar ist und `onNextExercise` (→ `selectedExerciseKey = nil`) jederzeit zurückführt.
- **Stale-`@State`-Verdacht in Schritt 3:** Das Einfrieren von `showsRestTimer` in `init` ist Absicht, nicht der klassische Bug. `.sheet(item:)` erzeugt pro Präsentation frische View-Identity → es gibt keinen Reuse-Pfad mit geändertem Wert. Diese Begründung als Kommentar in den Code, nicht nur in den Plan.
- **`isFinalExercise` per `allSetsCompleted`:** Bei Re-Selektion einer früheren Übung nach Trainingsende greift das „Final"-Wording ebenfalls. Akzeptiert — `allSetsCompleted` wird hier bewusst nur für eine **Darstellungsentscheidung** genutzt; der Bug bestand darin, es als **Logik-Gate** zu verwenden. Diese Unterscheidung im Commit/Review explizit benennen.
- Keine Schema-/CloudKit-Risiken: nur bestehende Felder (`rpe`, `rpeRecorded`, `isLastSetOfExercise`), keine neuen Models, kein `AppSchema`-Eingriff.

## Implementation Steps

### Kernfix — Commit 1

- [x] **1a — `SetManager.completeSet` entkoppeln.** In `SetManager.swift` den Block Z. 174–193 umbauen: Superset-Rotation und Rest-Timer werden zu **einer** `if/else if`-Kette ohne `return`. Erster Zweig unverändert: bei `set.supersetGroupId != nil` → `handleSupersetRotation(completedSet:supersetGroupId:)`. Zweiter Zweig (`else if`): Rest-Timer nur starten, wenn `!session.allSetsCompleted` **und** `!set.isTimeBased` — damit bleibt die Timer-Unterdrückung am Trainingsende exakt erhalten und die Superset-Rotation behält Vorrang vor dem normalen Timer. Der Kommentar in Z. 180 („kein Timer, kein RIR-Sheet") wird auf die Timer-Semantik korrigiert.
- [x] **1b — RIR-Trigger unbedingt.** Der Block `if set.isLastSetOfExercise { rirSheetShouldShow.send(set) }` steht danach auf oberster Ebene der Funktion und wird von keinem `return` mehr übersprungen — er feuert damit auch am Trainingsende und im Superset. Position **nach** der Rest-Timer-Kette beibehalten (siehe Risks). Kommentar ergänzt, analog zum Pace-Sheet in Z. 168–172. **Reichweite bestätigt durch User: Superset-RIR wird für alle Superset-Übungen aktiviert (nicht nur die letzte) — konsistent mit Pace-Sheet-Präzedenz.**
- [x] **2 — `heroCard`-Sichtbarkeit.** In `ActiveWorkoutView.swift` in Z. 950 und Z. 987 jeweils das Teilprädikat `!session.allSetsCompleted` gestrichen, sodass nur noch `isSelectedExerciseComplete` prüft. Beide Stellen waren nötig: Z. 987 deckt den Normalfall ab (kein Timer nach dem letzten Satz), Z. 950 den Fall, dass beim Abschluss des letzten Satzes noch der Rest-Timer des vorherigen Satzes läuft. `isSelectedExerciseComplete` liefert `false` bei `selectedExerciseKey == nil` (verifiziert vor dem Edit) — `WorkoutCompletedCard`-Zweig bleibt erreichbar.
- [x] **STOPP-Gate 1:** Build grün (`xcodebuild ... build` → `** BUILD SUCCEEDED **`). Manuelle Verifikation am Gerät durch User erfolgreich bestätigt.

### Kosmetik — Commit 2 (unabhängig droppbar)

- [x] **3 — `RIRInputSheet` ohne laufenden Timer.** `@State private var showsRestTimer` eingeführt, in explizitem `init` per `State(initialValue: restTimerManager.isResting)` eingefroren — Muster wie `ExerciseRatingCard.init`. `CompactRestTimerView` nur gerendert wenn `showsRestTimer`; `presentationDetents` auf `.fraction(showsRestTimer ? 0.45 : 0.3)`. Begründung fürs Einfrieren (`.sheet(item:)` → frische View-Identity, kein Reuse-Pfad) als Kommentar im Code ergänzt.
- [x] **4 — Wording letzte Übung.** `ExerciseCompletedCard` um `let isFinalExercise: Bool` erweitert; Untertitel (Z. 35) und Button-Label (Z. 62) im Final-Fall auf „Alle Übungen abgeschlossen." / „Weiter zum Abschluss" umgestellt. Button ruft weiterhin `onNextExercise` (nicht `finishWorkout()`). An beiden Call-Sites in `heroCard` `isFinalExercise: session.allSetsCompleted` übergeben.

## Manual Verification

**Status: ✅ Vom User am Gerät erfolgreich getestet (2026-08-19).**

- [x] Xcode-Build (`Cmd+B`) grün.
- [x] **Hauptfall:** Training mit ≥2 Gewichts-Übungen. Letzten Satz der letzten Übung abschließen → RIR-Sheet erscheint (ohne Timer-Ring), danach `ExerciseCompletedCard` mit „Wie war die Übung?", erst nach Bewerten/Überspringen die `WorkoutCompletedCard`.
- [ ] **Regression Normalfall:** Letzter Satz einer *nicht*-letzten Übung → Rest-Timer läuft, RIR-Sheet mit Ring, Bewertungskarte — unverändert wie bisher.
- [ ] **Regression Timer-Unterdrückung:** Nach dem allerletzten Satz startet **kein** Rest-Timer.
- [ ] **Kante Z. 950:** Letzten Satz der letzten Übung abschließen, während der Rest-Timer des vorherigen Satzes noch läuft → Rest-Timer-Karte **und** `ExerciseCompletedCard` erscheinen zusammen.
- [ ] **Superset:** Superset als letzte Übungsgruppe. Letzte Runde abschließen → RIR-Sheet erscheint pro Superset-Übung genau einmal; Rotation/Timer-Verhalten sonst unverändert.
- [ ] **Superset mitten im Training (neu, Quality-Gate):** Superset ist NICHT die letzte Übungsgruppe. Letzte Runde abschließen → RIR-Sheet erscheint zusätzlich zum bereits laufenden Rest-Timer; Navigation zur nächsten Superset-Übung unter dem offenen Sheet landet nach Dismiss korrekt auf der nächsten Übung.
- [ ] **Zeitbasierter, nicht-letzter Satz (neu, Quality-Gate):** Zeitbasierter Satz, der nicht der letzte der Übung ist → Rest-Timer startet weiterhin normal (Regression zu `!set.isTimeBased`-Bedingung, verifiziert als vorbestehendes Verhalten, siehe `git show 83fa03f`).
- [ ] **Zeitbasiert als letzte Übung (Regression, darf sich nicht ändern):** → **kein** RIR-Sheet, Pace-Sheet erscheint weiterhin. Manueller Pencil/Retro-RIR-Pfad in `ExercisesOverviewCard` unverändert.
- [ ] **Ein-Übungs-Training (neu, Quality-Gate, Edge Case):** Workout mit nur einer Übung → `allSetsCompleted`, `isFinalExercise`-Wording, RIR-Sheet und Bewertungskarte treffen im selben Schritt zusammen; prüfen, dass die Sequenz trotzdem sauber durchläuft.
- [ ] **Rest-Timer läuft während offenem RIR-Sheet ab (neu, Quality-Gate, informativ):** `showsRestTimer` bleibt beim Öffnen eingefroren `true` → `CompactRestTimerView` bleibt nach Ablauf weiter sichtbar (0s-Anzeige). Bekanntes, jetzt load-bearing gemachtes Verhalten — nur gegenprüfen, kein Blocker.
- [ ] **Datenprüfung:** Nach `finishWorkout()` in der Session-Detailansicht prüfen, dass der letzte Work-Satz der letzten Übung `rpeRecorded == true` und `rpe == 10 - RIR` hat. Dieselbe Prüfung für die letzte Übung eines Supersets.
- [ ] **Escape-Hatch:** Während `ExerciseCompletedCard` der letzten Übung sichtbar ist, „Beenden" in der `bottomActionBar` tappen → Training wird direkt beendet (kein Dead-End).

---

**Relevante Pfade**
- `MotionCore/Views/Workouts/Active/ViewModel/SetManager.swift`
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift`
- `MotionCore/Views/Workouts/Active/Components/RIRInputSheet.swift`
- `MotionCore/Views/Workouts/Active/Components/ExerciseCompletedCard.swift`

---

## Fortschritt

**2026-08-19**

**Abgeschlossene Schritte:** 1a, 1b, 2 (Kernfix, Commit 1) und 3, 4 (Kosmetik, Commit 2). Nach jedem Commit-Block Build via `xcodebuild -scheme "MotionCore iOS" -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` verifiziert → beide Male `** BUILD SUCCEEDED **`.

**Commits:**
- `83fa03f` fix(workout): RIR-Trigger und Bewertungskarte für letzte Übung entkoppeln (1a, 1b, 2)
- `e8f3c77` fix(workout): RIRInputSheet ohne toten Timer-Ring, Wording letzte Übung (3, 4)

**Geänderte Dateien:**
- `MotionCore/Views/Workouts/Active/ViewModel/SetManager.swift` — 1a, 1b
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — 2, 4 (Call-Sites)
- `MotionCore/Views/Workouts/Active/Components/RIRInputSheet.swift` — 3
- `MotionCore/Views/Workouts/Active/Components/ExerciseCompletedCard.swift` — 4

**Vor der Implementierung verifiziert (Advisor-Review):**
- `isSelectedExerciseComplete` liefert `false` bei `selectedExerciseKey == nil` → `WorkoutCompletedCard`-Zweig in Schritt 2 bleibt erreichbar, kein Dead-End.
- Reihenfolge `restShouldStart` vor `rirSheetShouldShow` unverändert erhalten (kein Hochziehen des RIR-Triggers vor die Rest-Timer-Kette, nur die `return`s wurden entfernt).
- Zeitbasierte Sätze weiterhin ausgeschlossen: `isLastWorkSet(of:)` (Guard `!set.isTimeBased`) ist die einzige Stelle, die `isLastSetOfExercise` setzt — an dieser wurde nichts geändert, RIR-Block selbst bekam bewusst **keinen** zusätzlichen `!set.isTimeBased`-Check (würde die Invariante duplizieren statt an ihrer Quelle zu belassen).

**Offener Beobachtungspunkt für Quality-Gate (kein Blocker, aber gezielt gegenprüfen):**
- In Supersets feuert der RIR-Trigger jetzt für **jede** Superset-Übung einzeln (1b). In der letzten Runde eines Supersets mit ≥2 Übungen entstehen dadurch nacheinander mehrere Sheets über `$rirSheetSet` (`.sheet(item:)`) — die Präsentationen sind durch die Nutzerinteraktion serialisiert (das Sheet blockiert den Screen, bis es dismissed wird), kein Race. Gezielt verifizieren: jede Superset-Übung der letzten Runde bekommt genau ein Sheet, und `rpeRecorded` wird für alle gesetzt (nicht nur die zuerst/zuletzt geöffnete).
- Ordering-Invariante jetzt bewusst load-bearing: `RIRInputSheet.init` friert `restTimerManager.isResting` beim Öffnen ein (Schritt 3). Die Reihenfolge `restShouldStart.send()` VOR `rirSheetShouldShow.send()` in `SetManager.completeSet` ist deshalb nicht mehr nur eine Konvention, sondern zwingend — vertauscht ein künftiger Refactor beide Sends, verschwindet der Timer-Ring im Sheet für den Normalfall lautlos. Kommentar im Code an der RIR-Sende-Stelle ergänzt, damit das nicht wieder verloren geht.
- „Kante Z. 950" (letzter Satz der letzten Übung, während Timer des vorherigen Satzes noch läuft): Das RIR-Sheet zeigt dann `targetSeconds` des neu abgeschlossenen Satzes, aber `remainingSeconds` des noch laufenden älteren Timers. In der Praxis identisch (gleiche Übung, gleiches `restSeconds`), nur bei abweichender Pausenzeit pro Satz sichtbar — kein neuer Bug, aber beim manuellen Test erwähnenswert.

**Quality Gate (2026-08-19):** ⚠️ Changes Needed → nach Gegenprüfung aufgelöst. Einziges Finding ("`!set.isTimeBased`-Bedingung im Rest-Timer-Zweig neu eingeführt, widerspricht Scope-Exclusion") war ein False Positive — `git show 83fa03f` bestätigt, dass die Bedingung bereits vor dem Fix unverändert an derselben Stelle stand, nur in die neue if/else-if-Kette verschoben wurde. Kein Scope-Verstoß. Checkliste um 5 vom Quality Gate vorgeschlagene Testpunkte ergänzt (Superset mitten im Training, zeitbasierter nicht-letzter Satz, Ein-Übungs-Training, Timer-Ablauf während offenem Sheet).

**Gerätetest (2026-08-19):** ✅ Vom User erfolgreich getestet. Feature abgeschlossen.
