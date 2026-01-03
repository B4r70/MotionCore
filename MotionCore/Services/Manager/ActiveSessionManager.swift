//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Session-Management                                               /
// Datei . . . . : ActiveSessionManager.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 31.12.2025                                                       /
// Beschreibung  : Verwaltet aktive Workout-Sessions über App-Lebenszyklen hinweg   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Dieser Manager speichert den Zustand einer aktiven Session,       /
//                sodass sie nach App-Beendigung oder iPhone-Neustart               /
//                wiederhergestellt werden kann.                                    /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Active Session State

// Zustand einer pausierten Session (für UserDefaults-Persistenz)
struct ActiveSessionState: Codable {
    let sessionUUID: String          // PersistentIdentifier als String
    let workoutType: String          // WorkoutType rawValue
    let startedAt: Date              // Original-Startzeit
    let pausedAt: Date               // Referenzpunkt (historisch: "pausedAt", faktisch: "lastResumedAt")
    let accumulatedSeconds: Int      // Bereits angesammelte Zeit vor dem aktuellen Lauf
    let isPaused: Bool               // Ist die Session pausiert?
    let selectedExerciseIndex: Int?  // Ausgewählte Übung innerhalb eines Trainings

    // Berechnet die Gesamtzeit inkl. der Zeit seit Referenzpunkt (falls nicht pausiert)
    func totalElapsedSeconds(at date: Date = Date()) -> Int {
        if isPaused {
            return accumulatedSeconds
        } else {
            let additionalSeconds = Int(date.timeIntervalSince(pausedAt))
            return accumulatedSeconds + max(0, additionalSeconds)
        }
    }
}

// MARK: - Active Session Manager

// Verwaltet den Zustand der aktuell aktiven Workout-Session
class ActiveSessionManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ActiveSessionManager()

    // MARK: - Published Properties

    // Gibt es eine aktive Session?
    @Published private(set) var hasActiveSession: Bool = false

    // Typ der aktiven Session
    @Published private(set) var activeWorkoutType: WorkoutType?

    // Ist die aktive Session pausiert?
    @Published private(set) var isPaused: Bool = true

    // Aktuell verstrichene Zeit in Sekunden
    @Published private(set) var elapsedSeconds: Int = 0

    // Startzeit der Session
    @Published private(set) var sessionStartedAt: Date?

    // MARK: - Private Properties

    private let userDefaultsKey = "session.activeSessionState"
    private var timer: Timer?
    private var activeSessionState: ActiveSessionState?

    // MARK: - Init

    private init() {
        loadState()
    }

    // MARK: - Public Methods

    func startSession(sessionID: String, workoutType: WorkoutType) {
        let now = Date()

        let state = ActiveSessionState(
            sessionUUID: sessionID,
            workoutType: workoutType.rawValue,
            startedAt: now,
            pausedAt: now,              // Referenzpunkt ab Start
            accumulatedSeconds: 0,
            isPaused: false,
            selectedExerciseIndex: nil
        )

        activeSessionState = state
        saveState()

        // UI aktualisieren
        hasActiveSession = true
        activeWorkoutType = workoutType
        isPaused = false
        elapsedSeconds = 0
        sessionStartedAt = now

        startTimer()
    }

    func resumeSession() {
        guard var state = activeSessionState, state.isPaused else { return }

        // "Resume" -> neuer Referenzpunkt
        state = ActiveSessionState(
            sessionUUID: state.sessionUUID,
            workoutType: state.workoutType,
            startedAt: state.startedAt,
            pausedAt: Date(),
            accumulatedSeconds: state.accumulatedSeconds,
            isPaused: false,
            selectedExerciseIndex: state.selectedExerciseIndex
        )

        activeSessionState = state
        saveState()

        isPaused = false
        startTimer()
    }

    func pauseSession() {
        guard var state = activeSessionState, !state.isPaused else { return }

        let now = Date()
        let additionalSeconds = Int(now.timeIntervalSince(state.pausedAt))

        state = ActiveSessionState(
            sessionUUID: state.sessionUUID,
            workoutType: state.workoutType,
            startedAt: state.startedAt,
            pausedAt: now,
            accumulatedSeconds: state.accumulatedSeconds + max(0, additionalSeconds),
            isPaused: true,
            selectedExerciseIndex: state.selectedExerciseIndex
        )

        activeSessionState = state
        saveState()

        isPaused = true
        elapsedSeconds = state.accumulatedSeconds
        stopTimer()
    }

    @discardableResult
    func endSession() -> Int {
        // Falls nicht pausiert, finalen Stand sauber berechnen
        let finalSeconds: Int
        if let state = activeSessionState {
            finalSeconds = state.totalElapsedSeconds()
        } else {
            finalSeconds = elapsedSeconds
        }

        activeSessionState = nil
        clearState()

        hasActiveSession = false
        activeWorkoutType = nil
        isPaused = true
        elapsedSeconds = 0
        sessionStartedAt = nil

        stopTimer()
        return finalSeconds
    }

    func discardSession() {
        _ = endSession()
    }

    func getActiveSessionID() -> String? {
        activeSessionState?.sessionUUID
    }

    func getRestorationInfo() -> (sessionID: String, workoutType: WorkoutType)? {
        guard let state = activeSessionState,
              let workoutType = WorkoutType(rawValue: state.workoutType) else {
            return nil
        }
        return (state.sessionUUID, workoutType)
    }

    var formattedElapsedTime: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    func setSelectedExerciseIndex(_ index: Int?) {
        guard let state = activeSessionState else { return }

        let updated = ActiveSessionState(
            sessionUUID: state.sessionUUID,
            workoutType: state.workoutType,
            startedAt: state.startedAt,
            pausedAt: state.pausedAt,
            accumulatedSeconds: state.accumulatedSeconds,
            isPaused: state.isPaused,
            selectedExerciseIndex: index
        )

        activeSessionState = updated
        saveState()
    }

    func getSelectedExerciseIndex() -> Int? {
        activeSessionState?.selectedExerciseIndex
    }

    var elapsedMinutes: Int {
        elapsedSeconds / 60
    }

    // MARK: - App Lifecycle

    /// Variante B: Nicht automatisch pausieren.
    /// Nur State sichern, damit nach Kill/Restart korrekt restored wird.
    func handleBackgroundTransition() {
        saveState()
    }

    func handleForegroundTransition() {
        loadState()
        // UI sofort refreshen (falls state läuft)
        updateElapsedTime()
    }

    // MARK: - Private Methods

    private func startTimer() {
        stopTimer()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }

        if let timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateElapsedTime() {
        guard let state = activeSessionState, !state.isPaused else { return }
        elapsedSeconds = state.totalElapsedSeconds()
    }

    private func saveState() {
        guard let state = activeSessionState else { return }

        do {
            let data = try JSONEncoder().encode(state)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("ActiveSessionManager: Fehler beim Speichern des Zustands: \(error)")
        }
    }

    private func loadState() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let state = try? JSONDecoder().decode(ActiveSessionState.self, from: data) else {

            activeSessionState = nil
            hasActiveSession = false
            activeWorkoutType = nil
            isPaused = true
            elapsedSeconds = 0
            sessionStartedAt = nil
            stopTimer()
            return
        }

        activeSessionState = state

        hasActiveSession = true
        activeWorkoutType = WorkoutType(rawValue: state.workoutType)
        isPaused = state.isPaused
        sessionStartedAt = state.startedAt

        // ✅ Bugfix: korrekt auch im "läuft"-Zustand
        elapsedSeconds = state.totalElapsedSeconds()

        if !state.isPaused {
            startTimer()
        } else {
            stopTimer()
        }
    }

    private func clearState() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

// MARK: - SwiftUI Environment Integration

private struct ActiveSessionManagerKey: EnvironmentKey {
    static let defaultValue = ActiveSessionManager.shared
}

extension EnvironmentValues {
    var activeSessionManager: ActiveSessionManager {
        get { self[ActiveSessionManagerKey.self] }
        set { self[ActiveSessionManagerKey.self] = newValue }
    }
}

// MARK: - View Extension für ScenePhase Handling

extension View {
    func handleSessionLifecycle() -> some View {
        self.modifier(SessionLifecycleModifier())
    }
}

private struct SessionLifecycleModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var sessionManager = ActiveSessionManager.shared

    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .background:
                    sessionManager.handleBackgroundTransition()
                case .active:
                    sessionManager.handleForegroundTransition()
                case .inactive:
                    break
                @unknown default:
                    break
                }
            }
    }
}
