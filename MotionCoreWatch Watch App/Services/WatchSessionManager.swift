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

    // MARK: - Published State (Live-Timer)

    /// Lokale verstrichene Sekunden (sekündlich inkrementiert, wird via iPhone-State synchronisiert)
    @Published private(set) var liveElapsedSeconds: TimeInterval = 0

    // MARK: - Published State (Rest-Timer)

    /// Gibt an ob auf dem iPhone gerade ein Rest-Timer läuft
    @Published private(set) var isResting: Bool = false

    /// Absolutes Enddatum des Rest-Timers (für Date-Anchor-Countdown in der Watch-UI)
    @Published private(set) var restEndDate: Date?

    // MARK: - Private Properties (Heartbeat + lokaler Timer)

    private var heartbeatTimer: Timer?
    private var localTimer: Timer?

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

            // elapsedTime aus iPhone-Nachricht als Basis für den Live-Timer setzen
            if let elapsed = message[WatchStateKey.elapsedTime] as? TimeInterval {
                self.liveElapsedSeconds = elapsed
            }

            // Rest-Timer-State aus iPhone-Nachricht auslesen
            if let resting = message[WatchStateKey.isResting] as? Bool {
                self.isResting = resting
            }
            if let endInterval = message[WatchStateKey.restEndDate] as? TimeInterval {
                self.restEndDate = Date(timeIntervalSinceReferenceDate: endInterval)
            } else if !(message[WatchStateKey.isResting] as? Bool ?? false) {
                // isResting = false ohne restEndDate → Timer abgelaufen oder nicht aktiv
                self.restEndDate = nil
            }

            // Lokaler Timer je nach Workout-State starten oder stoppen
            if self.workoutState == .active {
                self.startLocalTimer()
            } else {
                self.stopLocalTimer()
            }

            // Health-Tracking Lifecycle verarbeiten
            self.handleHealthLifecycle(message: message)

            // Self-Healing: Workout aktiv aber kein Health-Tracking läuft → auto-starten
            // Guard: nicht bei Stop/Discard auslösen (workoutManager ist dort gerade nil gesetzt worden,
            // aber workoutState noch nicht .idle — Idle kommt als separate Nachricht vom iPhone)
            let isStoppingNow = message[WatchWorkoutLifecycleKey.stopHealthTracking] != nil
                             || message[WatchWorkoutLifecycleKey.discardHealthTracking] != nil
            if self.workoutState != .idle && self.workoutManager == nil && !isStoppingNow {
                let manager = WatchWorkoutManager()
                self.workoutManager = manager
                Task {
                    let authorized = await manager.requestAuthorization()
                    guard authorized else {
                        // HealthKit verweigert — Self-Healing abbrechen
                        print("WatchSessionManager: HealthKit-Auth verweigert (Self-Healing)")
                        await MainActor.run { self.workoutManager = nil }
                        return
                    }
                    do {
                        try await manager.startWorkout()
                        // Heartbeat erst starten wenn Workout läuft und erste Werte vorliegen
                        try? await Task.sleep(for: .seconds(2))
                        await MainActor.run {
                            self.startHeartbeatTimer()
                            self.sendHeartbeatUpdate()
                        }
                    } catch {
                        print("WatchSessionManager: Self-Healing Workout-Start fehlgeschlagen: \(error.localizedDescription)")
                        await MainActor.run {
                            self.workoutManager = nil
                            self.stopLocalTimer()
                        }
                    }
                }
            }

            // liveElapsedSeconds auf 0 zurücksetzen wenn Workout endet
            if self.workoutState == .idle {
                self.liveElapsedSeconds = 0
            }
        }
    }

    /// Empfängt Nachrichten vom iPhone mit replyHandler (Request/Response)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        // Snapshot-Anforderung mit sofortiger Antwort via replyHandler
        if message[WatchWorkoutLifecycleKey.requestSnapshot] != nil {
            DispatchQueue.main.async { [weak self] in
                guard let self, let manager = self.workoutManager else {
                    replyHandler([:])
                    return
                }
                var combined = manager.currentSnapshot()
                let exerciseSnap = manager.exerciseSnapshot()
                for (key, value) in exerciseSnap {
                    combined[key] = value
                }
                combined[WatchExerciseSnapshotKey.exerciseSnapshot] = true
                replyHandler(combined)
            }
        } else {
            // Alle anderen Nachrichten mit leerem Reply quittieren
            replyHandler([:])
        }
    }
}

// MARK: - Health Tracking Lifecycle

extension WatchSessionManager {

    /// Verarbeitet Health-Lifecycle-Nachrichten vom iPhone.
    private func handleHealthLifecycle(message: [String: Any]) {

        // Health-Tracking starten (F1: Auth automatisch beim ersten Start)
        if message[WatchWorkoutLifecycleKey.startHealthTracking] != nil {
            if let existing = workoutManager {
                workoutManager = nil
                stopHeartbeatTimer()
                Task { await existing.discardWorkout() }
            }
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
                    // Initialen Snapshot nach Workout-Start senden (2s Wartezeit für ersten HR-Wert)
                    try? await Task.sleep(for: .seconds(2))
                    await MainActor.run { self.sendHeartbeatUpdate() }
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
            let manager = workoutManager
            workoutManager = nil
            stopHeartbeatTimer()
            Task {
                // discardWorkout ist async — muss endCollection abwarten bevor discard gültig ist
                await manager?.discardWorkout()
            }
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

    /// Startet den 5-Sekunden-Heartbeat-Timer für periodische HR-Updates.
    private func startHeartbeatTimer() {
        stopHeartbeatTimer()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.sendHeartbeatUpdate()
        }
    }

    /// Stoppt den Heartbeat-Timer.
    private func stopHeartbeatTimer() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    /// Startet den lokalen 1-Sekunden-Timer für den Live-Timer.
    private func startLocalTimer() {
        stopLocalTimer()
        localTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.liveElapsedSeconds += 1
        }
    }

    /// Stoppt den lokalen Live-Timer.
    private func stopLocalTimer() {
        localTimer?.invalidate()
        localTimer = nil
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
