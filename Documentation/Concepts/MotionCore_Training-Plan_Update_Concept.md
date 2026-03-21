# MotionCore — Plan-Update Feature (Konzept)

## Übersicht

Ermöglicht dem User, seinen Trainingsplan intelligent zu aktualisieren, basierend auf tatsächlich durchgeführten Sessions. Das Feature erkennt **strukturelle Änderungen** (Gewicht, Reps, Satzzahl, neue/übersprungene Übungen) und schlägt diese per **Diff-View** zur granularen Übernahme vor. Einmalige Abweichungen (schlechter Tag) werden über Schwellenwerte und Trend-Erkennung herausgefiltert.

---

## Architektur-Entscheidungen

| Entscheidung | Gewählt |
|---|---|
| Trigger | Dual: Banner nach Session-Ende + manueller Button in `TrainingDetailView` |
| Relevante Felder | Gewicht, Reps (targetRepsMin/Max), Satzzahl, neue/entfernte Übungen |
| Trend-Erkennung | Letzte N Sessions (konfigurierbar, Default: 3) |
| UI | Granulare Diff-View als Sheet mit Toggle pro Änderung |
| Schwellenwerte | In `AppSettings` / `WorkoutSettingsView`, v1: hardcodierte Defaults |
| Reihenfolge | Wird NICHT aktualisiert |
| Historie | Minimalistisch: `lastUpdatedFromSession` + `lastUpdateSourceSessionUUID` |
| Scope | Nur plan-basierte Sessions (`sourceTrainingPlan != nil`) |

---

## Neue Dateien

### 1. `PlanUpdateCalcEngine.swift` — Berechnung

Pure struct, kein State, kein SwiftUI. Erhält Plan + Sessions, gibt `PlanUpdateProposal` zurück.

```swift
// MARK: - Ergebnis-Typen

/// Einzelne vorgeschlagene Änderung an einer Übung
struct PlanUpdateChange: Identifiable {
    let id = UUID()
    let exerciseGroupKey: String          // groupKey der Übung
    let exerciseName: String              // Anzeigename
    let changeType: PlanUpdateChangeType
    var isSelected: Bool = true           // User-Toggle im Diff-View
}

enum PlanUpdateChangeType {
    /// Gewichtsänderung: alter Wert → neuer Wert
    case weightUpdate(from: Double, to: Double)
    /// Zielreps geändert
    case targetRepsUpdate(fromMin: Int, fromMax: Int, toMin: Int, toMax: Int)
    /// Satzanzahl geändert (z.B. 3 → 4 Sätze)
    case setCountUpdate(from: Int, to: Int)
    /// Neue Übung, die im Training hinzugefügt wurde
    case exerciseAdded(sets: [ExerciseSetSnapshot])
    /// Übung aus Plan wurde in N Sessions übersprungen (nur Info, kein Auto-Remove)
    case exerciseSkipped(timesSkipped: Int, outOf: Int)
}

/// Snapshot eines ExerciseSets — reine Werte, kein SwiftData-Objekt
struct ExerciseSetSnapshot {
    let exerciseName: String
    let exerciseNameSnapshot: String
    let exerciseUUIDSnapshot: String
    let exerciseMediaAssetName: String
    let setNumber: Int
    let weight: Double
    let weightPerSide: Double
    let reps: Int
    let targetRepsMin: Int
    let targetRepsMax: Int
    let targetRIR: Int
    let setKind: SetKind
    let restSeconds: Int
    let sortOrder: Int
    let groupId: String
}

/// Gesamtergebnis der Analyse
struct PlanUpdateProposal {
    let plan: TrainingPlan
    let changes: [PlanUpdateChange]
    let analyzedSessionCount: Int
    let analyzedSessionDates: [Date]

    var hasChanges: Bool { !changes.isEmpty }
    var selectedChanges: [PlanUpdateChange] { changes.filter(\.isSelected) }
}

// MARK: - CalcEngine

struct PlanUpdateCalcEngine {

    // Konfigurierbare Schwellenwerte (aus AppSettings)
    let minWeightDelta: Double    // z.B. 2.5 kg
    let minRepsDelta: Int         // z.B. 2
    let trendSessionCount: Int    // z.B. 3 — wie viele Sessions für Trend

    /// Hauptmethode: Analysiert Plan gegen seine derivedSessions
    func analyze(plan: TrainingPlan) -> PlanUpdateProposal {
        // 1. Nur abgeschlossene Sessions, sortiert nach Datum (neueste zuerst)
        let completedSessions = (plan.derivedSessions ?? [])
            .filter { $0.isCompleted }
            .sorted { $0.date > $1.date }

        // 2. Nur Sessions NACH dem letzten Plan-Update berücksichtigen
        let relevantSessions: [StrengthSession]
        if let lastUpdate = plan.lastUpdatedFromSession {
            relevantSessions = Array(
                completedSessions.filter { $0.date > lastUpdate }.prefix(trendSessionCount)
            )
        } else {
            relevantSessions = Array(completedSessions.prefix(trendSessionCount))
        }

        guard !relevantSessions.isEmpty else {
            return PlanUpdateProposal(
                plan: plan, changes: [], analyzedSessionCount: 0, analyzedSessionDates: []
            )
        }

        var changes: [PlanUpdateChange] = []

        // 3. Pro Übung im Plan: Vergleich mit Session-Daten
        let templateGroups = plan.groupedTemplateSets
        for templateGroup in templateGroups {
            guard let firstTemplate = templateGroup.first else { continue }
            let groupKey = firstTemplate.groupKey
            let exerciseName = firstTemplate.exerciseNameSnapshot.isEmpty
                ? firstTemplate.exerciseName
                : firstTemplate.exerciseNameSnapshot

            // Sets dieser Übung aus allen relevanten Sessions sammeln
            let sessionSetsPerSession: [[ExerciseSet]] = relevantSessions.map { session in
                session.safeExerciseSets.filter { $0.groupKey == groupKey && $0.isCompleted }
            }

            // Nur Sessions die diese Übung enthalten
            let sessionsWithExercise = sessionSetsPerSession.filter { !$0.isEmpty }

            // --- Gewichts-Trend ---
            analyzeWeightTrend(
                templateGroup: templateGroup,
                sessionsWithExercise: sessionsWithExercise,
                exerciseName: exerciseName,
                groupKey: groupKey,
                changes: &changes
            )

            // --- Satzanzahl-Trend ---
            analyzeSetCountTrend(
                templateGroup: templateGroup,
                sessionsWithExercise: sessionsWithExercise,
                exerciseName: exerciseName,
                groupKey: groupKey,
                changes: &changes
            )

            // --- Übung übersprungen? ---
            let skippedCount = relevantSessions.count - sessionsWithExercise.count
            if skippedCount > 0 && sessionsWithExercise.isEmpty {
                changes.append(PlanUpdateChange(
                    exerciseGroupKey: groupKey,
                    exerciseName: exerciseName,
                    changeType: .exerciseSkipped(
                        timesSkipped: skippedCount,
                        outOf: relevantSessions.count
                    ),
                    isSelected: false  // ← Standardmäßig NICHT ausgewählt
                ))
            }
        }

        // 4. Neue Übungen erkennen (in Sessions aber nicht im Plan)
        detectNewExercises(
            plan: plan,
            sessions: relevantSessions,
            changes: &changes
        )

        return PlanUpdateProposal(
            plan: plan,
            changes: changes,
            analyzedSessionCount: relevantSessions.count,
            analyzedSessionDates: relevantSessions.map(\.date)
        )
    }
}
```

**Hilfsmethoden (private extensions):**

```swift
private extension PlanUpdateCalcEngine {

    /// Gewichts-Trend: Median der Work-Sets pro Session berechnen,
    /// dann prüfen ob ≥ 2/3 der Sessions über dem Schwellenwert liegen
    func analyzeWeightTrend(
        templateGroup: [ExerciseSet],
        sessionsWithExercise: [[ExerciseSet]],
        exerciseName: String,
        groupKey: String,
        changes: inout [PlanUpdateChange]
    ) {
        let templateWorkSets = templateGroup.filter { $0.setKind == .work }
        guard !templateWorkSets.isEmpty else { return }

        let templateMedianWeight = medianWeight(of: templateWorkSets)

        // Median-Gewicht pro Session berechnen
        let sessionMedians: [Double] = sessionsWithExercise.compactMap { sets in
            let workSets = sets.filter { $0.setKind == .work }
            guard !workSets.isEmpty else { return nil }
            return medianWeight(of: workSets)
        }

        guard !sessionMedians.isEmpty else { return }

        // Trend: Wenn ≥ 2/3 der Sessions ein höheres/niedrigeres Gewicht haben
        let threshold = Double(sessionMedians.count) * 2.0 / 3.0
        let higherCount = sessionMedians.filter { $0 > templateMedianWeight + minWeightDelta }.count
        let lowerCount = sessionMedians.filter { $0 < templateMedianWeight - minWeightDelta }.count

        if Double(higherCount) >= threshold {
            // Gewichtserhöhung vorschlagen — neues Gewicht = Median der Session-Mediane
            let newWeight = median(of: sessionMedians)
            changes.append(PlanUpdateChange(
                exerciseGroupKey: groupKey,
                exerciseName: exerciseName,
                changeType: .weightUpdate(from: templateMedianWeight, to: newWeight)
            ))
        } else if Double(lowerCount) >= threshold {
            // Gewichtsreduktion vorschlagen (seltener, aber möglich bei Deload)
            let newWeight = median(of: sessionMedians)
            changes.append(PlanUpdateChange(
                exerciseGroupKey: groupKey,
                exerciseName: exerciseName,
                changeType: .weightUpdate(from: templateMedianWeight, to: newWeight),
                isSelected: false  // Reduktion standardmäßig nicht ausgewählt
            ))
        }
    }

    /// Satzanzahl-Trend: Wenn in ≥ 2/3 der Sessions mehr/weniger Sets gemacht
    func analyzeSetCountTrend(
        templateGroup: [ExerciseSet],
        sessionsWithExercise: [[ExerciseSet]],
        exerciseName: String,
        groupKey: String,
        changes: inout [PlanUpdateChange]
    ) {
        let templateWorkSetCount = templateGroup.filter { $0.setKind == .work }.count
        guard templateWorkSetCount > 0 else { return }

        let sessionWorkSetCounts: [Int] = sessionsWithExercise.map { sets in
            sets.filter { $0.setKind == .work }.count
        }

        guard !sessionWorkSetCounts.isEmpty else { return }

        let threshold = Double(sessionWorkSetCounts.count) * 2.0 / 3.0
        let moreCount = sessionWorkSetCounts.filter { $0 > templateWorkSetCount }.count
        let lessCount = sessionWorkSetCounts.filter { $0 < templateWorkSetCount }.count

        // Satzanzahl nur bei konsistentem Unterschied ≥ 1
        if Double(moreCount) >= threshold {
            let newCount = mostFrequent(in: sessionWorkSetCounts) ?? templateWorkSetCount
            if newCount != templateWorkSetCount {
                changes.append(PlanUpdateChange(
                    exerciseGroupKey: groupKey,
                    exerciseName: exerciseName,
                    changeType: .setCountUpdate(from: templateWorkSetCount, to: newCount)
                ))
            }
        } else if Double(lessCount) >= threshold {
            let newCount = mostFrequent(in: sessionWorkSetCounts) ?? templateWorkSetCount
            if newCount != templateWorkSetCount {
                changes.append(PlanUpdateChange(
                    exerciseGroupKey: groupKey,
                    exerciseName: exerciseName,
                    changeType: .setCountUpdate(from: templateWorkSetCount, to: newCount),
                    isSelected: false
                ))
            }
        }
    }

    /// Erkennt Übungen, die in Sessions vorkommen aber NICHT im Plan
    func detectNewExercises(
        plan: TrainingPlan,
        sessions: [StrengthSession],
        changes: inout [PlanUpdateChange]
    ) {
        let templateGroupKeys = Set(plan.safeTemplateSets.map(\.groupKey))

        // Alle groupKeys aus Sessions sammeln, die NICHT im Plan sind
        var newExerciseKeys: [String: [[ExerciseSet]]] = [:]
        for session in sessions {
            for group in session.groupedSets {
                guard let first = group.first else { continue }
                let key = first.groupKey
                if !templateGroupKeys.contains(key) {
                    newExerciseKeys[key, default: []].append(group)
                }
            }
        }

        // Nur vorschlagen wenn in ≥ 2 Sessions (oder bei nur 1 analysierten Session)
        let minOccurrences = sessions.count == 1 ? 1 : 2
        for (key, groupsPerSession) in newExerciseKeys {
            guard groupsPerSession.count >= minOccurrences else { continue }

            // Repräsentatives Set-Layout: aus der neuesten Session nehmen
            guard let latestGroup = groupsPerSession.first else { continue }
            let snapshots: [ExerciseSetSnapshot] = latestGroup.map { set in
                ExerciseSetSnapshot(
                    exerciseName: set.exerciseName,
                    exerciseNameSnapshot: set.exerciseNameSnapshot,
                    exerciseUUIDSnapshot: set.exerciseUUIDSnapshot,
                    exerciseMediaAssetName: set.exerciseMediaAssetName,
                    setNumber: set.setNumber,
                    weight: set.weight,
                    weightPerSide: set.weightPerSide,
                    reps: set.reps,
                    targetRepsMin: set.targetRepsMin,
                    targetRepsMax: set.targetRepsMax,
                    targetRIR: set.targetRIR,
                    setKind: set.setKind,
                    restSeconds: set.restSeconds,
                    sortOrder: 0,   // wird bei Übernahme neu vergeben
                    groupId: set.groupId
                )
            }

            let displayName = latestGroup.first?.exerciseNameSnapshot.isEmpty == false
                ? latestGroup.first!.exerciseNameSnapshot
                : (latestGroup.first?.exerciseName ?? key)

            changes.append(PlanUpdateChange(
                exerciseGroupKey: key,
                exerciseName: displayName,
                changeType: .exerciseAdded(sets: snapshots),
                isSelected: false  // Neue Übungen standardmäßig NICHT ausgewählt
            ))
        }
    }

    // MARK: - Mathematik-Hilfsfunktionen

    func medianWeight(of sets: [ExerciseSet]) -> Double {
        median(of: sets.map(\.weight))
    }

    func median(of values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[mid - 1] + sorted[mid]) / 2.0
        }
        return sorted[mid]
    }

    func mostFrequent(in values: [Int]) -> Int? {
        let counts = values.reduce(into: [:]) { $0[$1, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
```

### 2. `PlanUpdateTypes.swift` — Typen (falls CalcEngine-Datei > 400 Zeilen)

Enthält `PlanUpdateChange`, `PlanUpdateChangeType`, `ExerciseSetSnapshot`, `PlanUpdateProposal`. Kann beim CalcEngine bleiben, wenn die Gesamtlänge < 400 Zeilen ist.

### 3. `PlanUpdateSheet.swift` — Diff-View (UI)

Sheet mit granularer Auswahl der vorgeschlagenen Änderungen.

```swift
struct PlanUpdateSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let proposal: PlanUpdateProposal
    @State private var changes: [PlanUpdateChange]

    init(proposal: PlanUpdateProposal) {
        self.proposal = proposal
        self._changes = State(initialValue: proposal.changes)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header: "X Änderungen in Y Sessions erkannt"
                    headerSection

                    // Abschnitt 1: Gewichts-/Reps-/Satzänderungen
                    if !structuralChanges.isEmpty {
                        changeSection(
                            title: "Übungs-Updates",
                            icon: "arrow.triangle.2.circlepath",
                            changes: structuralChanges
                        )
                    }

                    // Abschnitt 2: Neue Übungen
                    if !addedExercises.isEmpty {
                        changeSection(
                            title: "Neue Übungen",
                            icon: "plus.circle",
                            changes: addedExercises
                        )
                    }

                    // Abschnitt 3: Übersprungene Übungen (nur Info)
                    if !skippedExercises.isEmpty {
                        changeSection(
                            title: "Übersprungene Übungen",
                            icon: "exclamationmark.triangle",
                            changes: skippedExercises
                        )
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Plan aktualisieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Übernehmen") { applyChanges() }
                        .disabled(changes.filter(\.isSelected).isEmpty)
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        // GlassCard mit Info-Text
        // "3 Änderungen erkannt basierend auf deinen letzten 3 Sessions"
    }

    private func changeSection(title: String, icon: String, changes: [PlanUpdateChange]) -> some View {
        // Section Header + ForEach mit PlanUpdateChangeRow
    }

    // MARK: - Gefilterte Änderungen

    private var structuralChanges: [PlanUpdateChange] {
        changes.filter {
            if case .exerciseAdded = $0.changeType { return false }
            if case .exerciseSkipped = $0.changeType { return false }
            return true
        }
    }

    private var addedExercises: [PlanUpdateChange] {
        changes.filter { if case .exerciseAdded = $0.changeType { return true }; return false }
    }

    private var skippedExercises: [PlanUpdateChange] {
        changes.filter { if case .exerciseSkipped = $0.changeType { return true }; return false }
    }

    // MARK: - Änderungen anwenden

    private func applyChanges() {
        let selected = changes.filter(\.isSelected)
        PlanUpdateApplicator.apply(changes: selected, to: proposal.plan, context: context)
        try? context.save()
        dismiss()
    }
}
```

### 4. `PlanUpdateChangeRow.swift` — Einzelne Diff-Zeile

```swift
struct PlanUpdateChangeRow: View {
    @Binding var change: PlanUpdateChange

    var body: some View {
        HStack {
            Toggle(isOn: $change.isSelected) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(change.exerciseName)
                        .font(.headline)
                    changeDetail
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
        }
        .padding()
        .glassCard()
    }

    @ViewBuilder
    private var changeDetail: some View {
        switch change.changeType {
        case .weightUpdate(let from, let to):
            // "80 kg → 85 kg" mit grünem/rotem Pfeil
            HStack(spacing: 4) {
                Text(AppFormatter.weight(from))
                Image(systemName: to > from ? "arrow.up.right" : "arrow.down.right")
                    .foregroundStyle(to > from ? .green : .orange)
                Text(AppFormatter.weight(to))
            }

        case .targetRepsUpdate(let fromMin, let fromMax, let toMin, let toMax):
            Text("\(fromMin)-\(fromMax) Reps → \(toMin)-\(toMax) Reps")

        case .setCountUpdate(let from, let to):
            Text("\(from) Sätze → \(to) Sätze")

        case .exerciseAdded(let sets):
            Text("\(sets.count) Sätze — In Plan übernehmen?")

        case .exerciseSkipped(let timesSkipped, let outOf):
            Text("In \(timesSkipped) von \(outOf) Sessions übersprungen")
                .foregroundStyle(.orange)
        }
    }
}
```

### 5. `PlanUpdateApplicator.swift` — Änderungen auf Plan anwenden

Separiert die Mutationslogik vom CalcEngine (der pure bleibt) und der View.

```swift
/// Wendet ausgewählte PlanUpdateChanges auf einen TrainingPlan an.
/// Wird aus PlanUpdateSheet aufgerufen.
struct PlanUpdateApplicator {

    static func apply(
        changes: [PlanUpdateChange],
        to plan: TrainingPlan,
        context: ModelContext
    ) {
        for change in changes {
            switch change.changeType {
            case .weightUpdate(_, let newWeight):
                // Alle Work-Sets dieser Übung im Plan aktualisieren
                let matchingSets = plan.safeTemplateSets.filter {
                    $0.groupKey == change.exerciseGroupKey && $0.setKind == .work
                }
                for set in matchingSets {
                    set.weight = newWeight
                }

            case .targetRepsUpdate(_, _, let newMin, let newMax):
                let matchingSets = plan.safeTemplateSets.filter {
                    $0.groupKey == change.exerciseGroupKey
                }
                for set in matchingSets {
                    set.targetRepsMin = newMin
                    set.targetRepsMax = newMax
                }

            case .setCountUpdate(let oldCount, let newCount):
                let matchingSets = plan.safeTemplateSets
                    .filter { $0.groupKey == change.exerciseGroupKey && $0.setKind == .work }
                    .sorted { $0.setNumber < $1.setNumber }

                if newCount > oldCount {
                    // Sets hinzufügen — letzten Set als Vorlage klonen
                    guard let templateSet = matchingSets.last else { continue }
                    for i in (oldCount + 1)...newCount {
                        let newSet = templateSet.cloneForPlanEditing()
                        newSet.setNumber = i
                        newSet.isCompleted = false
                        plan.addTemplateSet(newSet)
                    }
                } else if newCount < oldCount {
                    // Überschüssige Sets entfernen (von hinten)
                    let setsToRemove = matchingSets.suffix(oldCount - newCount)
                    for set in setsToRemove {
                        context.delete(set)
                    }
                }

            case .exerciseAdded(let snapshots):
                // Neue Übung in Plan einfügen
                let nextOrder = plan.nextSortOrder
                for snapshot in snapshots {
                    let newSet = ExerciseSet(
                        exerciseName: snapshot.exerciseName,
                        exerciseNameSnapshot: snapshot.exerciseNameSnapshot,
                        exerciseUUIDSnapshot: snapshot.exerciseUUIDSnapshot,
                        exerciseMediaAssetName: snapshot.exerciseMediaAssetName,
                        setNumber: snapshot.setNumber,
                        weight: snapshot.weight,
                        weightPerSide: snapshot.weightPerSide,
                        reps: snapshot.reps,
                        targetRepsMin: snapshot.targetRepsMin,
                        targetRepsMax: snapshot.targetRepsMax,
                        targetRIR: snapshot.targetRIR,
                        setKind: snapshot.setKind,
                        restSeconds: snapshot.restSeconds,
                        sortOrder: nextOrder,
                        groupId: snapshot.groupId
                    )
                    plan.addTemplateSet(newSet)
                }

            case .exerciseSkipped:
                // Keine automatische Aktion — nur Info für den User
                break
            }
        }

        // Metadaten aktualisieren
        plan.lastUpdatedFromSession = Date()
        // Optional: UUID der neuesten analysierten Session
    }
}
```

### 6. `PlanUpdateBanner.swift` — Banner nach Session-Ende

Dezentes Banner, das in der `WorkoutAnalyseView` (oder alternativ nach `dismiss()` in der `ListView`) erscheint.

```swift
struct PlanUpdateBanner: View {
    let proposal: PlanUpdateProposal
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Plan aktualisieren?")
                        .font(.headline)
                    Text("\(proposal.changes.count) Änderungen erkannt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}
```

---

## Bestehende Dateien — Änderungen

### `TrainingPlan.swift` — 2 neue Properties

```swift
// MARK: - Plan-Update Tracking

/// Wann wurde der Plan zuletzt durch das Update-Feature aktualisiert?
var lastUpdatedFromSession: Date?

/// UUID der Session, die das letzte Update ausgelöst hat
var lastUpdateSourceSessionUUID: UUID?
```

### `AppSettings.swift` — 3 neue Properties

```swift
// MARK: - Plan-Update Schwellenwerte

/// Minimale Gewichtsänderung (kg) für Plan-Update-Vorschlag
@Published var planUpdateMinWeightDelta: Double {
    didSet {
        UserDefaults.standard.set(planUpdateMinWeightDelta, forKey: "workout.planUpdateMinWeightDelta")
    }
}

/// Minimale Reps-Änderung für Plan-Update-Vorschlag
@Published var planUpdateMinRepsDelta: Int {
    didSet {
        UserDefaults.standard.set(planUpdateMinRepsDelta, forKey: "workout.planUpdateMinRepsDelta")
    }
}

/// Anzahl der Sessions für Trend-Erkennung
@Published var planUpdateTrendSessionCount: Int {
    didSet {
        UserDefaults.standard.set(planUpdateTrendSessionCount, forKey: "workout.planUpdateTrendSessionCount")
    }
}
```

**Default-Werte im `init()`:**

```swift
planUpdateMinWeightDelta = UserDefaults.standard.object(forKey: "workout.planUpdateMinWeightDelta") as? Double ?? 2.5
planUpdateMinRepsDelta = UserDefaults.standard.object(forKey: "workout.planUpdateMinRepsDelta") as? Int ?? 2
planUpdateTrendSessionCount = UserDefaults.standard.object(forKey: "workout.planUpdateTrendSessionCount") as? Int ?? 3
```

### `WorkoutSettingsView.swift` — Neue Section

```swift
Section("Plan-Updates") {
    // Minimale Gewichtsänderung
    Stepper(
        "Gewichts-Schwelle: \(AppFormatter.weight(appSettings.planUpdateMinWeightDelta))",
        value: $appSettings.planUpdateMinWeightDelta,
        in: 1.0...10.0,
        step: 0.5
    )

    // Minimale Reps-Änderung
    Stepper(
        "Reps-Schwelle: \(appSettings.planUpdateMinRepsDelta)",
        value: $appSettings.planUpdateMinRepsDelta,
        in: 1...5
    )

    // Trend-Sessions
    Stepper(
        "Trend-Sessions: \(appSettings.planUpdateTrendSessionCount)",
        value: $appSettings.planUpdateTrendSessionCount,
        in: 1...5
    )
}
```

### `TrainingDetailView.swift` — Manueller Update-Button

```swift
// Neuer State
@State private var showPlanUpdateSheet = false
@State private var planUpdateProposal: PlanUpdateProposal?

// Button im VStack (nach PlanActionsSection oder als Teil davon):
if let proposal = planUpdateProposal, proposal.hasChanges {
    PlanUpdateBanner(proposal: proposal) {
        showPlanUpdateSheet = true
    }
    .padding(.horizontal)
}

// Sheet
.sheet(isPresented: $showPlanUpdateSheet) {
    if let proposal = planUpdateProposal {
        PlanUpdateSheet(proposal: proposal)
    }
}

// In .task {} oder .onAppear:
.task {
    let engine = PlanUpdateCalcEngine(
        minWeightDelta: appSettings.planUpdateMinWeightDelta,
        minRepsDelta: appSettings.planUpdateMinRepsDelta,
        trendSessionCount: appSettings.planUpdateTrendSessionCount
    )
    planUpdateProposal = engine.analyze(plan: plan)
}
```

### `ActiveWorkoutView.swift` — Banner nach Session-Ende

In `finishWorkout()` vor `dismiss()`:

```swift
// Plan-Update-Analyse nach Session-Ende
if let sourcePlan = session.sourceTrainingPlan {
    let engine = PlanUpdateCalcEngine(
        minWeightDelta: appSettings.planUpdateMinWeightDelta,
        minRepsDelta: appSettings.planUpdateMinRepsDelta,
        trendSessionCount: appSettings.planUpdateTrendSessionCount
    )
    let proposal = engine.analyze(plan: sourcePlan)
    if proposal.hasChanges {
        // Proposal an die übergeordnete View weitergeben
        // Option A: über Binding/Callback
        // Option B: über Notification
        // Option C: Neuer State in ActiveSessionManager
    }
}
```

> **Hinweis:** Die genaue Übergabe-Mechanik (Binding, Callback, Notification oder State im SessionManager) hängt von der View-Hierarchie ab. Da `ActiveWorkoutView` als `.fullScreenCover` präsentiert wird und danach `dismiss()` aufruft, ist ein Callback-Closure (z.B. `onFinishWithProposal: (PlanUpdateProposal?) -> Void`) der sauberste Weg.

---

## Implementierungsreihenfolge (10 Schritte)

| # | Schritt | Datei(en) | Komplexität |
|---|---------|-----------|-------------|
| 1 | `ExerciseSetSnapshot` + `PlanUpdateChange` + `PlanUpdateChangeType` + `PlanUpdateProposal` definieren | `PlanUpdateCalcEngine.swift` (oder `PlanUpdateTypes.swift`) | Niedrig |
| 2 | `PlanUpdateCalcEngine` struct mit `analyze(plan:)` implementieren | `PlanUpdateCalcEngine.swift` | Hoch |
| 3 | Mathematik-Hilfsmethoden (Median, mostFrequent) | `PlanUpdateCalcEngine.swift` | Niedrig |
| 4 | `lastUpdatedFromSession` + `lastUpdateSourceSessionUUID` auf `TrainingPlan` | `TrainingPlan.swift` | Niedrig |
| 5 | `PlanUpdateApplicator` implementieren | `PlanUpdateApplicator.swift` | Mittel |
| 6 | `PlanUpdateChangeRow` UI-Komponente | `PlanUpdateChangeRow.swift` | Niedrig |
| 7 | `PlanUpdateSheet` zusammenbauen | `PlanUpdateSheet.swift` | Mittel |
| 8 | `PlanUpdateBanner` erstellen | `PlanUpdateBanner.swift` | Niedrig |
| 9 | Integration in `TrainingDetailView` (manueller Trigger) | `TrainingDetailView.swift` | Niedrig |
| 10 | Integration in `ActiveWorkoutView` / Post-Session Flow (automatischer Trigger) | `ActiveWorkoutView.swift` | Mittel |
| **Bonus** | AppSettings-Schwellenwerte + WorkoutSettingsView Section | `AppSettings.swift`, `WorkoutSettingsView.swift` | Niedrig |

---

## Betroffene Dateien (Zusammenfassung)

**Neue Dateien (6):**
- `PlanUpdateCalcEngine.swift` — Pure Berechnungslogik
- `PlanUpdateTypes.swift` — Typen (optional, kann im CalcEngine bleiben)
- `PlanUpdateApplicator.swift` — Mutationslogik
- `PlanUpdateSheet.swift` — Diff-View Sheet
- `PlanUpdateChangeRow.swift` — Einzelne Diff-Zeile
- `PlanUpdateBanner.swift` — Dezentes Vorschlags-Banner

**Geänderte Dateien (4):**
- `TrainingPlan.swift` — 2 neue optionale Properties
- `AppSettings.swift` — 3 neue Published Properties + init-Defaults
- `WorkoutSettingsView.swift` — Neue Section "Plan-Updates"
- `TrainingDetailView.swift` — Banner + Sheet-Integration

**Optional geändert (1):**
- `ActiveWorkoutView.swift` — Post-Session Analyse-Trigger

---

## Edge Cases

1. **Keine Sessions vorhanden:** `analyze()` gibt leeres Proposal zurück → kein Banner
2. **Plan hat keine templateSets:** Keine Changes für bestehende Übungen, aber neue Übungen aus Sessions könnten vorgeschlagen werden
3. **Session hat übersprungene Übungen:** Wird als Info angezeigt, standardmäßig NICHT zum Löschen ausgewählt
4. **Gleichzeitige Gewichts- UND Satzänderung:** Beides wird separat als Change erfasst
5. **Unilaterale Übungen:** `weight` wird normal verglichen — `weightPerSide` wird von der aktuellen Logik nicht separat behandelt (v2-Erweiterung)
6. **Plan wurde noch nie aktualisiert** (`lastUpdatedFromSession == nil`): Alle Sessions werden berücksichtigt (bis trendSessionCount)
