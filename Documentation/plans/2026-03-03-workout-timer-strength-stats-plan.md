# Workout-Erweiterung: RestTimer, ActiveWorkout & Kraft-Statistiken

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** RestTimerCard als Kreis-Timer mit Zeitanpassung, Volumen-Anzeige im Workout-Header, und eine neue Kraft-Statistiken-Ansicht mit Volumen-Trend und 1RM-Progression.

**Architecture:** Drei unabhängige Bereiche werden erweitert. Der RestTimer bekommt ein neues UI und einen `onAdjust`-Callback. `ActiveWorkoutStatus` erhält einen neuen `sessionVolume`-Parameter. Die Kraft-Statistiken werden durch eine neue `StrengthStatisticCalcEngine` und drei neue SwiftUI-Views ergänzt, die als drittes Segment in `StatsAndRecordsView` eingebunden werden.

**Tech Stack:** SwiftUI, Swift Charts, SwiftData, UIKit (Haptic Feedback), iOS 17+

---

## Kontext für den Implementierer

### Wichtige Konventionen

- Alle Views nutzen `.glassCard()` als Modifier für Cards
- `AnimatedBackground(showAnimatedBlob:)` ist der Standard-Hintergrund
- Datei-Header: Kopiere den Kommentar-Header aus einer bestehenden Datei (z.B. `RestTimerCard.swift`)
- `TrendPoint` ist bereits in `StatisticCalcEngine.swift` definiert — nicht neu erstellen
- `SummaryTimeframe` (week/month/year/all) ist in `SummaryTimeframe.swift` definiert
- `TimeframePicker` ist eine fertige Komponente in `Views/Summary/Components/TimeframePicker.swift`
- `StatisticGridCard` existiert in `Views/Statistics/Workouts/Components/StatisticCard.swift`
- `EmptyState()` ist eine fertige Komponente für leere Listen

### Wichtige Modell-Facts

- `StrengthSession.totalVolume: Double` ist bereits berechnet (`weight × reps` aller Sets)
- `StrengthSession.safeExerciseSets: [ExerciseSet]` gibt die Sets sicher zurück
- `ExerciseSet.exerciseName: String` enthält den Übungsnamen
- `ExerciseSet.weight: Double` und `ExerciseSet.reps: Int` sind die Set-Werte

### Previews statt Tests

Da das Projekt keine XCTest-Unit-Tests hat, wird jeder Schritt mit SwiftUI `#Preview` verifiziert. Baue nach jeder Aufgabe das Projekt (`Cmd+B`) und prüfe die Preview.

---

## Task 1: RestTimerCard — Kreisförmiger Ring-Timer

**Files:**
- Modify: `MotionCore/Views/Workouts/Active/Components/RestTimerCard.swift`

### Schritt 1: `onAdjust`-Callback Parameter hinzufügen

Füge den neuen Parameter in die Struct-Definition ein:

```swift
struct RestTimerCard: View {
    @EnvironmentObject private var appSettings: AppSettings

    let remainingSeconds: Int
    let targetSeconds: Int
    let onSkip: () -> Void
    let onAdjust: (Int) -> Void   // NEU: delta in Sekunden (z.B. +15 oder -15)

    let nextExerciseName: String?
    let nextSetNumber: Int?
    let totalSetsForExercise: Int?
    // ...
}
```

### Schritt 2: `body` durch Kreis-Timer ersetzen

Ersetze den gesamten `body`:

```swift
var body: some View {
    VStack(spacing: 24) {
        // "Pause" Label
        Text("Pause")
            .font(.title2.bold())
            .foregroundStyle(.secondary)

        // Kreisförmiger Ring-Timer
        ringTimer

        // Zeitanpassung
        adjustButtons

        // Nächster Satz Info
        if let exerciseName = nextExerciseName,
           let setNumber = nextSetNumber,
           let totalSets = totalSetsForExercise {
            VStack(spacing: 4) {
                Text(exerciseName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text("Nächster: Satz \(setNumber) von \(totalSets)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        if nextExerciseName == nil {
            Text("Nächster Satz bereit in \(remainingSeconds) Sekunden")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }

        // Skip Button
        Button {
            onSkip()
        } label: {
            HStack {
                Image(systemName: "forward.fill")
                Text("Pause überspringen")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.blue, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    .glassCard()
}
```

### Schritt 3: `ringTimer` View hinzufügen

```swift
private var ringTimer: some View {
    ZStack {
        // Hintergrund-Ring
        Circle()
            .stroke(Color.primary.opacity(0.1), lineWidth: 14)

        // Fortschritts-Ring
        Circle()
            .trim(from: 0, to: progress)
            .stroke(
                LinearGradient(
                    colors: progressGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: 14, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .animation(.linear(duration: 1.0), value: remainingSeconds)

        // Zahl in der Mitte
        Text(formatRestTime(remainingSeconds))
            .font(.system(size: 72, weight: .bold, design: .rounded))
            .foregroundStyle(remainingSeconds > 10 ? Color.primary : Color.orange)
            .monospacedDigit()
            .contentTransition(.numericText())
    }
    .frame(width: 210, height: 210)
}
```

### Schritt 4: `adjustButtons` View hinzufügen

```swift
private var adjustButtons: some View {
    HStack {
        Button {
            onAdjust(-15)
        } label: {
            Label("−15s", systemImage: "minus.circle.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
        }

        Spacer()

        Button {
            onAdjust(15)
        } label: {
            Label("+15s", systemImage: "plus.circle.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
    .padding(.horizontal, 8)
}
```

### Schritt 5: `progressBar` Property entfernen

Entferne die gesamte `progressBar`-Property — sie wird durch `ringTimer` ersetzt.

### Schritt 6: Preview aktualisieren

Füge `onAdjust: { _ in }` in alle Preview-Initialisierungen ein:

```swift
#Preview("Rest Timer Card") {
    ZStack {
        AnimatedBackground(showAnimatedBlob: true)
        VStack(spacing: 20) {
            RestTimerCard(
                remainingSeconds: 90,
                targetSeconds: 90,
                onSkip: {},
                onAdjust: { _ in },
                nextExerciseName: "Bankdrücken",
                nextSetNumber: 3,
                totalSetsForExercise: 4
            )
            RestTimerCard(
                remainingSeconds: 5,
                targetSeconds: 90,
                onSkip: {},
                onAdjust: { _ in },
                nextExerciseName: nil,
                nextSetNumber: nil,
                totalSetsForExercise: nil
            )
        }
        .padding()
    }
    .environmentObject(AppSettings.shared)
}
```

### Schritt 7: Build verifizieren

`Cmd+B` — Ziel: kein Compile-Fehler. Preview prüfen.

### Schritt 8: Commit

```bash
git add MotionCore/Views/Workouts/Active/Components/RestTimerCard.swift
git commit -m "feat(RestTimerCard): Kreisförmiger Ring-Timer mit +/-15s Zeitanpassung"
```

---

## Task 2: ActiveWorkoutView — `onAdjust` Wiring + Haptic

**Files:**
- Modify: `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift`

### Schritt 1: Haptic-Generator hinzufügen

Direkt neben dem bestehenden `hapticGenerator`:

```swift
private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
private let completionHaptic = UINotificationFeedbackGenerator()  // NEU
```

### Schritt 2: `onAdjust`-Handler implementieren

Füge diese Methode in den `// MARK: - Actions`-Abschnitt ein:

```swift
private func adjustRestTimer(delta: Int) {
    let newValue = restTimerSeconds + delta
    let clamped = max(5, min(300, newValue))  // 5s bis 5min
    restTimerSeconds = clamped
}
```

### Schritt 3: Haptic bei Timer-Ablauf auslösen

Füge ein `.onChange` Modifier am ZStack in `body` hinzu (nach den bestehenden `.onChange`-Modifiern):

```swift
.onChange(of: restTimerSeconds) { _, newValue in
    if newValue == 0 && isResting {
        completionHaptic.notificationOccurred(.success)
    }
}
```

### Schritt 4: `RestTimerCard`-Aufruf um `onAdjust` ergänzen

Suche den `RestTimerCard`-Aufruf in `scrollContent` und füge den neuen Parameter ein:

```swift
RestTimerCard(
    remainingSeconds: restTimerSeconds,
    targetSeconds: appSettings.defaultRestDuration,
    onSkip: { stopRestTimer() },
    onAdjust: { delta in adjustRestTimer(delta: delta) },  // NEU
    nextExerciseName: ...,
    nextSetNumber: ...,
    totalSetsForExercise: ...
)
```

### Schritt 5: Build verifizieren

`Cmd+B` — kein Compile-Fehler.

### Schritt 6: Commit

```bash
git add MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift
git commit -m "feat(ActiveWorkoutView): onAdjust Wiring und Haptic-Feedback beim Pausenende"
```

---

## Task 3: ActiveWorkoutStatus — Volumen-Anzeige

**Files:**
- Modify: `MotionCore/Views/Workouts/Active/Components/ActiveWorkoutStatus.swift`

### Schritt 1: Neuen Parameter hinzufügen

```swift
struct ActiveWorkoutStatus: View {
    let isPaused: Bool
    let formattedElapsedTime: String
    let completedSets: Int
    let totalSets: Int
    let progress: Double
    let sessionVolume: Double   // NEU
    // ...
}
```

### Schritt 2: Formatierungs-Helper hinzufügen

```swift
private var formattedVolume: String {
    if sessionVolume >= 1000 {
        let thousands = sessionVolume / 1000
        return String(format: "%.1f t", thousands)
    } else {
        return String(format: "%.0f kg", sessionVolume)
    }
}
```

### Schritt 3: `body` mit drei Spalten ersetzen

```swift
var body: some View {
    VStack(spacing: 12) {
        HStack(alignment: .top) {
            // Timer (links)
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: isPaused ? "pause.circle.fill" : "clock.fill")
                        .foregroundStyle(isPaused ? .orange : .blue)
                    Text(formattedElapsedTime)
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(.primary)
                }
                if isPaused {
                    Text("Pausiert")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Volumen (Mitte) — nur anzeigen wenn > 0
            if sessionVolume > 0 {
                VStack(spacing: 2) {
                    Text(formattedVolume)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text("Volumen")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .transition(.scale.combined(with: .opacity))
            }

            // Sätze (rechts)
            VStack(spacing: 2) {
                Text("\(completedSets)/\(totalSets)")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                Text("Sätze")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .animation(.easeInOut(duration: 0.3), value: sessionVolume > 0)

        // Fortschrittsbalken (bleibt unverändert)
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.primary.opacity(0.1))
                    .frame(height: 8)
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .green],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * max(0, min(1, progress)), height: 8)
                    .animation(.easeInOut, value: progress)
            }
        }
        .frame(height: 8)
    }
    .padding()
    .background(.ultraThinMaterial)
}
```

### Schritt 4: Build verifizieren

`Cmd+B` — wird mit Fehler schlagen, weil der Aufrufer `sessionVolume` noch nicht übergibt. Das ist erwartet.

### Schritt 5: Commit (noch mit Fehler — wird in Task 4 behoben)

Noch nicht committen — erst nach Task 4.

---

## Task 4: ActiveWorkoutView — `sessionVolume` berechnen und übergeben

**Files:**
- Modify: `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift`

### Schritt 1: Berechnete Property hinzufügen

Im `// MARK: - Derived`-Abschnitt:

```swift
private var sessionVolume: Double {
    session.safeExerciseSets
        .filter { $0.isCompleted }
        .reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
}
```

### Schritt 2: `ActiveWorkoutStatus`-Aufruf ergänzen

```swift
ActiveWorkoutStatus(
    isPaused: sessionManager.isPaused,
    formattedElapsedTime: sessionManager.formattedElapsedTime,
    completedSets: session.completedSets,
    totalSets: session.totalSets,
    progress: session.progress,
    sessionVolume: sessionVolume   // NEU
)
```

### Schritt 3: Build verifizieren

`Cmd+B` — kein Compile-Fehler.

### Schritt 4: Commit (Tasks 3+4 zusammen)

```bash
git add MotionCore/Views/Workouts/Active/Components/ActiveWorkoutStatus.swift
git add MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift
git commit -m "feat(ActiveWorkout): Session-Volumen-Anzeige im Workout-Header"
```

---

## Task 5: StrengthStatisticCalcEngine

**Files:**
- Create: `MotionCore/Services/Calculation/StrengthStatisticCalcEngine.swift`

### Schritt 1: Datei erstellen

```swift
//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StrengthStatisticCalcEngine.swift                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-03                                                       /
// Beschreibung  : Berechnungen für Kraft-Statistiken                               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

struct StrengthStatisticCalcEngine {

    // MARK: - Input

    let sessions: [StrengthSession]

    // MARK: - Initializer

    init(sessions: [StrengthSession]) {
        self.sessions = sessions
    }

    // MARK: - Timeframe-Filter

    func filtered(by timeframe: SummaryTimeframe) -> StrengthStatisticCalcEngine {
        let now = Date()
        let calendar = Calendar.current
        let filtered: [StrengthSession]

        switch timeframe {
        case .week:
            let start = calendar.date(byAdding: .day, value: -7, to: now)!
            filtered = sessions.filter { $0.date >= start }
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: now)!
            filtered = sessions.filter { $0.date >= start }
        case .year:
            let start = calendar.date(byAdding: .year, value: -1, to: now)!
            filtered = sessions.filter { $0.date >= start }
        case .all:
            filtered = sessions
        }

        return StrengthStatisticCalcEngine(sessions: filtered)
    }

    // MARK: - Kennzahlen

    var totalSessions: Int {
        sessions.count
    }

    var totalVolume: Double {
        sessions.reduce(0.0) { $0 + $1.totalVolume }
    }

    var averageVolumePerSession: Double {
        guard !sessions.isEmpty else { return 0 }
        return totalVolume / Double(sessions.count)
    }

    var averageSetsPerSession: Double {
        guard !sessions.isEmpty else { return 0 }
        let total = sessions.reduce(0) { $0 + $1.totalSets }
        return Double(total) / Double(sessions.count)
    }

    // MARK: - Trend-Daten

    /// Volumen pro Session, chronologisch sortiert
    var volumeTrend: [TrendPoint] {
        sessions
            .filter { $0.totalVolume > 0 }
            .sorted { $0.date < $1.date }
            .map { TrendPoint(trendDate: $0.date, trendValue: $0.totalVolume) }
    }

    // MARK: - Übungs-spezifisch

    /// Alle trainierten Übungsnamen (alphabetisch, dedupliziert)
    var allTrainedExerciseNames: [String] {
        let names = sessions.flatMap { session in
            session.safeExerciseSets.map { $0.exerciseName }
        }
        return Array(Set(names)).sorted()
    }

    /// Geschätzter 1RM (Epley-Formel) pro Session für eine Übung
    /// Epley: weight × (1 + reps / 30) — nur der höchste Wert je Session
    func estimatedOneRM(for exerciseName: String) -> [TrendPoint] {
        sessions
            .sorted { $0.date < $1.date }
            .compactMap { session -> TrendPoint? in
                let relevantSets = session.safeExerciseSets.filter {
                    $0.exerciseName == exerciseName
                        && $0.weight > 0
                        && $0.reps > 0
                        && $0.isCompleted
                }
                guard !relevantSets.isEmpty else { return nil }
                let maxOneRM = relevantSets
                    .map { $0.weight * (1.0 + Double($0.reps) / 30.0) }
                    .max() ?? 0
                return TrendPoint(trendDate: session.date, trendValue: maxOneRM)
            }
    }
}
```

### Schritt 2: Build verifizieren

`Cmd+B` — kein Compile-Fehler. `TrendPoint` ist in `StatisticCalcEngine.swift` bereits definiert und sichtbar.

### Schritt 3: Commit

```bash
git add MotionCore/Services/Calculation/StrengthStatisticCalcEngine.swift
git commit -m "feat(StrengthStatisticCalcEngine): Berechnungen für Volumen-Trend und 1RM-Progression"
```

---

## Task 6: StrengthVolumeChart

**Files:**
- Create: `MotionCore/Views/Statistics/Strength/Components/StrengthVolumeChart.swift`

Erstelle zuerst das Verzeichnis `Views/Statistics/Strength/Components/` in Xcode (New Group).

### Schritt 1: Datei erstellen

```swift
//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StrengthVolumeChart.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-03                                                       /
// Beschreibung  : Balkendiagramm für Trainingsvolumen je Session                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import Charts

struct StrengthVolumeChart: View {
    let data: [TrendPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Volumen-Trend")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text("kg")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()

            if data.isEmpty {
                Text("Noch keine Daten vorhanden")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .multilineTextAlignment(.center)
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("Datum", point.trendDate, unit: .day),
                        y: .value("Volumen", point.trendValue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(4)
                }
                .frame(minHeight: 220)
                .padding()
            }
        }
        .glassCard()
    }
}
```

### Schritt 2: Build verifizieren (`Cmd+B`)

### Schritt 3: Commit

```bash
git add MotionCore/Views/Statistics/Strength/Components/StrengthVolumeChart.swift
git commit -m "feat(StrengthVolumeChart): Balkendiagramm für Trainingsvolumen-Trend"
```

---

## Task 7: StrengthOneRMChart

**Files:**
- Create: `MotionCore/Views/Statistics/Strength/Components/StrengthOneRMChart.swift`

### Schritt 1: Datei erstellen

```swift
//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StrengthOneRMChart.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-03                                                       /
// Beschreibung  : 1RM-Progressionschart je Übung (Epley-Formel)                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import Charts

struct StrengthOneRMChart: View {
    let exerciseNames: [String]
    let calcEngine: StrengthStatisticCalcEngine

    @State private var selectedExercise: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("1RM-Progression")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text("kg (est.)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding([.horizontal, .top])

            // Übungs-Picker
            if !exerciseNames.isEmpty {
                Menu {
                    ForEach(exerciseNames, id: \.self) { name in
                        Button(name) {
                            selectedExercise = name
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedExercise.isEmpty ? "Übung wählen" : selectedExercise)
                            .font(.subheadline)
                            .foregroundStyle(selectedExercise.isEmpty ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                }
                .onAppear {
                    if selectedExercise.isEmpty, let first = exerciseNames.first {
                        selectedExercise = first
                    }
                }
            }

            // Chart
            let oneRMData = selectedExercise.isEmpty ? [] : calcEngine.estimatedOneRM(for: selectedExercise)

            if oneRMData.isEmpty {
                Text(selectedExercise.isEmpty ? "Bitte Übung wählen" : "Keine Daten für diese Übung")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .multilineTextAlignment(.center)
            } else {
                Chart(oneRMData) { point in
                    LineMark(
                        x: .value("Datum", point.trendDate),
                        y: .value("1RM", point.trendValue)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(.init(lineWidth: 2.5))
                    .foregroundStyle(Color.orange)

                    PointMark(
                        x: .value("Datum", point.trendDate),
                        y: .value("1RM", point.trendValue)
                    )
                    .symbol(.circle)
                    .symbolSize(45)
                    .foregroundStyle(Color.orange)

                    AreaMark(
                        x: .value("Datum", point.trendDate),
                        y: .value("1RM", point.trendValue)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(minHeight: 220)
                .padding()
            }
        }
        .glassCard()
    }
}
```

### Schritt 2: Build verifizieren (`Cmd+B`)

### Schritt 3: Commit

```bash
git add MotionCore/Views/Statistics/Strength/Components/StrengthOneRMChart.swift
git commit -m "feat(StrengthOneRMChart): 1RM-Progressionschart mit Übungs-Picker"
```

---

## Task 8: StrengthStatisticView

**Files:**
- Create: `MotionCore/Views/Statistics/Strength/View/StrengthStatisticView.swift`

Erstelle zuerst das Verzeichnis `Views/Statistics/Strength/View/` in Xcode (New Group).

### Schritt 1: Datei erstellen

```swift
//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StrengthStatisticView.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-03                                                       /
// Beschreibung  : Hauptansicht für Kraft-Statistiken                               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct StrengthStatisticView: View {

    @Query(sort: \StrengthSession.date, order: .reverse)
    private var allSessions: [StrengthSession]

    @EnvironmentObject private var appSettings: AppSettings

    @State private var selectedTimeframe: SummaryTimeframe = .all

    private let gridColumns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    private var calc: StrengthStatisticCalcEngine {
        StrengthStatisticCalcEngine(sessions: allSessions).filtered(by: selectedTimeframe)
    }

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    // Zeitraum-Filter
                    TimeframePicker(selection: $selectedTimeframe)

                    // Kennzahlen-Grid
                    LazyVGrid(columns: gridColumns, spacing: 20) {
                        StatisticGridCard(
                            icon: .system("figure.strengthtraining.traditional"),
                            title: "Kraft-Sessions",
                            valueView: Text("\(calc.totalSessions)"),
                            color: .blue
                        )
                        StatisticGridCard(
                            icon: .system("scalemass.fill"),
                            title: "Gesamt Volumen",
                            valueView: Text(formattedVolume(calc.totalVolume)),
                            color: .purple
                        )
                        StatisticGridCard(
                            icon: .system("chart.bar.fill"),
                            title: "⌀ Volumen",
                            valueView: Text(formattedVolume(calc.averageVolumePerSession)),
                            color: .indigo
                        )
                        StatisticGridCard(
                            icon: .system("list.number"),
                            title: "⌀ Sätze",
                            valueView: Text(String(format: "%.1f", calc.averageSetsPerSession)),
                            color: .teal
                        )
                    }

                    // Volumen-Trend
                    StrengthVolumeChart(data: calc.volumeTrend)

                    // 1RM-Progression
                    StrengthOneRMChart(
                        exerciseNames: calc.allTrainedExerciseNames,
                        calcEngine: calc
                    )
                }
                .scrollViewContentPadding()
            }
            .scrollIndicators(.hidden)

            if allSessions.isEmpty {
                EmptyState()
            }
        }
    }

    private func formattedVolume(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1f t", value / 1000)
        } else {
            return String(format: "%.0f kg", value)
        }
    }
}

// MARK: - Preview

#Preview("Kraft Statistiken") {
    StrengthStatisticView()
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
}
```

### Schritt 2: Build verifizieren (`Cmd+B`)

Falls `StatisticGridCard` einen anderen Initialisierungs-Parameternamen hat, passe ihn an. Prüfe `Views/Statistics/Workouts/Components/StatisticCard.swift` für die korrekte Signatur.

### Schritt 3: Commit

```bash
git add MotionCore/Views/Statistics/Strength/View/StrengthStatisticView.swift
git commit -m "feat(StrengthStatisticView): Hauptansicht für Kraft-Statistiken"
```

---

## Task 9: StatsAndRecordsView — Kraft-Segment

**Files:**
- Modify: `MotionCore/Views/Statistics/StatsAndRecordsView.swift`

### Schritt 1: `StatsSegment` Enum erweitern

```swift
enum StatsSegment: String, CaseIterable, Identifiable {
    case statistics = "statistics"
    case records = "records"
    case strength = "strength"   // NEU

    var id: String { rawValue }

    var label: String {
        switch self {
        case .statistics: return "Statistiken"
        case .records: return "Rekorde"
        case .strength: return "Kraft"   // NEU
        }
    }
}
```

### Schritt 2: Switch-Statement erweitern

```swift
switch selectedSegment {
case .statistics:
    StatisticView()
case .records:
    RecordView()
case .strength:           // NEU
    StrengthStatisticView()
}
```

### Schritt 3: Build verifizieren (`Cmd+B`)

### Schritt 4: Preview verifizieren

Öffne die Preview von `StatsAndRecordsView` und prüfe, ob der neue Tab erscheint.

### Schritt 5: Commit

```bash
git add MotionCore/Views/Statistics/StatsAndRecordsView.swift
git commit -m "feat(StatsAndRecordsView): Kraft-Statistiken als drittes Segment"
```

---

## Abschluss

Nach allen 9 Tasks:

1. **Vollständiger Build** (`Cmd+B`) — kein Fehler
2. **Alle Previews** der geänderten Dateien prüfen
3. **Manueller Test** auf Simulator:
   - Aktives Workout starten → Satz abschließen → Volumen im Header prüfen
   - Pausentimer starten → Ring-Animation prüfen → +/- 15s testen
   - Stats → "Kraft" Tab öffnen → Timeframe wechseln
4. **Finaler Commit** falls nötig

---

## Dateien-Übersicht

| Status | Datei |
|---|---|
| NEU | `Services/Calculation/StrengthStatisticCalcEngine.swift` |
| NEU | `Views/Statistics/Strength/Components/StrengthVolumeChart.swift` |
| NEU | `Views/Statistics/Strength/Components/StrengthOneRMChart.swift` |
| NEU | `Views/Statistics/Strength/View/StrengthStatisticView.swift` |
| GEÄNDERT | `Views/Workouts/Active/Components/RestTimerCard.swift` |
| GEÄNDERT | `Views/Workouts/Active/Components/ActiveWorkoutStatus.swift` |
| GEÄNDERT | `Views/Workouts/Active/View/ActiveWorkoutView.swift` |
| GEÄNDERT | `Views/Statistics/StatsAndRecordsView.swift` |
