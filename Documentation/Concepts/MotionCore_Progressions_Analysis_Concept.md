# MotionCore – Konzept: Progressions-Analyse Integration

> **Version 2.0 – 18. März 2026**
> Aktualisiert nach Performance-Refactoring: ViewModel-Architektur mit `@Observable` + gecachten Berechnungen.

---

## 1. Zusammenfassung

Die bestehende Progressions-Analyse (Tab „Analyse") wird an drei zusätzlichen Stellen integriert, um dem Nutzer während und nach dem Training kontextbezogene Leistungsdaten zu liefern.

| Einstiegspunkt | Beschreibung |
|---|---|
| **ActiveSetCard** | Neues Icon pro Übung → Push-Navigation zu kompakter Einzel-Übungsanalyse mit Mini-Sparklines, Key-Stats und Last-Workout-Vergleich |
| **StrengthDetailView (pro Übung)** | Analyse-Button unter den Satz-Details jeder abgeschlossenen Übung → gleiche kompakte Analyse-View |
| **StrengthDetailView (Header)** | `brain.head.profile`-Icon im Header → Push-Navigation zu Workout-Übersicht mit OverviewCard + ExerciseCards (identisch zum Analyse-Tab, gefiltert auf Workout-Übungen) |

**Konsistentes Icon:** `brain.head.profile` – wird überall als Erkennungszeichen für „Analyse" verwendet.

---

## 2. Architektur-Übersicht

### 2.1 Aktuelle ViewModel-Architektur (Stand 18.03.2026)

Nach dem Performance-Refactoring nutzt die App durchgehend `@Observable`-ViewModels mit gecachten Berechnungen. Die relevanten ViewModels sind:

| ViewModel | Zweck | Berechnung |
|---|---|---|
| `ProgressionViewModel` | Gecachte Progressions-Analysen für den Analyse-Tab | `recalculate(sessions:exercises:)` → cached `analyses`, `trainedExercises`, `oneRMTrendMap`, `volumeTrendMap` |
| `SummaryViewModel` | Summary-Daten inkl. Progressions-Analysen für die Übersicht | `recalculate(cardio:strength:outdoor:exercises:timeframe:)` → cached `progressionAnalyses` |
| `StatisticsViewModel` | Statistik-KPIs und Chart-Daten | `recalculate(cardio:strength:outdoor:timeframe:)` |
| `RecordsViewModel` | Gecachte Rekord-Daten | `recalculateStrength(sessions:)` / `recalculateCardio(sessions:)` |

**Prinzip:** Alle ViewModels sind `@Observable`-Klassen, die per `@State private var viewModel = ...` in der View gehalten werden. Neuberechnung erfolgt via `.task {}` beim Erscheinen und `.onChange(of:)` bei Datenänderungen. Die CalcEngines bleiben reine Structs ohne State.

### 2.2 Performance-Muster in ActiveWorkoutView

Die `ActiveWorkoutView` nutzt ein Cache-Pattern ohne separates ViewModel:

- `cachedGroupedSets`, `cachedSessionVolume`, `cachedCurrentSet`, `cachedLastCompletedSet`, `cachedCurrentExerciseIndex` sind `@State`-Properties
- `refreshSetCaches()` wird nach jeder Set-Änderung aufgerufen (ein einziger `safeExerciseSets`-Durchlauf)
- `ExercisesOverviewCard` und `RestTimerCard` erhalten vorberechnete Werte als Parameter (keine eigenen Queries)

### 2.3 Neue CalcEngine-Methode

Die `ProgressionAnalyseCalcEngine` hat bereits `allAnalyses` als berechnete Property (umbenannt von der früheren privaten `allAnalyses`-Property, jetzt public). Für die Workout-gefilterte Analyse wird eine neue Methode ergänzt:

```swift
// In ProgressionAnalyseCalcEngine.swift

/// Analysiert nur die Übungen, die in der übergebenen Session trainiert wurden.
/// Die Analyse selbst bleibt global (alle historischen Sessions).
func analysesForSession(_ session: StrengthSession) -> [ProgressionAnalysis] {
    let workoutExerciseNames: Set<String> = Set(
        session.safeExerciseSets.compactMap { set -> String? in
            let name = set.exerciseNameSnapshot
            return name.isEmpty ? nil : name
        }
    )
    return exercises
        .filter { workoutExerciseNames.contains($0.name) }
        .sorted { $0.name < $1.name }
        .map { analysis(for: $0) }
}
```

### 2.4 Neue View-Komponenten

| View | Typ | Aufgerufen von |
|---|---|---|
| `ExerciseProgressionView` | Kompakte Einzel-Übungs-Analyse (Sparklines + Stats + Vergleich) | ActiveSetCard, StrengthDetailView (pro Übung) |
| `WorkoutAnalyseView` | Workout-Übersicht (OverviewCard + ExerciseCard-Liste) | StrengthDetailView (Header) |
| `MiniSparkline` | Minimalistischer Trend-Chart (SwiftUI Charts) | ExerciseProgressionView |
| `LastWorkoutCompareCard` | Prominenter Vergleich: letzte Session vs. aktuell | ExerciseProgressionView |

### 2.5 ViewModel-Strategie für neue Views

Die neuen Views folgen dem bestehenden Muster:

| View | ViewModel-Ansatz | Begründung |
|---|---|---|
| `ExerciseProgressionView` | **Kein eigenes ViewModel** — erhält alle Daten als Parameter | Wird aus dem bereits berechneten `ProgressionViewModel`-Cache oder `ActiveWorkoutView`-Cache gespeist. Keine eigenen Queries. |
| `WorkoutAnalyseView` | **Eigenes `@State private var viewModel = ProgressionViewModel()`** | Benötigt Session-gefilterte Neuberechnung. Nutzt `.task {}` + `.onChange(of:)` wie `ProgressionAnalyseView`. |
| `MiniSparkline` | Kein ViewModel — pure View mit `[TrendPoint]` Input | Reine Darstellung. |
| `LastWorkoutCompareCard` | Kein ViewModel — pure View mit Snapshot + Sets Input | Reine Darstellung, Berechnung inline. |

---

## 3. Feature-Details

### 3.1 ActiveSetCard → Einzel-Übungsanalyse

#### Trigger & Platzierung

- Neuer Button **unterhalb** des bestehenden Anleitungs-Buttons (`figure.run.square.stack`), in eigener Zeile
- Icon: `brain.head.profile` mit blauem Akzent (`.blue`) auf `.ultraThinMaterial`-Circle
- Label: „Analyse" als kleine Caption neben dem Icon
- Navigation: `NavigationLink` (Push) innerhalb des bestehenden NavigationStack

#### Sichtbarkeit

- Button ist **nur sichtbar**, wenn historische Daten für diese Übung existieren
- Prüfung über die bereits in `ActiveWorkoutView` vorhandenen `historicalSessions`
- Keine Daten vorhanden → Button wird **nicht gerendert** (kein deaktivierter Zustand)

#### Daten-Fluss (Performance-konform)

Die Berechnung erfolgt **in `ActiveWorkoutView`**, nicht in der `ActiveSetCard`. Das folgt dem bestehenden Cache-Pattern:

```swift
// In ActiveWorkoutView.swift — neue Cache-Properties

@State private var cachedExerciseAnalyses: [String: ProgressionAnalysis] = [:]
@State private var cachedOneRMData: [String: [TrendPoint]] = [:]
@State private var cachedVolumeData: [String: [TrendPoint]] = [:]
@State private var cachedLastSnapshots: [String: SessionSnapshot] = [:]

/// Berechnet Progressions-Daten für alle Übungen der aktuellen Session.
/// Aufrufen in .task {} und nach Set-Completion.
private func refreshProgressionAnalyses() {
    let calcEngine = ProgressionCalcEngine()
    let exerciseNames = Set(session.safeExerciseSets.map { $0.exerciseName })
    
    for name in exerciseNames {
        // Snapshots extrahieren
        let snapshots = calcEngine.extractSnapshots(for: name, from: historicalSessions)
        guard !snapshots.isEmpty else { continue }
        
        // Letzten Snapshot cachen
        cachedLastSnapshots[name] = snapshots.first
        
        // 1RM-Trend
        cachedOneRMData[name] = Array(snapshots.reversed()).compactMap { snapshot -> TrendPoint? in
            guard let oneRM = snapshot.estimatedOneRM else { return nil }
            return TrendPoint(trendDate: snapshot.date, trendValue: oneRM)
        }
        
        // Volumen-Trend
        cachedVolumeData[name] = Array(snapshots.reversed()).map {
            TrendPoint(trendDate: $0.date, trendValue: $0.totalVolume)
        }
        
        // Volle Analyse (benötigt Exercise-Objekt)
        if let exercise = session.safeExerciseSets.first(where: { $0.exerciseName == name })?.exercise {
            cachedExerciseAnalyses[name] = calcEngine.analyze(
                exercise: exercise,
                sessions: historicalSessions
            )
        }
    }
}
```

Die `ActiveSetCard` erhält dann vorberechnete Werte:

```swift
// Erweiterte ActiveSetCard Properties
let hasHistoricalData: Bool
let progressionAnalysis: ProgressionAnalysis?
let oneRMData: [TrendPoint]
let volumeData: [TrendPoint]
let lastSessionSnapshot: SessionSnapshot?
let currentSetsForExercise: [ExerciseSet]
```

#### Code-Skizze: Button in ActiveSetCard

```swift
// In ActiveSetCard.swift — nach dem bestehenden Anleitungs-Button,
// VOR dem GlassDivider, in eigener Zeile

// Analyse-Button
if hasHistoricalData, let analysis = progressionAnalysis {
    NavigationLink {
        ExerciseProgressionView(
            analysis: analysis,
            oneRMData: oneRMData,
            volumeData: volumeData,
            lastSessionSnapshot: lastSessionSnapshot,
            currentSessionSets: currentSetsForExercise
        )
    } label: {
        HStack(spacing: 8) {
            Image(systemName: "brain.head.profile")
                .font(.subheadline)
                .foregroundStyle(.blue)
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().fill(Color.white.opacity(0.06)))

            Text("Analyse")
                .font(.subheadline)
                .foregroundStyle(.blue)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
    .buttonStyle(.plain)
}
```

### 3.2 ExerciseProgressionView – Kompakte Analyse

Die neue View ist bewusst kompakt gehalten. **Kein eigenes ViewModel** — alle Daten kommen als Parameter.

#### Layout-Aufbau (von oben nach unten)

1. **Übungsname** als Titel (`.headline`) mit Trend-Icon und Trend-Farbe
2. **LastWorkoutCompareCard** – prominente Vergleichs-Section
3. **Zwei Mini-Sparklines** nebeneinander: 1RM-Trend (links) und Volumen-Trend (rechts)
4. **ProgressionInsightCard** (bestehende Komponente) – Empfehlung, Rep-Fortschritt, Trend, Details
5. **Kompakte Stats-Zeile**: Sessions | Zuletzt | Level

#### Code-Skizze: ExerciseProgressionView

```swift
// ExerciseProgressionView.swift

import SwiftUI

struct ExerciseProgressionView: View {
    let analysis: ProgressionAnalysis
    let oneRMData: [TrendPoint]
    let volumeData: [TrendPoint]
    let lastSessionSnapshot: SessionSnapshot?
    let currentSessionSets: [ExerciseSet]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // 1. Header mit Trend
                headerSection

                // 2. Letztes-Workout-Vergleich
                if let lastSnapshot = lastSessionSnapshot {
                    LastWorkoutCompareCard(
                        lastSnapshot: lastSnapshot,
                        currentSets: currentSessionSets
                    )
                }

                // 3. Mini-Sparklines
                if oneRMData.count >= 2 || volumeData.count >= 2 {
                    HStack(spacing: 12) {
                        if oneRMData.count >= 2 {
                            MiniSparkline(title: "1RM", unit: "kg", data: oneRMData)
                        }
                        if volumeData.count >= 2 {
                            MiniSparkline(title: "Volumen", unit: "kg", data: volumeData)
                        }
                    }
                }

                // 4. Bestehende InsightCard (Wiederverwendung)
                ProgressionInsightCard(analysis: analysis)

                // 5. Stats
                statsRow
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(analysis.exerciseName)
                    .font(.headline)
                    .lineLimit(1)
            }
        }
    }

    // Header-Bereich mit Trend-Icon und Farbe
    @ViewBuilder
    private var headerSection: some View {
        HStack(spacing: 10) {
            Image(systemName: analysis.trend.icon)
                .font(.title2)
                .foregroundStyle(trendColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(analysis.trend.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(trendColor)
                if analysis.currentWeight > 0 {
                    Text(String(format: "Aktuell: %.1f kg", analysis.currentWeight))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .glassCard()
    }

    // Kompakte Stats-Zeile
    @ViewBuilder
    private var statsRow: some View {
        HStack {
            statItem(label: "Sessions", value: "\(analysis.sessionsAnalyzed)")
            Spacer()
            statItem(label: "Zuletzt", value: daysText)
            Spacer()
            statItem(label: "Level", value: analysis.trainingLevel.displayName)
        }
        .glassCard()
    }

    private var daysText: String {
        let days = analysis.daysSinceLastSession
        if days == 0 { return "Heute" }
        if days == 1 { return "Gestern" }
        return "Vor \(days)d"
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.weight(.semibold))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var trendColor: Color {
        switch analysis.trend {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        case .volatile: return .yellow
        case .insufficient: return .secondary
        }
    }
}
```

#### MiniSparkline-Komponente

```swift
// MiniSparkline.swift

import SwiftUI
import Charts

struct MiniSparkline: View {
    let title: String
    let unit: String
    let data: [TrendPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Titel + letzter Wert
            HStack {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                if let last = data.last {
                    Text(String(format: "%.1f %@", last.trendValue, unit))
                        .font(.caption.weight(.semibold).monospacedDigit())
                }
            }

            // Kompakter Chart
            Chart(data) { point in
                LineMark(
                    x: .value("Datum", point.trendDate),
                    y: .value(unit, point.trendValue)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(.init(lineWidth: 2))
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 80)
        }
        .glassCard()
    }
}
```

#### LastWorkoutCompareCard

```swift
// LastWorkoutCompareCard.swift

import SwiftUI

struct LastWorkoutCompareCard: View {
    let lastSnapshot: SessionSnapshot
    let currentSets: [ExerciseSet]

    // Berechnete Werte aus den aktuellen Sets (inline, keine CalcEngine nötig)
    private var currentWeight: Double {
        currentSets
            .filter { $0.setKind == .work && $0.isCompleted }
            .compactMap { $0.weight > 0 ? $0.weight : nil }
            .max() ?? 0
    }

    private var currentReps: [Int] {
        currentSets
            .filter { $0.setKind == .work && $0.isCompleted }
            .map { $0.reps }
    }

    private var currentVolume: Double {
        currentSets
            .filter { $0.setKind == .work && $0.isCompleted }
            .map { Double($0.reps) * $0.weight }
            .reduce(0, +)
    }

    private var currentOneRM: Double? {
        currentSets
            .filter { $0.setKind == .work && $0.isCompleted && $0.reps > 0 && $0.weight > 0 }
            .compactMap { $0.weight * (1.0 + Double($0.reps) / 30.0) }
            .max()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundStyle(.blue)
                Text("Vergleich")
                    .font(.headline)
            }

            compareRow(label: "Gewicht", last: lastSnapshot.weight, current: currentWeight, format: "%.1f kg")
            compareRow(label: "Reps", last: Double(lastSnapshot.minReps), current: Double(currentReps.min() ?? 0), format: "%.0f Wdh.")
            compareRow(label: "Volumen", last: lastSnapshot.totalVolume, current: currentVolume, format: "%.0f kg")

            if let lastRM = lastSnapshot.estimatedOneRM, let curRM = currentOneRM {
                compareRow(label: "Gesch. 1RM", last: lastRM, current: curRM, format: "%.1f kg")
            }
        }
        .glassCard()
    }

    @ViewBuilder
    private func compareRow(label: String, last: Double, current: Double, format: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)

            Text(String(format: format, last))
                .font(.subheadline.monospacedDigit())
                .frame(maxWidth: .infinity)

            HStack(spacing: 4) {
                Image(systemName: current > last ? "arrow.up" : current < last ? "arrow.down" : "arrow.right")
                    .font(.caption)
                Text(String(format: format, current))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
            }
            .foregroundStyle(current > last ? .green : current < last ? .orange : .blue)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
```

### 3.3 StrengthDetailView – Pro-Übung-Analyse

#### Trigger & Platzierung

- Unter den Satz-Details jeder Übung erscheint eine neue Zeile
- Aufbau: `HStack` mit `brain.head.profile` Icon + „Progression anzeigen" + Chevron
- Styling: Wie die bestehenden Action-Buttons (`.blue.opacity(0.15)` Background, `.blue` Foreground)
- Navigation: `NavigationLink` (Push) zur `ExerciseProgressionView`

#### Sichtbarkeit

- Nur sichtbar wenn historische Snapshots > 0 für diese Übung vorhanden sind
- Keine Daten → Zeile wird nicht gerendert

#### Daten-Kontext

Im Gegensatz zum aktiven Workout gibt es hier keinen „Heute"-Vergleich. Stattdessen vergleicht die `LastWorkoutCompareCard` **diese Session** (als „Aktuell") mit der **Session davor** (als „Letztes Mal").

#### ViewModel-Integration

Die `StrengthDetailView` nutzt einen lokalen Cache mit Lazy-Berechnung:

```swift
// In StrengthDetailView.swift — neue Properties

@Query(filter: #Predicate<StrengthSession> { $0.isCompleted }, sort: \StrengthSession.date, order: .reverse)
private var allCompletedSessions: [StrengthSession]

@State private var exerciseAnalysisCache: [String: ProgressionAnalysis] = [:]
@State private var exerciseSnapshotCache: [String: [SessionSnapshot]] = [:]

private func ensureAnalysisCached(for exerciseName: String) {
    guard exerciseAnalysisCache[exerciseName] == nil else { return }
    let calcEngine = ProgressionCalcEngine()
    let snapshots = calcEngine.extractSnapshots(for: exerciseName, from: allCompletedSessions)
    exerciseSnapshotCache[exerciseName] = snapshots
    
    if let exercise = session.safeExerciseSets.first(where: { $0.exerciseName == exerciseName })?.exercise {
        exerciseAnalysisCache[exerciseName] = calcEngine.analyze(exercise: exercise, sessions: allCompletedSessions)
    }
}
```

#### Code-Skizze: Integration in exerciseDetailCard

```swift
// In StrengthDetailView.swift — am Ende von exerciseDetailCard(),
// nach dem ForEach der Satz-Details

let snapshots = exerciseSnapshotCache[name] ?? []
if !snapshots.isEmpty, let analysis = exerciseAnalysisCache[name] {
    NavigationLink {
        ExerciseProgressionView(
            analysis: analysis,
            oneRMData: snapshots.reversed().compactMap { s -> TrendPoint? in
                guard let oneRM = s.estimatedOneRM else { return nil }
                return TrendPoint(trendDate: s.date, trendValue: oneRM)
            },
            volumeData: snapshots.reversed().map {
                TrendPoint(trendDate: $0.date, trendValue: $0.totalVolume)
            },
            lastSessionSnapshot: snapshots.dropFirst().first,
            currentSessionSets: sets
        )
    } label: {
        HStack(spacing: 8) {
            Image(systemName: "brain.head.profile")
                .foregroundStyle(.blue)
            Text("Progression anzeigen")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
        .foregroundStyle(.blue)
    }
    .buttonStyle(.plain)
    .onAppear { ensureAnalysisCached(for: name) }
}
```

### 3.4 StrengthDetailView – Workout-Übersicht (Header)

#### Trigger & Platzierung

```swift
// In StrengthDetailView.swift — im .toolbar { } Block

ToolbarItem(placement: .topBarTrailing) {
    NavigationLink {
        WorkoutAnalyseView(session: session)
    } label: {
        Image(systemName: "brain.head.profile")
            .foregroundStyle(.blue)
    }
}
```

#### WorkoutAnalyseView — mit eigenem ProgressionViewModel

Diese View nutzt ein eigenes `ProgressionViewModel`, das die volle Berechnung durchführt. Die View filtert die Anzeige dann auf die Workout-Übungen. Das folgt exakt dem Pattern der `ProgressionAnalyseView`:

```swift
// WorkoutAnalyseView.swift

import SwiftData
import SwiftUI

struct WorkoutAnalyseView: View {

    let session: StrengthSession

    @Query(sort: \StrengthSession.date, order: .reverse)
    private var allSessions: [StrengthSession]

    @Query(sort: \Exercise.name)
    private var allExercises: [Exercise]

    @EnvironmentObject private var appSettings: AppSettings
    @State private var selectedExercise: Exercise?
    @State private var viewModel = ProgressionViewModel()

    // Übungsnamen dieses Workouts
    private var workoutExerciseNames: Set<String> {
        Set(session.safeExerciseSets.compactMap { set -> String? in
            let name = set.exerciseNameSnapshot
            return name.isEmpty ? nil : name
        })
    }

    // Gefilterte Daten — nur Übungen dieses Workouts
    private var workoutExercises: [Exercise] {
        viewModel.trainedExercises.filter { workoutExerciseNames.contains($0.name) }
    }

    private var workoutAnalyses: [ProgressionAnalysis] {
        viewModel.analyses.filter { workoutExerciseNames.contains($0.exerciseName) }
    }

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 16) {

                    // Hero-Card (gefiltert auf Workout-Übungen)
                    if !workoutAnalyses.isEmpty {
                        ProgressionOverviewCard(
                            improvingCount: workoutAnalyses.filter { $0.trend == .improving }.count,
                            stableCount: workoutAnalyses.filter { $0.trend == .stable || $0.trend == .volatile }.count,
                            decliningCount: workoutAnalyses.filter { $0.trend == .declining }.count,
                            needsDeload: workoutAnalyses.filter { $0.trend == .declining }.count >= 3
                        )
                    }

                    // Übungsliste (gefiltert)
                    VStack(spacing: 10) {
                        ForEach(workoutExercises) { exercise in
                            if let analysis = viewModel.analysis(for: exercise) {
                                ProgressionExerciseCard(analysis: analysis)
                                    .onTapGesture {
                                        selectedExercise = exercise
                                    }
                            }
                        }
                    }
                }
                .scrollViewContentPadding()
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Workout-Analyse")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedExercise) { exercise in
            if let analysis = viewModel.analysis(for: exercise) {
                ProgressionDetailView(
                    analysis: analysis,
                    oneRMData: viewModel.oneRMTrendMap[exercise.persistentModelID] ?? [],
                    volumeData: viewModel.volumeTrendMap[exercise.persistentModelID] ?? []
                )
            }
        }
        .task {
            viewModel.recalculate(sessions: allSessions, exercises: allExercises)
        }
        .onChange(of: allSessions) { _, new in
            viewModel.recalculate(sessions: new, exercises: allExercises)
        }
    }
}
```

**Wichtig:** Das ViewModel berechnet ALLE trainierten Übungen (wie im Analyse-Tab), aber die View filtert die Anzeige auf die Workout-Übungen. So können die vorberechneten `oneRMTrendMap`/`volumeTrendMap` Dictionaries direkt per `PersistentIdentifier` genutzt werden. Die `stableCount`-Berechnung zählt `.volatile` mit (konsistent mit `ProgressionViewModel.recalculate`).

---

## 4. Navigations-Fluss

### 4.1 Aktives Workout

```
ActiveWorkoutView → ActiveSetCard → brain.head.profile Button
    → PUSH → ExerciseProgressionView
```

### 4.2 Trainingsdetails – Pro Übung

```
StrengthDetailView → exerciseDetailCard → „Progression anzeigen"
    → PUSH → ExerciseProgressionView
```

### 4.3 Trainingsdetails – Workout-Übersicht

```
StrengthDetailView → Toolbar brain.head.profile
    → PUSH → WorkoutAnalyseView → Tap auf Übung
        → SHEET → ProgressionDetailView
```

### 4.4 Tab-Analyse (bestehend, unverändert)

```
BaseView Tab .analyse → ProgressionAnalyseView → Tap auf Übung
    → SHEET → ProgressionDetailView
```

---

## 5. Betroffene Dateien

### 5.1 Neue Dateien

| Datei | Beschreibung |
|---|---|
| `ExerciseProgressionView.swift` | Kompakte Einzel-Übungsanalyse (Mini-Sparklines + Stats + Vergleich). Kein eigenes ViewModel. |
| `WorkoutAnalyseView.swift` | Gefilterte Workout-Übersicht. Eigenes `@State ProgressionViewModel`. |
| `MiniSparkline.swift` | Kompakter Trend-Chart (80pt Höhe, SwiftUI Charts) |
| `LastWorkoutCompareCard.swift` | Vergleichskarte: letzte Session vs. aktuell |

### 5.2 Geänderte Dateien

| Datei | Änderung |
|---|---|
| `ProgressionAnalyseCalcEngine.swift` | Neue Methode: `analysesForSession(_:)` (optional, falls `WorkoutAnalyseView` die Filterung nicht client-seitig macht) |
| `ActiveSetCard.swift` | Neue Zeile mit `brain.head.profile` NavigationLink. Neue Input-Properties: `hasHistoricalData`, `progressionAnalysis`, `oneRMData`, `volumeData`, `lastSessionSnapshot`, `currentSetsForExercise` |
| `ActiveWorkoutView.swift` | Neue `@State`-Caches für Progressions-Analysen (`cachedExerciseAnalyses`, `cachedOneRMData`, `cachedVolumeData`, `cachedLastSnapshots`). Neue `refreshProgressionAnalyses()` Methode. Erweiterte Parameterübergabe an `ActiveSetCard`. |
| `StrengthDetailView.swift` | 1) `@Query` für `allCompletedSessions`. 2) Analyse-Cache + `ensureAnalysisCached(for:)`. 3) Analyse-Button pro Übung unter Satz-Details. 4) Toolbar-Icon für Workout-Übersicht. |

### 5.3 Unveränderte Dateien (Wiederverwendung)

- `ProgressionViewModel.swift` – wird 1:1 in `WorkoutAnalyseView` wiederverwendet
- `ProgressionOverviewCard.swift` – 1:1 wiederverwendet in `WorkoutAnalyseView`
- `ProgressionExerciseCard.swift` – 1:1 wiederverwendet in `WorkoutAnalyseView`
- `ProgressionInsightCard.swift` – 1:1 wiederverwendet in `ExerciseProgressionView`
- `ProgressionDetailView.swift` – als Sheet aus `WorkoutAnalyseView` aufgerufen
- `ProgressionCalcEngine.swift` – keine Änderung, wird intern genutzt
- `RecordsViewModel.swift`, `StatisticsViewModel.swift`, `SummaryViewModel.swift` – nicht betroffen

---

## 6. Implementierungsplan

Die Umsetzung erfolgt in 5 Schritten. Jeder Schritt ist unabhängig testbar.

| # | Schritt | Dateien | Testbar durch |
|---|---|---|---|
| 1 | UI-Komponenten bauen | `MiniSparkline.swift`, `LastWorkoutCompareCard.swift` | Previews mit Mock-Daten |
| 2 | ExerciseProgressionView | `ExerciseProgressionView.swift` | Preview mit Mock-ProgressionAnalysis |
| 3 | ActiveSetCard + ActiveWorkoutView | `ActiveSetCard.swift`, `ActiveWorkoutView.swift` | Live-Test: Satz abschließen → Analyse-Button erscheint → Push-Navigation |
| 4 | StrengthDetailView (Pro-Übung + Header) | `StrengthDetailView.swift` | Abgeschlossenes Workout öffnen → Analyse-Buttons testen |
| 5 | WorkoutAnalyseView | `WorkoutAnalyseView.swift`, optional `ProgressionAnalyseCalcEngine.swift` | Push aus StrengthDetailView-Header → Gefilterte Übersicht prüfen |

---

## 7. Design-Richtlinien

- Alle neuen Views verwenden `.glassCard()` und `AnimatedBackground`
- Icon: `brain.head.profile` in `.blue`, konsistent an allen drei Stellen
- Button-Styling: `.ultraThinMaterial` Circle (wie der bestehende Anleitungs-Button)
- Farbschema für Vergleichswerte: `.green` (↑), `.orange` (↓), `.blue` (→)
- MiniSparklines: `LineMark` mit `.catmullRom` Interpolation, `.chartXAxis(.hidden)`, `.chartYAxis(.hidden)`
- **Keine Business-Logik in Views** – CalcEngine berechnet alle Werte
- **Cache-Pattern konsistent**: Berechnungen in `refreshProgressionAnalyses()` / `ensureAnalysisCached(for:)`, nicht bei jedem Render
- **Kein Timer-Trigger**: `refreshProgressionAnalyses()` wird NICHT bei Timer-Ticks aufgerufen, nur bei Set-Completion und `.task {}`
- Kommentare im Code auf **Deutsch**, Variablen/Methoden auf **Englisch**

---

## 8. Edge Cases

| Situation | Verhalten |
|---|---|
| Übung nie trainiert | Button nicht sichtbar (kein deaktivierter Zustand) |
| Nur 1 Session | Sparklines ausgeblendet (< 2 Datenpunkte), InsightCard zeigt „Mehr Daten sammeln" |
| Körpergewichts-Übung (0 kg) | Gewichts-Vergleich zeigt „Körpergewicht" statt 0 kg, 1RM-Sparkline wird ausgeblendet |
| Superset-Übungen | Jede Übung im Superset erhält ihren eigenen Analyse-Button |
| Keine Exercise-Relationship | Analyse arbeitet mit `exerciseNameSnapshot` – funktioniert auch ohne Relationship. `cachedExerciseAnalyses` bleibt leer → Button nicht sichtbar |
| Workout mit nur Warmup-Sätzen | Work-Sets = 0 → Kein Snapshot → Button nicht sichtbar |
| Übung in laufender Session noch nicht begonnen | LastWorkoutCompareCard zeigt nur „Letztes Mal"-Spalte, „Heute" bleibt leer mit Hinweis „Noch keine Daten" |
| Timer-Ticks in ActiveWorkoutView | `refreshProgressionAnalyses()` wird NICHT bei Timer-Ticks aufgerufen — Performance bleibt stabil |

---

## 9. Abgrenzung

**Nicht im Scope dieses Features:**

- Keine Änderungen an der bestehenden `ProgressionAnalyseView` (Tab) oder `ProgressionViewModel`
- Keine Änderungen an `ProgressionCalcEngine` (nur optional die `AnalyseCalcEngine`)
- Kein neues Datenmodell – alle Daten kommen aus bestehenden Queries
- Keine Apple Watch Integration (nur iPhone)
- Keine Cardio/Outdoor-Analyse (nur Strength Sessions)
- Kein neues globales ViewModel in `MotionCoreApp.swift` – ViewModels bleiben View-lokal (`@State`)
