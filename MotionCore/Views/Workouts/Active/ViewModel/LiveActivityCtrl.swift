//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts / ViewModel                                      /
// Datei . . . . : LiveActivityCtrl.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.05.2026                                                       /
// Beschreibung  : Kapselt das Live-Activity-Management für aktive Trainings.       /
//                 Subscribed auf SetManager.setCompleted für debounced Sync.       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import ActivityKit
import Combine
import Foundation

// MARK: - LiveActivityCtrl

/// Verwaltet Live Activity (Dynamic Island / Lock Screen) für das aktive Training.
/// Subscribed automatisch auf setCompleted für debounced Updates.
@MainActor
@Observable
final class LiveActivityCtrl {

    // MARK: - State

    private(set) var currentActivity: Activity<WorkoutActivityAttributes>?
    private(set) var workoutStartDate: Date = Date()

    // MARK: - Private

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var syncDebounceTask: Task<Void, Never>?

    @ObservationIgnored private var session: StrengthSession?
    private weak var sessionManager: ActiveSessionManager?
    private weak var restTimer: RestTimerManager?
    @ObservationIgnored private var setManager: SetManager?

    // MARK: - Init

    init() {}

    // MARK: - Configure

    func configure(
        session: StrengthSession,
        sessionManager: ActiveSessionManager,
        restTimer: RestTimerManager,
        setManager: SetManager,
        setCompleted: AnyPublisher<ExerciseSet, Never>
    ) {
        self.session = session
        self.sessionManager = sessionManager
        self.restTimer = restTimer
        self.setManager = setManager

        cancellables.removeAll()

        setCompleted
            .sink { [weak self] _ in self?.syncDebounced(saveResume: nil) }
            .store(in: &cancellables)
    }

    // MARK: - Live Activity starten

    func start() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            let attached = await self.ensureSingleActivity()
            if attached { return }

            guard let session = self.session,
                  let sessionManager = self.sessionManager else { return }

            self.workoutStartDate = Date().addingTimeInterval(-Double(sessionManager.elapsedSeconds))

            let attributes = WorkoutActivityAttributes(
                sessionID: session.sessionUUID.uuidString,
                workoutType: "Krafttraining",
                planName: session.planName
            )

            let contentState = self.makeLiveContentState()

            do {
                self.currentActivity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: contentState, staleDate: nil),
                    pushType: nil
                )
            } catch {}
        }
    }

    // MARK: - Live Activity aktualisieren

    func update() {
        guard let activity = currentActivity else { return }
        let contentState = makeLiveContentState()
        let content = ActivityContent(state: contentState, staleDate: nil)
        Task {
            await activity.update(content)
        }
    }

    // MARK: - Live Activity beenden

    func end() {
        guard let activity = currentActivity,
              let session = session,
              let sessionManager = sessionManager else { return }

        let finalState = WorkoutActivityAttributes.ContentState(
            workoutStartDate: workoutStartDate,
            isPaused: true,
            elapsedAtPause: sessionManager.elapsedSeconds,
            currentExercise: nil,
            currentSet: nil,
            isResting: false,
            restStartDate: nil,
            restEndDate: nil,
            completedSets: session.completedSets,
            totalSets: session.totalSets
        )

        let finalContent = ActivityContent(state: finalState, staleDate: nil)
        Task {
            await activity.end(finalContent, dismissalPolicy: .after(.now + 60))
        }

        currentActivity = nil
    }

    // MARK: - Reattach nach App-Start

    func reattachIfNeeded() {
        guard currentActivity == nil, let session else { return }
        let mySessionID = session.sessionUUID.uuidString

        Task { @MainActor [weak self] in
            guard let self else { return }
            let activities = Activity<WorkoutActivityAttributes>.activities
            if let existing = activities.first(where: { $0.attributes.sessionID == mySessionID }) {
                self.currentActivity = existing
                self.update()
            }
        }
    }

    // MARK: - Content State

    func makeLiveContentState() -> WorkoutActivityAttributes.ContentState {
        guard let session, let sessionManager, let restTimer, let setManager else {
            return WorkoutActivityAttributes.ContentState(
                workoutStartDate: workoutStartDate,
                isPaused: false,
                elapsedAtPause: nil,
                currentExercise: nil,
                currentSet: nil,
                isResting: false,
                restStartDate: nil,
                restEndDate: nil,
                completedSets: 0,
                totalSets: 0
            )
        }

        // workoutStartDate nur aktualisieren wenn Session aktiv läuft (nicht pausiert).
        // Während Pause bleibt der Anker stabil — verhindert Flickern im Widget-Timer.
        if !sessionManager.isPaused {
            workoutStartDate = Date().addingTimeInterval(-Double(sessionManager.elapsedSeconds))
        }

        let setsForCurrentExercise: Int? = {
            guard let current = setManager.cachedCurrentSet else { return nil }
            let count = setManager.cachedGroupedSets
                .first(where: { $0.first?.groupKey == current.groupKey })?.count ?? 0
            return count > 0 ? count : nil
        }()

        return WorkoutActivityAttributes.ContentState(
            workoutStartDate: workoutStartDate,
            isPaused: sessionManager.isPaused,
            elapsedAtPause: sessionManager.isPaused ? sessionManager.elapsedSeconds : nil,
            currentExercise: setManager.cachedCurrentSet?.exerciseName,
            currentSet: setManager.cachedCurrentSet.map { "Satz \($0.setNumber)" },
            isResting: restTimer.isResting,
            restStartDate: restTimer.isResting ? restTimer.restStartDate : nil,
            restEndDate: restTimer.isResting ? restTimer.restEndDate : nil,
            completedSets: session.completedSets,
            totalSets: session.totalSets,
            totalSetsForCurrentExercise: setsForCurrentExercise
        )
    }

    // MARK: - Debounced Sync

    /// Aggregiert mehrere schnelle State-Änderungen zu einem einzigen Update.
    /// saveResume: optionaler Callback der nach dem Update aufgerufen wird (saveResumeState).
    func syncDebounced(saveResume: (() -> Void)?) {
        syncDebounceTask?.cancel()
        syncDebounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            self?.update()
            saveResume?()
        }
    }

    // MARK: - Resume State

    func restoreWorkoutStartDate(_ date: Date) {
        workoutStartDate = date
    }

    // MARK: - Hilfsmethoden

    func cancelDebounce() {
        syncDebounceTask?.cancel()
    }

    // MARK: - Single Activity sicherstellen

    func ensureSingleActivity() async -> Bool {
        guard let session else { return false }
        let mySessionID = session.sessionUUID.uuidString
        let activities = Activity<WorkoutActivityAttributes>.activities

        var matching: Activity<WorkoutActivityAttributes>?
        var others: [Activity<WorkoutActivityAttributes>] = []

        for activity in activities {
            if activity.attributes.sessionID == mySessionID {
                if matching == nil {
                    matching = activity
                } else {
                    others.append(activity) // Duplikat
                }
            } else {
                others.append(activity)
            }
        }

        if !others.isEmpty {
            await endActivities(others)
        }

        if let matching {
            await MainActor.run {
                self.currentActivity = matching
            }
            let content = ActivityContent(state: makeLiveContentState(), staleDate: nil)
            await matching.update(content)
            return true
        }

        return false
    }

    func endActivities(_ activities: [Activity<WorkoutActivityAttributes>]) async {
        guard let session, let sessionManager else { return }
        for activity in activities {
            let final = WorkoutActivityAttributes.ContentState(
                workoutStartDate: workoutStartDate,
                isPaused: true,
                elapsedAtPause: sessionManager.elapsedSeconds,
                currentExercise: nil,
                currentSet: nil,
                isResting: false,
                restStartDate: nil,
                restEndDate: nil,
                completedSets: session.completedSets,
                totalSets: session.totalSets
            )
            let finalContent = ActivityContent(state: final, staleDate: nil)
            await activity.end(finalContent, dismissalPolicy: .immediate)
        }
    }
}
