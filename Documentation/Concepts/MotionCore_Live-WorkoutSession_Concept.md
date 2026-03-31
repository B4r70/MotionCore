# MotionCore – Konzept: HealthKit Workout Session (Live HR & Kalorien)

> **Version 2.0 – 31.03.2026**
> Claude-Code-ready. Alle offenen Entscheidungen sind getroffen.
> Dieses Dokument ist die einzige Quelle der Wahrheit für die Implementierung.

---

## 1. Zusammenfassung

MotionCore startet eine eigene `HKWorkoutSession` auf der Apple Watch, sodass Herzfrequenz (HR) und Kalorienverbrauch automatisch gemessen und in Apple Health geschrieben werden — ohne die Apple Fitness App.

**User-Flow:** Workout in MotionCore starten → Watch trackt HR + Kalorien im Hintergrund → Werte erscheinen live auf dem iPhone → nach Beenden steht ein vollständiges `HKWorkout` in Apple Health.

**Architektur-Entscheidungen (final):**

| # | Entscheidung | Gewählt |
|---|---|---|
| 1 | Pro-Übung Metriken speichern | Separates `ExerciseMetrics` SwiftData Model |
| 2 | Heartbeat-Timer für Live-HR | 60-Sek-Timer mitbauen (Setting ein/ausschaltbar) |
| 3 | Pause-Verhalten Watch | Watch pausiert komplett mit iPhone (HR + Kalorien stoppen) |
| 4 | HealthKit-Auth Zeitpunkt | In den Watch-App Settings vorab |
| 5 | WatchWorkoutManager Pattern | Als Property im `WatchSessionManager` (kein Singleton) |
| 6 | Exercise Transition Trigger | Automatisch wenn `selectedExerciseKey` sich ändert |
| 7 | Cancel Workout Verhalten | User fragen: „Health-Daten behalten oder verwerfen?" |

---

## 2. Ist-Zustand

### Was bereits existiert

| Komponente | Status |
|---|---|
| `HealthKitManager` | Liest HR, Kalorien, Schritte, Schlaf — **nur Read** (`toShare: []`) |
| `StrengthSession` | Hat `calories`, `heartRate`, `maxHeartRate`, `healthKitWorkoutUUID` — **ungenutzt** |
| `ExerciseSet` | Hat keine HR/Kalorien-Felder (bleibt so — neues Model stattdessen) |
| `WatchSessionManager` | Singleton, `ObservableObject`. Empfängt State vom iPhone, sendet Actions |
| `PhoneSessionManager` | Singleton. Sendet Workout-State an Watch, empfängt Actions via `onAction` Callback |
| `WatchMessageKeys` | Definiert `WatchStateKey`, `WatchAction`, `WatchWorkoutState` |
| `ActiveSessionManager` | Timer + State-Management auf iPhone-Seite, kein HealthKit |
| `ActiveWorkoutView` | ~2000 Zeilen. `completeSet()` → PR-Check → Rest-Timer. Kein HR-Bezug |
| `ActiveWorkoutStatus` | Status-Bar mit Timer, Volumen, Sätze, Fortschrittsbalken |
| `AppSettings` | `ObservableObject` Singleton, UserDefaults-backed `@Published` Properties |

### Was fehlt

- `HKWorkoutSession` + `HKLiveWorkoutBuilder` auf der Watch
- HealthKit **Write**-Berechtigungen auf der Watch
- Watch → iPhone Kommunikation für HR/Kalorien-Daten
- `ExerciseMetrics` SwiftData Model für pro-Übung Health-Daten
- UI-Karte für Live-HR/Kalorien in `ActiveWorkoutView`
- 60-Sek Heartbeat-Timer für Live-Updates (als Setting)
- Fallback wenn Watch nicht verbunden ist

---

## 3. Architektur-Übersicht

```
┌─────────────────────────────────────────┐
│              iPhone                      │
│                                          │
│  ActiveWorkoutView                       │
│    ├── ActiveWorkoutStatus (erweitert)   │
│    │     └── ⌚ Watch-Indikator (NEU)    │
│    ├── LiveHealthCard (NEU)              │
│    │     HR: 142 bpm | Kal: 287          │
│    └── completeSet()                     │
│          ├── bestehende Logik            │
│          └── Health-Snapshot verarbeiten │
│                                          │
│  PhoneSessionManager (erweitert)         │
│    ├── sendet State + Lifecycle → Watch  │
│    ├── empfängt HR-Snapshots ← Watch     │
│    └── @Published liveHealthData         │
│                                          │
│  ExerciseMetrics (@Model, NEU)           │
│    └── Relationship zu StrengthSession   │
│                                          │
│  StrengthSession (unverändert!)          │
│    └── calories, heartRate, maxHeartRate  │
│        werden beim Finish befüllt        │
│                                          │
│  AppSettings (erweitert)                 │
│    └── enableLiveHeartbeatTimer: Bool    │
└──────────────┬───────────────────────────┘
               │ WatchConnectivity
               │ (sendMessage)
┌──────────────▼───────────────────────────┐
│          Apple Watch                      │
│                                           │
│  WatchSessionManager (erweitert)          │
│    ├── var workoutManager: WatchWorkout-  │
│    │   Manager? (als Property, NEU)       │
│    ├── empfängt "startWorkout" →          │
│    │   erstellt + startet Manager         │
│    ├── empfängt "completeSet" →           │
│    │   sendet Health-Snapshot → iPhone    │
│    ├── empfängt "exerciseTransition" →    │
│    │   setzt pro-Übung Samples zurück    │
│    ├── empfängt "pause/resume" →          │
│    │   pausiert/resumed HKWorkoutSession  │
│    ├── empfängt "endWorkout" →            │
│    │   beendet + speichert HKWorkout      │
│    ├── empfängt "discardWorkout" →        │
│    │   beendet OHNE speichern             │
│    └── Heartbeat-Timer (60 Sek)           │
│                                           │
│  WatchWorkoutManager (NEU, kein Singleton)│
│    ├── HKWorkoutSession                   │
│    ├── HKLiveWorkoutBuilder               │
│    ├── HKLiveWorkoutBuilderDelegate       │
│    ├── HKWorkoutSessionDelegate           │
│    └── sammelt HR, Kalorien               │
│                                           │
│  WatchBaseView (erweitert)                │
│    └── HealthKit-Auth Button in Settings  │
│                                           │
│  WatchActiveWorkoutView (erweitert)       │
│    └── Kleine HR-Anzeige                  │
└───────────────────────────────────────────┘
```

---

## 4. Neue Dateien und Änderungen

### 4.1 Neue Dateien

| Datei | Target | Beschreibung |
|---|---|---|
| `WatchWorkoutManager.swift` | Watch | `HKWorkoutSession` + `HKLiveWorkoutBuilder`, Delegates, Start/Stop/Pause |
| `WatchHealthDataTypes.swift` | Shared (beide Targets) | Message-Keys, Lifecycle-Keys, `ExerciseHealthSnapshot` Struct |
| `ExerciseMetrics.swift` | iPhone | SwiftData `@Model` für pro-Übung Health-Metriken |
| `LiveHealthCard.swift` | iPhone | GlassCard UI: aktuelle HR, Ø HR, max HR, Kalorien |
| `HealthDataCalcEngine.swift` | iPhone | Pure Struct: aggregiert ExerciseMetrics für Session-Zusammenfassung |

### 4.2 Geänderte Dateien

| Datei | Änderung |
|---|---|
| `WatchMessageKeys.swift` | Neue Keys: Health-Daten, Workout-Lifecycle, Heartbeat, Discard |
| `WatchSessionManager.swift` | Property `workoutManager: WatchWorkoutManager?`, Integration Lifecycle + Heartbeat |
| `PhoneSessionManager.swift` | `@Published` Health-Properties, Empfang von Snapshots + Heartbeats, Lifecycle-Sende-Methoden |
| `ActiveWorkoutView.swift` | `LiveHealthCard` einbinden, Exercise-Transition bei `selectedExerciseKey`-Änderung, Health-Daten bei `finishWorkout()` + `cancelWorkout()` |
| `ActiveWorkoutStatus.swift` | Neuer optionaler Parameter `watchConnectionState`, ⌚-Indikator |
| `StrengthSession.swift` | Neue inverse Relationship zu `ExerciseMetrics` |
| `AppSettings.swift` | Neues Setting `enableLiveHeartbeatTimer: Bool` |
| `WorkoutSettingsView.swift` | Toggle für Heartbeat-Timer |
| `WatchActiveWorkoutView.swift` | Kleine HR-Anzeige unter dem Timer |
| `WatchBaseView.swift` | HealthKit-Autorisierungs-Button in Settings-Section |
| `Info.plist` (Watch) | `NSHealthShareUsageDescription` + `NSHealthUpdateUsageDescription` |
| Watch Target Capabilities | HealthKit + Background Modes: "Workout processing" |

---

## 5. Implementierungsdetails

### 5.1 ExerciseMetrics — Neues SwiftData Model (iPhone)

Separates Model statt Felder auf `ExerciseSet`. Saubere Trennung, keine Verschmutzung des bestehenden Models.

```swift
// ExerciseMetrics.swift — iPhone Target

import Foundation
import SwiftData

@Model
final class ExerciseMetrics {

    // MARK: - Identifikation

    /// groupKey der Übung (exerciseUUIDSnapshot oder exerciseNameSnapshot)
    var exerciseGroupKey: String = ""

    /// Snapshot des Übungsnamens für Anzeige
    var exerciseNameSnapshot: String = ""

    // MARK: - Health-Metriken

    var avgHeartRate: Double = 0        // Durchschnittliche HR während dieser Übung
    var minHeartRate: Double = 0        // Minimale HR
    var maxHeartRate: Double = 0        // Maximale HR
    var activeCalories: Double = 0      // Kalorien während dieser Übung
    var durationSeconds: Int = 0        // Dauer der Übung in Sekunden

    // MARK: - Beziehungen

    @Relationship(deleteRule: .nullify)
    var session: StrengthSession?

    // MARK: - Initialisierung

    init(
        exerciseGroupKey: String = "",
        exerciseNameSnapshot: String = "",
        avgHeartRate: Double = 0,
        minHeartRate: Double = 0,
        maxHeartRate: Double = 0,
        activeCalories: Double = 0,
        durationSeconds: Int = 0
    ) {
        self.exerciseGroupKey = exerciseGroupKey
        self.exerciseNameSnapshot = exerciseNameSnapshot
        self.avgHeartRate = avgHeartRate
        self.minHeartRate = minHeartRate
        self.maxHeartRate = maxHeartRate
        self.activeCalories = activeCalories
        self.durationSeconds = durationSeconds
    }
}
```

### 5.2 StrengthSession — Inverse Relationship

```swift
// In StrengthSession.swift — neue Relationship hinzufügen:

// MARK: - Health-Metriken (pro Übung)

@Relationship(deleteRule: .cascade, inverse: \ExerciseMetrics.session)
var exerciseMetrics: [ExerciseMetrics]? = []

var safeExerciseMetrics: [ExerciseMetrics] { exerciseMetrics ?? [] }
```

**Wichtig:** Die bestehenden Felder `calories`, `heartRate`, `maxHeartRate`, `healthKitWorkoutUUID` auf `StrengthSession` bleiben unverändert und werden beim `finishWorkout()` mit den finalen Gesamt-Werten befüllt.

### 5.3 WatchWorkoutManager (NEU — Watch Target)

Wird als Property im `WatchSessionManager` gehalten, **kein Singleton**. Wird bei Workout-Start erstellt, bei Workout-Ende auf `nil` gesetzt.

```swift
// WatchWorkoutManager.swift — Watch Target

import Foundation
import HealthKit

final class WatchWorkoutManager: NSObject, ObservableObject {

    // MARK: - Properties

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    // Aktuelle Live-Werte
    @Published private(set) var currentHeartRate: Double = 0
    @Published private(set) var averageHeartRate: Double = 0
    @Published private(set) var maxHeartRate: Double = 0
    @Published private(set) var activeCalories: Double = 0

    // Status
    @Published private(set) var isActive: Bool = false

    // Pro-Übung Tracking
    private var exerciseStartDate: Date?
    private var heartRateSamplesForExercise: [Double] = []

    // MARK: - HealthKit Authorization

    /// Muss VOR dem ersten Workout aufgerufen werden.
    /// Wird über WatchBaseView Settings-Button getriggert.
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            return true
        } catch {
            print("WatchWorkoutManager: Auth fehlgeschlagen: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Workout Lifecycle

    func startWorkout() async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor

        let session = try HKWorkoutSession(
            healthStore: healthStore,
            configuration: config
        )
        let builder = session.associatedWorkoutBuilder()

        builder.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: config
        )

        session.delegate = self
        builder.delegate = self

        self.workoutSession = session
        self.workoutBuilder = builder

        let startDate = Date()
        session.startActivity(with: startDate)
        try await builder.beginCollection(at: startDate)

        exerciseStartDate = startDate
        isActive = true
    }

    func pauseWorkout() {
        workoutSession?.pause()
    }

    func resumeWorkout() {
        workoutSession?.resume()
    }

    /// Beendet das Workout und speichert ein HKWorkout in Apple Health.
    func endWorkout() async throws {
        guard let session = workoutSession, let builder = workoutBuilder else { return }
        session.end()
        try await builder.endCollection(at: Date())
        try await builder.finishWorkout()
        cleanup()
    }

    /// Beendet das Workout OHNE in Apple Health zu speichern.
    func discardWorkout() {
        workoutSession?.end()
        // Kein finishWorkout() → kein HKWorkout in Health
        cleanup()
    }

    // MARK: - Exercise Transition

    /// Setzt die pro-Übung HR-Samples zurück.
    /// Wird aufgerufen wenn selectedExerciseKey sich ändert.
    func markExerciseTransition() {
        heartRateSamplesForExercise.removeAll()
        exerciseStartDate = Date()
    }

    // MARK: - Snapshot für Set-Completion

    /// Gibt den aktuellen Health-Snapshot zurück.
    /// Wird bei Set-Completion und als Heartbeat gesendet.
    func currentSnapshot() -> [String: Any] {
        return [
            WatchHealthKey.healthUpdate:    true,
            WatchHealthKey.currentHR:       currentHeartRate,
            WatchHealthKey.averageHR:       averageHeartRate,
            WatchHealthKey.maxHR:           maxHeartRate,
            WatchHealthKey.activeCalories:  activeCalories,
            WatchHealthKey.isWorkoutActive: isActive
        ]
    }

    /// Gibt einen Exercise-Snapshot für die pro-Übung Metriken zurück.
    func exerciseSnapshot() -> [String: Any] {
        return [
            WatchExerciseSnapshotKey.exerciseSnapshot:  true,
            WatchExerciseSnapshotKey.snapshotAvgHR:     averageHRForCurrentExercise(),
            WatchExerciseSnapshotKey.snapshotMinHR:     heartRateSamplesForExercise.min() ?? 0,
            WatchExerciseSnapshotKey.snapshotMaxHR:     heartRateSamplesForExercise.max() ?? 0,
            WatchExerciseSnapshotKey.snapshotCalories:  activeCalories,
            WatchExerciseSnapshotKey.snapshotDuration:  exerciseDurationSeconds()
        ]
    }

    // MARK: - Private Helpers

    private func averageHRForCurrentExercise() -> Double {
        guard !heartRateSamplesForExercise.isEmpty else { return 0 }
        return heartRateSamplesForExercise.reduce(0, +) / Double(heartRateSamplesForExercise.count)
    }

    private func exerciseDurationSeconds() -> Int {
        guard let start = exerciseStartDate else { return 0 }
        return Int(Date().timeIntervalSince(start))
    }

    private func cleanup() {
        workoutSession = nil
        workoutBuilder = nil
        isActive = false
        currentHeartRate = 0
        averageHeartRate = 0
        maxHeartRate = 0
        activeCalories = 0
        heartRateSamplesForExercise.removeAll()
        exerciseStartDate = nil
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchWorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        DispatchQueue.main.async {
            self.isActive = (toState == .running)
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didFailWithError error: Error) {
        print("WatchWorkoutManager: Session failed: \(error.localizedDescription)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {

    func workoutBuilder(_ builder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {

        let hrUnit = HKUnit.count().unitDivided(by: .minute())

        // Herzfrequenz auslesen
        if let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate),
           collectedTypes.contains(hrType),
           let statistics = builder.statistics(for: hrType) {

            DispatchQueue.main.async {
                if let mostRecent = statistics.mostRecentQuantity() {
                    let value = mostRecent.doubleValue(for: hrUnit)
                    self.currentHeartRate = value
                    self.heartRateSamplesForExercise.append(value)
                }
                if let avg = statistics.averageQuantity() {
                    self.averageHeartRate = avg.doubleValue(for: hrUnit)
                }
                if let max = statistics.maximumQuantity() {
                    self.maxHeartRate = max.doubleValue(for: hrUnit)
                }
            }
        }

        // Kalorien auslesen
        if let calType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
           collectedTypes.contains(calType),
           let sum = builder.statistics(for: calType)?.sumQuantity() {

            DispatchQueue.main.async {
                self.activeCalories = sum.doubleValue(for: .kilocalorie())
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
```

### 5.4 WatchHealthDataTypes (NEU — Shared, beide Targets)

```swift
// WatchHealthDataTypes.swift — In beiden Targets identisch

// MARK: - Health Data Keys (Watch → iPhone)

enum WatchHealthKey {
    static let healthUpdate     = "healthUpdate"
    static let currentHR        = "currentHR"
    static let averageHR        = "averageHR"
    static let maxHR            = "maxHR"
    static let activeCalories   = "activeCalories"
    static let isWorkoutActive  = "isWorkoutActive"
}

// MARK: - Exercise Snapshot Keys (Watch → iPhone, bei Set-Completion)

enum WatchExerciseSnapshotKey {
    static let exerciseSnapshot     = "exerciseSnapshot"
    static let snapshotAvgHR        = "snapshotAvgHR"
    static let snapshotMinHR        = "snapshotMinHR"
    static let snapshotMaxHR        = "snapshotMaxHR"
    static let snapshotCalories     = "snapshotCalories"
    static let snapshotDuration     = "snapshotDuration"
}

// MARK: - Workout Lifecycle Keys (iPhone → Watch)

enum WatchWorkoutLifecycleKey {
    static let startHealthTracking  = "startHealthTracking"
    static let stopHealthTracking   = "stopHealthTracking"
    static let discardHealthTracking = "discardHealthTracking"
    static let pauseHealthTracking  = "pauseHealthTracking"
    static let resumeHealthTracking = "resumeHealthTracking"
    static let exerciseTransition   = "exerciseTransition"
    static let requestSnapshot      = "requestHealthSnapshot"
}

// MARK: - Heartbeat Keys (Watch → iPhone, periodisch)

enum WatchHeartbeatKey {
    /// iPhone sendet diesen Key um den 60-Sek-Timer auf der Watch zu aktivieren/deaktivieren
    static let enableHeartbeat  = "enableHeartbeat"
}
```

### 5.5 WatchMessageKeys — Erweiterungen

```swift
// In WatchMessageKeys.swift — Ergänzungen:

// Bestehende WatchWorkoutState erhält keinen neuen Case.
// Die Health-Lifecycle-Events laufen über eigene Keys (WatchWorkoutLifecycleKey).
// Keine Änderung an WatchAction nötig — Exercise-Transition wird über
// WatchWorkoutLifecycleKey.exerciseTransition gesendet, nicht als WatchAction.
```

**Hinweis:** `WatchMessageKeys.swift` wird NICHT um neue WatchAction-Cases erweitert. Die Health-Lifecycle-Kommunikation läuft über die separaten `WatchWorkoutLifecycleKey`-Keys aus `WatchHealthDataTypes.swift`. So bleibt die bestehende Action-Logik unberührt.

### 5.6 Datenfluss — Event-basiert + optionaler Heartbeat

```
=== EVENT-BASIERT (immer aktiv) ===

User tippt "Satz abschließen" auf iPhone oder Watch
    │
    ├─► iPhone sendet WatchWorkoutLifecycleKey.requestSnapshot an Watch
    │
    ├─► Watch: workoutManager?.exerciseSnapshot()
    │     └─► Sammelt aktuelle HR-Werte (avg/min/max), Kalorien, Dauer
    │
    ├─► Watch sendet Snapshot via sendMessage() an iPhone
    │
    ├─► iPhone: PhoneSessionManager empfängt Snapshot
    │     └─► Published Properties aktualisieren (→ LiveHealthCard)
    │
    └─► ActiveWorkoutView: erstellt ExerciseMetrics aus Snapshot


=== HEARTBEAT-TIMER (optional, via Setting) ===

AppSettings.enableLiveHeartbeatTimer == true
    │
    ├─► iPhone sendet WatchHeartbeatKey.enableHeartbeat = true an Watch
    │
    ├─► Watch startet 60-Sek-Timer
    │     └─► Alle 60 Sek: workoutManager?.currentSnapshot()
    │         └─► Sendet aktuelle HR + Kalorien via sendMessage()
    │
    └─► iPhone: PhoneSessionManager empfängt → LiveHealthCard aktualisiert

AppSettings.enableLiveHeartbeatTimer == false
    └─► iPhone sendet WatchHeartbeatKey.enableHeartbeat = false
        └─► Watch stoppt Timer
```

### 5.7 PhoneSessionManager — Erweiterungen

```swift
// PhoneSessionManager.swift — Ergänzungen

final class PhoneSessionManager: NSObject {

    // ... bestehender Code ...

    // MARK: - Live Health Data (NEU)

    /// Aktuelle Health-Daten von der Watch (via Heartbeat oder Snapshot)
    @Published var liveCurrentHR: Double = 0
    @Published var liveAverageHR: Double = 0
    @Published var liveMaxHR: Double = 0
    @Published var liveActiveCalories: Double = 0
    @Published var isWatchTrackingActive: Bool = false

    /// Letzter Exercise-Snapshot (pro Übung)
    @Published var lastExerciseSnapshot: ExerciseSnapshotData?

    // MARK: - Workout Lifecycle senden (iPhone → Watch)

    func sendStartHealthTracking() {
        sendLifecycleMessage([WatchWorkoutLifecycleKey.startHealthTracking: true])
    }

    func sendStopHealthTracking() {
        sendLifecycleMessage([WatchWorkoutLifecycleKey.stopHealthTracking: true])
    }

    func sendDiscardHealthTracking() {
        sendLifecycleMessage([WatchWorkoutLifecycleKey.discardHealthTracking: true])
    }

    func sendPauseHealthTracking() {
        sendLifecycleMessage([WatchWorkoutLifecycleKey.pauseHealthTracking: true])
    }

    func sendResumeHealthTracking() {
        sendLifecycleMessage([WatchWorkoutLifecycleKey.resumeHealthTracking: true])
    }

    func sendExerciseTransition() {
        sendLifecycleMessage([WatchWorkoutLifecycleKey.exerciseTransition: true])
    }

    func sendRequestSnapshot() {
        sendLifecycleMessage([WatchWorkoutLifecycleKey.requestSnapshot: true])
    }

    func sendHeartbeatEnabled(_ enabled: Bool) {
        sendLifecycleMessage([WatchHeartbeatKey.enableHeartbeat: enabled])
    }

    private func sendLifecycleMessage(_ message: [String: Any]) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("PhoneSessionManager: Lifecycle-Fehler: \(error.localizedDescription)")
        }
    }

    // MARK: - Health-Daten zurücksetzen

    func resetHealthData() {
        liveCurrentHR = 0
        liveAverageHR = 0
        liveMaxHR = 0
        liveActiveCalories = 0
        isWatchTrackingActive = false
        lastExerciseSnapshot = nil
    }
}

/// Parsed Exercise-Snapshot (Convenience-Struct, kein SwiftData)
struct ExerciseSnapshotData {
    let avgHR: Double
    let minHR: Double
    let maxHR: Double
    let calories: Double
    let durationSeconds: Int
}

// In der bestehenden didReceiveMessage-Extension ergänzen:
//
// func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
//     // ... bestehende Action-Verarbeitung ...
//
//     // NEU: Health-Updates verarbeiten
//     if message[WatchHealthKey.healthUpdate] != nil {
//         DispatchQueue.main.async { [weak self] in
//             self?.liveCurrentHR = message[WatchHealthKey.currentHR] as? Double ?? 0
//             self?.liveAverageHR = message[WatchHealthKey.averageHR] as? Double ?? 0
//             self?.liveMaxHR = message[WatchHealthKey.maxHR] as? Double ?? 0
//             self?.liveActiveCalories = message[WatchHealthKey.activeCalories] as? Double ?? 0
//             self?.isWatchTrackingActive = message[WatchHealthKey.isWorkoutActive] as? Bool ?? false
//         }
//     }
//
//     // NEU: Exercise-Snapshot verarbeiten
//     if message[WatchExerciseSnapshotKey.exerciseSnapshot] != nil {
//         DispatchQueue.main.async { [weak self] in
//             self?.lastExerciseSnapshot = ExerciseSnapshotData(
//                 avgHR: message[WatchExerciseSnapshotKey.snapshotAvgHR] as? Double ?? 0,
//                 minHR: message[WatchExerciseSnapshotKey.snapshotMinHR] as? Double ?? 0,
//                 maxHR: message[WatchExerciseSnapshotKey.snapshotMaxHR] as? Double ?? 0,
//                 calories: message[WatchExerciseSnapshotKey.snapshotCalories] as? Double ?? 0,
//                 durationSeconds: message[WatchExerciseSnapshotKey.snapshotDuration] as? Int ?? 0
//             )
//         }
//     }
// }
```

### 5.8 WatchSessionManager — Erweiterungen

```swift
// WatchSessionManager.swift — Ergänzungen

final class WatchSessionManager: NSObject, ObservableObject {

    // ... bestehende Properties ...

    // MARK: - Health Tracking (NEU)

    /// WatchWorkoutManager als Property (kein Singleton).
    /// Wird bei Workout-Start erstellt, bei Workout-Ende nil gesetzt.
    @Published private(set) var workoutManager: WatchWorkoutManager?

    /// Timer für periodische Heartbeat-Updates an das iPhone
    private var heartbeatTimer: Timer?

    // ... bestehender init + sendAction ...

    // MARK: - Heartbeat Timer (NEU)

    private func startHeartbeatTimer() {
        stopHeartbeatTimer()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.sendHeartbeatUpdate()
        }
    }

    private func stopHeartbeatTimer() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    private func sendHeartbeatUpdate() {
        guard let manager = workoutManager,
              manager.isActive,
              WCSession.default.isReachable else { return }

        let snapshot = manager.currentSnapshot()
        WCSession.default.sendMessage(snapshot, replyHandler: nil) { error in
            print("WatchSessionManager: Heartbeat-Fehler: \(error.localizedDescription)")
        }
    }
}

// In der bestehenden didReceiveMessage-Extension ergänzen:
//
// func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
//     DispatchQueue.main.async { [weak self] in
//         guard let self else { return }
//
//         // ... bestehende State-Verarbeitung ...
//
//         // NEU: Health-Tracking starten
//         if message[WatchWorkoutLifecycleKey.startHealthTracking] != nil {
//             Task {
//                 let manager = WatchWorkoutManager()
//                 self.workoutManager = manager
//                 try? await manager.startWorkout()
//             }
//         }
//
//         // NEU: Health-Tracking beenden + speichern
//         if message[WatchWorkoutLifecycleKey.stopHealthTracking] != nil {
//             Task {
//                 try? await self.workoutManager?.endWorkout()
//                 self.workoutManager = nil
//                 self.stopHeartbeatTimer()
//             }
//         }
//
//         // NEU: Health-Tracking beenden + verwerfen
//         if message[WatchWorkoutLifecycleKey.discardHealthTracking] != nil {
//             self.workoutManager?.discardWorkout()
//             self.workoutManager = nil
//             self.stopHeartbeatTimer()
//         }
//
//         // NEU: Pause/Resume
//         if message[WatchWorkoutLifecycleKey.pauseHealthTracking] != nil {
//             self.workoutManager?.pauseWorkout()
//         }
//         if message[WatchWorkoutLifecycleKey.resumeHealthTracking] != nil {
//             self.workoutManager?.resumeWorkout()
//         }
//
//         // NEU: Exercise-Transition
//         if message[WatchWorkoutLifecycleKey.exerciseTransition] != nil {
//             self.workoutManager?.markExerciseTransition()
//         }
//
//         // NEU: Snapshot angefordert
//         if message[WatchWorkoutLifecycleKey.requestSnapshot] != nil {
//             guard let manager = self.workoutManager,
//                   WCSession.default.isReachable else { return }
//             // Sende sowohl Health-Update als auch Exercise-Snapshot
//             var combined = manager.currentSnapshot()
//             manager.exerciseSnapshot().forEach { combined[$0.key] = $0.value }
//             WCSession.default.sendMessage(combined, replyHandler: nil, errorHandler: nil)
//         }
//
//         // NEU: Heartbeat-Timer ein/ausschalten
//         if let enabled = message[WatchHeartbeatKey.enableHeartbeat] as? Bool {
//             if enabled { self.startHeartbeatTimer() }
//             else { self.stopHeartbeatTimer() }
//         }
//     }
// }
```

### 5.9 ActiveWorkoutView — Erweiterungen

```swift
// In ActiveWorkoutView.swift — Ergänzungen:

// MARK: - Neue State Properties

// (keine neuen @State nötig — PhoneSessionManager.shared ist die Single Source of Truth)

// MARK: - onChange: Exercise-Transition automatisch senden

// Bestehender onChange(of: selectedExerciseKey) erweitern:
.onChange(of: selectedExerciseKey) { _, newValue in
    refreshSetCaches()
    sessionManager.setSelectedExerciseKey(newValue)
    syncLiveActivityStates()
    sendWatchState()

    // NEU: Exercise-Transition an Watch senden
    PhoneSessionManager.shared.sendExerciseTransition()
}

// MARK: - onAppear: Health-Tracking starten

// In .onAppear ergänzen:
// PhoneSessionManager.shared.sendStartHealthTracking()
// if appSettings.enableLiveHeartbeatTimer {
//     PhoneSessionManager.shared.sendHeartbeatEnabled(true)
// }

// MARK: - LiveHealthCard in scrollContent einbinden

// Nach ActiveWorkoutStatus, vor der Übungsliste:
// if PhoneSessionManager.shared.isWatchTrackingActive {
//     LiveHealthCard(
//         currentHR: PhoneSessionManager.shared.liveCurrentHR,
//         averageHR: PhoneSessionManager.shared.liveAverageHR,
//         maxHR: PhoneSessionManager.shared.liveMaxHR,
//         activeCalories: PhoneSessionManager.shared.liveActiveCalories
//     )
// }

// MARK: - completeSet() erweitern

// In completeSet(), nach dem PR-Check:
// PhoneSessionManager.shared.sendRequestSnapshot()

// MARK: - finishWorkout() erweitern

// In finishWorkout(), vor try? context.save():
//
// // Finale Health-Daten in Session schreiben
// let phone = PhoneSessionManager.shared
// if phone.isWatchTrackingActive || phone.liveAverageHR > 0 {
//     session.calories = Int(phone.liveActiveCalories)
//     session.heartRate = Int(phone.liveAverageHR)
//     session.maxHeartRate = Int(phone.liveMaxHR)
// }
//
// // ExerciseMetrics aus letztem Snapshot erstellen (falls vorhanden)
// // Hinweis: ExerciseMetrics werden primär bei Exercise-Transitions gespeichert.
// // Der finale Snapshot fängt die letzte Übung ab.
// saveCurrentExerciseMetrics()
//
// // Watch-Workout beenden → speichert HKWorkout in Apple Health
// PhoneSessionManager.shared.sendStopHealthTracking()
// PhoneSessionManager.shared.resetHealthData()

// MARK: - cancelWorkout() erweitern

// In cancelWorkout():
//
// // NEU: User fragen ob Health-Daten gespeichert werden sollen
// // (Alert wird über neuen @State showCancelHealthAlert gesteuert)
// // Bei "Behalten" → PhoneSessionManager.shared.sendStopHealthTracking()
// // Bei "Verwerfen" → PhoneSessionManager.shared.sendDiscardHealthTracking()
// PhoneSessionManager.shared.resetHealthData()

// MARK: - Neue Hilfsfunktion

// private func saveCurrentExerciseMetrics() {
//     guard let snapshot = PhoneSessionManager.shared.lastExerciseSnapshot,
//           let key = selectedExerciseKey else { return }
//
//     let name = session.safeExerciseSets
//         .first(where: { $0.groupKey == key })?
//         .exerciseNameSnapshot ?? ""
//
//     let metrics = ExerciseMetrics(
//         exerciseGroupKey: key,
//         exerciseNameSnapshot: name,
//         avgHeartRate: snapshot.avgHR,
//         minHeartRate: snapshot.minHR,
//         maxHeartRate: snapshot.maxHR,
//         activeCalories: snapshot.calories,
//         durationSeconds: snapshot.durationSeconds
//     )
//     metrics.session = session
//     context.insert(metrics)
// }
```

### 5.10 Cancel-Alert mit Health-Entscheidung

```swift
// Neuer Alert in ActiveWorkoutView — ersetzt den bestehenden Cancel-Alert:

// @State private var showCancelHealthAlert = false

// .alert("Training verwerfen", isPresented: $showCancelHealthAlert) {
//     Button("Health-Daten behalten") {
//         PhoneSessionManager.shared.sendStopHealthTracking()
//         PhoneSessionManager.shared.resetHealthData()
//         cancelWorkoutCore()
//     }
//     Button("Alles verwerfen", role: .destructive) {
//         PhoneSessionManager.shared.sendDiscardHealthTracking()
//         PhoneSessionManager.shared.resetHealthData()
//         cancelWorkoutCore()
//     }
//     Button("Abbrechen", role: .cancel) {}
// } message: {
//     Text("Möchtest du die Health-Daten (HR, Kalorien) in Apple Health behalten oder ebenfalls verwerfen?")
// }
//
// Hinweis: showCancelHealthAlert wird nur gezeigt wenn isWatchTrackingActive == true.
// Ansonsten wird der bestehende Cancel-Flow verwendet.
```

### 5.11 LiveHealthCard (NEU — iPhone UI)

```swift
// LiveHealthCard.swift — iPhone Target

// Kompakte GlassCard mit HR + Kalorien.
// Wird nur angezeigt wenn Watch Health-Tracking aktiv ist.

// Layout:
// ┌──────────────────────────────────────┐
// │  ❤️ 142 bpm       🔥 287 kcal       │
// │  Ø 128  ↑ 158     aktive Kalorien   │
// └──────────────────────────────────────┘

// Parameter:
//   currentHR: Double
//   averageHR: Double
//   maxHR: Double
//   activeCalories: Double

// Design: .glassCard(), ❤️ mit roter Farbe, sanftes Pulsieren bei aktueller HR
// Nur anzeigen wenn mindestens ein Wert > 0
```

### 5.12 ActiveWorkoutStatus — Watch-Indikator

```swift
// ActiveWorkoutStatus.swift — neuer optionaler Parameter:
//
// let watchConnectionState: WatchConnectionState   // Default: .hidden

// Enum:
// enum WatchConnectionState {
//     case hidden             // Keine Watch gekoppelt → kein Icon
//     case connected          // Watch da, aber kein HR-Tracking
//     case activeTracking     // HKWorkoutSession läuft, HR kommt rein
//     case disconnected       // Verbindung verloren
// }

// Anzeige: ⌚ Icon (systemName: "applewatch"), ~12pt
//   .activeTracking → grün, sanft pulsierend
//   .connected → blau, statisch
//   .disconnected → grau, statisch
//   .hidden → kein Icon

// Platzierung: Links neben dem Timer-Icon im bestehenden HStack
// Bestehende Preview-Aufrufe brechen nicht (Default = .hidden)
```

### 5.13 AppSettings — Neues Setting

```swift
// In AppSettings.swift:

// MARK: Workout Health-Tracking

@Published var enableLiveHeartbeatTimer: Bool {
    didSet {
        UserDefaults.standard.set(enableLiveHeartbeatTimer, forKey: "workout.enableLiveHeartbeatTimer")
    }
}

// Im init():
// self.enableLiveHeartbeatTimer = UserDefaults.standard.bool(forKey: "workout.enableLiveHeartbeatTimer")
// Default: false (Event-basiert reicht für die meisten User)
```

### 5.14 WatchBaseView — HealthKit Authorization

```swift
// In WatchBaseView.swift — Settings-Section ergänzen:
//
// Section("Health") {
//     Button("HealthKit-Zugriff erlauben") {
//         Task {
//             let manager = WatchWorkoutManager()
//             let success = await manager.requestAuthorization()
//             // Status anzeigen (checkmark oder Fehler)
//         }
//     }
// }
//
// Hinweis: Muss VOR dem ersten Workout-Start einmal getippt werden.
// Danach merkt sich das System die Berechtigung.
```

### 5.15 WatchActiveWorkoutView — HR-Anzeige

```swift
// In WatchActiveWorkoutView.swift — nach dem Timer:
//
// if let manager = watchSession.workoutManager,
//    manager.currentHeartRate > 0 {
//     HStack(spacing: 4) {
//         Image(systemName: "heart.fill")
//             .foregroundStyle(.red)
//             .font(.caption2)
//         Text("\(Int(manager.currentHeartRate))")
//             .font(.system(.caption, design: .monospaced))
//     }
// }
//
// Hinweis: watchSession ist WatchSessionManager, der jetzt workoutManager als Property hat.
```

### 5.16 HealthDataCalcEngine (NEU — iPhone)

```swift
// HealthDataCalcEngine.swift — iPhone Target
// Pure Struct, keine Side Effects.

struct HealthDataCalcEngine {

    /// Berechnet Session-Zusammenfassung aus allen ExerciseMetrics.
    func sessionSummary(from metrics: [ExerciseMetrics]) -> SessionHealthSummary {
        guard !metrics.isEmpty else {
            return SessionHealthSummary(avgHR: 0, maxHR: 0, totalCalories: 0, totalDuration: 0)
        }

        let allAvgHR = metrics.map { $0.avgHeartRate }.filter { $0 > 0 }
        let avgHR = allAvgHR.isEmpty ? 0 : allAvgHR.reduce(0, +) / Double(allAvgHR.count)
        let maxHR = metrics.map { $0.maxHeartRate }.max() ?? 0
        let totalCalories = metrics.map { $0.activeCalories }.max() ?? 0 // Kumulativ von Watch
        let totalDuration = metrics.reduce(0) { $0 + $1.durationSeconds }

        return SessionHealthSummary(
            avgHR: avgHR,
            maxHR: maxHR,
            totalCalories: totalCalories,
            totalDuration: totalDuration
        )
    }
}

struct SessionHealthSummary {
    let avgHR: Double
    let maxHR: Double
    let totalCalories: Double
    let totalDuration: Int  // Sekunden
}
```

---

## 6. Fallback-Strategie

```
Watch verbunden? ──┬── JA  → HKWorkoutSession starten
                   │         → LiveHealthCard anzeigen
                   │         → HR/Kalorien bei Set-Completion + Heartbeat empfangen
                   │
                   └── NEIN → Workout startet normal (wie heute)
                              → LiveHealthCard wird NICHT angezeigt
                              → ⌚ Icon: .hidden
                              → calories/heartRate bleiben 0 auf StrengthSession
                              → Kein Error, kein Alert
```

**Verbindungsverlust während des Workouts:**
- `HKWorkoutSession` läuft auf der Watch weiter (unabhängig vom iPhone)
- Die Watch speichert das HKWorkout lokal in Apple Health
- `LiveHealthCard` zeigt letzten bekannten Wert + "Nicht verbunden"-Hinweis
- Bei `finishWorkout()`: iPhone sendet Stop → Watch empfängt beim nächsten Connect

---

## 7. Pause-Synchronisation

```
iPhone pausiert (ActiveSessionManager.pauseSession)
    │
    ├─► PhoneSessionManager.sendPauseHealthTracking()
    │
    └─► Watch: workoutManager?.pauseWorkout()
          └─► HKWorkoutSession.pause()
                ├─► HR-Sensor stoppt
                ├─► Kalorien-Zählung stoppt
                └─► Builder pausiert automatisch

iPhone resumed (ActiveSessionManager.resumeSession)
    │
    ├─► PhoneSessionManager.sendResumeHealthTracking()
    │
    └─► Watch: workoutManager?.resumeWorkout()
          └─► HKWorkoutSession.resume()
                └─► Alles läuft weiter
```

---

## 8. Berechtigungen und Info.plist

### Watch App — Info.plist

```xml
<key>NSHealthShareUsageDescription</key>
<string>MotionCore benötigt Zugriff auf deine Gesundheitsdaten, um Herzfrequenz und Kalorienverbrauch während des Trainings zu tracken.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>MotionCore speichert deine Trainings in Apple Health, damit sie in deiner Gesundheitsübersicht erscheinen.</string>
```

### Watch App — Capabilities

- HealthKit Capability aktivieren im Watch-Target
- Background Modes: "Workout processing" aktivieren

### iPhone App — HealthKitManager

- `typesToRead` bleibt unverändert
- `toShare` bleibt `[]` auf dem iPhone (nur die Watch schreibt Workouts)
- Die Watch hat ihre eigene Auth via `WatchWorkoutManager.requestAuthorization()`

---

## 9. Implementierungsreihenfolge

Jeder Schritt ist einzeln baubar und testbar. Kein Schritt hat Forward-Dependencies.

### Phase 1: Foundation (Watch-seitig)

| # | Schritt | Dateien | Prüfung |
|---|---|---|---|
| 1 | Info.plist + Capabilities | Watch Info.plist, Xcode Capabilities | Build erfolgreich |
| 2 | `WatchHealthDataTypes.swift` | NEU (Shared, beide Targets) | Build erfolgreich |
| 3 | `WatchWorkoutManager.swift` | NEU (Watch) | Build erfolgreich |
| 4 | `WatchBaseView.swift` | ÄNDERUNG: HealthKit-Auth Button | Build erfolgreich, Auth-Dialog erscheint |
| 5 | `WatchSessionManager.swift` | ÄNDERUNG: `workoutManager` Property + Lifecycle-Handling | Build erfolgreich |
| 6 | **BUILD + DEVICE TEST** | — | Auth genehmigen → Workout starten → Console: HR-Samples ankommen |

### Phase 2: Kommunikation (Watch → iPhone)

| # | Schritt | Dateien | Prüfung |
|---|---|---|---|
| 7 | `PhoneSessionManager.swift` | ÄNDERUNG: Published Health-Properties, Empfang, Lifecycle-Methoden | Build erfolgreich |
| 8 | `WatchSessionManager.swift` | ÄNDERUNG: Snapshot-Senden, Heartbeat-Timer | Build erfolgreich |
| 9 | **BUILD + DEVICE TEST** | — | Set abschließen → Console: Snapshot empfangen auf iPhone |

### Phase 3: iPhone Model + UI

| # | Schritt | Dateien | Prüfung |
|---|---|---|---|
| 10 | `ExerciseMetrics.swift` | NEU (iPhone) | Build erfolgreich |
| 11 | `StrengthSession.swift` | ÄNDERUNG: Inverse Relationship + safeExerciseMetrics | Build erfolgreich |
| 12 | `HealthDataCalcEngine.swift` | NEU (iPhone) | Build erfolgreich |
| 13 | `LiveHealthCard.swift` | NEU (iPhone) | Build erfolgreich, Preview sieht gut aus |
| 14 | `ActiveWorkoutStatus.swift` | ÄNDERUNG: watchConnectionState Parameter + ⌚ Icon | Build erfolgreich, Previews brechen nicht |
| 15 | **BUILD + TEST** | — | Preview-Check aller neuen/geänderten Views |

### Phase 4: Integration + Settings

| # | Schritt | Dateien | Prüfung |
|---|---|---|---|
| 16 | `AppSettings.swift` | ÄNDERUNG: enableLiveHeartbeatTimer | Build erfolgreich |
| 17 | `WorkoutSettingsView.swift` | ÄNDERUNG: Toggle für Heartbeat-Timer | Build erfolgreich |
| 18 | `ActiveWorkoutView.swift` | ÄNDERUNG: Health-Integration (Start, LiveHealthCard, completeSet, Transition, Finish, Cancel) | Build erfolgreich |
| 19 | **BUILD + DEVICE TEST** | — | Kompletter Flow: Start → Sätze → Pause → Finish → Apple Health prüfen |

### Phase 5: Polish

| # | Schritt | Dateien | Prüfung |
|---|---|---|---|
| 20 | `WatchActiveWorkoutView.swift` | ÄNDERUNG: HR-Anzeige | Build erfolgreich |
| 21 | Cancel-Alert mit Health-Entscheidung | `ActiveWorkoutView.swift` | Flow testen: Cancel → Health behalten vs. verwerfen |
| 22 | Fallback testen | — | Watch nicht verbunden → Workout läuft normal ohne Fehler |

### Phase 6: Optional / Ausbau (nicht im Scope)

| # | Schritt | Beschreibung |
|---|---|---|
| 23 | `StrengthDetailView` | HR/Kalorien pro Übung in der Session-Detailansicht anzeigen |
| 24 | Supabase-Schema | `exercise_metrics` Tabelle für pro-Übung Health-Daten |
| 25 | HR-Trend-Chart | Mini-Chart mit HR-Verlauf über die Session |

---

## 10. Akku-Analyse

| Faktor | Impact | Begründung |
|---|---|---|
| `HKWorkoutSession` im Hintergrund | **Sehr gering** | Apple-optimiert, nativer Sensor-Chip |
| HR-Sensor aktiv (1.5h) | **~3–5%** | Standard für Workout-Tracking |
| WatchConnectivity Event-basiert | **Minimal** | ~20–30 Transfers pro Session |
| Heartbeat-Timer (optional, 60 Sek) | **~1–2% extra** | ~90 zusätzliche Transfers bei 1.5h Session |
| **Gesamt geschätzt** | **4–7%** | Weniger als Apple Fitness (~8–12%) |

---

## 11. SwiftData ModelContainer

`ExerciseMetrics` muss zum ModelContainer hinzugefügt werden:

```swift
// In der ModelContainer-Konfiguration (MotionCoreApp.swift oder SwiftDataFactory.swift):
// Schema: [StrengthSession.self, ExerciseSet.self, ..., ExerciseMetrics.self]
```

**Hinweis:** Da `ExerciseMetrics` ein komplett neues Model ist (nicht umbenannt oder migriert), braucht es keine explizite Migration. SwiftData erstellt die Tabelle automatisch beim ersten Start.

---

## 12. Risiken und Mitigationen

| Risiko | Wahrscheinlichkeit | Mitigation |
|---|---|---|
| Watch-Connectivity bricht ab | Mittel | HKWorkoutSession läuft unabhängig weiter. Daten in Health gespeichert |
| HealthKit-Berechtigung verweigert | Gering | Graceful Degradation: kein HR-Tracking, kein Error |
| Watch-Akku stirbt während Workout | Sehr gering | iPhone-Workout läuft weiter, HR-Felder bleiben leer |
| CloudKit-Sync durch neues Model | Gering | `ExerciseMetrics` hat optionale Felder + Default-Werte |
| `HKWorkoutSession` im Simulator | Sicher | Nur auf echter Hardware testbar |
| PhoneSessionManager als class (nicht @Observable) | Kein Risiko | Ist bereits `NSObject` — `@Published` Properties funktionieren per Combine |

---

## 13. Nicht im Scope

- **Cardio/Outdoor Sessions:** Nur Krafttraining (`StrengthSession`). Cardio + Outdoor separat.
- **Historische Backfills:** Alte Sessions bekommen keine HR-Daten nachträglich.
- **HR-basierte Empfehlungen:** Keine Pausenempfehlungen basierend auf HR.
- **Eigenständiges Watch-Workout:** Watch bleibt Remote-Control, kein eigenständiges Starten.
- **HealthKitManager iPhone-Write:** iPhone schreibt keine Workouts. Nur die Watch.
