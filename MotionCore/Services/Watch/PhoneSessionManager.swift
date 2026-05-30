//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Watch Integration                                                /
// Datei . . . . : PhoneSessionManager.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.03.2026                                                       /
// Beschreibung  : Verwaltet WatchConnectivity auf iPhone-Seite                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import WatchConnectivity
import Combine

// MARK: - Exercise Snapshot Data

/// Enthält aggregierte Gesundheitsdaten für eine einzelne Übung
struct ExerciseSnapshotData {
    let avgHR: Double
    let minHR: Double
    let maxHR: Double
    let calories: Double
    let durationSeconds: Int
}

// MARK: - Phone Session Manager

/// Verwaltet die WCSession auf dem iPhone
/// Sendet Workout-State-Updates an die Watch und empfängt Actions sowie Health-Daten
final class PhoneSessionManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = PhoneSessionManager()

    // MARK: - Callbacks

    /// Wird aufgerufen wenn die Watch eine Action sendet.
    /// Muss vom Main Thread aus gesetzt werden.
    var onAction: ((WatchAction) -> Void)?

    /// Wird aufgerufen wenn die Watch erreichbar wird (sessionReachabilityDidChange → isReachable = true).
    /// Ermöglicht sofortigen State-Push ohne auf das nächste onChange-Event zu warten.
    var onWatchBecameReachable: (() -> Void)?

    // MARK: - Live Health Data (Watch → iPhone)

    @Published var liveCurrentHR: Double = 0
    @Published var liveAverageHR: Double = 0
    @Published var liveMaxHR: Double = 0
    @Published var liveActiveCalories: Double = 0
    @Published var isWatchTrackingActive: Bool = false
    @Published var lastExerciseSnapshot: ExerciseSnapshotData?

    // MARK: - Init

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - State senden

    /// Sendet den aktuellen Workout-State an die Watch
    func sendWorkoutState(
        state: WatchWorkoutState,
        exerciseName: String,
        setIndex: Int,
        totalSets: Int,
        exerciseIndex: Int,
        totalExercises: Int,
        elapsedTime: TimeInterval,
        isResting: Bool = false,
        restEndDate: Date? = nil
    ) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else {
            print("PhoneSessionManager: Watch nicht erreichbar, State-Update verworfen.")
            return
        }

        var message: [String: Any] = [
            WatchStateKey.workoutState:   state.rawValue,
            WatchStateKey.exerciseName:   exerciseName,
            WatchStateKey.setIndex:       setIndex,
            WatchStateKey.totalSets:      totalSets,
            WatchStateKey.exerciseIndex:  exerciseIndex,
            WatchStateKey.totalExercises: totalExercises,
            WatchStateKey.elapsedTime:    elapsedTime,
            WatchStateKey.isResting:      isResting
        ]

        // restEndDate nur mitsenden wenn ein Timer läuft
        if let restEndDate {
            message[WatchStateKey.restEndDate] = restEndDate.timeIntervalSinceReferenceDate
        }

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("PhoneSessionManager: Fehler beim Senden: \(error.localizedDescription)")
        }
    }

    /// Sendet den Idle-State wenn kein Workout aktiv ist
    func sendIdleState() {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else {
            print("PhoneSessionManager: Watch nicht erreichbar, Idle-State verworfen.")
            return
        }

        let message: [String: Any] = [
            WatchStateKey.workoutState: WatchWorkoutState.idle.rawValue
        ]

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("PhoneSessionManager: Fehler beim Senden von Idle-State: \(error.localizedDescription)")
        }
    }

    // MARK: - Health Tracking Lifecycle

    /// Startet das Health-Tracking auf der Watch.
    func sendStartHealthTracking() {
        updateDesiredHealthState(.active)
        sendLifecycleMessage([WatchWorkoutLifecycleKey.startHealthTracking: true])
        DispatchQueue.main.async {
            self.isWatchTrackingActive = true
        }
    }

    /// Beendet das Health-Tracking und speichert das Workout in Apple Health.
    func sendStopHealthTracking() {
        updateDesiredHealthState(.finished)
        sendGuaranteedLifecycle([WatchWorkoutLifecycleKey.stopHealthTracking: true])
        DispatchQueue.main.async {
            self.isWatchTrackingActive = false
        }
    }

    /// Verwirft das Health-Tracking ohne Speicherung in Apple Health.
    func sendDiscardHealthTracking() {
        updateDesiredHealthState(.discarded)
        sendGuaranteedLifecycle([WatchWorkoutLifecycleKey.discardHealthTracking: true])
        DispatchQueue.main.async {
            self.isWatchTrackingActive = false
            self.resetHealthData()
        }
    }

    /// Pausiert das Health-Tracking auf der Watch.
    func sendPauseHealthTracking() {
        sendLifecycleMessage([WatchWorkoutLifecycleKey.pauseHealthTracking: true])
    }

    /// Setzt das Health-Tracking auf der Watch fort.
    func sendResumeHealthTracking() {
        sendLifecycleMessage([WatchWorkoutLifecycleKey.resumeHealthTracking: true])
    }

    /// Signalisiert der Watch eine Übungs-Transition (HR-Samples zurücksetzen).
    func sendExerciseTransition() {
        sendLifecycleMessage([WatchWorkoutLifecycleKey.exerciseTransition: true])
    }

    /// Fordert einen kombinierten Health-Snapshot von der Watch an.
    func sendRequestSnapshot() {
        sendLifecycleMessage([WatchWorkoutLifecycleKey.requestSnapshot: true])
    }

    /// Aktiviert oder deaktiviert den Heartbeat-Timer auf der Watch.
    func sendHeartbeatEnabled(_ enabled: Bool) {
        sendLifecycleMessage([WatchHeartbeatKey.enableHeartbeat: enabled])
    }

    /// Fordert einen finalen Snapshot von der Watch via Request/Response an.
    /// Wartet maximal 3 Sekunden auf eine Antwort.
    /// Gibt `true` zurück wenn der Snapshot erfolgreich empfangen wurde, sonst `false`.
    func requestFinalSnapshot() async -> Bool {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else {
            print("PhoneSessionManager: Watch nicht erreichbar, finaler Snapshot übersprungen.")
            return false
        }

        return await withCheckedContinuation { continuation in
            // Sicherheits-Flag — alle Zugriffe laufen auf dem Main Thread (serialisiert)
            var resumed = false

            // Timeout nach 3 Sekunden — auf Main Thread serialisiert
            let timeoutTask = Task {
                try? await Task.sleep(for: .seconds(3))
                DispatchQueue.main.async {
                    guard !resumed else { return }
                    resumed = true
                    continuation.resume(returning: false)
                }
            }

            WCSession.default.sendMessage(
                [WatchWorkoutLifecycleKey.requestSnapshot: true],
                replyHandler: { [weak self] reply in
                    timeoutTask.cancel()
                    DispatchQueue.main.async {
                        guard !resumed else { return }
                        resumed = true
                        guard let self else {
                            continuation.resume(returning: false)
                            return
                        }
                        // Snapshot-Daten in Live-Properties übernehmen
                        if let hr = reply[WatchHealthKey.currentHR] as? Double {
                            self.liveCurrentHR = hr
                        }
                        if let avg = reply[WatchHealthKey.averageHR] as? Double {
                            self.liveAverageHR = avg
                        }
                        if let max = reply[WatchHealthKey.maxHR] as? Double {
                            self.liveMaxHR = max
                        }
                        if let cal = reply[WatchHealthKey.activeCalories] as? Double {
                            self.liveActiveCalories = cal
                        }
                        continuation.resume(returning: true)
                    }
                },
                errorHandler: { error in
                    timeoutTask.cancel()
                    DispatchQueue.main.async {
                        guard !resumed else { return }
                        resumed = true
                        print("PhoneSessionManager: Fehler beim finalen Snapshot: \(error.localizedDescription)")
                        continuation.resume(returning: false)
                    }
                }
            )
        }
    }

    /// Setzt alle Live-Health-Daten zurück (inkl. Tracking-Flag).
    func resetHealthData() {
        isWatchTrackingActive = false
        liveCurrentHR = 0
        liveAverageHR = 0
        liveMaxHR = 0
        liveActiveCalories = 0
        lastExerciseSnapshot = nil
    }

    /// Sendet eine Lifecycle-Nachricht mit garantierter Zustellung.
    /// Strategie: sendMessage (sofort, falls reachable) + transferUserInfo (garantiert, FIFO, Background).
    /// transferUserInfo schließt die Drop-bei-Unreachable-Lücke von sendLifecycleMessage.
    private func sendGuaranteedLifecycle(_ message: [String: Any]) {
        guard WCSession.default.activationState == .activated else {
            print("PhoneSessionManager: Session nicht aktiviert, Lifecycle-Message verworfen.")
            return
        }

        // Unique Command-ID für Deduplizierung auf der Watch
        var payload = message
        payload[WatchWorkoutLifecycleKey.lifecycleCommandID] = UUID().uuidString

        // Schnellpfad: sendMessage wenn Watch erreichbar (minimiert Auto-Save-Fenster)
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { error in
                print("PhoneSessionManager: Fehler beim Senden der garantierten Lifecycle-Message: \(error.localizedDescription)")
            }
        }

        // Garantierter Hintergrundpfad: transferUserInfo — immer, unabhängig von Erreichbarkeit
        _ = WCSession.default.transferUserInfo(payload)
    }

    /// Setzt den gewünschten Health-State im applicationContext der Watch.
    /// Der applicationContext ist persistent — die Watch liest ihn bei jedem Wake für Reconciliation.
    /// WICHTIG: Nur bei echten Zustands-Transitionen aufrufen — NICHT in sendIdleState(),
    /// um .finished/.discarded nicht zu überschreiben.
    func updateDesiredHealthState(_ state: WatchDesiredHealthState) {
        guard WCSession.default.activationState == .activated else { return }
        do {
            try WCSession.default.updateApplicationContext(
                [WatchDesiredHealthStateKey.desiredHealthState: state.rawValue]
            )
        } catch {
            print("PhoneSessionManager: updateApplicationContext fehlgeschlagen: \(error.localizedDescription)")
        }
    }

    /// Sendet eine Lifecycle-Nachricht an die Watch (fire-and-forget).
    private func sendLifecycleMessage(_ message: [String: Any]) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else {
            print("PhoneSessionManager: Watch nicht erreichbar, Lifecycle-Message verworfen.")
            return
        }

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("PhoneSessionManager: Fehler beim Senden der Lifecycle-Message: \(error.localizedDescription)")
        }
    }
}

// MARK: - WCSessionDelegate

extension PhoneSessionManager: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("PhoneSessionManager: Aktivierung fehlgeschlagen: \(error.localizedDescription)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Session nach Deaktivierung neu aktivieren (z.B. Watch-Wechsel)
        WCSession.default.activate()
    }

    /// Wird aufgerufen wenn sich die Erreichbarkeit der Watch ändert.
    /// Wenn die Watch erreichbar wird (z.B. App geöffnet), wird der Callback ausgelöst,
    /// damit ActiveWorkoutView sofort den State pusht.
    func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }
        DispatchQueue.main.async { [weak self] in
            self?.onWatchBecameReachable?()
        }
    }

    /// Empfängt Nachrichten von der Watch (Actions + Health-Daten)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {

        // Watch-Action verarbeiten (bestehende Logik)
        if let actionRaw = message[WatchActionKey.action] as? String,
           let action = WatchAction(rawValue: actionRaw) {
            DispatchQueue.main.async { [weak self] in
                self?.onAction?(action)
            }
            return
        }

        // Live-Health-Update verarbeiten (Heartbeat oder direkte Updates)
        if message[WatchHealthKey.healthUpdate] != nil {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if let hr = message[WatchHealthKey.currentHR] as? Double {
                    self.liveCurrentHR = hr
                }
                if let avg = message[WatchHealthKey.averageHR] as? Double {
                    self.liveAverageHR = avg
                }
                if let max = message[WatchHealthKey.maxHR] as? Double {
                    self.liveMaxHR = max
                }
                if let cal = message[WatchHealthKey.activeCalories] as? Double {
                    self.liveActiveCalories = cal
                }
            }
            return
        }

        // Übungs-Snapshot verarbeiten (nach Set-Completion oder Transition)
        if message[WatchExerciseSnapshotKey.exerciseSnapshot] != nil {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                // Live-Daten aktualisieren (aus kombiniertem Snapshot)
                if let hr = message[WatchHealthKey.currentHR] as? Double {
                    self.liveCurrentHR = hr
                }
                if let avg = message[WatchHealthKey.averageHR] as? Double {
                    self.liveAverageHR = avg
                }
                if let max = message[WatchHealthKey.maxHR] as? Double {
                    self.liveMaxHR = max
                }
                if let cal = message[WatchHealthKey.activeCalories] as? Double {
                    self.liveActiveCalories = cal
                }

                // Übungs-Snapshot speichern
                let snapshot = ExerciseSnapshotData(
                    avgHR:           message[WatchExerciseSnapshotKey.snapshotAvgHR] as? Double ?? 0,
                    minHR:           message[WatchExerciseSnapshotKey.snapshotMinHR] as? Double ?? 0,
                    maxHR:           message[WatchExerciseSnapshotKey.snapshotMaxHR] as? Double ?? 0,
                    calories:        message[WatchExerciseSnapshotKey.snapshotCalories] as? Double ?? 0,
                    durationSeconds: message[WatchExerciseSnapshotKey.snapshotDuration] as? Int ?? 0
                )
                self.lastExerciseSnapshot = snapshot
            }
        }
    }
}
