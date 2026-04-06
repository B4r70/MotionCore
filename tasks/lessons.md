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
