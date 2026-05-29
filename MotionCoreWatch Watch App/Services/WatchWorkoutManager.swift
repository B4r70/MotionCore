//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Watch Integration                                                /
// Datei . . . . : WatchWorkoutManager.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 31.03.2026                                                       /
// Beschreibung  : Verwaltet HKWorkoutSession und HKLiveWorkoutBuilder auf der Watch /
//                 Trackt HR und Kalorien pro Übung und gesamt                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Combine
import Foundation
import HealthKit
import WatchConnectivity

// MARK: - Watch Workout Manager

/// Startet und verwaltet eine HKWorkoutSession für Krafttraining auf der Watch.
/// Publiziert Live-HR- und Kalorienmetriken und erstellt pro Übung Snapshots.
final class WatchWorkoutManager: NSObject, ObservableObject {

    // MARK: - Published State

    @Published private(set) var currentHeartRate: Double = 0
    @Published private(set) var averageHeartRate: Double = 0
    @Published private(set) var maxHeartRate: Double = 0
    @Published private(set) var activeCalories: Double = 0
    @Published private(set) var isActive: Bool = false

    // MARK: - Private Properties

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    // Gecachte HK-Typen und Einheiten — vermeiden wiederholte Allokation in didCollectDataOf
    private let hrType   = HKQuantityType(.heartRate)
    private let calType  = HKQuantityType(.activeEnergyBurned)
    private let hrUnit   = HKUnit.count().unitDivided(by: .minute())
    private let calUnit  = HKUnit.kilocalorie()

    /// HR-Samples für die aktuelle Übung (wird bei Transition zurückgesetzt)
    private var heartRateSamplesForExercise: [Double] = []
    private var minHRForExercise: Double = .infinity

    /// Startzeit der aktuellen Übung (für Snapshot-Dauer)
    private var exerciseStartDate: Date?

    /// Kalorien zu Beginn der aktuellen Übung (für Snapshot-Delta)
    private var caloriesAtExerciseStart: Double = 0

    // MARK: - HealthKit Auth

    /// Fordert HealthKit-Berechtigung an.
    /// Gibt true zurück wenn Schreiben genehmigt wurde, false sonst.
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        let typesToShare: Set<HKSampleType> = [
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.heartRate),
            HKObjectType.workoutType()
        ]

        let typesToRead: Set<HKObjectType> = [
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.heartRate),
            HKObjectType.workoutType()
        ]

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            return true
        } catch {
            print("WatchWorkoutManager: HealthKit-Auth fehlgeschlagen: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Workout Lifecycle

    /// Startet eine neue HKWorkoutSession für traditionelles Krafttraining.
    func startWorkout() async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor

        let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
        let builder = session.associatedWorkoutBuilder()

        session.delegate = self
        builder.delegate = self
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)

        workoutSession = session
        workoutBuilder = builder

        // Session und Builder starten
        let startDate = Date()
        session.startActivity(with: startDate)
        try await builder.beginCollection(at: startDate)

        await MainActor.run {
            self.exerciseStartDate = startDate
            self.caloriesAtExerciseStart = 0
            self.isActive = true
        }
    }

    /// Pausiert das laufende Workout.
    func pauseWorkout() {
        workoutSession?.pause()
    }

    /// Setzt ein pausiertes Workout fort.
    func resumeWorkout() {
        workoutSession?.resume()
    }

    /// Beendet das Workout und speichert es in Apple Health.
    func endWorkout() async {
        guard let session = workoutSession, let builder = workoutBuilder else { return }

        let endDate = Date()
        session.end()

        do {
            try await builder.endCollection(at: endDate)
            try await builder.finishWorkout()
        } catch {
            print("WatchWorkoutManager: Fehler beim Beenden des Workouts: \(error.localizedDescription)")
        }

        await MainActor.run {
            self.cleanup()
        }
    }

    /// Verwirft das Workout ohne es in Apple Health zu speichern.
    func discardWorkout() async {
        guard let session = workoutSession, let builder = workoutBuilder else { return }

        let endDate = Date()
        session.end()

        // endCollection abwarten — erst danach ist builder.discardWorkout() gültig
        do {
            try await builder.endCollection(at: endDate)
            builder.discardWorkout()
        } catch {
            print("WatchWorkoutManager: Fehler beim Verwerfen des Workouts: \(error.localizedDescription)")
        }

        await MainActor.run { self.cleanup() }
    }

    /// Markiert eine Übungs-Transition — setzt pro-Übung-Tracking zurück.
    func markExerciseTransition() {
        heartRateSamplesForExercise = []
        minHRForExercise = .infinity
        exerciseStartDate = Date()
        caloriesAtExerciseStart = activeCalories
    }

    // MARK: - Snapshots

    /// Gibt den aktuellen Live-Status als Dictionary zurück (für Heartbeat-Updates).
    func currentSnapshot() -> [String: Any] {
        return [
            WatchHealthKey.currentHR:      currentHeartRate,
            WatchHealthKey.averageHR:      averageHeartRate,
            WatchHealthKey.maxHR:          maxHeartRate,
            WatchHealthKey.activeCalories: activeCalories,
            WatchHealthKey.isWorkoutActive: isActive
        ]
    }

    /// Gibt den Übungs-Snapshot als Dictionary zurück (für Set-Completion).
    func exerciseSnapshot() -> [String: Any] {
        let avgHR: Double
        if heartRateSamplesForExercise.isEmpty {
            avgHR = 0
        } else {
            avgHR = heartRateSamplesForExercise.reduce(0, +) / Double(heartRateSamplesForExercise.count)
        }

        let minHR = minHRForExercise == .infinity ? 0 : minHRForExercise
        let caloriesDelta = activeCalories - caloriesAtExerciseStart
        let duration: Int
        if let startDate = exerciseStartDate {
            duration = Int(Date().timeIntervalSince(startDate))
        } else {
            duration = 0
        }

        return [
            WatchExerciseSnapshotKey.snapshotAvgHR:    avgHR,
            WatchExerciseSnapshotKey.snapshotMinHR:    minHR,
            WatchExerciseSnapshotKey.snapshotMaxHR:    maxHeartRate,
            WatchExerciseSnapshotKey.snapshotCalories: max(0, caloriesDelta),
            WatchExerciseSnapshotKey.snapshotDuration: duration
        ]
    }

    // MARK: - Private Helpers

    /// Setzt alle internen Zustände zurück.
    private func cleanup() {
        workoutSession = nil
        workoutBuilder = nil
        heartRateSamplesForExercise = []
        minHRForExercise = .infinity
        exerciseStartDate = nil
        caloriesAtExerciseStart = 0
        currentHeartRate = 0
        averageHeartRate = 0
        maxHeartRate = 0
        activeCalories = 0
        isActive = false
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchWorkoutManager: HKWorkoutSessionDelegate {

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.isActive = toState == .running
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("WatchWorkoutManager: Session-Fehler: \(error.localizedDescription)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            // Herzfrequenz auslesen
            if collectedTypes.contains(self.hrType) {
                if let stats = workoutBuilder.statistics(for: self.hrType) {
                    // Aktuelle HR (letzter Wert)
                    if let mostRecent = stats.mostRecentQuantity() {
                        let hr = mostRecent.doubleValue(for: self.hrUnit)
                        self.currentHeartRate = hr
                        self.heartRateSamplesForExercise.append(hr)
                        if hr < self.minHRForExercise {
                            self.minHRForExercise = hr
                        }
                    }
                    // Durchschnittliche HR seit Workout-Start
                    if let avg = stats.averageQuantity() {
                        self.averageHeartRate = avg.doubleValue(for: self.hrUnit)
                    }
                    // Maximale HR seit Workout-Start
                    if let max = stats.maximumQuantity() {
                        self.maxHeartRate = max.doubleValue(for: self.hrUnit)
                    }
                }
            }

            // Aktive Kalorien auslesen
            if collectedTypes.contains(self.calType) {
                if let stats = workoutBuilder.statistics(for: self.calType),
                   let sum = stats.sumQuantity() {
                    self.activeCalories = sum.doubleValue(for: self.calUnit)
                }
            }
        }
    }
}
