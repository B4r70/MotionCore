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

// MARK: - Phone Session Manager

/// Verwaltet die WCSession auf dem iPhone
/// Sendet Workout-State-Updates an die Watch und empfängt Actions
final class PhoneSessionManager: NSObject {

    // MARK: - Singleton

    static let shared = PhoneSessionManager()

    // MARK: - Callback für eingehende Actions

    /// Wird aufgerufen wenn die Watch eine Action sendet.
    /// Muss vom Main Thread aus gesetzt werden.
    var onAction: ((WatchAction) -> Void)?

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
        elapsedTime: TimeInterval
    ) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else {
            print("PhoneSessionManager: Watch nicht erreichbar, State-Update verworfen.")
            return
        }

        let message: [String: Any] = [
            WatchStateKey.workoutState:   state.rawValue,
            WatchStateKey.exerciseName:   exerciseName,
            WatchStateKey.setIndex:       setIndex,
            WatchStateKey.totalSets:      totalSets,
            WatchStateKey.exerciseIndex:  exerciseIndex,
            WatchStateKey.totalExercises: totalExercises,
            WatchStateKey.elapsedTime:    elapsedTime
        ]

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

    /// Empfängt Actions von der Watch
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let actionRaw = message[WatchActionKey.action] as? String,
              let action = WatchAction(rawValue: actionRaw) else { return }

        DispatchQueue.main.async { [weak self] in
            self?.onAction?(action)
        }
    }
}
