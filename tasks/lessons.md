# Lessons Learned

Only add project-wide, high-value, recurring MotionCore learnings.
Do not add generic notes from unrelated projects.

## Format

### [Short Title]

- Added: YYYY-MM-DD
- Trigger: What typically causes the issue
- Symptom: How it shows up
- Root Cause: The actual cause
- Rule: The concrete rule going forward
- Applies To: affected layers / files / areas
- Example: optional

---

### Live Activity Timer Anchors

- Added: 2026-03-19
- Trigger: countdown / timer in Live Activities
- Symptom: timer freezes in background or drifts
- Root Cause: render-time based timer rendering / unsuitable timer approach
- Rule: For Live Activities, use fixed time anchors from `ContentState`; prefer `Text(timerInterval: start...end, countsDown: true)`
- Applies To: `ActivityKit`, `MotionCoreWidgetsLiveActivity.swift`

### Background-Safe Time Logic

- Added: 2026-03-19
- Trigger: ongoing time measurement with `Timer.scheduledTimer`
- Symptom: timer stops in background
- Root Cause: iOS suspends classic timers in background
- Rule: Compute time deltas from date anchors, not from continuously running background timers
- Applies To: `RestTimerManager.swift`, `ActiveSessionManager.swift`, `ActiveWorkoutView.swift`

### SwiftData Shared Types

- Added: 2026-03-19
- Trigger: new DTOs / view models / chart types are introduced
- Symptom: duplicate definitions, conflicts, unnecessary types
- Root Cause: existing shared types were not checked first
- Rule: Before creating any new type, check `CLAUDE.md` and the existing CalcEngines first
- Applies To: `Services/Calculation/`, `StatisticCalcEngine.swift`, `StrengthRecordCalcEngine.swift`

### SwiftData + CloudKit Schema Safety

- Added: 2026-03-19
- Trigger: changes to production-adjacent models
- Symptom: CloudKit / schema problems
- Root Cause: risky changes without a dev-safe path
- Rule: Plan schema changes deliberately and validate them locally / in a dev-safe way first
- Applies To: `Models/Core/`, `StrengthSession.swift`, `CardioSession.swift`, `OutdoorSession.swift`

### SwiftData Model-Identifiers as Dictionary Keys

- Added: 2026-03-19
- Trigger: using SwiftData `@Model` instances as Dictionary keys
- Symptom: build errors or runtime crashes from non-unique keys
- Root Cause: `exercise.id` is `PersistentIdentifier` (not `UUID`), and `exercise.name` is not unique — both lead to duplicate keys
- Rule: Use `exercise.persistentModelID` as Dictionary key. For content-based lookups, use the `exerciseName` field of the associated value struct.
- Applies To: `Services/Calculation/`, any code building dictionaries from SwiftData queries
- Example: `trained.map { ex -> (PersistentIdentifier, [TrendPoint]) in ... }`

### @Observable ViewModels — CalcEngine Caching

- Added: 2026-03-19
- Trigger: CalcEngines used as computed properties directly in Views
- Symptom: expensive operations (e.g. `allAnalyses`) recalculated 4× per render cycle
- Root Cause: computed properties in Views are re-evaluated on every render
- Rule: Wrap CalcEngines in `@Observable` ViewModels. Trigger `recalculate()` only via `.task {}` + `.onChange(of:)`. Call expensive operations once and store as `let`, then derive all counts from that result.
- Applies To: `ProgressionViewModel.swift`, `StatisticsViewModel.swift`, `RecordsViewModel.swift`, `SummaryViewModel.swift`

### Anthropic API Batch-Größe und Token-Limits

- Added: 2026-04-05
- Trigger: Python-Skripte die viele Datensätze per API verarbeiten
- Symptom: JSON-Fehler / stille Fehler bei großen Batches; Retries kosten genauso viel wie erfolgreiche Calls
- Root Cause: `max_tokens=4096` zu klein für 50 Exercises × ~80 Output-Tokens = ~4000 Tokens → JSON wird mitten im Schreiben abgeschnitten
- Rule: Batch-Größe × erwartete Output-Tokens pro Item muss deutlich unter `max_tokens` liegen. Faustregel: Batch 25 + `max_tokens=8096` für Muskel-Enrichment-Tasks
- Applies To: `ExerciseEnrich/enrich_exercise_muscles.py`, zukünftige API-Batch-Skripte

### Hybridmodell für LLM-Batch-Verarbeitung

- Added: 2026-04-05
- Trigger: große Datenmengen per LLM anreichern + auf Korrektheit prüfen
- Symptom: unnötig hohe Kosten wenn ein starkes Modell für einfache Faktenabfragen genutzt wird
- Root Cause: Opus/Sonnet für reine Faktenwissen-Aufgaben überdimensioniert
- Rule: Günstiges Modell (Haiku) für Generierung, stärkeres Modell (Sonnet) für QA. Checkpoint-System immer einbauen damit bei Abbruch nicht von vorne gestartet wird.
- Applies To: `ExerciseEnrich/`, zukünftige Batch-Anreicherungs-Skripte

### .sheet(isPresented:) Race Condition — immer .sheet(item:) verwenden

- Added: 2026-04-06
- Trigger: `.sheet(isPresented: $bool)` kombiniert mit einem separaten `@State var selectedId` — beide in derselben Tap-Closure gesetzt
- Symptom: Sheet öffnet sich komplett leer (kein Inhalt sichtbar, kein Titel, keine Liste) — speziell beim ersten Aufruf nach App-Start; nach mehrmaligem Öffnen verschiedener Sheets funktioniert es plötzlich
- Root Cause: SwiftUI evaluiert den Sheet-Content-Closure manchmal in einem eigenen Render-Pass, bevor der separat gesetzte `selectedId`-State sichtbar ist. Das `if let data = viewModel.analysis?.data(for: selectedId)` schlägt fehl → leeres Sheet. Besonders ausgeprägt beim ersten App-Start, wenn SwiftData noch die View-Hierarchy aufbaut.
- Rule: **Niemals `.sheet(isPresented:)` + separaten ID-State verwenden.** Stattdessen immer `.sheet(item: $selectedItem) { item in ... }` — item-Binding ist atomar, kein Race möglich.
- Applies To: alle Sheets in MotionCore die von einer Tap-Aktion auf eine Liste/SVG/Card ausgelöst werden
- Example: `@State private var selectedRegion: MuscleHeatData?` + `.sheet(item: $selectedRegion) { data in MuscleDetailSheet(data: data, ...) }` statt Bool + String-State

### Dictionary from SwiftData Results — Type Annotation

- Added: 2026-03-19
- Trigger: `Dictionary(uniqueKeysWithValues:)` with SwiftData objects in a `map` closure
- Symptom: compiler error "ambiguous without type annotation"
- Root Cause: Swift compiler cannot infer return type of the closure
- Rule: Always annotate the explicit return type in the closure: `trained.map { ex -> (PersistentIdentifier, [TrendPoint]) in ... }`
- Applies To: any `Dictionary(uniqueKeysWithValues:)` call with SwiftData model objects

### HealthKit Dictionary `.values.first` ist non-deterministisch

- Added: 2026-04-26
- Trigger: `HealthKitManager.hrvSamples(daysBack:)` / `.restingHRSamples(daysBack:)` liefert `Dictionary<Date, Double>`. Code nutzt `.values.first` zur Auswahl
- Symptom: `BodyReadinessFactorsCard` Bar-Farben flackern bei jedem View-Rebuild, obwohl HK-Daten stabil sind. Werte oszillieren um Schwellen (0.75 / 0.4) → Farb-Flip green/yellow/orange
- Root Cause: `Dictionary.values` hat **keine garantierte Reihenfolge**. Bei z.B. 10–20 HRV-Samples pro Tag wählt `.values.first` zufällig ein Sample (38ms vs 51ms etc.) → unterschiedlicher `normalizedScore` jeden Aufruf
- Rule: Bei Mehrfach-Samples pro Tag immer **deterministische Auswahl**: `.max(by: { $0.key < $1.key })` für letztes Sample des Tages, oder Tagesdurchschnitt. Niemals `.values.first` auf HK-Dictionaries. Zusätzlich bei UI-Schwellen ~0.03 Buffer einbauen, um Float-Mikrovariationen abzufangen
- Applies To: `SessionReadinessService.computeLive(...)`, `HealthKitManager.hrvSamples/restingHRSamples`, alle UI-Karten mit hartem Farb-Threshold (`BodyReadinessFactorsCard.tintForScore`)
- Example:
  ```swift
  // Falsch
  let hrv = HealthKitManager.shared.hrvSamples(daysBack: 1).values.first

  // Richtig — deterministisch
  let hrv = HealthKitManager.shared.hrvSamples(daysBack: 1)
      .max(by: { $0.key < $1.key })?.value
  ```

### .contextMenu — niemals conditional via if/else in ViewModifier

- Added: 2026-04-27
- Trigger: ViewModifier wrapt `content` mal mit `.contextMenu`, mal ohne, abhängig von Datenzustand (z.B. `set.isLastSetOfExercise && !set.rpeRecorded`)
- Symptom: HStack-Inhalt teilweise unsichtbar — nur das letzte Element (z.B. trailing Icon) wird gerendert. Tritt nur bei den Rows auf, deren Bedingung beim ersten Render `true` ist
- Root Cause: Conditional-`if` in `body(content:)` produziert `_ConditionalContent` → unterschiedliche View-Identity zwischen Rows. SwiftUI's `.contextMenu` interagiert mit dieser Identity-Variation und kollabiert HStack-Children auf intrinsische Größe (Text/Spacer = 0pt)
- Rule: `.contextMenu` IMMER unconditional anwenden. Den Inhalt (Buttons) conditional rendern. So bleibt View-Identity stabil. Nicht-eligible Rows zeigen leeres Menü on Long-Press — minor UX-Trade-off, akzeptabel
- Applies To: `ExercisesOverviewCard.swift` (`RetroRIRContextMenu`), allgemein alle ViewModifier die `.contextMenu` conditional anhängen
- Example:
  ```swift
  // Falsch — kollabiert Layout
  func body(content: Content) -> some View {
      if eligible { content.contextMenu { ... } } else { content }
  }
  // Richtig — stabile Identity
  func body(content: Content) -> some View {
      content.contextMenu {
          if eligible { Button(...) }
      }
  }
  ```

### Clone-Methods — Library-Relations erhalten, nur Ownership entkoppeln

- Added: 2026-04-29
- Trigger: neue `clone*`-Methode auf `@Model`-Typ; oder Bestehende ergänzen (z.B. `cloneForPlanEditing`, `cloneForSession`)
- Symptom: Beim Plan-Duplizieren keine Übungs-Poster sichtbar; ActiveSetCard ausgegraut (Felder editierbar fehlt); UI-Bindings auf `set.exercise?.xxx` liefern nil
- Root Cause: `cloneForPlanEditing` setzte alle Relationships auf `nil` (Kommentar "detach relations"). Die `exercise`-Relation ist aber many-to-one auf die Library-Übung — viele Sets dürfen dieselbe Exercise referenzieren. Beim Detachen geht Poster/Video/Equipment/repRange/cautionNote verloren. `cloneForSession` machte es korrekt (`copy.exercise = self.exercise`).
- Rule: Bei Clone-Methoden zwischen **Ownership-Relationen** (`trainingPlan`, `session` — vom Aufrufer neu zu setzen) und **Library-Relationen** (`exercise` — Verweis auf gemeinsame Stammdaten) unterscheiden. Library-Relationen IMMER per `copy.X = self.X` übernehmen, nicht auf nil setzen.
- Applies To: `ExerciseSet.cloneForPlanEditing`, `ExerciseSet.cloneForSession`, alle künftigen `clone*`-Methoden auf SwiftData-Models mit Library-Verknüpfungen
- Example:
  ```swift
  // Falsch — Library-Verweis verloren
  copy.exercise = nil
  copy.trainingPlan = nil
  copy.session = nil

  // Richtig — Library bleibt, Ownership wird neu gesetzt
  copy.exercise = self.exercise
  copy.trainingPlan = nil
  copy.session = nil
  ```

### EquipmentWeightRounding — Clamp/Rundung kann newWeight ≤ workingWeight liefern

- Added: 2026-04-30
- Trigger: Engines die `workingWeight + step` berechnen und anschließend via `EquipmentWeightRounding.roundToValidWeight(...)` auf valide Equipment-Stufen runden (z.B. `AutoProgressionCalcEngine`, `ProgressionCalcEngine`)
- Symptom: „Arbeitsgewichte erhöht"-Karte zeigt 24→24 kg (0 kg Steigerung) oder 36→24 kg (Regression). `workingWeight` fällt nach „Auto-Progression" sogar nach unten.
- Root Cause: `roundToValidWeight` clampt auf `eq.maxWeight` und rundet via `.nearest` auf einen Sprung — beides kann ein `newWeight ≤ workingWeight` liefern. Tritt z.B. auf wenn Equipment-Konfiguration nachträglich geändert wurde (`maxWeight` jetzt unter aktuellem `workingWeight`) oder wenn `increment` so groß ist, dass der nächstgelegene Sprung der aktuelle Wert selbst ist. Die Engine setzte trotzdem `shouldAutoProgress: true` und der Applier schrieb `workingWeight = newWeight`.
- Rule: Nach jeder `roundToValidWeight(...)`-Berechnung in einer Progressions-Engine **immer** prüfen `guard newWeight > workingWeight else { return noProgress }`. Eine Regression ist keine Progression — wenn Equipment keinen höheren validen Schritt zulässt, gibt es keinen Progressions-Vorschlag.
- Applies To: `AutoProgressionCalcEngine.calculate`, `ProgressionCalcEngine` und alle künftigen Engines die Equipment-aware aufrunden
- Example:
  ```swift
  // Falsch — clamp/round kann ≤ liefern, Engine progressiert trotzdem
  let newWeight = EquipmentWeightRounding.roundToValidWeight(raw, equipment: eq, ...)
  return Output(shouldAutoProgress: true, newWeight: newWeight, amount: newWeight - workingWeight, ...)

  // Richtig — Guard gegen Null/Negativ-Progression
  let newWeight = EquipmentWeightRounding.roundToValidWeight(raw, equipment: eq, ...)
  guard newWeight > state.workingWeight else { return noProgress }
  return Output(shouldAutoProgress: true, newWeight: newWeight, ...)
  ```

### Watch ClosedRange Crash — Date()...endDate Guard

- Added: 2026-06-07
- Trigger: `Text(timerInterval: Date()...endDate, countsDown: true)` in WatchActiveWorkoutView
- Symptom: Watch-App crasht wenn endDate in der Vergangenheit liegt (ClosedRange verlangt lowerBound ≤ upperBound)
- Root Cause: WCSession-Nachrichten können verzögert ankommen. Zwischen Senden und Rendern kann endDate bereits abgelaufen sein.
- Rule: **Immer `max(Date().addingTimeInterval(1), endDate)` verwenden** wenn endDate aus einer externen Quelle kommt (WCSession, Notification). Gilt für alle `Text(timerInterval:)` Aufrufe mit dynamischem endDate.
- Applies To: `WatchActiveWorkoutView.swift` (countdownView + restView), potenziell auch `MotionCoreWidgetsLiveActivity.swift`

### ExerciseSetSnapshot — neue Felder immer mitsynchronisieren

- Added: 2026-06-07
- Trigger: `trackingMode` zu ExerciseSet hinzugefügt, aber ExerciseSetSnapshot vergessen
- Symptom: Plan-Sync/Undo verliert den Tracking-Modus — Time-Übungen werden nach Roundtrip zu Weight-Übungen
- Root Cause: ExerciseSetSnapshot ist eine manuelle Kopie von ExerciseSet-Feldern. Neue Felder in ExerciseSet werden nicht automatisch in den Snapshot übernommen.
- Rule: **Bei jedem neuen Feld auf ExerciseSet auch ExerciseSetSnapshot + alle 3 Erstellungsorte (SessionPlanSyncCalcEngine, PlanUpdateCalcEngine, SessionSyncUndoService) + Undo-Restore aktualisieren.** Grep nach `ExerciseSetSnapshot(` um alle Sites zu finden.
- Applies To: `PlanUpdateTypes.swift`, `SessionPlanSyncCalcEngine.swift`, `PlanUpdateCalcEngine.swift`, `SessionSyncUndoService.swift`

### handleCountdownSetChange — laufenden Timer nicht killen bei Übungswechsel

- Added: 2026-06-07
- Trigger: User wechselt während laufendem Time-Countdown zu einer anderen Übung
- Symptom: Timer-Display friert ein (Timer invalidiert, aber isRunning/endDate bleiben gesetzt); oder Countdown wird komplett resettet
- Root Cause: `handleCountdownSetChange()` rief `cleanup()` bei Weight-Sets und `reset()` ohne UUID-Guard bei Time-Sets
- Rule: **(1)** Kein `cleanup()` bei Weight-Set wenn Countdown für anderen Satz läuft. **(2)** Guard `currentSetUUID != set.setUUID` vor `reset()` — selber Satz = noop. Timer-Loop darf nur durch explizite User-Aktion (Start/Pause/Resume) oder Set-Completion gestoppt werden.
- Applies To: `ActiveWorkoutView.swift` — `handleCountdownSetChange()`

### Button-disabled-Predicate — alle States abdecken, nicht nur den aktiven

- Added: 2026-06-07
- Trigger: `.disabled(countdown.isRunning && !isPaused && !isFinished)` — schützt nur vor Tap während Countdown läuft
- Symptom: „Satz abschließen" im Idle-Zustand (vor Start) tappbar → schreibt duration=0 in den Satz
- Root Cause: Predicate deckt nur den „Running"-State ab, nicht den „Idle"-State. Button ist in 3 von 4 States enabled.
- Rule: **Disabled-Prädikate positiv formulieren (wann DARF getappt werden), nicht negativ (wann nicht).** `canComplete = isPaused || isFinished` ist klarer und sicherer als das Gegenteil aufzuzählen.
- Applies To: `ActiveTimeSetContent.swift`
