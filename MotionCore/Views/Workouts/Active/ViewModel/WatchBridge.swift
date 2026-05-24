//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts / ViewModel                                      /
// Datei . . . . : WatchBridge.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.05.2026                                                       /
// Beschreibung  : Kapselt Watch-Sync-Logik für das aktive Training.               /
//                 Sendet Workout-State an Apple Watch und verarbeitet Watch-Actions./
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Combine
import Foundation

// MARK: - WatchBridge

/// Konkrete Klasse für Watch-Kommunikation während eines aktiven Trainings.
/// Subscribed auf SetManager.setCompleted und sendet automatisch den aktuellen State.
@MainActor
@Observable
final class WatchBridge {

    // MARK: - Private

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var session: StrengthSession?
    private weak var sessionManager: ActiveSessionManager?
    private weak var restTimer: RestTimerManager?
    @ObservationIgnored private var setManager: SetManager?
    @ObservationIgnored private var exerciseNav: ExerciseNav?

    // MARK: - Init

    init() {}

    // MARK: - Configure

    func configure(
        session: StrengthSession,
        sessionManager: ActiveSessionManager,
        restTimer: RestTimerManager,
        setManager: SetManager,
        exerciseNav: ExerciseNav,
        setCompleted: AnyPublisher<ExerciseSet, Never>
    ) {
        self.session = session
        self.sessionManager = sessionManager
        self.restTimer = restTimer
        self.setManager = setManager
        self.exerciseNav = exerciseNav

        cancellables.removeAll()

        setCompleted
            .sink { [weak self] _ in self?.sendState() }
            .store(in: &cancellables)
    }

    // MARK: - State senden

    func sendState() {
        guard let session, let sessionManager, let restTimer, let setManager else { return }

        let state: WatchWorkoutState = sessionManager.isPaused ? .paused : .active
        let grouped = setManager.cachedGroupedSets
        let currentKey = exerciseNav?.selectedExerciseKey
            ?? session.nextUncompletedSet?.groupKey
            ?? ""

        let exIdx = grouped.firstIndex(where: { $0.first?.groupKey == currentKey }) ?? 0
        let currentExName = grouped[safe: exIdx]?.first?.exerciseName ?? ""
        let completedInGroup = grouped[safe: exIdx]?.filter { $0.isCompleted }.count ?? 0
        let totalInGroup = grouped[safe: exIdx]?.count ?? 0

        PhoneSessionManager.shared.sendWorkoutState(
            state: state,
            exerciseName: currentExName,
            setIndex: completedInGroup,
            totalSets: totalInGroup,
            exerciseIndex: exIdx,
            totalExercises: grouped.count,
            elapsedTime: TimeInterval(sessionManager.elapsedSeconds),
            isResting: restTimer.isResting,
            restEndDate: restTimer.isResting ? restTimer.restEndDate : nil
        )
    }

    // MARK: - Watch Actions verarbeiten

    func handleAction(_ action: WatchAction) {
        guard let setManager, let exerciseNav else { return }

        switch action {
        case .pauseResume:
            if let sessionManager {
                if sessionManager.isPaused {
                    sessionManager.resumeSession()
                } else {
                    sessionManager.pauseSession()
                }
            }

        case .completeSet:
            // Ersten nicht abgeschlossenen Satz der aktuellen Übung abschließen
            guard let key = exerciseNav.selectedExerciseKey,
                  let session else { return }
            let openSet = session.safeExerciseSets
                .filter { $0.groupKey == key }
                .sorted { $0.setNumber < $1.setNumber }
                .first { !$0.isCompleted }
            if let set = openSet {
                setManager.completeSet(set)
            }

        case .nextExercise:
            let grouped = setManager.cachedGroupedSets
            let currentKey = exerciseNav.selectedExerciseKey ?? ""
            let currentIdx = grouped.firstIndex(where: { $0.first?.groupKey == currentKey }) ?? -1
            let nextIdx = currentIdx + 1
            guard nextIdx < grouped.count else { return }
            if let nextKey = grouped[safe: nextIdx]?.first?.groupKey {
                exerciseNav.selectExercise(key: nextKey)
            }

        case .previousExercise:
            let grouped = setManager.cachedGroupedSets
            let currentKey = exerciseNav.selectedExerciseKey ?? ""
            let currentIdx = grouped.firstIndex(where: { $0.first?.groupKey == currentKey }) ?? 0
            let prevIdx = currentIdx - 1
            guard prevIdx >= 0 else { return }
            if let prevKey = grouped[safe: prevIdx]?.first?.groupKey {
                exerciseNav.selectExercise(key: prevKey)
            }

        case .skipRest:
            restTimer?.skip()
        }
    }
}

// MARK: - Array Helper (WatchBridge-lokal)

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
