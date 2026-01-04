//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout                                                          /
// Datei . . . . : ActiveWorkoutView.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Live-Tracking View während eines Krafttrainings                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI
import ActivityKit

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var sessionManager: ActiveSessionManager

    @Bindable var session: StrengthSession

        // MARK: - Local timers (UI only)

    @State private var localTimer: Timer?

        // Live Activities
    @State private var currentActivity: Activity<WorkoutActivityAttributes>?

        // NEW: Live Activity timer anchor
    @State private var workoutStartDate: Date = Date()

        // UI
    @State private var showFinishAlert = false
    @State private var showCancelAlert = false
    @State private var selectedSetForEdit: ExerciseSet?
    @State private var selectedExerciseIndex: Int? = nil

    // NEU: Sheet zum Hinzufügen einer Übung während des Trainings
    @State private var showAddExerciseSheet = false

    // NEU: Refresh-Trigger für die Übersicht nach dem Hinzufügen neuer Übungen
    @State private var exerciseListRefreshID = UUID()

        // Rest
    @State private var restTimerSeconds: Int = 0
    @State private var restTimer: Timer?
    @State private var isResting: Bool = false

        // NEW: Rest end date anchor (system-side countdown)
    @State private var restEndDate: Date?

    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

        // MARK: - Derived

    private var currentSet: ExerciseSet? {
        if let selectedIndex = selectedExerciseIndex {
            let grouped = session.groupedSets
            guard selectedIndex < grouped.count else { return nil }
            return grouped[selectedIndex].first { !$0.isCompleted }
        }
        return session.nextUncompletedSet
    }

    private var currentExerciseIndex: Int {
        if let selectedIndex = selectedExerciseIndex {
            return selectedIndex
        }
        guard let current = session.nextUncompletedSet else { return 0 }
        let grouped = session.groupedSets
        return grouped.firstIndex { group in
            group.contains { $0.id == current.id }
        } ?? 0
    }

    private var lastCompletedSet: ExerciseSet? {
        session.exerciseSets
            .filter { $0.isCompleted }
            .last
    }

        // MARK: - Body

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            VStack(spacing: 0) {
                headerSection

                ScrollView {
                    VStack(spacing: 20) {
                        if isResting, let completedSet = lastCompletedSet {
                            RestTimerCard(
                                remainingSeconds: restTimerSeconds,
                                targetSeconds: completedSet.restSeconds,
                                onSkip: skipRest
                            )
                        } else if let current = currentSet {
                            currentSetCard(current)
                        } else if isSelectedExerciseComplete, !session.allSetsCompleted {
                            exerciseCompletedCard
                        } else {
                            allCompletedCard
                        }

                        exercisesOverview
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
            }

            VStack {
                Spacer()
                bottomActionBar
            }
        }
        .navigationTitle(session.planName ?? "Training")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    if sessionManager.isPaused {
                        handlePausedExit()
                    } else {
                        showCancelAlert = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            setupSession()
            hapticGenerator.prepare()
        }

        // =====================================================================
        // MARK: - onChange Handler (einzige Quelle für Live Activity Updates)
        // =====================================================================
        // Diese Handler reagieren auf State-Änderungen und updaten die Live
        // Activity EINMAL. Die Action-Funktionen ändern nur den State.
        // =====================================================================

        .onChange(of: sessionManager.isPaused) { _, _ in
            updateLiveActivity()
            saveResumeState()
        }
        .onChange(of: isResting) { _, _ in
            updateLiveActivity()
            saveResumeState()
        }
        .onChange(of: session.completedSets) { _, _ in
            updateLiveActivity()
            saveResumeState()
        }
        .onChange(of: selectedExerciseIndex) { _, newValue in
            sessionManager.setSelectedExerciseIndex(newValue)
            updateLiveActivity()
            saveResumeState()
        }

        .onDisappear {
            cleanupTimer()
            saveResumeState()
        }

        .alert("Training läuft noch", isPresented: $showCancelAlert) {
            Button("Pausieren") {
                handlePauseAndExit()
            }
            Button("Verwerfen", role: .destructive) {
                cancelWorkout()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Möchtest du das Training pausieren oder verwerfen?")
        }
        .alert("Training beenden?", isPresented: $showFinishAlert) {
            Button("Weiter trainieren", role: .cancel) {}
            Button("Beenden", role: .none) {
                finishWorkout()
            }
        } message: {
            Text("Du hast \(session.completedSets) von \(session.totalSets) Sätzen abgeschlossen.")
        }
        .sheet(item: $selectedSetForEdit) { set in
            SetEditSheet(set: set, session: session)
                .environmentObject(appSettings)
        }
        // NEU: Sheet zum Hinzufügen einer Übung während des Trainings
        .sheet(isPresented: $showAddExerciseSheet) {
            AddExerciseDuringWorkoutSheet(session: session) {
                // Nach dem Hinzufügen: UI refreshen und Live Activity updaten
                exerciseListRefreshID = UUID() // Erzwingt Neuaufbau der Liste
                updateLiveActivity()
                saveResumeState()
            }
            .environmentObject(appSettings)
        }
    }

        // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: sessionManager.isPaused ? "pause.circle.fill" : "clock.fill")
                        .foregroundStyle(sessionManager.isPaused ? .orange : .blue)

                    Text(sessionManager.formattedElapsedTime)
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(.primary)

                    if sessionManager.isPaused {
                        Text("(Pausiert)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Text("\(session.completedSets)/\(session.totalSets)")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)

                    Text("Sätze")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * session.progress, height: 8)
                        .animation(.easeInOut, value: session.progress)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

        // MARK: - Current Set Card

    private func currentSetCard(_ set: ExerciseSet) -> some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                ExerciseGifView(assetName: set.exerciseGifAssetName, size: 80)

                VStack(alignment: .leading, spacing: 4) {
                    if set.setKind != .work {
                        Text(set.setKind.description.uppercased())
                            .font(.caption.bold())
                            .foregroundStyle(set.setKind.color)
                    }

                    Text(set.exerciseName)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)

                    Text("Satz \(set.setNumber) von \(setsForCurrentExercise)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            .glassDivider()

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(set.weight > 0 ? String(format: "%.2f", set.weight) : "0.00")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(set.weight > 0 ? .primary : .secondary)

                    Text(set.weight > 0 ? "kg" : "Körpergewicht")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.primary.opacity(0.2))
                    .frame(width: 1, height: 50)

                VStack(spacing: 4) {
                    Text("\(set.reps)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Wdh.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            Button {
                selectedSetForEdit = set
            } label: {
                Label("Anpassen", systemImage: "pencil")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }

            .glassDivider()

            Button {
                completeSet(set)
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Satz abschließen")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.green, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .glassCard()
    }

    private var setsForCurrentExercise: Int {
        guard let current = currentSet else { return 0 }
        return session.exerciseSets.filter { $0.exerciseName == current.exerciseName }.count
    }

    private var isSelectedExerciseComplete: Bool {
        guard let selectedIndex = selectedExerciseIndex else { return false }
        let grouped = session.groupedSets
        guard selectedIndex < grouped.count else { return false }
        return grouped[selectedIndex].allSatisfy { $0.isCompleted }
    }

    private var selectedExerciseName: String? {
        guard let selectedIndex = selectedExerciseIndex else { return nil }
        let grouped = session.groupedSets
        guard selectedIndex < grouped.count else { return nil }
        return grouped[selectedIndex].first?.exerciseName
    }

    private var exerciseCompletedCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            if let exerciseName = selectedExerciseName {
                Text("Übung \"\(exerciseName)\" abgeschlossen!")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }

            Text("Wähle die nächste Übung aus der Liste unten.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                withAnimation(.easeInOut) {
                    selectedExerciseIndex = nil
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Nächste Übung")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.blue, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .glassCard()
    }

    private var allCompletedCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)

            Text("Alle Sätze abgeschlossen!")
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text("Großartige Arbeit! Du kannst das Training jetzt beenden.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                finishWorkout()
            } label: {
                HStack {
                    Image(systemName: "flag.checkered")
                    Text("Training beenden")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.green, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .glassCard()
    }

        // MARK: - Overview

    private var exercisesOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Übersicht")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                Spacer()

                // NEU: Button zum Hinzufügen einer Übung
                Button {
                    showAddExerciseSheet = true
                } label: {
                    Label("Übung", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.blue)
                }
            }

            ForEach(Array(session.groupedSets.enumerated()), id: \.element.first!.id) { index, sets in
                if let firstSet = sets.first {
                    exerciseOverviewRow(
                        name: firstSet.exerciseName,
                        sets: sets,
                        index: index + 1,
                        isCurrentExercise: index == currentExerciseIndex
                    )
                    .onTapGesture {
                        selectExercise(at: index)
                    }
                }
            }
        }
        .glassCard()
        .id(exerciseListRefreshID) // NEU: Erzwingt Neuaufbau bei Änderung
    }

    private func exerciseOverviewRow(name: String, sets: [ExerciseSet], index: Int, isCurrentExercise: Bool) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(index). \(name)")
                    .font(.subheadline.bold())
                    .foregroundStyle(isCurrentExercise ? .blue : .primary)

                Spacer()

                let completed = sets.filter { $0.isCompleted }.count
                if completed == sets.count {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Text("\(completed)/\(sets.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 6) {
                ForEach(sets, id: \.id) { set in
                    Circle()
                        .fill(set.isCompleted ? Color.green : Color.primary.opacity(0.2))
                        .frame(width: 12, height: 12)
                        .overlay {
                            if set.setKind == .warmup {
                                Circle()
                                    .stroke(Color.orange, lineWidth: 2)
                            }
                        }
                }
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentExercise ? Color.blue.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
    }

        // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        HStack(spacing: 16) {
            Button {
                toggleTimer()
            } label: {
                Image(systemName: sessionManager.isPaused ? "play.fill" : "pause.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 56, height: 56)
                    .background(
                        sessionManager.isPaused ? Color.green.opacity(0.2) : Color.primary.opacity(0.1),
                        in: Circle()
                    )
                    .overlay(
                        Circle()
                            .stroke(sessionManager.isPaused ? Color.green : Color.clear, lineWidth: 2)
                    )
            }

            Spacer()

            Button {
                if session.allSetsCompleted {
                    finishWorkout()
                } else {
                    showFinishAlert = true
                }
            } label: {
                HStack {
                    Image(systemName: "flag.checkered")
                    Text("Beenden")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    session.allSetsCompleted ? Color.green : Color.orange,
                    in: Capsule()
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

        // MARK: - Session Setup

    private func setupSession() {
        let sessionID = session.sessionUUID.uuidString
        let activeID = sessionManager.getActiveSessionID()

            // 1) Resume zuerst versuchen
        if restoreResumeStateIfPossible() {
            reattachLiveActivityIfNeeded()
            return
        }

            // 2) sonst normales Verhalten
        if let activeID, activeID == sessionID {
                // already active
        } else if sessionManager.hasActiveSession {
            sessionManager.discardSession()
            startNewSession(sessionID: sessionID)
        } else {
            startNewSession(sessionID: sessionID)
        }

            // Index wiederherstellen
        if let savedIndex = sessionManager.getSelectedExerciseIndex() {
            selectedExerciseIndex = savedIndex
        }

        reattachLiveActivityIfNeeded()
    }

    private func startNewSession(sessionID: String) {
        sessionManager.startSession(sessionID: sessionID, workoutType: .strength)

        session.start()
        try? context.save()

            // Live Activity starten
        startLiveActivity()

        saveResumeState()
    }

    private func cleanupTimer() {
        localTimer?.invalidate()
        localTimer = nil
    }

        // MARK: - Actions
        // =========================================================================
        // WICHTIG: Diese Funktionen ändern nur den State.
        // Die onChange-Handler oben reagieren darauf und updaten Live Activity.
        // =========================================================================

    private func toggleTimer() {
        if sessionManager.isPaused {
            sessionManager.resumeSession()
        } else {
            sessionManager.pauseSession()
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func selectExercise(at index: Int) {
        withAnimation(.easeInOut) {
            selectedExerciseIndex = index
        }
        hapticGenerator.impactOccurred()
    }

    private func completeSet(_ set: ExerciseSet) {
        withAnimation(.easeInOut) {
            set.isCompleted = true
        }
        try? context.save()

        if selectedExerciseIndex == nil {
            let grouped = session.groupedSets
            if let currentIndex = grouped.firstIndex(where: { group in
                group.contains { $0.id == set.id }
            }) {
                selectedExerciseIndex = currentIndex
            }
        }

        if let selectedIndex = selectedExerciseIndex {
            let grouped = session.groupedSets
            guard selectedIndex < grouped.count else { return }

            let allSetsComplete = grouped[selectedIndex].allSatisfy { $0.isCompleted }
            if allSetsComplete {
                withAnimation(.easeInOut) {
                    selectedExerciseIndex = nil
                }
            }
        }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        let remainingSetsForExercise = session.exerciseSets.filter {
            $0.exerciseName == set.exerciseName && !$0.isCompleted
        }

        if !remainingSetsForExercise.isEmpty {
            startRestTimer(for: set)
        }
    }

    private func finishWorkout() {
        let finalSeconds = sessionManager.endSession()

        session.complete()
        session.duration = finalSeconds / 60
        try? context.save()

        endLiveActivity()
        SessionResumeStore.clear()

        dismiss()
    }

    private func cancelWorkout() {
        sessionManager.discardSession()

        context.delete(session)
        try? context.save()

        endLiveActivity()
        SessionResumeStore.clear()

        dismiss()
    }

    private func handlePausedExit() {
        dismiss()
    }

    private func handlePauseAndExit() {
        sessionManager.pauseSession()
        dismiss()
    }

        // MARK: - Rest Timer

    private func startRestTimer(for set: ExerciseSet) {
        let restTime = set.restSeconds
        guard restTime > 0 else { return }

        restTimerSeconds = restTime
        restEndDate = Date().addingTimeInterval(Double(restTime))

        withAnimation(.easeInOut) {
            isResting = true
        }
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.restTimerSeconds > 0 {
                self.restTimerSeconds -= 1
            } else {
                self.endRestTimer()

                if self.appSettings.enableRestTimerHaptic {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
        }
    }

    private func endRestTimer() {
        restTimer?.invalidate()
        restTimer = nil

        withAnimation(.easeInOut) {
            isResting = false
        }

        restTimerSeconds = 0
        restEndDate = nil
    }

    private func skipRest() {
        endRestTimer()
        hapticGenerator.impactOccurred()
    }

        // MARK: - Live Activity

    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

            //  1) Vorher aufräumen / reattach
        Task {
            let attached = await ensureSingleLiveActivityForCurrentSession()

                // Wenn wir bereits eine passende Activity haben -> fertig
            if attached {
                return
            }

                //  2) Neu starten
            await MainActor.run {
                workoutStartDate = Date().addingTimeInterval(-Double(sessionManager.elapsedSeconds))

                let attributes = WorkoutActivityAttributes(
                    sessionID: session.sessionUUID.uuidString,
                    workoutType: "Krafttraining",
                    planName: session.planName
                )

                let contentState = makeLiveContentState()

                do {
                    currentActivity = try Activity.request(
                        attributes: attributes,
                        content: .init(state: contentState, staleDate: nil),
                        pushType: nil
                    )
                } catch {
                }
            }
        }
    }

    private func updateLiveActivity() {
        guard let activity = currentActivity else { return }

        let contentState = makeLiveContentState()
        let content = ActivityContent(state: contentState, staleDate: nil)

        Task {
            await activity.update(content)
        }
    }

    private func endLiveActivity() {
        guard let activity = currentActivity else { return }

        let finalState = WorkoutActivityAttributes.ContentState(
            workoutStartDate: workoutStartDate,
            isPaused: true,
            elapsedAtPause: sessionManager.elapsedSeconds,
            currentExercise: nil,
            currentSet: nil,
            isResting: false,
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

    private func makeLiveContentState() -> WorkoutActivityAttributes.ContentState {
        if !sessionManager.isPaused {
            workoutStartDate = Date().addingTimeInterval(-Double(sessionManager.elapsedSeconds))
        }

        return WorkoutActivityAttributes.ContentState(
            workoutStartDate: workoutStartDate,
            isPaused: sessionManager.isPaused,
            elapsedAtPause: sessionManager.isPaused ? sessionManager.elapsedSeconds : nil,
            currentExercise: currentSet?.exerciseName,
            currentSet: currentSet.map { "Satz \($0.setNumber)" },
            isResting: isResting,
            restEndDate: isResting ? restEndDate : nil,
            completedSets: session.completedSets,
            totalSets: session.totalSets
        )
    }

    private func reattachLiveActivityIfNeeded() {
        if currentActivity != nil { return }

        let mySessionID = session.sessionUUID.uuidString

        Task {
            let activities = Activity<WorkoutActivityAttributes>.activities
            if let existing = activities.first(where: { $0.attributes.sessionID == mySessionID }) {
                await MainActor.run {
                    self.currentActivity = existing
                }
                updateLiveActivity()
            } else {
            }
        }
    }

        // MARK: - Resume Store (Rest + LiveActivity Anchors)

    @discardableResult
    private func restoreResumeStateIfPossible() -> Bool {
        guard let state = SessionResumeStore.load() else { return false }
        guard state.sessionID == session.sessionUUID.uuidString else { return false }

        workoutStartDate = state.workoutStartDate
        selectedExerciseIndex = state.selectedExerciseIndex

            // Pause-Status wiederherstellen
        if state.isPaused && !sessionManager.isPaused {
            sessionManager.pauseSession()
        } else if !state.isPaused && sessionManager.isPaused {
            sessionManager.resumeSession()
        }

            // Rest wiederherstellen
        if state.isResting, let end = state.restEndDate, end > Date() {
            restEndDate = end
            isResting = true
            restTimerSeconds = max(0, Int(end.timeIntervalSinceNow.rounded()))
            restartLocalRestTimerFromResume()
        } else {
            restEndDate = nil
            isResting = false
            restTimerSeconds = 0
        }
        return true
    }

    private func restartLocalRestTimerFromResume() {
        restTimer?.invalidate()
        guard let end = restEndDate else { return }

        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let remaining = Int(end.timeIntervalSinceNow.rounded())
            if remaining > 0 {
                self.restTimerSeconds = remaining
            } else {
                self.endRestTimer()
                if self.appSettings.enableRestTimerHaptic {
                    let gen = UINotificationFeedbackGenerator()
                    gen.notificationOccurred(.success)
                }
            }
        }
    }

    private func saveResumeState() {
        let state = SessionResumeState(
            sessionID: session.sessionUUID.uuidString,
            workoutType: session.workoutType.rawValue,
            isPaused: sessionManager.isPaused,
            elapsedSeconds: sessionManager.elapsedSeconds,
            workoutStartDate: workoutStartDate,
            isResting: isResting,
            restEndDate: isResting ? restEndDate : nil,
            selectedExerciseIndex: selectedExerciseIndex,
            updatedAt: Date()
        )
        SessionResumeStore.save(state)
    }

    private func ensureSingleLiveActivityForCurrentSession() async -> Bool {
        let mySessionID = session.sessionUUID.uuidString

            // Alle laufenden Activities dieses Typs
        let activities = Activity<WorkoutActivityAttributes>.activities

        var matching: Activity<WorkoutActivityAttributes>?
        var others: [Activity<WorkoutActivityAttributes>] = []

        for activity in activities {
            if activity.attributes.sessionID == mySessionID {
                    // Wenn mehrere matchen, nehmen wir "die erste" als canonical
                if matching == nil {
                    matching = activity
                } else {
                    others.append(activity) // Duplikat
                }
            } else {
                    // Andere Sessions -> aufräumen
                others.append(activity)
            }
        }

            // 1) Duplikate/alte Activities beenden
        if !others.isEmpty {
            await endActivities(others)
        }

            // 2) Matching activity -> reattach
        if let matching {
            await MainActor.run {
                self.currentActivity = matching
            }

                // Einmal synchronisieren ( neue API)
            let content = ActivityContent(state: makeLiveContentState(), staleDate: nil)
            await matching.update(content)

            return true
        }

        return false
    }

    private func endActivities(_ activities: [Activity<WorkoutActivityAttributes>]) async {
        for activity in activities {
            let final = WorkoutActivityAttributes.ContentState(
                workoutStartDate: workoutStartDate,
                isPaused: true,
                elapsedAtPause: sessionManager.elapsedSeconds,
                currentExercise: nil,
                currentSet: nil,
                isResting: false,
                restEndDate: nil,
                completedSets: session.completedSets,
                totalSets: session.totalSets
            )

                //  neue API
            let finalContent = ActivityContent(state: final, staleDate: nil)
            await activity.end(finalContent, dismissalPolicy: .immediate)
        }
    }
}

// MARK: - Sheet zum Hinzufügen einer Übung während des Trainings

struct AddExerciseDuringWorkoutSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings

    @Bindable var session: StrengthSession
    let onComplete: () -> Void

    // Schritt 1: Übung wählen, Schritt 2: Sets konfigurieren
    @State private var selectedExercise: Exercise?
    @State private var numberOfSets: Int = 3
    @State private var defaultWeight: Double = 0.0
    @State private var defaultReps: Int = 10
    @State private var restSeconds: Int = 90

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

                if let exercise = selectedExercise {
                    // Schritt 2: Sets konfigurieren
                    configureExerciseView(exercise)
                } else {
                    // Schritt 1: Übung wählen
                    exerciseSelectionView
                }
            }
            .navigationTitle(selectedExercise == nil ? "Übung hinzufügen" : "Konfigurieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if selectedExercise != nil {
                            // Zurück zur Auswahl
                            withAnimation {
                                selectedExercise = nil
                            }
                        } else {
                            dismiss()
                        }
                    } label: {
                        if selectedExercise != nil {
                            Label("Zurück", systemImage: "chevron.left")
                        } else {
                            Text("Abbrechen")
                        }
                    }
                }
            }
            .onDisappear {
                // Timer aufräumen beim Schließen
                stopContinuousAdjustment()
            }
        }
    }

    // MARK: - Schritt 1: Übung wählen (eigene Implementierung statt ExercisePickerSheet)

    @Query(sort: \Exercise.name, order: .forward)
    private var allExercises: [Exercise]

    @State private var selectedMuscleGroup: MuscleGroup? = nil
    @State private var selectedEquipment: ExerciseEquipment? = nil
    @State private var searchText: String = ""

    private var filteredExercises: [Exercise] {
        var exercises = allExercises

        if let muscle = selectedMuscleGroup {
            exercises = exercises.filter { exercise in
                exercise.primaryMuscles.contains(muscle) ||
                exercise.secondaryMuscles.contains(muscle)
            }
        }

        if let equipment = selectedEquipment {
            exercises = exercises.filter { $0.equipment == equipment }
        }

        if !searchText.isEmpty {
            exercises = exercises.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return exercises
    }

    private var exerciseSelectionView: some View {
        VStack(spacing: 0) {
            // Suchleiste
            searchBar
                .padding(.horizontal)
                .padding(.top, 16)

            // Filter-Chips
            filterChipsView
                .padding(.horizontal)
                .padding(.top, 12)

            // Übungsliste
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredExercises) { exercise in
                        Button {
                            withAnimation {
                                selectedExercise = exercise
                                defaultReps = exercise.repRangeMax > 0 ? exercise.repRangeMax : 10
                            }
                        } label: {
                            exercisePickerRow(exercise)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)

            // Empty State
            if filteredExercises.isEmpty {
                emptyStateOverlay
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Übung suchen...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
        )
    }

    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Muskelgruppen
                Menu {
                    Button("Alle Muskelgruppen") {
                        selectedMuscleGroup = nil
                    }

                    ForEach(MuscleGroup.allCases) { muscle in
                        Button {
                            selectedMuscleGroup = muscle
                        } label: {
                            HStack {
                                Text(muscle.description)
                                Spacer()
                                if selectedMuscleGroup == muscle {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    FilterChip(
                        title: selectedMuscleGroup?.description ?? "Muskel",
                        icon: .system("figure.strengthtraining.traditional"),
                        count: selectedMuscleGroup != nil ? 1 : 0,
                        isSelected: selectedMuscleGroup != nil
                    ) {}
                }

                // Equipment
                Menu {
                    Button("Alle Geräte") {
                        selectedEquipment = nil
                    }

                    ForEach(ExerciseEquipment.allCases) { equipment in
                        Button {
                            selectedEquipment = equipment
                        } label: {
                            HStack {
                                Text(equipment.description)
                                Spacer()
                                if selectedEquipment == equipment {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    FilterChip(
                        title: selectedEquipment?.description ?? "Gerät",
                        icon: .system("dumbbell.fill"),
                        count: selectedEquipment != nil ? 1 : 0,
                        isSelected: selectedEquipment != nil
                    ) {}
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func exercisePickerRow(_ exercise: Exercise) -> some View {
        HStack(spacing: 12) {
            ExerciseGifView(assetName: exercise.gifAssetName, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Label(exercise.equipment.description, systemImage: exercise.equipment.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let primaryMuscle = exercise.primaryMuscles.first {
                        Text(primaryMuscle.description)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.2))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
        )
    }

    private var emptyStateOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("Keine Übungen gefunden")
                .font(.headline)

            Text("Versuche es mit anderen Filtern")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Schritt 2: Sets konfigurieren

    private func configureExerciseView(_ exercise: Exercise) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Übungsinfo
                exerciseInfoCard(exercise)

                // Set-Konfiguration
                setConfigurationCard

                // Hinzufügen-Button
                addButton(exercise)
            }
            .padding()
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }

    private func exerciseInfoCard(_ exercise: Exercise) -> some View {
        HStack(spacing: 16) {
            ExerciseGifView(assetName: exercise.gifAssetName, size: 80)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Label(exercise.equipment.description, systemImage: exercise.equipment.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let primaryMuscle = exercise.primaryMuscles.first {
                        Text(primaryMuscle.description)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.2))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()
        }
        .glassCard()
    }

    private var setConfigurationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Set-Konfiguration")
                .font(.headline)
                .foregroundStyle(.primary)

            .glassDivider()

            // Anzahl Sets
            HStack {
                Text("Anzahl Sets")
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 12) {
                    Button { decreaseSets() } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(numberOfSets > 1 ? .blue : .gray)
                    }
                    .disabled(numberOfSets <= 1)
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if pressing { startContinuousAdjustment(field: .sets, increment: false) }
                        else { stopContinuousAdjustment() }
                    }, perform: {})

                    Text("\(numberOfSets)")
                        .font(.title2.bold().monospacedDigit())
                        .frame(minWidth: 40)
                        .contentTransition(.numericText())

                    Button { increaseSets() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(numberOfSets < 10 ? .blue : .gray)
                    }
                    .disabled(numberOfSets >= 10)
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if pressing { startContinuousAdjustment(field: .sets, increment: true) }
                        else { stopContinuousAdjustment() }
                    }, perform: {})
                }
            }

            .glassDivider()

            // Gewicht mit +/- Buttons und LongPress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(isSelectedExerciseUnilateral ? "Gewicht pro Seite (kg)" : "Gewicht (kg)")
                        .foregroundStyle(.primary)

                    if isSelectedExerciseUnilateral {
                        Text("2×")
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 12) {
                    Button { decreaseWeight() } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(defaultWeight > 0 ? .blue : .gray)
                    }
                    .disabled(defaultWeight <= 0)
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if pressing { startContinuousAdjustment(field: .weight, increment: false) }
                        else { stopContinuousAdjustment() }
                    }, perform: {})

                    Spacer()

                    if isSelectedExerciseUnilateral && defaultWeight > 0 {
                        HStack(spacing: 4) {
                            Text("2×")
                                .font(.title3)
                                .foregroundStyle(.orange)
                            Text(String(format: "%.2f", defaultWeight))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                        }
                        .contentTransition(.numericText())
                    } else {
                        Text(defaultWeight > 0 ? String(format: "%.2f", defaultWeight) : "–")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())
                    }

                    Spacer()

                    Button { increaseWeight() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if pressing { startContinuousAdjustment(field: .weight, increment: true) }
                        else { stopContinuousAdjustment() }
                    }, perform: {})
                }

                if isSelectedExerciseUnilateral {
                    if defaultWeight > 0 {
                        Text("Gesamt: \(String(format: "%.2f", defaultWeight * 2)) kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Gewicht einer Seite eingeben")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("0 = Körpergewicht")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            .glassDivider()

            // Wiederholungen
            HStack {
                Text("Wiederholungen")
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 12) {
                    Button { decreaseReps() } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(defaultReps > 1 ? .blue : .gray)
                    }
                    .disabled(defaultReps <= 1)
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if pressing { startContinuousAdjustment(field: .reps, increment: false) }
                        else { stopContinuousAdjustment() }
                    }, perform: {})

                    Text("\(defaultReps)")
                        .font(.title2.bold().monospacedDigit())
                        .frame(minWidth: 40)
                        .contentTransition(.numericText())

                    Button { increaseReps() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(defaultReps < 50 ? .blue : .gray)
                    }
                    .disabled(defaultReps >= 50)
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if pressing { startContinuousAdjustment(field: .reps, increment: true) }
                        else { stopContinuousAdjustment() }
                    }, perform: {})
                }
            }

            .glassDivider()

            // Pausenzeit
            HStack {
                Text("Pause (Sek.)")
                    .foregroundStyle(.primary)

                Spacer()

                Picker("", selection: $restSeconds) {
                    ForEach([30, 45, 60, 90, 120, 150, 180], id: \.self) { seconds in
                        Text("\(seconds)s").tag(seconds)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .glassCard()
    }

    // MARK: - Hilfsvariable für unilateral

    private var isSelectedExerciseUnilateral: Bool {
        selectedExercise?.isUnilateral ?? false
    }

    // MARK: - Adjustment Timer für LongPress

    @State private var incrementTimer: Timer?

    private enum AdjustmentField { case sets, reps, weight }

    private func increaseSets() {
        guard numberOfSets < 10 else { return }
        withAnimation { numberOfSets += 1 }
        hapticFeedback()
    }

    private func decreaseSets() {
        guard numberOfSets > 1 else { return }
        withAnimation { numberOfSets -= 1 }
        hapticFeedback()
    }

    private func increaseReps() {
        guard defaultReps < 50 else { return }
        withAnimation { defaultReps += 1 }
        hapticFeedback()
    }

    private func decreaseReps() {
        guard defaultReps > 1 else { return }
        withAnimation { defaultReps -= 1 }
        hapticFeedback()
    }

    private func increaseWeight() {
        withAnimation {
            defaultWeight += 0.25
            defaultWeight = (defaultWeight * 4).rounded() / 4
        }
        hapticFeedback()
    }

    private func decreaseWeight() {
        guard defaultWeight >= 0.25 else { return }
        withAnimation {
            defaultWeight -= 0.25
            defaultWeight = (defaultWeight * 4).rounded() / 4
        }
        hapticFeedback()
    }

    private func startContinuousAdjustment(field: AdjustmentField, increment: Bool) {
        stopContinuousAdjustment()

        var counter = 0
        incrementTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
            counter += 1
            switch field {
            case .sets:
                if increment { increaseSets() } else { decreaseSets() }
            case .reps:
                if increment { increaseReps() } else { decreaseReps() }
            case .weight:
                // Nach 20 Iterationen schneller (0.5 statt 0.25)
                let step: Double = counter > 20 ? 0.5 : 0.25
                if increment {
                    withAnimation {
                        defaultWeight += step
                        defaultWeight = (defaultWeight * 4).rounded() / 4
                    }
                } else if defaultWeight >= step {
                    withAnimation {
                        defaultWeight -= step
                        defaultWeight = (defaultWeight * 4).rounded() / 4
                    }
                }
                hapticFeedback()
            }
        }

        if let t = incrementTimer {
            RunLoop.current.add(t, forMode: .common)
        }
    }

    private func stopContinuousAdjustment() {
        incrementTimer?.invalidate()
        incrementTimer = nil
    }

    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func addButton(_ exercise: Exercise) -> some View {
        Button {
            addExerciseToSession(exercise)
            dismiss()
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("\(numberOfSets) \(numberOfSets == 1 ? "Set" : "Sets") hinzufügen")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.blue, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Logik zum Hinzufügen

    private func addExerciseToSession(_ exercise: Exercise) {
        // Höchsten sortOrder in der Session finden
        let maxSortOrder = session.exerciseSets.map { $0.sortOrder }.max() ?? -1
        let newSortOrder = maxSortOrder + 1

        // Gewicht berechnen (bei unilateral: Gesamtgewicht = 2 × Eingabe)
        let isUnilateral = exercise.isUnilateral
        let finalWeight = isUnilateral ? defaultWeight * 2 : defaultWeight

        // Sets erstellen
        for setNumber in 1...numberOfSets {
            let newSet = ExerciseSet(
                exerciseName: exercise.name,
                exerciseNameSnapshot: exercise.name,
                exerciseUUIDSnapshot: exercise.persistentModelID.hashValue.description,
                exerciseGifAssetName: exercise.gifAssetName,
                isUnilateralSnapshot: exercise.isUnilateral,
                setNumber: setNumber,
                weight: finalWeight,
                weightPerSide: isUnilateral ? defaultWeight : 0,
                reps: defaultReps,
                restSeconds: restSeconds,
                setKind: .work,
                isCompleted: false, // NEU: Nicht abgeschlossen, da während des Trainings
                targetRepsMin: exercise.repRangeMin,
                targetRepsMax: exercise.repRangeMax,
                sortOrder: newSortOrder
            )

            newSet.exercise = exercise
            newSet.session = session
            session.exerciseSets.append(newSet)
            context.insert(newSet)
        }

        try? context.save()

        // Haptic Feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Callback ausführen (Live Activity updaten etc.)
        onComplete()
    }
}
