//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Watch Integration                                                /
// Datei . . . . : WatchSessionManager.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.03.2026                                                       /
// Beschreibung  : Verwaltet WatchConnectivity auf Watch-Seite                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import WatchConnectivity
import Combine
import HealthKit

// MARK: - Watch Session Manager

/// Verwaltet WCSession auf der Watch
/// Empfängt State-Updates vom iPhone und sendet Actions
final class WatchSessionManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = WatchSessionManager()

    // MARK: - Published State

    @Published private(set) var workoutState: WatchWorkoutState = .idle
    @Published private(set) var exerciseName: String = ""
    @Published private(set) var setIndex: Int = 0
    @Published private(set) var totalSets: Int = 0
    @Published private(set) var exerciseIndex: Int = 0
    @Published private(set) var totalExercises: Int = 0
    @Published private(set) var elapsedTime: TimeInterval = 0

    /// Aktiver WatchWorkoutManager — nil wenn kein Health-Tracking läuft
    @Published private(set) var workoutManager: WatchWorkoutManager?

    // MARK: - Private Properties (Heartbeat)

    private var heartbeatTimer: Timer?

    // MARK: - Init

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Action senden

    /// Sendet eine Action an das iPhone
    func sendAction(_ action: WatchAction) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else {
            print("WatchSessionManager: iPhone nicht erreichbar, Action verworfen.")
            return
        }

        let message: [String: Any] = [
            WatchActionKey.action: action.rawValue
        ]

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("WatchSessionManager: Fehler beim Senden: \(error.localizedDescription)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("WatchSessionManager: Aktivierung fehlgeschlagen: \(error.localizedDescription)")
        }
    }

    /// Empfängt State-Updates und Lifecycle-Kommandos vom iPhone
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            // Workout-State auslesen
            if let stateRaw = message[WatchStateKey.workoutState] as? String,
               let state = WatchWorkoutState(rawValue: stateRaw) {
                self.workoutState = state
            }

            // Übungs- und Satz-Daten auslesen
            self.exerciseName   = message[WatchStateKey.exerciseName] as? String ?? self.exerciseName
            self.setIndex       = message[WatchStateKey.setIndex] as? Int ?? self.setIndex
            self.totalSets      = message[WatchStateKey.totalSets] as? Int ?? self.totalSets
            self.exerciseIndex  = message[WatchStateKey.exerciseIndex] as? Int ?? self.exerciseIndex
            self.totalExercises = message[WatchStateKey.totalExercises] as? Int ?? self.totalExercises
            self.elapsedTime    = message[WatchStateKey.elapsedTime] as? TimeInterval ?? self.elapsedTime

            // Health-Tracking Lifecycle verarbeiten
            self.handleHealthLifecycle(message: message)
        }
    }
}

// MARK: - Health Tracking Lifecycle

extension WatchSessionManager {

    /// Verarbeitet Health-Lifecycle-Nachrichten vom iPhone.
    private func handleHealthLifecycle(message: [String: Any]) {

        // Health-Tracking starten (F1: Auth automatisch beim ersten Start)
        if message[WatchWorkoutLifecycleKey.startHealthTracking] != nil {
            let manager = WatchWorkoutManager()
            self.workoutManager = manager

            Task {
                // Erst Auth anfordern — wenn verweigert, trotzdem weiter (Fallback ohne HR)
                let authorized = await manager.requestAuthorization()
                if !authorized {
                    print("WatchSessionManager: HealthKit-Auth verweigert — Workout ohne HR-Tracking")
                }
                do {
                    try await manager.startWorkout()
                } catch {
                    print("WatchSessionManager: Workout-Start fehlgeschlagen: \(error.localizedDescription)")
                    await MainActor.run { self.workoutManager = nil }
                }
            }
        }

        // Health-Tracking beenden und in Apple Health speichern
        if message[WatchWorkoutLifecycleKey.stopHealthTracking] != nil {
            guard let manager = workoutManager else { return }
            stopHeartbeatTimer()
            Task {
                await manager.endWorkout()
                await MainActor.run { self.workoutManager = nil }
            }
        }

        // Health-Tracking verwerfen (kein Apple-Health-Eintrag)
        if message[WatchWorkoutLifecycleKey.discardHealthTracking] != nil {
            workoutManager?.discardWorkout()
            workoutManager = nil
            stopHeartbeatTimer()
        }

        // Pause
        if message[WatchWorkoutLifecycleKey.pauseHealthTracking] != nil {
            workoutManager?.pauseWorkout()
        }

        // Fortsetzen
        if message[WatchWorkoutLifecycleKey.resumeHealthTracking] != nil {
            workoutManager?.resumeWorkout()
        }

        // Übungs-Transition — pro-Übung-Tracking zurücksetzen
        if message[WatchWorkoutLifecycleKey.exerciseTransition] != nil {
            workoutManager?.markExerciseTransition()
        }

        // Snapshot anfordern — kombiniert Health + Exercise und sendet zurück
        if message[WatchWorkoutLifecycleKey.requestSnapshot] != nil {
            guard let manager = workoutManager else { return }
            var combined = manager.currentSnapshot()
            let exerciseSnap = manager.exerciseSnapshot()
            for (key, value) in exerciseSnap {
                combined[key] = value
            }
            combined[WatchExerciseSnapshotKey.exerciseSnapshot] = true
            sendSnapshotToPhone(combined)
        }

        // Heartbeat-Timer aktivieren oder deaktivieren
        if let enabled = message[WatchHeartbeatKey.enableHeartbeat] as? Bool {
            if enabled {
                startHeartbeatTimer()
            } else {
                stopHeartbeatTimer()
            }
        }
    }

    // MARK: - Heartbeat Timer

    /// Startet den 60-Sekunden-Heartbeat-Timer für periodische HR-Updates.
    private func startHeartbeatTimer() {
        stopHeartbeatTimer()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.sendHeartbeatUpdate()
        }
    }

    /// Stoppt den Heartbeat-Timer.
    private func stopHeartbeatTimer() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    /// Sendet ein periodisches HR-Update an das iPhone.
    private func sendHeartbeatUpdate() {
        guard let manager = workoutManager else { return }
        var snapshot = manager.currentSnapshot()
        snapshot[WatchHealthKey.healthUpdate] = true
        sendSnapshotToPhone(snapshot)
    }

    // MARK: - Snapshot senden

    /// Sendet einen Snapshot-Dictionary an das iPhone via WCSession.
    private func sendSnapshotToPhone(_ snapshot: [String: Any]) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else {
            print("WatchSessionManager: iPhone nicht erreichbar, Snapshot verworfen.")
            return
        }

        WCSession.default.sendMessage(snapshot, replyHandler: nil) { error in
            print("WatchSessionManager: Fehler beim Senden des Snapshots: \(error.localizedDescription)")
        }
    }
}
