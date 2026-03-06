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

    /// Empfängt State-Updates vom iPhone
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
        }
    }
}
