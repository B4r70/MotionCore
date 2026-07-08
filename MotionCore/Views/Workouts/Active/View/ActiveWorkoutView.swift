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
import Combine
import SwiftData
import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var sessionManager: ActiveSessionManager

    @Bindable var session: StrengthSession

    @Query(filter: #Predicate<StrengthSession> { $0.isCompleted }, sort: \StrengthSession.date, order: .reverse)
    private var allSessions: [StrengthSession]

    @Query private var studioEquipments: [StudioEquipment]

    // MARK: - Fokussierte Observables

    @State private var setManager = SetManager()
    @State private var exerciseNav = ExerciseNav()
    @State private var watchBridge = WatchBridge()
    @State private var liveActivity = LiveActivityCtrl()

    // MARK: - UI-State (bleibt in View)

    @State private var showFinishAlert = false
    @State private var showCancelAlert = false
    @State private var selectedSetForEdit: ExerciseSet?
    @State private var exerciseToDelete: String?
    @State private var showDeleteAlert = false
    @State private var showAddExerciseSheet = false
    @State private var exerciseListRefreshID = UUID()

    @State private var prSetIDs: Set<PersistentIdentifier> = []
    @State private var prBannerExercise: String? = nil
    @State private var prBannerOneRM: Double = 0

    @State private var smartFill: ActiveWorkoutSmartFillViewModel?
    @State private var cachedExerciseRatings: [String: ExerciseQualityRating] = [:]

    @StateObject private var restTimerManager = RestTimerManager()
    /// Countdown-Manager für zeitbasierte Übungs-Sätze (Phase C — Verdrahtung in Phase D)
    @StateObject private var exerciseCountdownManager = ExerciseCountdownManager()
    @ObservedObject private var phoneSession = PhoneSessionManager.shared

    @State private var showCancelHealthAlert = false
    @State private var rirSheetSet: ExerciseSet? = nil
    @State private var rirRetroSet: ExerciseSet? = nil

    /// Merkt sich ob der Übungs-Countdown vor einer Session-Pause lief,
    /// damit er beim Resume nur dann fortgesetzt wird, wenn er nicht manuell pausiert war.
    @State private var wasRunningBeforeSessionPause: Bool = false

    @State private var currentReadinessModifier: Double = 1.0
    @State private var currentSessionReadiness: SessionReadiness? = nil
    @State private var readinessTask: Task<Void, Never>?
    @State private var selectedReadinessForDetail: SessionReadiness? = nil
    @State private var quickConfigExercise: Exercise? = nil

    // MARK: - Superset-Selection-State

    @State private var isSupersetSelectionMode: Bool = false
    @State private var selectedGroupIndicesForSuperset: Set<Int> = []

    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    private let completionHapticMedium = UIImpactFeedbackGenerator(style: .medium)

    // MARK: - Derived

    private var selectedExerciseSets: [ExerciseSet] {
        guard let key = exerciseNav.selectedExerciseKey else { return [] }
        return session.safeExerciseSets
            .filter { $0.groupKey == key }
            .sorted { $0.setNumber < $1.setNumber }
    }

    private var isSelectedExerciseComplete: Bool {
        guard exerciseNav.selectedExerciseKey != nil else { return false }
        return !selectedExerciseSets.isEmpty && selectedExerciseSets.allSatisfy { $0.isCompleted }
    }

    private var selectedExerciseName: String? {
        selectedExerciseSets.first.map {
            $0.exerciseNameSnapshot.isEmpty ? $0.exerciseName : $0.exerciseNameSnapshot
        }
    }

    private var setsForCurrentExercise: Int {
        guard let current = setManager.cachedCurrentSet else { return 0 }
        return setManager.cachedGroupedSets
            .first(where: { $0.first?.groupKey == current.groupKey })?.count ?? 0
    }

    private var equipmentByID: [UUID: StudioEquipment] {
        Dictionary(uniqueKeysWithValues: studioEquipments.map { ($0.id, $0) })
    }

    /// Hilfsproperty damit der Compiler den Typ in .onChange separat auflösen kann.
    private var currentSetPersistentID: PersistentIdentifier? {
        setManager.cachedCurrentSet?.persistentModelID
    }

    // MARK: - Body

    // MARK: - Base View (ZStack + Navigation + onAppear)

    /// ZStack, Toolbar und onAppear ausgelagert damit der Compiler body separat type-checkt.
    private var baseView: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            VStack(spacing: 0) {
                ActiveWorkoutStatus(
                    isPaused: sessionManager.isPaused,
                    formattedElapsedTime: sessionManager.formattedElapsedTime,
                    completedSets: session.completedSets,
                    totalSets: session.totalSets,
                    progress: session.progress,
                    sessionVolume: setManager.cachedSessionVolume,
                    currentHR: phoneSession.liveCurrentHR,
                    activeCalories: phoneSession.liveActiveCalories,
                    planTitle: session.sourceTrainingPlan?.title,
                    watchConnectionState: phoneSession.isWatchTrackingActive ? .activeTracking : .hidden
                )
                ScrollView {
                    scrollContent
                }
                .scrollIndicators(.hidden)
            }

            // PR-Banner Overlay
            if prBannerExercise != nil {
                VStack {
                    if let exercise = prBannerExercise {
                        PRBannerView(exerciseName: exercise, oneRM: prBannerOneRM)
                    }
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: prBannerExercise)
                .zIndex(100)
            }

            VStack(spacing: 0) {
                Spacer()
                if isSupersetSelectionMode {
                    supersetActionBar
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                bottomActionBar
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSupersetSelectionMode)
        }
        .navigationTitle(session.planName ?? "Training")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
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
            completionHapticMedium.prepare()

            // Watch-Action-Handler registrieren
            PhoneSessionManager.shared.onAction = { action in
                watchBridge.handleAction(action)
            }
            // Sofortiger State-Push wenn Watch-App während laufendem Training geöffnet wird
            PhoneSessionManager.shared.onWatchBecameReachable = {
                if !PhoneSessionManager.shared.isWatchTrackingActive {
                    PhoneSessionManager.shared.sendStartHealthTracking()
                    PhoneSessionManager.shared.sendHeartbeatEnabled(true)
                }
                watchBridge.sendState()
            }
            // RestTimerManager Callbacks konfigurieren
            restTimerManager.onTimerFinished = {
                if self.appSettings.enableRestTimerHaptic {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }

            // ExerciseCountdownManager: Haptik beim Ablauf des Übungs-Countdowns
            exerciseCountdownManager.onFinished = {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }

            // Initialer Cache-Aufbau
            setManager.rebuildGroupedCaches()
            setManager.refreshSetCaches()
            setManager.recomputeSessionVolume()

            // Letzte-Session-Referenzen für alle Übungen vorbereiten
            let initialKeys = Set(setManager.cachedGroupedSets.compactMap { $0.first?.groupKey })
            for key in initialKeys {
                setManager.refreshLastSessionReference(for: key)
            }

            // Health-Tracking nur starten wenn noch kein Tracking läuft (verhindert
            // Session-Fragmentierung bei Re-Appear der View während laufendem Workout).
            if !PhoneSessionManager.shared.isWatchTrackingActive {
                PhoneSessionManager.shared.resetHealthData()
                PhoneSessionManager.shared.sendStartHealthTracking()
                PhoneSessionManager.shared.sendHeartbeatEnabled(true)
            }
        }
    }

    // MARK: - Reactive View (onReceive + onChange + onDisappear)

    /// Publisher- und onChange-Handler ausgelagert damit body nur Alerts + Sheets enthält.
    private var reactiveView: some View {
        baseView
            .onReceive(setManager.setCompleted) { completedSet in
                Task { @MainActor in try? context.save() }
                PhoneSessionManager.shared.sendRequestSnapshot()
                completionHapticMedium.impactOccurred()
                smartFill?.recordSetCompletion(
                    completedSet: completedSet,
                    exercise: setManager.resolveExercise(for: completedSet.groupKey)
                )
                prefillSmartSuggestionsIfNeeded()
            }
            .onReceive(setManager.restShouldStart) { secs in
                restTimerManager.start(seconds: secs)
            }
            .onReceive(setManager.rirSheetShouldShow) { set in
                rirSheetSet = set
            }
            .onReceive(setManager.prDetected) { set, name, oneRM in
                prSetIDs.insert(set.persistentModelID)
                prBannerExercise = name
                prBannerOneRM = oneRM
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation(.easeOut) { prBannerExercise = nil }
                }
            }
            .onChange(of: restTimerManager.isResting) { _, _ in
                liveActivity.syncDebounced(saveResume: saveResumeState)
                watchBridge.sendState()
            }
            .onChange(of: restTimerManager.restEndDate) { _, _ in
                watchBridge.sendState()
            }
            .onChange(of: session.completedSets) { _, _ in
                setManager.rebuildGroupedCaches()
                setManager.refreshSetCaches()
                setManager.recomputeSessionVolume()
                liveActivity.syncDebounced(saveResume: saveResumeState)
                watchBridge.sendState()
            }
            .onChange(of: exerciseListRefreshID) { _, _ in
                setManager.rebuildGroupedCaches()
                setManager.refreshSetCaches()
                let allKeys = Set(setManager.cachedGroupedSets.compactMap { $0.first?.groupKey })
                for key in allKeys {
                    setManager.refreshLastSessionReference(for: key)
                }
            }
            .onChange(of: exerciseNav.selectedExerciseKey) { oldValue, newValue in
                setManager.refreshSetCaches()
                sessionManager.setSelectedExerciseKey(newValue)
                liveActivity.syncDebounced(saveResume: saveResumeState)
                watchBridge.sendState()
                saveCurrentExerciseMetrics(forKey: oldValue)
                PhoneSessionManager.shared.sendExerciseTransition()
                prefillSmartSuggestionsIfNeeded()
                if let key = newValue {
                    setManager.refreshLastSessionReference(for: key)
                }
            }
            .onChange(of: sessionManager.isPaused) { _, isPaused in
                handleSessionPauseChange(isPaused: isPaused)
            }
            .onChange(of: exerciseCountdownManager.isRunning) { _, _ in
                // Countdown gestartet oder gestoppt → LiveActivity und Watch sofort aktualisieren
                liveActivity.syncDebounced(saveResume: saveResumeState)
                watchBridge.sendState()
            }
            .onChange(of: session.safeExerciseSets.count) { _, _ in
                let groupKeys = Set(session.safeExerciseSets.map { $0.groupKey })
                for key in groupKeys { setManager.cleanupLastSetFlag(for: key) }
                Task { @MainActor in try? context.save() }
                if let retroSet = setManager.retroRIRCandidate(for: exerciseNav.selectedExerciseKey) {
                    rirRetroSet = retroSet
                }
            }
            .background {
                Color.clear.onChange(of: currentSetPersistentID) { _, _ in
                    handleCountdownSetChange()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                restTimerManager.handleForegroundReturn()
                exerciseCountdownManager.handleForegroundReturn()
                if restTimerManager.isResting {
                    liveActivity.syncDebounced(saveResume: saveResumeState)
                }
            }
            .onDisappear {
                restTimerManager.cleanup()
                exerciseCountdownManager.cleanup()
                liveActivity.cancelDebounce()
                saveResumeState()
                PhoneSessionManager.shared.onAction = nil
                PhoneSessionManager.shared.onWatchBecameReachable = nil
                PhoneSessionManager.shared.sendIdleState()
            }
    }

    // body enthält nur reactiveView + Alerts + Sheets (drei separate Typ-Check-Ausdrücke).
    var body: some View {
        reactiveView
        .alert("Training läuft noch", isPresented: $showCancelAlert) {
            Button("Pausieren") { handlePauseAndExit() }
            Button("Verwerfen", role: .destructive) { cancelWorkout() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Möchtest du das Training pausieren oder verwerfen?")
        }
        .alert("Training beenden?", isPresented: $showFinishAlert) {
            Button("Weiter trainieren", role: .cancel) {}
            Button("Beenden", role: .none) { finishWorkout() }
        } message: {
            Text("Du hast \(session.completedSets) von \(session.totalSets) Sätzen abgeschlossen.")
        }
        .alert("Training verwerfen", isPresented: $showCancelHealthAlert) {
            Button("Health-Daten behalten") {
                PhoneSessionManager.shared.sendHeartbeatEnabled(false)
                PhoneSessionManager.shared.sendStopHealthTracking()
                PhoneSessionManager.shared.resetHealthData()
                cancelWorkout()
            }
            Button("Alles verwerfen", role: .destructive) {
                PhoneSessionManager.shared.sendHeartbeatEnabled(false)
                PhoneSessionManager.shared.sendDiscardHealthTracking()
                PhoneSessionManager.shared.resetHealthData()
                cancelWorkout()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Möchtest du die Health-Daten (HR, Kalorien) in Apple Health behalten oder ebenfalls verwerfen?")
        }
        .alert("Übung löschen?", isPresented: $showDeleteAlert) {
            Button("Löschen", role: .destructive) { confirmDelete() }
            Button("Abbrechen", role: .cancel) { exerciseToDelete = nil }
        } message: {
            if let key = exerciseToDelete {
                let sets = session.safeExerciseSets.filter { $0.groupKey == key }
                let name = sets.first?.exerciseName ?? "Übung"
                Text("Möchtest du '\(name)' mit \(sets.count) Sätzen aus diesem Training entfernen?")
            }
        }
        .sheet(item: $selectedSetForEdit) { set in
            SetEditSheet(set: set, session: session)
                .environmentObject(appSettings)
        }
        .sheet(item: $rirSheetSet) { set in
            RIRInputSheet(
                restTimerManager: restTimerManager,
                targetSeconds: set.restSeconds,
                onAdjustRest: { delta in
                    restTimerManager.adjust(delta: delta)
                    liveActivity.syncDebounced(saveResume: saveResumeState)
                },
                onSelectRIR: { rir in
                    if rir == 4 { set.rpe = 6 } else { set.rpe = 10 - rir }
                    set.rpeRecorded = true
                    Task { @MainActor in try? context.save() }
                },
                onSkip: {}
            )
        }
        .sheet(item: $rirRetroSet) { set in
            RIRRetroSheet(
                onSelectRIR: { rir in
                    if rir == 4 { set.rpe = 6 } else { set.rpe = 10 - rir }
                    set.rpeRecorded = true
                    Task { @MainActor in try? context.save() }
                },
                onSkip: {}
            )
        }
        .sheet(item: $quickConfigExercise) { exercise in
            ExerciseQuickConfigSheet(exercise: exercise)
                .environmentObject(appSettings)
        }
        .sheet(item: $selectedReadinessForDetail) { readiness in
            ReadinessDetailView(readiness: readiness)
                .environmentObject(appSettings)
        }
        .onChange(of: selectedSetForEdit) { _, newSet in
            if let newSet { smartFill?.markUserConfirmed(set: newSet) }
        }
        .sheet(isPresented: $showAddExerciseSheet) {
            AddExerciseDuringWorkoutSheet(session: session) {
                exerciseListRefreshID = UUID()
                liveActivity.syncDebounced(saveResume: saveResumeState)
            }
            .environmentObject(appSettings)
        }
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        HStack(spacing: 16) {
            Button {
                toggleTimer()
            } label: {
                Image(systemName: sessionManager.isPaused ? "play.fill" : "pause.fill")
                    .font(AppFont.title)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 56, height: 56)
                    .background(
                        sessionManager.isPaused ? Theme.success.opacity(0.15) : Theme.surfaceSunken,
                        in: Circle()
                    )
                    .overlay(
                        Circle()
                            .stroke(sessionManager.isPaused ? Theme.success : Color.clear, lineWidth: 2)
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
                        .font(AppFont.headline)
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, Space.s6)
                .padding(.vertical, Space.s4)
                .background(
                    session.allSetsCompleted ? Theme.success : Theme.warning,
                    in: Capsule()
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // =========================================================================
    // MARK: - Session Setup (Verdrahtung)
    // =========================================================================

    private func setupSession() {
        let sessionID = session.sessionUUID.uuidString
        let activeID = sessionManager.getActiveSessionID()

        let didRestore = restoreResumeStateIfPossible()

        if !didRestore {
            if let activeID, activeID == sessionID {
                // bereits aktiv
            } else if sessionManager.hasActiveSession {
                sessionManager.discardSession()
                startNewSession(sessionID: sessionID)
            } else {
                startNewSession(sessionID: sessionID)
            }
        }

        // Fallback: falls ResumeStore nix gesetzt hat
        if exerciseNav.selectedExerciseKey == nil {
            exerciseNav.selectedExerciseKey = sessionManager.getSelectedExerciseKey()
        }

        // Repository für SmartFill und AutoProgression
        let repo = ProgressionStateRepository(context: context)

        // 1. SetManager zuerst konfigurieren (publiziert Events)
        setManager.configure(
            session: session,
            historicalSessionsProvider: { [allSessions, session] in
                allSessions.filter { $0.persistentModelID != session.persistentModelID }
            },
            selectedKeyProvider: { [exerciseNav] in exerciseNav.selectedExerciseKey },
            selectedKeySetter: { [exerciseNav] key in exerciseNav.selectedExerciseKey = key }
        )

        // 2. ExerciseNav subscribed auf SetManager.exerciseKeyChanged
        exerciseNav.configure(
            session: session,
            supersetKeyChanged: setManager.exerciseKeyChanged.eraseToAnyPublisher()
        )

        // 3. WatchBridge + LiveActivityCtrl subscriben auf setManager.setCompleted
        watchBridge.configure(
            session: session,
            sessionManager: sessionManager,
            restTimer: restTimerManager,
            setManager: setManager,
            exerciseNav: exerciseNav,
            countdown: exerciseCountdownManager,
            setCompleted: setManager.setCompleted.eraseToAnyPublisher()
        )
        liveActivity.configure(
            session: session,
            sessionManager: sessionManager,
            restTimer: restTimerManager,
            setManager: setManager,
            countdown: exerciseCountdownManager,
            setCompleted: setManager.setCompleted.eraseToAnyPublisher()
        )

        // Key validieren (nach configure, da cachedGroupedSets jetzt befüllt)
        exerciseNav.validateSelectedKey(against: setManager.cachedGroupedSets)

        // Übungs-Countdown wiederherstellen — nur wenn setUUID zum aktuellen Satz passt
        if let resumeState = SessionResumeStore.load(),
           resumeState.sessionID == session.sessionUUID.uuidString,
           let snapshot = resumeState.exerciseCountdown,
           snapshot.setUUID == setManager.cachedCurrentSet?.setUUID {
            exerciseCountdownManager.restore(from: snapshot)
        }

        // SmartFill initialisieren
        if smartFill == nil {
            smartFill = ActiveWorkoutSmartFillViewModel(context: context, repository: repo)
        }
        prefillSmartSuggestionsIfNeeded()

        // Live Activity reattachen und initialen Sync anstoßen
        liveActivity.reattachIfNeeded()
        liveActivity.syncDebounced(saveResume: saveResumeState)
        watchBridge.sendState()

        // Bestehende Übungsbewertungen laden
        cachedExerciseRatings = Dictionary(
            uniqueKeysWithValues: session.safeExerciseRatings.map { ($0.exerciseGroupKey, $0.rating) }
        )

        // Readiness-Snapshot einmalig beim Start erzeugen
        let captureSession = session
        let captureContext = context
        let takesCardio = appSettings.takesCardioMedication
        readinessTask = Task { @MainActor in
            let modifier = await SessionReadinessService.captureReadiness(
                for: captureSession,
                context: captureContext,
                takesCardioMedication: takesCardio
            )
            currentReadinessModifier = modifier
            let snapshots = (try? captureContext.fetch(FetchDescriptor<SessionReadiness>())) ?? []
            currentSessionReadiness = snapshots.first {
                $0.sessionUUID == captureSession.sessionUUID.uuidString
            }
        }
    }

    // =========================================================================
    // MARK: - Actions
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

    private func deleteExercise(groupKey: String) {
        hapticGenerator.impactOccurred()
        exerciseToDelete = groupKey
        showDeleteAlert = true
    }

    private func confirmDelete() {
        guard let groupKey = exerciseToDelete else { return }
        let setsToDelete = session.safeExerciseSets.filter { $0.groupKey == groupKey }
        for set in setsToDelete {
            context.delete(set)
        }
        exerciseListRefreshID = UUID()
        exerciseNav.handleDeleted(groupKey: groupKey)
        exerciseToDelete = nil
        showDeleteAlert = false
    }

    private func rateExercise(groupKey: String, rating: ExerciseQualityRating) {
        guard cachedExerciseRatings[groupKey] != rating else { return }

        let nameSnapshot = session.safeExerciseSets
            .first { $0.groupKey == groupKey }
            .map { $0.exerciseNameSnapshot.isEmpty ? $0.exerciseName : $0.exerciseNameSnapshot }
            ?? groupKey

        let existing = session.safeExerciseRatings.filter { $0.exerciseGroupKey == groupKey }
        for old in existing { context.delete(old) }

        let newRating = ExerciseRating(
            exerciseGroupKey: groupKey,
            exerciseNameSnapshot: nameSnapshot,
            rating: rating,
            session: session
        )
        context.insert(newRating)
        cachedExerciseRatings[groupKey] = rating
        try? context.save()
    }

    private func startNewSession(sessionID: String) {
        sessionManager.startSession(sessionID: sessionID, workoutType: .strength)
        session.start()
        Task { @MainActor in try? context.save() }
        liveActivity.start()
        saveResumeState()
    }

    private func finishWorkout() {
        let finalSeconds = sessionManager.endSession()

        for set in session.safeExerciseSets.filter({ !$0.isCompleted }) {
            context.delete(set)
        }

        session.complete()
        session.duration = finalSeconds / 60

        let qualityInput = SessionQualityCalcEngine.Input(
            session: session,
            allSets: session.safeExerciseSets,
            readiness: nil
        )
        let qualityOutput = SessionQualityCalcEngine.calculate(input: qualityInput)
        session.sessionQualityScore = qualityOutput.score

        AutoProgressionApplier.resetAllUndoable(context: context)
        AutoProgressionApplier.apply(
            forSession: session,
            allPreviousSessions: allSessions,
            studioEquipments: studioEquipments,
            context: context,
            repository: ProgressionStateRepository(context: context),
            readinessModifier: currentReadinessModifier
        )

        saveCurrentExerciseMetrics(forKey: exerciseNav.selectedExerciseKey)

        Task {
            _ = await PhoneSessionManager.shared.requestFinalSnapshot()

            let phone = PhoneSessionManager.shared
            if phone.liveAverageHR > 0 {
                session.heartRate = Int(phone.liveAverageHR)
                session.maxHeartRate = Int(phone.liveMaxHR)
            }
            if phone.liveActiveCalories > 0 {
                session.calories = Int(phone.liveActiveCalories)
            }

            PhoneSessionManager.shared.sendHeartbeatEnabled(false)
            PhoneSessionManager.shared.sendStopHealthTracking()
            PhoneSessionManager.shared.resetHealthData()

            try? context.save()

            if appSettings.smartPlanUpdateEnabled,
               let sourcePlan = session.sourceTrainingPlan {
                let engine = PlanUpdateCalcEngine(
                    minWeightDelta: appSettings.planUpdateMinWeightDelta,
                    minRepsDelta: appSettings.planUpdateMinRepsDelta,
                    trendSessionCount: appSettings.planUpdateTrendSessionCount
                )
                let proposal = engine.analyze(plan: sourcePlan)
                if proposal.hasChanges {
                    sessionManager.pendingPlanUpdateProposal = proposal
                }
            }

            WatchComplicationService.updateComplications(allSessions: allSessions)
            WidgetSnapshotPublisher.publish(allSessions: allSessions)

            Task {
                await readinessTask?.value
                let success = await SupabaseSessionService.shared.upload(session, readiness: currentSessionReadiness)
                if success {
                    await MainActor.run {
                        session.syncedToSupabase = true
                        try? context.save()
                    }
                }
            }

            liveActivity.end()
            SessionResumeStore.clear()
            PhoneSessionManager.shared.sendIdleState()
            dismiss()
        }
    }

    private func cancelWorkout() {
        guard !PhoneSessionManager.shared.isWatchTrackingActive else {
            showCancelHealthAlert = true
            return
        }

        sessionManager.discardSession()
        context.delete(session)
        try? context.save()

        liveActivity.end()
        SessionResumeStore.clear()
        PhoneSessionManager.shared.sendIdleState()
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
    // MARK: - Superset-Aktionen
    // =========================================================================

    private func createSupersetFromSelection() {
        // Indizes → stabile groupKeys vor dem API-Aufruf (Watch-Sync kann Indizes
        // zwischen Snapshot und Live-groupedSets verschieben)
        let cached = setManager.cachedGroupedSets
        let keys = Array(selectedGroupIndicesForSuperset)
            .compactMap { cached[safe: $0]?.first?.groupKey }
        session.createSuperset(fromGroupKeys: keys)

        try? context.save()

        // Cache-Refresh — sonst zeigt ExercisesOverviewCard alte Daten
        setManager.rebuildGroupedCaches()
        setManager.refreshSetCaches()

        // Selection-Modus beenden
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isSupersetSelectionMode = false
            selectedGroupIndicesForSuperset = []
        }

        completionHapticMedium.impactOccurred()
    }

    private func removeFromSupersetAtIndex(_ index: Int) {
        session.removeFromSuperset(groupAt: index)

        try? context.save()

        setManager.rebuildGroupedCaches()
        setManager.refreshSetCaches()

        hapticGenerator.impactOccurred()
    }

    // =========================================================================
    // MARK: - Health Metrics
    // =========================================================================

    private func saveCurrentExerciseMetrics(forKey key: String?) {
        guard let key,
              let snapshot = PhoneSessionManager.shared.lastExerciseSnapshot,
              snapshot.avgHR > 0 || snapshot.calories > 0 else { return }

        let name = session.safeExerciseSets
            .first(where: { $0.groupKey == key })?
            .exerciseNameSnapshot ?? key

        let metrics = ExerciseMetrics(
            exerciseGroupKey: key,
            exerciseNameSnapshot: name,
            avgHeartRate: snapshot.avgHR,
            minHeartRate: snapshot.minHR,
            maxHeartRate: snapshot.maxHR,
            activeCalories: snapshot.calories,
            durationSeconds: snapshot.durationSeconds
        )
        metrics.session = session
        context.insert(metrics)
    }

    // =========================================================================
    // MARK: - Resume Store
    // =========================================================================

    @discardableResult
    private func restoreResumeStateIfPossible() -> Bool {
        guard let state = SessionResumeStore.load() else { return false }
        guard state.sessionID == session.sessionUUID.uuidString else { return false }

        liveActivity.restoreWorkoutStartDate(state.workoutStartDate)
        exerciseNav.selectedExerciseKey = state.selectedExerciseKey

        if state.isPaused && !sessionManager.isPaused {
            sessionManager.pauseSession()
        } else if !state.isPaused && sessionManager.isPaused {
            sessionManager.resumeSession()
        }

        if state.isResting, let end = state.restEndDate, end > Date() {
            restTimerManager.restore(endDate: end)
        }
        return true
    }

    private func saveResumeState() {
        let state = SessionResumeState(
            sessionID: session.sessionUUID.uuidString,
            workoutType: session.workoutType.rawValue,
            isPaused: sessionManager.isPaused,
            elapsedSeconds: sessionManager.elapsedSeconds,
            workoutStartDate: liveActivity.workoutStartDate,
            isResting: restTimerManager.isResting,
            restStartDate: restTimerManager.isResting ? restTimerManager.restStartDate : nil,
            restEndDate: restTimerManager.isResting ? restTimerManager.restEndDate : nil,
            selectedExerciseKey: exerciseNav.selectedExerciseKey,
            exerciseCountdown: exerciseCountdownManager.snapshot(),
            updatedAt: Date()
        )
        SessionResumeStore.save(state)
    }

    // =========================================================================
    // MARK: - Smart-Fill
    // =========================================================================

    private func prefillSmartSuggestionsIfNeeded() {
        guard let smartFill, let currentKey = exerciseNav.selectedExerciseKey else { return }
        smartFill.prefillSuggestion(
            exerciseGroupKey: currentKey,
            exercise: setManager.resolveExercise(for: currentKey),
            session: session,
            lastCompletedSession: setManager.lastCompletedSession(for: currentKey),
            equipmentByID: equipmentByID,
            readinessModifier: currentReadinessModifier
        )
    }

    // =========================================================================
    // MARK: - Scroll Content
    // =========================================================================

    private var scrollContent: some View {
        VStack(spacing: 20) {
            heroCard

            ReadinessCard(readiness: currentSessionReadiness) {
                selectedReadinessForDetail = currentSessionReadiness
            }

            exercisesOverview
        }
        .animation(.easeInOut, value: restTimerManager.isResting)
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 100)
    }

    @ViewBuilder
    private var heroCard: some View {
        if restTimerManager.isResting, let completedSet = setManager.cachedLastCompletedSet {
            let restTimer = RestTimerCardContainer(
                restTimerManager: restTimerManager,
                completedSet: completedSet,
                currentSet: setManager.cachedCurrentSet,
                setsForCurrentExercise: setsForCurrentExercise,
                supersetNextRoundNames: completedSet.supersetGroupId != nil
                    ? setManager.supersetNextRoundNames(for: completedSet)
                    : nil,
                onSkip: {
                    restTimerManager.skip()
                    hapticGenerator.impactOccurred()
                },
                onAdjust: { delta in
                    restTimerManager.adjust(delta: delta)
                    liveActivity.syncDebounced(saveResume: saveResumeState)
                }
            )

            if isSelectedExerciseComplete, !session.allSetsCompleted {
                VStack(spacing: 20) {
                    restTimer
                    ExerciseCompletedCard(
                        exerciseName: selectedExerciseName,
                        exerciseGroupKey: exerciseNav.selectedExerciseKey,
                        existingRating: exerciseNav.selectedExerciseKey.flatMap { cachedExerciseRatings[$0] },
                        onRate: { rating in
                            if let key = exerciseNav.selectedExerciseKey {
                                rateExercise(groupKey: key, rating: rating)
                            }
                        },
                        onNextExercise: { exerciseNav.selectedExerciseKey = nil }
                    )
                }
            } else {
                restTimer
            }
        } else if let activeSet = setManager.cachedCurrentSet {
            let ctx = setManager.supersetDisplayContext(for: activeSet)
            ActiveSetCard(
                set: activeSet,
                setsForCurrentExercise: setsForCurrentExercise,
                supersetExerciseNames: ctx?.exerciseNames,
                supersetCurrentIndex: ctx?.currentIndex ?? 0,
                supersetCurrentRound: ctx?.currentRound ?? 1,
                supersetTotalRounds: ctx?.totalRounds ?? 1,
                onOpenQuickConfig: {
                    quickConfigExercise = setManager.resolveExercise(for: activeSet.groupKey)
                },
                isEngineSuggestion: smartFill?.isSuggestionActive(for: activeSet) ?? false,
                isReadinessReduced: smartFill?.isReadinessReduced(for: activeSet) ?? false,
                lastSessionReference: setManager.lastSessionReference(for: activeSet),
                countdown: exerciseCountdownManager,
                selectedSetForEdit: $selectedSetForEdit,
                onComplete: { set in setManager.completeSet(set) }
            )
        } else if isSelectedExerciseComplete, !session.allSetsCompleted {
            ExerciseCompletedCard(
                exerciseName: selectedExerciseName,
                exerciseGroupKey: exerciseNav.selectedExerciseKey,
                existingRating: exerciseNav.selectedExerciseKey.flatMap { cachedExerciseRatings[$0] },
                onRate: { rating in
                    if let key = exerciseNav.selectedExerciseKey {
                        rateExercise(groupKey: key, rating: rating)
                    }
                },
                onNextExercise: { exerciseNav.selectedExerciseKey = nil }
            )
        } else {
            WorkoutCompletedCard(
                onFinishWorkout: finishWorkout,
                onAddExercise: { showAddExerciseSheet = true }
            )
        }
    }

    private var exercisesOverview: some View {
        ExercisesOverviewCard(
            groupedSets: setManager.cachedGroupedSets,
            currentExerciseIndex: setManager.cachedCurrentExerciseIndex,
            selectedExerciseKey: exerciseNav.selectedExerciseKey,
            prSetIDs: prSetIDs,
            onAddExercise: { showAddExerciseSheet = true },
            onSelectExercise: { key in
                exerciseNav.selectExercise(key: key)
                hapticGenerator.impactOccurred()
            },
            onDeleteExercise: { key in deleteExercise(groupKey: key) },
            onReorderExercise: { from, to in
                exerciseNav.reorderExercise(from: from, to: to, in: setManager.cachedGroupedSets)
                setManager.rebuildGroupedCaches()
                setManager.refreshSetCaches()
                Task { @MainActor in try? context.save() }
                hapticGenerator.impactOccurred()
            },
            onRetroRIR: { set in rirRetroSet = set },
            onRemoveFromSuperset: { index in
                removeFromSupersetAtIndex(index)
            },
            isSupersetSelectionMode: $isSupersetSelectionMode,
            selectedGroupIndicesForSuperset: $selectedGroupIndicesForSuperset
        )
    }

    // MARK: - Superset Action Bar

    private var supersetActionBar: some View {
        let helper = SupersetSelectionHelper(groupedSets: setManager.cachedGroupedSets)
        let canCreate = helper.canCreateSuperset(from: selectedGroupIndicesForSuperset)
        let hasGap = selectedGroupIndicesForSuperset.count >= 2
            && !helper.isContiguous(selectedGroupIndicesForSuperset)

        return ActiveWorkoutSupersetActionBar(
            selectedCount: selectedGroupIndicesForSuperset.count,
            canCreate: canCreate,
            hasGap: hasGap,
            onCancel: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isSupersetSelectionMode = false
                    selectedGroupIndicesForSuperset = []
                }
            },
            onCreate: {
                createSupersetFromSelection()
            }
        )
    }

    // MARK: - Countdown Helpers

    /// Setzt den Countdown auf den neuen Satz oder räumt ihn auf.
    /// Ausgelagert damit der Compiler .onChange separat type-checken kann.
    private func handleCountdownSetChange() {
        guard let set = setManager.cachedCurrentSet else {
            exerciseCountdownManager.cleanup()
            return
        }
        if set.isTimeBased {
            // Laufenden Countdown für denselben Satz nicht resetten
            guard exerciseCountdownManager.currentSetUUID != set.setUUID else { return }
            exerciseCountdownManager.reset(to: set.duration, setUUID: set.setUUID)
        }
        // Kein cleanup bei Weight-Set — laufender Countdown für einen Time-Satz darf weiterlaufen
    }

    /// Session-Pause/-Resume inklusive Countdown-Kopplung (R4).
    /// Ausgelagert damit die onChange-Chain kürzer bleibt.
    private func handleSessionPauseChange(isPaused: Bool) {
        liveActivity.syncDebounced(saveResume: saveResumeState)
        watchBridge.sendState()
        if isPaused {
            // Merken ob Countdown lief — vor pause(), das isRunning zurücksetzt
            wasRunningBeforeSessionPause = exerciseCountdownManager.isRunning && !exerciseCountdownManager.isPaused
            exerciseCountdownManager.pause()
            PhoneSessionManager.shared.sendPauseHealthTracking()
        } else {
            // Countdown nur fortsetzen wenn er vor der Session-Pause aktiv war
            if wasRunningBeforeSessionPause {
                exerciseCountdownManager.resume()
            }
            wasRunningBeforeSessionPause = false
            PhoneSessionManager.shared.sendResumeHealthTracking()
        }
    }
}

// MARK: - Array Helper

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
