# Smart Plan-Update

**Complexity:** Large

## Summary

Nach Abschluss einer plan-basierten Session analysiert MotionCore automatisch die letzten N Sessions auf strukturelle Änderungen (Gewicht, Satzanzahl, neue/übersprungene Übungen) und schlägt diese per granularer Diff-View zur Übernahme in den Trainingsplan vor. Das Feature ist per Toggle in den Workout-Einstellungen aktivierbar ("Smart Plan-Update").

## Scope

- Enthalten:
  - Trend-Erkennung für Gewicht und Satzanzahl (Work-Sets)
  - Erkennung neuer Übungen (in Sessions aber nicht im Plan)
  - Erkennung übersprungener Übungen (nur Info, kein Auto-Remove)
  - Granulare Diff-View als Sheet mit Toggle pro Änderung
  - Banner in `TrainingDetailView` nach Session-Ende
  - Automatischer Trigger via `ActiveWorkoutView.finishWorkout()`
  - Settings-Toggle + Schwellenwert-Konfiguration in `WorkoutSettingsView`
- Explizit ausgeschlossen (v1):
  - `targetRepsUpdate` (Reps-Zielbereich-Änderungen)
  - `weightPerSide`-Behandlung (nur `weight` wird aktualisiert)
  - Reihenfolge-Änderungen
  - Manueller Update-Button in TrainingDetailView

## UX Placement

- **Location:** Banner erscheint in `TrainingDetailView`, nach `PlanStatisticsCard`, vor `PlanExercisesSection`
- **Entry Point:** Automatisch nach `dismiss()` des `fullScreenCover` (ActiveWorkoutView). Proposal wird via `ActiveSessionManager.shared.pendingPlanUpdateProposal` kommuniziert.
- **Rationale:** `TrainingDetailView` ist der natürliche Ort — User sieht direkt seinen Plan und kann sofort entscheiden.

## Affected Files

### Neue Dateien (6)

- `MotionCore/Models/Types/PlanUpdateTypes.swift`
- `MotionCore/Services/Calculation/PlanUpdateCalcEngine.swift`
- `MotionCore/Services/Calculation/PlanUpdateApplicator.swift`
- `MotionCore/Views/Training/PlanUpdate/PlanUpdateSheet.swift`
- `MotionCore/Views/Training/PlanUpdate/PlanUpdateChangeRow.swift`
- `MotionCore/Views/Training/PlanUpdate/PlanUpdateBanner.swift`

### Geänderte Dateien (6)

- `MotionCore/Models/Core/TrainingPlan.swift`
- `MotionCore/Models/Core/AppSettings.swift`
- `MotionCore/Services/Session/ActiveSessionManager.swift`
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift`
- `MotionCore/Views/Training/Plans/Detail/TrainingDetailView.swift`
- `MotionCore/Views/Settings/View/WorkoutSettingsView.swift`

## Risks

- **SwiftData Schema:** Nur optionale Properties → CloudKit-sicher. `lastUpdateSourceSessionUUID` als `String?` (nicht `UUID?`).
- **AppFormatter.weight() existiert nicht:** Gewichtsformatierung inline mit `String(format: "%.1f kg", value)`.
- **ExerciseSetSnapshot:** Konzept fehlt `isUnilateralSnapshot` und `supersetGroupId` — werden ergänzt.
- **ActiveWorkoutView Größe:** ~840 Zeilen. Eingriff in `finishWorkout()` ist minimal (~8 Zeilen).
- **Reaktivität TrainingDetailView:** `@EnvironmentObject var sessionManager: ActiveSessionManager` muss explizit hinzugefügt werden.

## Implementation Steps

### Phase 1: Typen und Datenmodell

- [x] **Schritt 1 — PlanUpdateTypes.swift erstellen**
  Neue Datei `MotionCore/Models/Types/PlanUpdateTypes.swift`:
  - `struct PlanUpdateChange: Identifiable` mit `id: UUID = UUID()`, `exerciseGroupKey: String`, `exerciseName: String`, `changeType: PlanUpdateChangeType`, `isSelected: Bool = true`
  - `enum PlanUpdateChangeType` mit Cases: `.weightUpdate(from: Double, to: Double)`, `.setCountUpdate(from: Int, to: Int)`, `.exerciseAdded(sets: [ExerciseSetSnapshot])`, `.exerciseSkipped(timesSkipped: Int, outOf: Int)`. **Kein** `.targetRepsUpdate` in v1.
  - `struct ExerciseSetSnapshot` mit Feldern: `exerciseName`, `exerciseNameSnapshot`, `exerciseUUIDSnapshot`, `exerciseMediaAssetName`, `isUnilateralSnapshot: Bool`, `setNumber`, `weight`, `weightPerSide`, `reps`, `targetRepsMin`, `targetRepsMax`, `targetRIR`, `setKind: SetKind`, `restSeconds`, `sortOrder`, `groupId`, `supersetGroupId: String?`
  - `struct PlanUpdateProposal` mit `plan: TrainingPlan`, `changes: [PlanUpdateChange]`, `analyzedSessionCount: Int`, `analyzedSessionDates: [Date]`, computed `hasChanges: Bool`, `selectedChanges: [PlanUpdateChange]`

- [x] **Schritt 2 — TrainingPlan.swift erweitern**
  2 neue optionale Properties (MARK: `// MARK: - Plan-Update Tracking`):
  - `var lastUpdatedFromSession: Date?`
  - `var lastUpdateSourceSessionUUID: String?`

- [x] **Schritt 3 — AppSettings.swift erweitern**
  4 neue `@Published` Properties (MARK: `// MARK: - Smart Plan-Update`):
  - `smartPlanUpdateEnabled: Bool` — Default `true`, Key `"workout.smartPlanUpdateEnabled"`
  - `planUpdateMinWeightDelta: Double` — Default `2.5`, Key `"workout.planUpdateMinWeightDelta"`
  - `planUpdateMinRepsDelta: Int` — Default `2`, Key `"workout.planUpdateMinRepsDelta"`
  - `planUpdateTrendSessionCount: Int` — Default `3`, Key `"workout.planUpdateTrendSessionCount"`
  Alle mit `didSet { UserDefaults.standard.set(...) }`. Init-Defaults ergänzen.

- [x] **Schritt 4 — ActiveSessionManager.swift erweitern**
  1 neue Property:
  - `@Published var pendingPlanUpdateProposal: PlanUpdateProposal?` (Default `nil`)

### Phase 2: Business-Logik

- [x] **Schritt 5 — PlanUpdateCalcEngine.swift erstellen**
  Neue Datei `MotionCore/Services/Calculation/PlanUpdateCalcEngine.swift`:
  - `struct PlanUpdateCalcEngine` mit `minWeightDelta: Double`, `minRepsDelta: Int`, `trendSessionCount: Int`
  - `func analyze(plan: TrainingPlan) -> PlanUpdateProposal`:
    1. Nur abgeschlossene `derivedSessions`, neueste zuerst
    2. Filter: nur Sessions NACH `plan.lastUpdatedFromSession` (wenn gesetzt)
    3. Limit: `prefix(trendSessionCount)`
    4. Pro Übungsgruppe: `analyzeWeightTrend` + `analyzeSetCountTrend` + Skipped-Check
    5. `detectNewExercises`
  - Private Extensions:
    - `analyzeWeightTrend(...)` — Median Work-Set-Gewicht, 2/3-Threshold. Erhöhung `isSelected = true`, Reduktion `isSelected = false`.
    - `analyzeSetCountTrend(...)` — Work-Set-Anzahl, 2/3-Threshold, `mostFrequent`. Erhöhung `isSelected = true`, Reduktion `isSelected = false`.
    - `detectNewExercises(...)` — groupKeys in Sessions nicht im Plan. Min 2 Vorkommen (oder 1 bei 1 Session). Snapshot aus neuester Session. `isSelected = false`.
    - Hilfsmethoden: `medianWeight(of:)`, `median(of:)`, `mostFrequent(in:)`

- [x] **Schritt 6 — PlanUpdateApplicator.swift erstellen**
  Neue Datei `MotionCore/Services/Calculation/PlanUpdateApplicator.swift`:
  - `static func apply(changes: [PlanUpdateChange], to plan: TrainingPlan, context: ModelContext, sourceSessionUUID: String? = nil)`
  - `.weightUpdate(_, newWeight)`: Work-Sets mit passendem groupKey → `set.weight = newWeight`
  - `.setCountUpdate(oldCount, newCount)`: Mehr → `cloneForPlanEditing()` + `plan.addTemplateSet()`. Weniger → `context.delete()`.
  - `.exerciseAdded(snapshots)`: ExerciseSets erstellen (inkl. `isUnilateralSnapshot`, `supersetGroupId`), `sortOrder = plan.nextSortOrder`, `plan.addTemplateSet()`
  - `.exerciseSkipped`: `break`
  - Abschluss: `plan.lastUpdatedFromSession = Date()`, `plan.lastUpdateSourceSessionUUID = sourceSessionUUID`

### Phase 3: UI-Komponenten

- [x] **Schritt 7 — PlanUpdateChangeRow.swift erstellen**
  Neue Datei `MotionCore/Views/Training/PlanUpdate/PlanUpdateChangeRow.swift`:
  - `@Binding var change: PlanUpdateChange`
  - Toggle mit exerciseName (`.headline`) + changeDetail (`.subheadline`, `.secondary`)
  - Alle 4 Cases. Gewicht: `String(format: "%.1f kg", value)`. Übersprungen: `.orange`.
  - Container: `.padding()` + `.glassCard()`

- [x] **Schritt 8 — PlanUpdateBanner.swift erstellen**
  Neue Datei `MotionCore/Views/Training/PlanUpdate/PlanUpdateBanner.swift`:
  - `let proposal: PlanUpdateProposal`, `let onTap: () -> Void`, `let onDismiss: () -> Void`
  - Icon + VStack (Titel + Untertitel mit Änderungsanzahl) + Spacer + Chevron
  - X-Button (`xmark`) für `onDismiss`
  - `.glassCard()`, `.buttonStyle(.plain)`

- [x] **Schritt 9 — PlanUpdateSheet.swift erstellen**
  Neue Datei `MotionCore/Views/Training/PlanUpdate/PlanUpdateSheet.swift`:
  - `let proposal: PlanUpdateProposal`, `let onApply: () -> Void`
  - `@State private var changes: [PlanUpdateChange]` aus `proposal.changes`
  - NavigationStack > ScrollView > VStack(spacing: 16): Header-GlassCard + 3 Sektionen (strukturell, neu, übersprungen)
  - Index-basiertes Binding für Toggles: `$changes[idx]`
  - Toolbar: Abbrechen + Übernehmen (disabled wenn keine selected)
  - `applyChanges()`: `PlanUpdateApplicator.apply(...)`, `try? context.save()`, `onApply()`, `dismiss()`

### Phase 4: Integration

- [x] **Schritt 10 — WorkoutSettingsView.swift erweitern**
  Neue Section am Ende der List (vor .navigationTitle).

- [x] **Schritt 11 — ActiveWorkoutView.swift erweitern**
  In `finishWorkout()`, nach `try? context.save()`, vor `WatchComplicationService`.

- [x] **Schritt 12 — TrainingDetailView.swift erweitern**
  1. `@EnvironmentObject private var sessionManager: ActiveSessionManager` hinzugefügt
  2. `@State private var showPlanUpdateSheet = false` hinzugefügt
  3. Banner nach PlanStatisticsCard eingefügt
  4. Sheet-Modifier hinzugefügt
  5. Previews mit `.environmentObject(ActiveSessionManager.shared)` ergänzt

## Manual Verification

- [ ] Xcode Build (`Cmd+B`) — keine Compile-Fehler
- [ ] Preview: `PlanUpdateChangeRow` mit allen 4 ChangeType-Varianten
- [ ] Preview: `PlanUpdateBanner` — Layout + Tap + Dismiss
- [ ] Preview: `PlanUpdateSheet` mit Mock-Proposal
- [ ] Preview: `WorkoutSettingsView` — neue Section, Toggle zeigt/versteckt Stepper
- [ ] Simulator: Plan öffnen → Workout starten → Gewicht erhöhen → Workout beenden → Banner in TrainingDetailView sichtbar
- [ ] Simulator: Banner antippen → Sheet → Changes togglen → "Übernehmen" → Plan aktualisiert, Banner weg
- [ ] Simulator: Banner X-Button → Banner weg, keine Änderungen
- [ ] Simulator: Smart Plan-Update in Settings deaktivieren → Workout beenden → kein Banner
- [ ] Simulator: Workout ohne Plan → kein Banner

## Progress Log

### 21.03.2026 — Vollständige Implementierung

**Abgeschlossene Schritte:** 1–12 (alle)

**Neue Dateien (manuell zum Xcode-Target hinzufügen):**
- `MotionCore/Models/Types/PlanUpdateTypes.swift`
- `MotionCore/Services/Calculation/PlanUpdateCalcEngine.swift`
- `MotionCore/Services/Calculation/PlanUpdateApplicator.swift`
- `MotionCore/Views/Training/PlanUpdate/PlanUpdateChangeRow.swift`
- `MotionCore/Views/Training/PlanUpdate/PlanUpdateBanner.swift`
- `MotionCore/Views/Training/PlanUpdate/PlanUpdateSheet.swift`

**Geänderte Dateien:**
- `MotionCore/Models/Core/TrainingPlan.swift` — `lastUpdatedFromSession`, `lastUpdateSourceSessionUUID`
- `MotionCore/Models/Core/AppSettings.swift` — 4 Smart Plan-Update Properties + Init-Defaults
- `MotionCore/Services/Session/ActiveSessionManager.swift` — `pendingPlanUpdateProposal`
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — Plan-Update-Trigger in `finishWorkout()`
- `MotionCore/Views/Training/Plans/Detail/TrainingDetailView.swift` — sessionManager EnvironmentObject, Banner, Sheet
- `MotionCore/Views/Settings/View/WorkoutSettingsView.swift` — neue Section "Smart Plan-Update"

**Offene Punkte:**
- Xcode Build (`Cmd+B`) notwendig — neue Dateien müssen manuell zum Target hinzugefügt werden
- Quality Gate ausstehend
