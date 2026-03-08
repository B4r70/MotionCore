# Timer-Sync Fix · Dynamic Island Redesign · RIR Auto-Progression — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix Background-Timer-Sync, Dynamic Island neu gestalten (Liquid Glass, blaue Gradient-Töne) und RIR-basierte Auto-Progression mit Empfehlungs-Badge implementieren.

**Architecture:** Drei unabhängige Bereiche. Bug-Fix in `ActiveWorkoutView` (scenePhase). Live Activity UI in `MotionCoreWidgetsLiveActivity.swift`. Progression: neues `progressionStep`-Feld in `Exercise`, neue `ProgressionCalcEngine`, neues `ProgressionBannerView`-Component, Integration in `ActiveWorkoutView`.

**Tech Stack:** SwiftUI, ActivityKit/WidgetKit, SwiftData, iOS 17+. Keine Unit-Tests — Verifikation über SwiftUI Previews + Xcode Simulator.

---

## Hinweise für alle Tasks

- Standard-Header (aus bestehender Datei kopieren) an den Anfang jeder neuen Swift-Datei
- Commit-Prefix-Konvention: `fix()`, `feat()`, `refactor()`
- Projektpfad: `/Users/bartosz/Developments/MotionCore/`
- Kein CLI-Build. Build-Verifikation: `Cmd+B` in Xcode, danach Preview prüfen
- `calculatedRIR` in `ExerciseSet` = `max(0, 10 - rpe)` (bereits vorhanden)

---

## Task 1: Background-Timer-Sync Bug Fix

**Problem:** `Timer.scheduledTimer` pausiert im App-Hintergrund. `restTimerSeconds` (In-App) bleibt stehen, Dynamic Island (Date-basiert) zählt korrekt weiter. Beim Rückkehren aus dem Hintergrund zeigt der In-App-Timer noch den alten Wert.

**Datei:** `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift`

### Schritt 1: scenePhase importieren

Am Anfang von `ActiveWorkoutView` die `scenePhase` Environment-Variable hinzufügen:

```swift
// Bereits vorhanden (oben im struct):
@Environment(\.modelContext) private var context
@Environment(\.dismiss) private var dismiss
@EnvironmentObject private var appSettings: AppSettings
@EnvironmentObject private var sessionManager: ActiveSessionManager

// NEU hinzufügen:
@Environment(\.scenePhase) private var scenePhase
```

### Schritt 2: onChange-Handler für scenePhase hinzufügen

In `body`, nach dem letzten bestehenden `.onChange`-Block (nach `.onChange(of: selectedExerciseKey)`), vor `.onDisappear`:

```swift
.onChange(of: scenePhase) { _, newPhase in
    guard newPhase == .active,
          isResting,
          let end = restEndDate,
          end > Date() else { return }
    restTimerSeconds = max(0, Int(end.timeIntervalSinceNow.rounded()))
    restartLocalRestTimerFromResume()
}
```

**Wo genau einfügen:** Suche den Block `.onChange(of: selectedExerciseKey) { _, newValue in` — der neue Handler kommt direkt danach.

### Schritt 3: Preview / Manuell testen

1. App starten, Training beginnen, Satz abschließen (startet Rest-Timer)
2. App in Hintergrund (Home-Button oder Swipe)
3. 10–15 Sekunden warten
4. App wieder in Vordergrund holen
5. Erwartung: `restTimerSeconds` springt auf korrekte Restzeit, zählt weiter
6. Dynamic Island-Timer und In-App-Timer zeigen jetzt dieselbe Zeit

### Schritt 4: Commit

```bash
cd /Users/bartosz/Developments/MotionCore
git add MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift
git commit -m "fix(timer): Rest-Timer bei Foreground-Rückkehr aus restEndDate neu berechnen"
```

---

## Task 2: Dynamic Island Redesign — Compact & Expanded

**Datei:** `MotionCoreWidgets/MotionCoreWidgetsLiveActivity.swift`

**Ziel:** Blaue Gradient-Töne statt Orange als Default-Farbe in Compact- und Expanded-Ansicht. Klarere visuelle Hierarchie.

### Schritt 1: Hilfsgradient definieren

Am Ende des `MotionCoreWidgetsLiveActivity`-Structs (vor dem letzten `}`), eine neue private Property einfügen:

```swift
private var blueRestGradient: LinearGradient {
    LinearGradient(
        colors: [Color.blue, Color.cyan],
        startPoint: .leading,
        endPoint: .trailing
    )
}
```

### Schritt 2: Compact Trailing — Pause-Timer in Blau

Den `compactTrailing`-Block ersetzen. Aktuell:

```swift
} compactTrailing: {
    if context.state.isResting, let end = context.state.restEndDate {
        Text(end, style: .timer)
            .font(.caption.bold().monospacedDigit())
            .foregroundStyle(restTimerColor(for: context))
            .contentTransition(.numericText())
    } else if context.state.isPaused {
        Text(formatTime(context.state.elapsedAtPause ?? 0))
            .font(.caption.bold().monospacedDigit())
            .foregroundStyle(.orange)
    } else {
        Text(context.state.workoutStartDate, style: .timer)
            .font(.caption.bold().monospacedDigit())
            .foregroundStyle(.green)
    }
```

Ersetzen durch:

```swift
} compactTrailing: {
    if context.state.isResting, let end = context.state.restEndDate {
        Text(end, style: .timer)
            .font(.caption.bold().monospacedDigit())
            .foregroundStyle(blueRestGradient)
            .contentTransition(.numericText())
    } else if context.state.isPaused {
        Text(formatTime(context.state.elapsedAtPause ?? 0))
            .font(.caption.bold().monospacedDigit())
            .foregroundStyle(.orange)
    } else {
        Text(context.state.workoutStartDate, style: .timer)
            .font(.caption.bold().monospacedDigit())
            .foregroundStyle(.green)
    }
```

### Schritt 3: Expanded Trailing — Timer mit blauem Gradient

Im `DynamicIslandExpandedRegion(.trailing)`-Block, den Pausen-Timer ersetzen:

Aktuell (Pausen-Timer im expanded trailing):
```swift
Text(end, style: .timer)
    .font(.title2.bold().monospacedDigit())
    .foregroundStyle(restTimerColor(for: context))
```

Ersetzen durch:
```swift
Text(end, style: .timer)
    .font(.title2.bold().monospacedDigit())
    .foregroundStyle(blueRestGradient)
```

Und die Pause-Label-Farbe:
```swift
Text("Pause")
    .font(.caption2)
    .foregroundStyle(blueRestGradient)
```

### Schritt 4: Xcode Preview prüfen

In Xcode den Preview `#Preview("Live Activity", as: .dynamicIsland(.compact), ...)` öffnen. Alle vier Content-States durchschalten. Die Rest-Timer-Anzeige soll in `blue → cyan` Gradient erscheinen.

### Schritt 5: Commit

```bash
git add MotionCoreWidgets/MotionCoreWidgetsLiveActivity.swift
git commit -m "feat(dynamic-island): Blaue Gradient-Töne für Rest-Timer in Compact und Expanded"
```

---

## Task 3: Dynamic Island Redesign — Lock Screen (Liquid Glass)

**Datei:** `MotionCoreWidgets/MotionCoreWidgetsLiveActivity.swift`

**Ziel:** `lockScreenView` mit `.ultraThinMaterial`-Hintergrund, blauem Gradient-Header und modernerem Layout neu gestalten.

### Schritt 1: lockScreenView komplett ersetzen

Die gesamte `lockScreenView`-Funktion (ab `private func lockScreenView(context:) -> some View`) durch folgende Version ersetzen:

```swift
private func lockScreenView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
    ZStack {
        // Glassmorphism-Hintergrund
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.4), Color.cyan.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )

        VStack(spacing: 16) {
            // Header: Plan- / Übungsname
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(context.attributes.planName ?? "Training")
                        .font(.headline.bold())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    if let exercise = context.state.currentExercise {
                        Text(exercise)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let set = context.state.currentSet {
                        Text(set)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                // Timer-Block
                if context.state.isResting, let end = context.state.restEndDate {
                    VStack(spacing: 3) {
                        Text("Pause")
                            .font(.caption.bold())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text(end, style: .timer)
                            .font(.title.bold().monospacedDigit())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                } else {
                    VStack(spacing: 3) {
                        Text(context.state.isPaused ? "Pausiert" : "Training")
                            .font(.caption.bold())
                            .foregroundStyle(context.state.isPaused ? .orange : .green)
                        if context.state.isPaused {
                            Text(formatTime(context.state.elapsedAtPause ?? 0))
                                .font(.title.bold().monospacedDigit())
                                .foregroundStyle(.orange)
                        } else {
                            Text(context.state.workoutStartDate, style: .timer)
                                .font(.title.bold().monospacedDigit())
                                .foregroundStyle(.green)
                        }
                    }
                }
            }

            // Fortschrittsbalken
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.15))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            context.state.isResting
                                ? LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [.green, .teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .frame(width: geometry.size.width * progress(context))
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())

            // Satz-Fortschritt
            HStack {
                Label(
                    "\(context.state.completedSets)/\(context.state.totalSets) Sätze",
                    systemImage: "checkmark.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()

                if context.state.isResting {
                    Label("Satzpause", systemImage: "pause.circle.fill")
                        .font(.caption)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                } else {
                    Label(
                        context.state.isPaused ? "Pausiert" : "Aktiv",
                        systemImage: context.state.isPaused ? "pause.circle.fill" : "play.circle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(context.state.isPaused ? .orange : .green)
                }
            }
        }
        .padding(18)
    }
}
```

### Schritt 2: Preview im Lock-Screen-Modus prüfen

Xcode Preview auf `.dynamicIsland(.expanded)` oder Lock Screen wechseln und alle States durchschalten.

### Schritt 3: Commit

```bash
git add MotionCoreWidgets/MotionCoreWidgetsLiveActivity.swift
git commit -m "feat(dynamic-island): Lock Screen Liquid Glass Redesign mit blauem Gradient"
```

---

## Task 4: Exercise-Modell — progressionStep Feld

**Datei:** `MotionCore/Models/Core/Exercise.swift`

**Ziel:** Neues persistentes Feld `progressionStep: Double` für den konfigurierbaren Gewichtsschritt.

### Schritt 1: Feld in Exercise einfügen

Nach `var repRangeMax: Int = 0` (ca. Zeile 26) einfügen:

```swift
var progressionStep: Double = 2.5    // Progressionsschritt in kg (z.B. 2.5 oder 5.0)
```

### Schritt 2: Initializer erweitern

In der `init(...)` der `Exercise`-Klasse, nach `repRangeMax: Int = 12`, neuen Parameter hinzufügen:

**In der Parameter-Liste:**
```swift
progressionStep: Double = 2.5,
```

**Im Initialisierungs-Body** (nach `self.repRangeMax = repRangeMax`):
```swift
self.progressionStep = progressionStep
```

### Schritt 3: Build-Check

`Cmd+B` in Xcode. Es darf keine Fehler geben — SwiftData ergänzt neue Felder automatisch (keine Migration nötig bei Default-Wert).

### Schritt 4: Commit

```bash
git add MotionCore/Models/Core/Exercise.swift
git commit -m "feat(model): progressionStep zu Exercise hinzufügen (Default 2.5 kg)"
```

---

## Task 5: ProgressionCalcEngine

**Neue Datei:** `MotionCore/Services/Calculation/ProgressionCalcEngine.swift`

**Ziel:** Pure struct, keine State, keine SwiftUI. Berechnet Empfehlungen anhand historischer Sessions.

### Schritt 1: Datei anlegen

Standard-Header verwenden (aus `CoreSessionCalcEngine.swift` kopieren, Felder anpassen). Vollständiger Inhalt:

```swift
//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Berechnung                                                       /
// Datei . . . . : ProgressionCalcEngine.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-08                                                       /
// Beschreibung  : RIR-basierte Auto-Progression für Kraft-Übungen                 /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Progressions-Empfehlung

struct ProgressionRecommendation {
    let exerciseName: String
    let currentWeight: Double       // Letztes verwendetes Gewicht
    let suggestedWeight: Double     // Empfohlenes neues Gewicht
    let progressionStep: Double     // Schritt, der hinzugefügt wurde
    let reason: String              // Menschenlesbare Begründung
    let sessionCount: Int           // Anzahl ausgewerteter Sessions
}

// MARK: - Progressions-Berechnungs-Engine

/// Pure struct — kein State, kein SwiftUI.
/// Vergleicht geloggten RIR (aus RPE) mit dem Ziel-RIR der letzten N Sessions.
/// Empfiehlt eine Gewichtserhöhung, wenn der tatsächliche RIR konsistent über dem Ziel liegt.
struct ProgressionCalcEngine {

    // MARK: - Kernberechnung

    /// Gibt eine Empfehlung zurück, wenn in allen letzten `sessionCount` Sessions
    /// der Ø-RIR einer Übung über dem `targetRIR` lag.
    ///
    /// - Parameters:
    ///   - exerciseName: Name der Übung (wird gegen `exerciseNameSnapshot` gematcht)
    ///   - targetRIR: Gewünschter RIR (aus `ExerciseSet.targetRIR`)
    ///   - progressionStep: Gewichtsschritt in kg (aus `Exercise.progressionStep`)
    ///   - sessions: Abgeschlossene Sessions (nur `.isCompleted == true`), neueste zuerst
    ///   - sessionCount: Anzahl der zu prüfenden Sessions (Default: 3)
    /// - Returns: `ProgressionRecommendation` oder `nil` wenn keine Empfehlung
    func recommendation(
        for exerciseName: String,
        targetRIR: Int,
        progressionStep: Double,
        sessions: [StrengthSession],
        sessionCount: Int = 3
    ) -> ProgressionRecommendation? {

        // 1) Letzte N Sessions, die diese Übung enthalten, filtern
        let relevantSessions = sessions
            .filter { session in
                session.safeExerciseSets.contains {
                    matchesExercise($0, name: exerciseName)
                }
            }
            .prefix(sessionCount)

        guard relevantSessions.count == sessionCount else { return nil }

        // 2) Durchschnittlichen RIR pro Session berechnen
        var averageRIRsPerSession: [Double] = []
        var lastWeight: Double = 0

        for session in relevantSessions {
            let workSets = session.safeExerciseSets.filter {
                matchesExercise($0, name: exerciseName) &&
                $0.setKind == .work &&
                $0.isCompleted &&
                $0.rpe > 0   // rpe == 0 bedeutet nicht erfasst
            }

            guard !workSets.isEmpty else { return nil }

            let avgRIR = workSets.map { Double($0.calculatedRIR) }.reduce(0, +) / Double(workSets.count)
            averageRIRsPerSession.append(avgRIR)

            // Letztes Gewicht aus der neuesten Session (erste in der Liste)
            if lastWeight == 0 {
                lastWeight = workSets.compactMap { $0.weight > 0 ? $0.weight : nil }.max() ?? 0
            }
        }

        // 3) Alle Sessions müssen über dem Ziel-RIR liegen
        let allAboveTarget = averageRIRsPerSession.allSatisfy { $0 > Double(targetRIR) }
        guard allAboveTarget, lastWeight > 0 else { return nil }

        // 4) Empfehlung berechnen
        let avgRIRFormatted = String(format: "%.1f", averageRIRsPerSession.reduce(0, +) / Double(averageRIRsPerSession.count))
        let suggestedWeight = lastWeight + progressionStep

        return ProgressionRecommendation(
            exerciseName: exerciseName,
            currentWeight: lastWeight,
            suggestedWeight: suggestedWeight,
            progressionStep: progressionStep,
            reason: "Ø RIR \(avgRIRFormatted) > Ziel \(targetRIR) in den letzten \(sessionCount) Sessions",
            sessionCount: sessionCount
        )
    }

    // MARK: - Hilfsmethoden

    private func matchesExercise(_ set: ExerciseSet, name: String) -> Bool {
        set.exerciseNameSnapshot == name || set.exerciseName == name
    }
}
```

### Schritt 2: Build-Check

`Cmd+B`. Prüfen ob `ProgressionCalcEngine` und `ProgressionRecommendation` kompilieren. `calculatedRIR` ist in `ExerciseSet` vorhanden (`max(0, 10 - rpe)`), `safeExerciseSets` ist in `StrengthSession` vorhanden.

### Schritt 3: Commit

```bash
git add MotionCore/Services/Calculation/ProgressionCalcEngine.swift
git commit -m "feat(progression): ProgressionCalcEngine mit RIR-basierter Gewichtsempfehlung"
```

---

## Task 6: ProgressionBannerView Component

**Neue Datei:** `MotionCore/Views/Workouts/Active/Components/ProgressionBannerView.swift`

**Ziel:** Liquid Glass Banner (ähnlich `PRBannerView`) in blauen Gradient-Tönen.

### Schritt 1: Datei anlegen

Standard-Header von `PRBannerView.swift` kopieren, Felder anpassen. Vollständiger Inhalt:

```swift
//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : ProgressionBannerView.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-08                                                       /
// Beschreibung  : Liquid Glass Banner für RIR-basierte Gewichtsempfehlung         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ProgressionBannerView: View {
    let recommendation: ProgressionRecommendation
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Gradient-Icon
            Image(systemName: "arrow.up.circle.fill")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Text-Block
            VStack(alignment: .leading, spacing: 3) {
                Text("Gewicht erhöhen · +\(formattedStep) kg")
                    .font(.headline.bold())
                    .foregroundStyle(.primary)

                Text(recommendation.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Dismiss-Button
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.5), Color.cyan.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.blue.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private var formattedStep: String {
        recommendation.progressionStep.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(recommendation.progressionStep))
            : String(format: "%.1f", recommendation.progressionStep)
    }
}

// MARK: - Preview

#Preview("Progression Banner") {
    ZStack {
        AnimatedBackground(showAnimatedBlob: true)

        VStack {
            ProgressionBannerView(
                recommendation: ProgressionRecommendation(
                    exerciseName: "Bankdrücken",
                    currentWeight: 80.0,
                    suggestedWeight: 82.5,
                    progressionStep: 2.5,
                    reason: "Ø RIR 3.5 > Ziel 2 in den letzten 3 Sessions",
                    sessionCount: 3
                ),
                onDismiss: {}
            )
            Spacer()
        }
        .padding(.top, 20)
    }
    .environmentObject(AppSettings.shared)
}
```

### Schritt 2: Preview prüfen

Xcode Preview öffnen und sicherstellen, dass der Banner wie erwartet aussieht — blaues Gradient-Icon, Glassmorphism-Hintergrund, blauer Gradient-Border.

### Schritt 3: Commit

```bash
git add MotionCore/Views/Workouts/Active/Components/ProgressionBannerView.swift
git commit -m "feat(progression): ProgressionBannerView Liquid Glass Component"
```

---

## Task 7: Progression-Integration in ActiveWorkoutView

**Datei:** `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift`

**Ziel:** Empfehlungen berechnen, pro Übung anzeigen, mit Dismiss-Funktion.

### Schritt 1: State-Variable hinzufügen

Im `struct ActiveWorkoutView`, nach `@State private var prBannerOneRM: Double = 0`, hinzufügen:

```swift
// Progression
@State private var dismissedProgressionExercises: Set<String> = []
```

### Schritt 2: Computed Property für Empfehlungen

Nach `private var lastCompletedSet: ExerciseSet? { ... }` eine neue Computed Property einfügen:

```swift
private var progressionRecommendations: [ProgressionRecommendation] {
    let engine = ProgressionCalcEngine()
    let exerciseNames = Set(session.safeExerciseSets.map { $0.exerciseName })

    return exerciseNames.compactMap { name in
        guard !dismissedProgressionExercises.contains(name) else { return nil }

        // targetRIR und progressionStep aus dem ersten Set dieser Übung holen
        let firstSet = session.safeExerciseSets.first { $0.exerciseName == name }
        let targetRIR = firstSet?.targetRIR ?? 2

        // progressionStep aus der Exercise-Relationship holen, Fallback 2.5
        let step = firstSet?.exercise?.progressionStep ?? 2.5

        return engine.recommendation(
            for: name,
            targetRIR: targetRIR,
            progressionStep: step,
            sessions: historicalSessions
        )
    }
}
```

### Schritt 3: progressionBanners View hinzufügen

Nach der `exercisesOverview`-Computed-Property, eine neue hinzufügen:

```swift
@ViewBuilder
private var progressionBanners: some View {
    if !progressionRecommendations.isEmpty {
        VStack(spacing: 8) {
            ForEach(progressionRecommendations, id: \.exerciseName) { rec in
                ProgressionBannerView(recommendation: rec) {
                    withAnimation(.easeOut) {
                        dismissedProgressionExercises.insert(rec.exerciseName)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progressionRecommendations.count)
    }
}
```

### Schritt 4: progressionBanners in scrollContent einbauen

Die `scrollContent`-Property suchen:

```swift
private var scrollContent: some View {
    VStack(spacing: 20) {
        heroCard
        exercisesOverview
    }
    ...
}
```

Ersetzen durch:

```swift
private var scrollContent: some View {
    VStack(spacing: 20) {
        heroCard
        progressionBanners
        exercisesOverview
    }
    .padding(.horizontal)
    .padding(.top, 16)
    .padding(.bottom, 100)
}
```

### Schritt 5: Build-Check und Test

`Cmd+B`. Dann manuell:
1. Training mit Übung starten, alle Sätze abschließen
2. Für jede abgeschlossene Übung RPE > `10 - targetRIR` setzen (z.B. RPE 6 bei targetRIR 2 = berechneter RIR 4 > Ziel 2)
3. Workout beenden
4. Neues Training mit derselben Übung starten
5. Wenn ≥3 historische Sessions mit konsistent hohem RIR → Banner erscheint
6. X-Button klicken → Banner verschwindet

**Hinweis:** Zum schnellen Testen die Engine mit `sessionCount: 1` in `progressionRecommendations` testen.

### Schritt 6: Commit

```bash
git add MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift
git commit -m "feat(progression): RIR-Empfehlungs-Banner in ActiveWorkoutView integrieren"
```

---

## Gesamt-Übersicht der geänderten/neuen Dateien

| Datei | Aktion | Task |
|-------|--------|------|
| `Views/Workouts/Active/View/ActiveWorkoutView.swift` | Modify | 1, 7 |
| `MotionCoreWidgets/MotionCoreWidgetsLiveActivity.swift` | Modify | 2, 3 |
| `Models/Core/Exercise.swift` | Modify | 4 |
| `Services/Calculation/ProgressionCalcEngine.swift` | Create | 5 |
| `Views/Workouts/Active/Components/ProgressionBannerView.swift` | Create | 6 |

---

## Abschluss-Verifikation

Nach allen Tasks:
1. `Cmd+B` — Build fehlerfrei
2. Timer-Test: App hintergrunden, 15s warten, zurückkehren → Zeiten synchron
3. Dynamic Island: Simulator → Live Activity starten → Pausen-Timer prüfen → blauer Countdown
4. Lock Screen Preview in Xcode → glassmorphism sichtbar
5. Progression: Mind. 1 historische Session mit hohem RPE vorhanden? → Banner erscheint

```bash
git log --oneline -7
```

Erwarteter Output: 7 neue Commits (1 docs + 6 feature/fix commits).
