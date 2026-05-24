# C1 — ActiveWorkoutView-Extraktion: Fokussierte Observables

**Status:** Bereit zur Implementierung · **Komplexität:** Large

---

## Ziel

`ActiveWorkoutView` (2 176 Zeilen, ~30 Methoden, kein Seam) in fokussierte, testbare Observables aufteilen.
Die View wird auf ~400 Zeilen reduziert und koordiniert nur noch UI/Sheets/Alerts/SwiftData-Writes.

---

## Design-Entscheide (unveränderlich)

| Frage | Entscheid |
|---|---|
| Scope | Mehrere fokussierte Observables (nicht ein großes ViewModel) |
| Koordination | Combine Publishers — `SetManager` publiziert Events, `WatchBridge` + `LiveActivityCtrl` subscriben |
| WatchBridge | Konkrete Klasse (kein Protokoll-Seam), `@Observable` |
| Datenfluss | View reicht `@Model`-Objekte durch — Observables enthalten KEINEN `ModelContext` |
| SwiftData-Mutationen | **Regel:** Property-Mutationen auf `@Model`-Instanzen (z.B. `set.isCompleted = true`) sind in Observables erlaubt. `context.insert / context.delete / context.save` MUSS in der View bleiben |
| C5 zuerst | `ExerciseProgressionStateResolver` → `ProgressionStateRepository` als Voraussetzung |

---

## Ziel-Architektur

```
ActiveWorkoutView (~400 L)
├── @Bindable var session: StrengthSession                             ← Input
├── @Query(filter: isCompleted) var allSessions: [StrengthSession]     ← bleibt
├── @Query var studioEquipments: [StudioEquipment]                     ← bleibt
├── @Environment(\.modelContext) var context                           ← bleibt (inserts/deletes/saves)
├── @EnvironmentObject var sessionManager: ActiveSessionManager         ← bleibt
├── @EnvironmentObject var appSettings: AppSettings                     ← bleibt
├── @ObservedObject var phoneSession = PhoneSessionManager.shared      ← bleibt
├── @StateObject var restTimerManager = RestTimerManager()             ← bleibt
├── @State var setManager: SetManager                                   ← ~200 L
├── @State var exerciseNav: ExerciseNav                                 ← ~150 L
├── @State var watchBridge: WatchBridge                                 ← ~100 L
├── @State var liveActivity: LiveActivityCtrl                           ← ~180 L
└── @State var smartFill: ActiveWorkoutSmartFillViewModel?             ← bleibt (Init mit Repository)

SetManager.setCompleted (PassthroughSubject<ExerciseSet, Never>)
    → WatchBridge.sink { sendState() }
    → LiveActivityCtrl.sink { syncDebounced() }
SetManager.exerciseKeyChanged (PassthroughSubject<String, Never>)
    → ExerciseNav.sink { selectedExerciseKey = $0 }   // Superset-Rotation
```

---

## Affected Files

| Datei | Änderung |
|---|---|
| `Services/Calculation/ExerciseProgressionStateResolver.swift` | **löschen** |
| `Services/Progression/ProgressionStateRepository.swift` | **neu** — Protokoll + konkrete Impl |
| `Services/AutoProgressionApplier.swift` | Signatur um `repository: ProgressionStateProviding` erweitern |
| `Views/Workouts/Active/ViewModel/ActiveWorkoutSmartFillViewModel.swift` | Init: `context` + `repository` |
| `Views/Workouts/Active/ViewModel/SetManager.swift` | **neu** — Set/Superset-Logik + Caches + Publishers |
| `Views/Workouts/Active/ViewModel/ExerciseNav.swift` | **neu** — Exercise-Selektion/Reorder |
| `Views/Workouts/Active/ViewModel/WatchBridge.swift` | **neu** — Watch-Sync konkrete Klasse |
| `Views/Workouts/Active/ViewModel/LiveActivityCtrl.swift` | **neu** — Live Activity Management |
| `Views/Workouts/Active/Components/RestTimerCardContainer.swift` | **neu** — aus View extrahiert |
| `Views/Workouts/Active/Components/AddExerciseDuringWorkoutSheet.swift` | **neu** — aus View extrahiert |
| `Views/Workouts/Active/View/ActiveWorkoutView.swift` | stark reduziert (~400 L) |

---

## Implementation Steps

### Phase 0 — C5: ProgressionStateRepository (Voraussetzung)

#### Schritt 0.1 — Protokoll + Implementierung anlegen

Neue Datei `MotionCore/Services/Progression/ProgressionStateRepository.swift`:

```swift
protocol ProgressionStateProviding {
    func fetch(exerciseGroupKey: String) -> ExerciseProgressionState?
    @discardableResult
    func createIfMissing(
        exerciseGroupKey: String,
        workingWeight: Double,
        exercise: Exercise
    ) -> ExerciseProgressionState
}

final class ProgressionStateRepository: ProgressionStateProviding {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func fetch(exerciseGroupKey: String) -> ExerciseProgressionState? {
        var d = FetchDescriptor<ExerciseProgressionState>(
            predicate: #Predicate { $0.exerciseGroupKey == exerciseGroupKey }
        )
        d.fetchLimit = 1
        return (try? context.fetch(d))?.first
    }

    @discardableResult
    func createIfMissing(
        exerciseGroupKey: String,
        workingWeight: Double,
        exercise: Exercise
    ) -> ExerciseProgressionState {
        if let existing = fetch(exerciseGroupKey: exerciseGroupKey) { return existing }
        let minReps = exercise.repRangeMin > 0 ? exercise.repRangeMin : 8
        let maxReps = exercise.repRangeMax > 0 ? exercise.repRangeMax : 12
        let targetReps: Int
        if let custom = exercise.customTargetReps, custom > 0 { targetReps = custom }
        else { targetReps = max(1, (minReps + maxReps) / 2) }
        let state = ExerciseProgressionState(
            exerciseGroupKey: exerciseGroupKey,
            workingWeight: workingWeight
        )
        state.targetReps = targetReps
        state.minTargetReps = minReps
        state.maxTargetReps = maxReps
        state.progressionModeRaw = exercise.progressionModeRaw
        context.insert(state)
        try? context.save()
        return state
    }
}
```

#### Schritt 0.2 — AutoProgressionApplier migrieren

`AutoProgressionApplier.apply(...)` bekommt einen zusätzlichen Parameter:
```swift
static func apply(
    forSession session: StrengthSession,
    allPreviousSessions: [StrengthSession],
    studioEquipments: [StudioEquipment],
    context: ModelContext,
    repository: ProgressionStateProviding,   // NEU
    readinessModifier: Double = 1.0
) -> [ExerciseProgressionState]
```
Im Body: `ExerciseProgressionStateResolver.fetch(in: context, exerciseGroupKey: groupKey)` → `repository.fetch(exerciseGroupKey: groupKey)`.
Aufrufer in `ActiveWorkoutView.finishWorkout()` reicht `ProgressionStateRepository(context: context)` durch.

#### Schritt 0.3 — ActiveWorkoutSmartFillViewModel migrieren

```swift
init(context: ModelContext, repository: ProgressionStateProviding)
```
- `context` bleibt (nötig für `context.save()` in `prefillSuggestion`)
- Callsite 1: `ExerciseProgressionStateResolver.fetch(in: context, ...)` → `repository.fetch(...)`
- Callsite 2: `ExerciseProgressionStateResolver.createIfMissing(in: context, ...)` → `repository.createIfMissing(...)`

In `ActiveWorkoutView.setupSession()`:
```swift
smartFill = ActiveWorkoutSmartFillViewModel(
    context: context,
    repository: ProgressionStateRepository(context: context)
)
```

#### Schritt 0.4 — ExerciseProgressionStateResolver löschen

Datei entfernen + aus `project.pbxproj` austragen.

**Verifikation Phase 0:** Build grün · `grep -r "ExerciseProgressionStateResolver" MotionCore/` → 0 Treffer.

---

### Phase 1 — Nested Structs extrahieren

#### Schritt 1.1 — RestTimerCardContainer

Datei `Views/Workouts/Active/Components/RestTimerCardContainer.swift` anlegen.
Struct 1:1 aus `ActiveWorkoutView.swift` ausschneiden — keine Logikänderung.

#### Schritt 1.2 — AddExerciseDuringWorkoutSheet

Struct (inkl. `AdjustmentField`-Enum, Increment/Decrement-Logik, `addExerciseToSession`) in:
`Views/Workouts/Active/Components/AddExerciseDuringWorkoutSheet.swift`

---

### Phase 2 — ExerciseNav extrahieren

Neue Datei `Views/Workouts/Active/ViewModel/ExerciseNav.swift`:

```swift
@Observable @MainActor
final class ExerciseNav {
    var selectedExerciseKey: String?
    private var session: StrengthSession?
    private var cancellables = Set<AnyCancellable>()

    func configure(session: StrengthSession, supersetKeyChanged: AnyPublisher<String, Never>) {
        self.session = session
        supersetKeyChanged
            .sink { [weak self] key in
                withAnimation(.easeInOut) { self?.selectedExerciseKey = key }
            }
            .store(in: &cancellables)
    }

    func selectExercise(key: String) { selectedExerciseKey = key }

    // Berechnet neue sortOrder-Werte — mutiert nur Properties, kein context.save
    func reorderExercise(from: Int, to: Int, in groupedSets: [[ExerciseSet]]) { ... }

    func validateSelectedKey(against groupedSets: [[ExerciseSet]]) { ... }

    // Nach Bestätigtem Delete: Key-Cleanup
    func handleDeleted(groupKey: String) {
        if selectedExerciseKey == groupKey { selectedExerciseKey = nil }
    }
}
```

Methoden aus `ActiveWorkoutView` migrieren:
- `selectExercise(key:)` → `ExerciseNav.selectExercise`
- `reorderExercise(from:to:)` → `ExerciseNav.reorderExercise` (Property-Mutation, kein save)
- `validateSelectedExerciseKey()` → `ExerciseNav.validateSelectedKey`

In View verbleibend:
- `deleteExercise(groupKey:)` → setzt `exerciseToDelete + showDeleteAlert` (Alert-Trigger)
- `confirmDelete()` → `context.delete(set)` + `exerciseNav.handleDeleted(groupKey:)` + Refresh
- `onChange(of: exerciseNav.selectedExerciseKey)` → ruft `sessionManager.setSelectedExerciseKey` + `watchBridge.sendState()` + `prefillSmartSuggestionsIfNeeded()` + `setManager.refreshLastSessionReference` + `saveCurrentExerciseMetrics`

---

### Phase 3 — SetManager extrahieren

Neue Datei `Views/Workouts/Active/ViewModel/SetManager.swift`:

**State-Inventar (wandert rein):**
- `cachedGroupedSets: [[ExerciseSet]]`
- `cachedSessionVolume: Double`
- `cachedCurrentSet: ExerciseSet?`
- `cachedLastCompletedSet: ExerciseSet?`
- `cachedCurrentExerciseIndex: Int`
- `cachedLastSessionReferences: [String: [Int: LastSessionReferenceCalcEngine.Reference]]`

**Publishers:**
```swift
let setCompleted = PassthroughSubject<ExerciseSet, Never>()
let exerciseKeyChanged = PassthroughSubject<String, Never>()   // Superset-Rotation
let workoutShouldFinish = PassthroughSubject<Void, Never>()
let restShouldStart = PassthroughSubject<Int, Never>()         // seconds
let rirSheetShouldShow = PassthroughSubject<ExerciseSet, Never>()
let prDetected = PassthroughSubject<(ExerciseSet, String, Double), Never>() // (set, name, oneRM)
```

**Configure-Signatur:**
```swift
func configure(
    session: StrengthSession,
    historicalSessionsProvider: @escaping () -> [StrengthSession],  // Closure statt @Query
    selectedKeyProvider: @escaping () -> String?,
    selectedKeySetter: @escaping (String?) -> Void
)
```

**API (kein `context`, keine SwiftData-Writes):**
- `rebuildGroupedCaches()` — aus `session.safeExerciseSets` neu aufbauen
- `refreshSetCaches()` — currentSet / lastCompletedSet / currentExerciseIndex ableiten
- `recomputeSessionVolume()` — Volume neu berechnen
- `completeSet(_ set: ExerciseSet)` — mutiert `set.isCompleted = true` + Flags; publiziert `setCompleted`, ggf. `exerciseKeyChanged`, `restShouldStart`, `rirSheetShouldShow`, `prDetected`; **kein** `context.save`
- `handleSupersetRotation(completedSet:supersetGroupId:)` → `exerciseKeyChanged.send(key)`
- `isLastWorkSet(of:) -> Bool`
- `cleanupLastSetFlag(for:)` — mutiert Properties via `ExerciseSetFlagUpdater`, kein save
- `retroRIRCandidate(for selectedKey: String?) -> ExerciseSet?`
- `refreshLastSessionReference(for groupKey: String)`
- `lastSessionReference(for set: ExerciseSet) -> LastSessionReferenceCalcEngine.Reference?`
- `resolveExercise(for groupKey: String) -> Exercise?`
- `lastCompletedSession(for groupKey: String) -> StrengthSession?`
- `saveCurrentExerciseMetrics(forKey:)` — **NEIN**: enthält `context.insert` → bleibt in View
- `supersetDisplayContext(for:) -> SupersetDisplayContext?`
- `supersetNextRoundNames(for:) -> [String]?`

**View bindet (onReceive):**
```swift
.onReceive(setManager.setCompleted) { _ in
    Task { @MainActor in try? context.save() }
    PhoneSessionManager.shared.sendRequestSnapshot()
    completionHapticMedium.impactOccurred()
}
.onReceive(setManager.restShouldStart) { secs in restTimerManager.start(seconds: secs) }
.onReceive(setManager.rirSheetShouldShow) { set in rirSheetSet = set }
.onReceive(setManager.prDetected) { set, name, oneRM in
    prSetIDs.insert(set.persistentModelID)
    prBannerExercise = name; prBannerOneRM = oneRM
    Task { try? await Task.sleep(for: .seconds(3)); withAnimation { prBannerExercise = nil } }
}
```

---

### Phase 4 — WatchBridge extrahieren

Neue Datei `Views/Workouts/Active/ViewModel/WatchBridge.swift`:

```swift
@Observable @MainActor
final class WatchBridge {
    private var cancellables = Set<AnyCancellable>()
    private weak var session: StrengthSession?
    private weak var sessionManager: ActiveSessionManager?
    private weak var restTimer: RestTimerManager?
    private weak var setManager: SetManager?
    private weak var exerciseNav: ExerciseNav?

    func configure(
        session: StrengthSession,
        sessionManager: ActiveSessionManager,
        restTimer: RestTimerManager,
        setManager: SetManager,
        exerciseNav: ExerciseNav,
        setCompleted: AnyPublisher<ExerciseSet, Never>
    ) {
        // deps speichern
        setCompleted
            .sink { [weak self] _ in self?.sendState() }
            .store(in: &cancellables)
    }

    func sendState() { /* PhoneSessionManager.shared.sendWorkoutState(...) */ }

    func handleAction(_ action: WatchAction) {
        // .completeSet → setManager.completeSet(_:)
        // .nextExercise / .previousExercise → exerciseNav.selectExercise(key:)
        // .skipRest → restTimer.skip()
        // .pauseResume → sessionManager.pauseSession() / resumeSession()
    }
}
```

In View verbleibend (PhoneSessionManager-Setup):
- `onAppear`: `PhoneSessionManager.shared.onAction = { watchBridge.handleAction($0) }`
- `onAppear`: `onWatchBecameReachable` → `if !isWatchTrackingActive { sendStartHealthTracking(); sendHeartbeatEnabled(true) }; watchBridge.sendState()`
- `onDisappear`: beide Closures nil + `sendIdleState()`
- `onChange(of: restTimerManager.isResting)` + `onChange(of: exerciseNav.selectedExerciseKey)` + `onChange(of: sessionManager.isPaused)` → `watchBridge.sendState()`

---

### Phase 5 — LiveActivityCtrl extrahieren

Neue Datei `Views/Workouts/Active/ViewModel/LiveActivityCtrl.swift`:

**State-Inventar (wandert rein):**
- `currentActivity: Activity<WorkoutActivityAttributes>?`
- `workoutStartDate: Date`
- `syncDebounceTask: Task<Void, Never>?`

**Configure-Signatur:**
```swift
func configure(
    session: StrengthSession,
    sessionManager: ActiveSessionManager,
    restTimer: RestTimerManager,
    setManager: SetManager,
    setCompleted: AnyPublisher<ExerciseSet, Never>
) {
    setCompleted
        .sink { [weak self] _ in self?.syncDebounced(saveResume: nil) }
        .store(in: &cancellables)
}
```

**API:**
- `start()` · `update()` · `end()` · `reattachIfNeeded()`
- `makeLiveContentState() -> WorkoutActivityAttributes.ContentState`
- `syncDebounced(saveResume: (() -> Void)?)` — debounce 150 ms; ruft `saveResume?()`
- `restoreWorkoutStartDate(_ date: Date)` — für Resume-State
- `async func ensureSingleActivity() -> Bool`
- `async func endActivities(_ activities: [Activity<WorkoutActivityAttributes>])`

In View verbleibend:
```swift
.onChange(of: restTimerManager.isResting) { _, _ in liveActivity.syncDebounced(saveResume: saveResumeState) }
.onChange(of: exerciseNav.selectedExerciseKey) { _, _ in liveActivity.syncDebounced(saveResume: saveResumeState) }
.onChange(of: sessionManager.isPaused) { _, _ in liveActivity.syncDebounced(saveResume: saveResumeState) }
```

---

### Phase 6 — ActiveWorkoutView verdrahten und reduzieren

**Setup-Reihenfolge (ORDER IS LOAD-BEARING):**
```swift
private func setupSession() {
    let plan = session.sourceTrainingPlan   // KEIN sessionManager.currentPlan — existiert nicht
    let repo = ProgressionStateRepository(context: context)
    if smartFill == nil {
        smartFill = ActiveWorkoutSmartFillViewModel(context: context, repository: repo)
    }

    // 1. SetManager zuerst (publiziert), dann Subscriber
    setManager.configure(
        session: session,
        historicalSessionsProvider: { [self] in
            allSessions.filter { $0.persistentModelID != session.persistentModelID }
        },
        selectedKeyProvider: { [exerciseNav] in exerciseNav.selectedExerciseKey },
        selectedKeySetter: { [exerciseNav] in exerciseNav.selectedExerciseKey = $0 }
    )
    // 2. ExerciseNav subscribed auf SetManager.exerciseKeyChanged
    exerciseNav.configure(
        session: session,
        supersetKeyChanged: setManager.exerciseKeyChanged.eraseToAnyPublisher()
    )
    // 3. WatchBridge + LiveActivityCtrl subscriben auf setManager.setCompleted
    watchBridge.configure(
        session: session, sessionManager: sessionManager,
        restTimer: restTimerManager, setManager: setManager, exerciseNav: exerciseNav,
        setCompleted: setManager.setCompleted.eraseToAnyPublisher()
    )
    liveActivity.configure(
        session: session, sessionManager: sessionManager,
        restTimer: restTimerManager, setManager: setManager,
        setCompleted: setManager.setCompleted.eraseToAnyPublisher()
    )

    exerciseNav.validateSelectedKey(against: setManager.cachedGroupedSets)
    liveActivity.reattachIfNeeded()
    liveActivity.syncDebounced(saveResume: saveResumeState)
    watchBridge.sendState()
    // ... Rest unverändert (Ratings-Cache, Readiness-Task, Initial-RefreshLastSession)
}
```

**In View verbleibende Methoden:**

| Methode | Begründung |
|---|---|
| `setupSession()` | Verdrahtung |
| `restoreResumeStateIfPossible()` / `saveResumeState()` | UserDefaults — liest `liveActivity.workoutStartDate` + `exerciseNav.selectedExerciseKey` |
| `startNewSession(sessionID:)` | `session.start()` + `context.save` + `liveActivity.start()` |
| `finishWorkout()` | `context.delete` unfertige Sets + `AutoProgressionApplier.apply(repository:)` + `liveActivity.end()` + Supabase-Upload + dismiss |
| `cancelWorkout()` | `context.delete(session)` + `liveActivity.end()` |
| `handlePausedExit()`, `handlePauseAndExit()` | dismiss-Logik |
| `toggleTimer()` | sessionManager.pause/resume + Haptic |
| `deleteExercise(groupKey:)` | `exerciseToDelete + showDeleteAlert` |
| `confirmDelete()` | `context.delete(set)` + `exerciseNav.handleDeleted(groupKey:)` |
| `rateExercise(groupKey:rating:)` | `context.delete(old)` + `context.insert(new)` |
| `saveCurrentExerciseMetrics(forKey:)` | `context.insert(metrics)` |
| `prefillSmartSuggestionsIfNeeded()` | View-Helper, ruft `smartFill?.prefillSuggestion(...)` |

---

## Risks

- **SwiftData-Mutationsregel:** Property-Mutationen auf `@Model` in Observables OK. `context.insert / delete / save` MUSS in der View bleiben. Coder-Drift verhindern.
- **`session.sourceTrainingPlan` statt `sessionManager.currentPlan`:** `ActiveSessionManager` hat KEIN `currentPlan`. Plan kommt aus `session.sourceTrainingPlan`.
- **Combine-Subscription-Ordnung:** `setupSession()` muss `setManager.configure()` VOR WatchBridge/LiveActivityCtrl aufrufen (Subscriber nach Publisher). `configure()` muss synchron vor dem ersten User-Event laufen.
- **Superset-Koordination:** `SetManager.exerciseKeyChanged` Publisher → `ExerciseNav` subscribed. Subjects sind `PassthroughSubject` (kein Replay) — aber `completeSet` wird erst durch User-Tap getriggert, niemals vor `onAppear`-Setup. OK.
- **Resume-State:** `saveResumeState()` liest nach Migration `exerciseNav.selectedExerciseKey` + `liveActivity.workoutStartDate` statt direkter @State.
- **`allSessions` Predicate:** `#Predicate { $0.isCompleted }` MUSS im @Query-Filter bleiben — sonst sehen historicalSessions auch die laufende Session.
- **`localTimer` @State:** Prüfen ob unbenutzt — falls ja löschen.
- **Combine-Import:** Alle neuen Observable-Dateien brauchen `import Combine`.

---

## Manual Verification

- [ ] Xcode-Build (`Cmd+B`) erfolgreich, keine neuen Warnings
- [ ] `grep -r "ExerciseProgressionStateResolver" MotionCore/` → 0 Treffer
- [ ] Aktives Workout starten → Sets abschließen → Rest-Timer startet korrekt
- [ ] Superset-Rotation: nach Set-Abschluss wechselt Übung automatisch (Publisher-Pfad)
- [ ] Letzter Work-Set einer Übung → RIR-Sheet öffnet sich
- [ ] PR-Banner erscheint bei neuem 1RM
- [ ] Watch-Sync: Satz-Abschluss auf Phone → Watch zeigt aktualisierten State
- [ ] Watch-Aktionen (`completeSet`, `nextExercise`, `previousExercise`, `pauseResume`, `skipRest`) funktionieren
- [ ] Live Activity: startet, aktualisiert bei Satz-Abschluss (debounced), endet nach Workout
- [ ] Übung löschen → Alert → Bestätigung → Liste aktualisiert
- [ ] Übungs-Reordering per Drag&Drop → persistent
- [ ] Übung hinzufügen via Sheet → Liste refresht
- [ ] Workout pausieren → App beenden → neu öffnen → Resume mit korrektem Key + workoutStartDate
- [ ] Ad-hoc-Workout (ohne `sourceTrainingPlan`) startet ohne Crash
- [ ] SmartFill-Vorschläge erscheinen korrekt (Repository-Pfad)
- [ ] Auto-Progression beim `finishWorkout` korrekt (Repository-Pfad)

---

## Progress

### 2026-05-22 — Phase 0 abgeschlossen

**Abgeschlossene Schritte:** 0.1 · 0.2 · 0.3 · 0.4

**Geänderte Dateien:**
- `Services/Progression/ProgressionStateRepository.swift` — neu angelegt (Protokoll + Implementierung)
- `Services/AutoProgressionApplier.swift` — `repository: ProgressionStateProviding` Parameter hinzugefügt, `ExerciseProgressionStateResolver.fetch` → `repository.fetch`
- `Views/Workouts/Active/ViewModel/ActiveWorkoutSmartFillViewModel.swift` — Init um `repository` erweitert, beide Callsites migriert
- `Views/Workouts/Active/View/ActiveWorkoutView.swift` — SmartFill-Init + AutoProgressionApplier-Aufruf aktualisiert
- `Services/Calculation/ExerciseProgressionStateResolver.swift` — **gelöscht**

**Phasen 1–6 abgeschlossen (2026-05-22):**

**Phase 1:** RestTimerCardContainer + AddExerciseDuringWorkoutSheet in eigene Dateien extrahiert, aus ActiveWorkoutView entfernt.

**Phase 2:** ExerciseNav.swift neu angelegt — Exercise-Selektion, Reordering, Superset-Key-Rotation via Combine-Publisher.

**Phase 3:** SetManager.swift neu angelegt — Caches, alle 6 Publisher, completeSet-Logik, Superset-Rotation, SmartProgression-Helpers, LastSessionReference.

**Phase 4:** WatchBridge.swift neu angelegt — Watch-State-Push, WatchAction-Verarbeitung.

**Phase 5:** LiveActivityCtrl.swift neu angelegt — Live-Activity-Lifecycle, debounced Sync, Resume-State-Integration.

**Phase 6:** ActiveWorkoutView vollständig verdrahtet — 2176 → 926 Zeilen, alle Observables als @State, Combine-onReceive Handler, Methoden SwiftData-konform.

**Geänderte Dateien (Phasen 1–6):**
- `Views/Workouts/Active/Components/RestTimerCardContainer.swift` — neu
- `Views/Workouts/Active/Components/AddExerciseDuringWorkoutSheet.swift` — neu
- `Views/Workouts/Active/ViewModel/ExerciseNav.swift` — neu
- `Views/Workouts/Active/ViewModel/SetManager.swift` — neu
- `Views/Workouts/Active/ViewModel/WatchBridge.swift` — neu
- `Views/Workouts/Active/ViewModel/LiveActivityCtrl.swift` — neu
- `Views/Workouts/Active/View/ActiveWorkoutView.swift` — stark reduziert (2176 → 926 L)

**Compile-Fixes und Bereinigung (2026-05-22):**
- `ExerciseNav.swift` — `import SwiftUI` hinzugefügt (fehlte; `withAnimation` braucht SwiftUI)
- `SetManager.swift` — `workoutShouldFinish` Publisher entfernt (dead code; View-Button steuert finishWorkout direkt)

**Offen:** Xcode-Build-Verifikation (Cmd+B) — durch motioncore-quality-gate
