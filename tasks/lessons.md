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
