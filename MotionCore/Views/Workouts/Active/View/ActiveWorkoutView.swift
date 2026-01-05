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
    @State private var selectedExerciseKey: String? = nil

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

    private var selectedExerciseSets: [ExerciseSet] {
        guard let key = selectedExerciseKey else { return [] }

        return session.exerciseSets
            .filter { $0.groupKey == key }
            .sorted { $0.setNumber < $1.setNumber }
    }

    private var currentSet: ExerciseSet? {
        if selectedExerciseKey != nil {
            return selectedExerciseSets.first { !$0.isCompleted }
        }
        return session.nextUncompletedSet
    }

    private var currentExerciseIndex: Int {
        let grouped = session.groupedSets

        if let key = selectedExerciseKey,
           let idx = grouped.firstIndex(where: { $0.first?.groupKey == key }) {
            return idx
        }

        guard let current = session.nextUncompletedSet else { return 0 }
        return grouped.firstIndex(where: { group in
            group.contains { $0.id == current.id }
        }) ?? 0
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
                // Workout-Status als Header der View
                ActiveWorkoutStatus(
                    isPaused: sessionManager.isPaused,
                    formattedElapsedTime: sessionManager.formattedElapsedTime,
                    completedSets: session.completedSets,
                    totalSets: session.totalSets,
                    progress: session.progress
                )
                ScrollView {
                    scrollContent
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
        .onChange(of: selectedExerciseKey) { _, newValue in
            sessionManager.setSelectedExerciseKey(newValue)
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

    private var setsForCurrentExercise: Int {
        guard let current = currentSet else { return 0 }
        return session.groupedSets.first(where: { $0.first?.groupKey == current.groupKey })?.count ?? 0
    }

    private var isSelectedExerciseComplete: Bool {
        guard selectedExerciseKey != nil else { return false }
        return !selectedExerciseSets.isEmpty && selectedExerciseSets.allSatisfy { $0.isCompleted }
    }

    private var selectedExerciseName: String? {
        selectedExerciseSets.first.map {
            $0.exerciseNameSnapshot.isEmpty ? $0.exerciseName : $0.exerciseNameSnapshot
        }
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

        let didRestore = restoreResumeStateIfPossible()

        if !didRestore {
            if let activeID, activeID == sessionID {
                // already active
            } else if sessionManager.hasActiveSession {
                sessionManager.discardSession()
                startNewSession(sessionID: sessionID)
            } else {
                startNewSession(sessionID: sessionID)
            }
        }

        // Fallback: falls ResumeStore nix gesetzt hat
        if selectedExerciseKey == nil {
            selectedExerciseKey = sessionManager.getSelectedExerciseKey()
        }

        // ✅ Schritt 2: Guard gegen ungültigen Key (nach dem Setzen!)
        validateSelectedExerciseKey()

        reattachLiveActivityIfNeeded()

        // ✅ Schritt 3: einmaliger Initial-Sync
        updateLiveActivity()
        saveResumeState()
    }

    private func validateSelectedExerciseKey() {
        if let key = selectedExerciseKey,
           !session.groupedSets.contains(where: { $0.first?.groupKey == key }) {
            selectedExerciseKey = nil
        }
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

    // =========================================================================
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

    private func selectExercise(key: String) {
        withAnimation(.easeInOut) {
            selectedExerciseKey = key
        }
        hapticGenerator.impactOccurred()
    }

    private func completeSet(_ set: ExerciseSet) {
        withAnimation(.easeInOut) {
            set.isCompleted = true
        }
        try? context.save()

        if selectedExerciseKey == nil {
            if let key = session.groupedSets
                .first(where: { group in group.contains(where: { $0.id == set.id }) })?
                .first?.groupKey {
                selectedExerciseKey = key
            }
        }

        if selectedExerciseKey == nil {
            selectedExerciseKey = set.groupKey
        }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        let remainingSetsForExercise = session.exerciseSets.filter {
            $0.groupKey == set.groupKey && !$0.isCompleted
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

    // =========================================================================
    // MARK: - Rest Timer
    // =========================================================================

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

    // =========================================================================
    // MARK: - Live Activity
    // =========================================================================

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
            }
        }
    }

    // =========================================================================
    // MARK: - Resume Store (Rest + LiveActivity Anchors)
    // =========================================================================

    @discardableResult
    private func restoreResumeStateIfPossible() -> Bool {
        guard let state = SessionResumeStore.load() else { return false }
        guard state.sessionID == session.sessionUUID.uuidString else { return false }

        workoutStartDate = state.workoutStartDate
        selectedExerciseKey = state.selectedExerciseKey

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
            selectedExerciseKey: selectedExerciseKey,
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
    private var exercisesOverview: some View {
        ExercisesOverviewCard(
            groupedSets: session.groupedSets,
            currentExerciseIndex: currentExerciseIndex,
            refreshID: exerciseListRefreshID,
            onAddExercise: { showAddExerciseSheet = true },
            onSelectExercise: { key in
                selectExercise(key: key)
            }
        )
    }

    private var scrollContent: some View {
        VStack(spacing: 20) {
            heroCard
            exercisesOverview
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 100)
    }

    private var heroCard: AnyView {
        if isResting, let completedSet = lastCompletedSet {
            return AnyView(
                RestTimerCard(
                    remainingSeconds: restTimerSeconds,
                    targetSeconds: completedSet.restSeconds,
                    onSkip: skipRest
                )
            )
        }

        if let activeSet = currentSet {
            return AnyView(
                ActiveSetCard(
                    set: activeSet,
                    setsForCurrentExercise: setsForCurrentExercise,
                    selectedSetForEdit: $selectedSetForEdit,
                    onComplete: completeSet
                )
            )
        }

        if isSelectedExerciseComplete, !session.allSetsCompleted {
            return AnyView(
                ExerciseCompletedCard(
                    exerciseName: selectedExerciseName,
                    onNextExercise: { selectedExerciseKey = nil }
                )
            )
        }

        return AnyView(
            WorkoutCompletedCard(
                onFinishWorkout: finishWorkout
            )
        )
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
                    ForEach(filteredExercises, id: \.persistentModelID) { exercise in
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
