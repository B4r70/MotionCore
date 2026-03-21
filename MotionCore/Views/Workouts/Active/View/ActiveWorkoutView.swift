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
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var sessionManager: ActiveSessionManager

    @Bindable var session: StrengthSession

    @Query(filter: #Predicate<StrengthSession> { $0.isCompleted }, sort: \StrengthSession.date, order: .reverse)
    private var allSessions: [StrengthSession]

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
    @State private var exerciseToDelete: String?
    @State private var showDeleteAlert = false

        // Sheet zum Hinzufügen einer Übung während des Trainings
    @State private var showAddExerciseSheet = false

        // Refresh-Trigger für die Übersicht nach dem Hinzufügen neuer Übungen
    @State private var exerciseListRefreshID = UUID()

        // Gecachte Kopie von session.groupedSets — verhindert wiederholte
        // Neuberechnungen bei jedem Re-Render der View.
    @State private var cachedGroupedSets: [[ExerciseSet]] = []

        // Performance-Caches: werden nur bei echten Datenänderungen aktualisiert,
        // nicht bei jedem sekündlichen Timer-Tick des ActiveSessionManager.
    @State private var cachedSessionVolume: Double = 0
    @State private var cachedCurrentSet: ExerciseSet? = nil
    @State private var cachedLastCompletedSet: ExerciseSet? = nil
    @State private var cachedCurrentExerciseIndex: Int = 0

    @State private var prSetIDs: Set<PersistentIdentifier> = []
    @State private var prBannerExercise: String? = nil
    @State private var prBannerOneRM: Double = 0

        // Debounce-Task für Live Activity Sync
    @State private var syncDebounceTask: Task<Void, Never>? = nil

        // Progression
    @State private var dismissedProgressionExercises: Set<String> = []
    @State private var cachedProgressionRecommendations: [ProgressionRecommendation] = []

        // Workout-Analyse Sheet
    @State private var showAnalyseSheet = false

        // Rest-Timer: ausgelagert in eine Klasse, damit Timer-Closures
        // zuverlässig auf den State zugreifen – auch nach SwiftUI-Redraws.
    @StateObject private var restTimerManager = RestTimerManager()

    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    private let completionHaptic = UINotificationFeedbackGenerator()
    private let completionHapticMedium = UIImpactFeedbackGenerator(style: .medium)

        // MARK: - Derived

    private var selectedExerciseSets: [ExerciseSet] {
        guard let key = selectedExerciseKey else { return [] }

        return session.safeExerciseSets
            .filter { $0.groupKey == key }
            .sorted { $0.setNumber < $1.setNumber }
    }

    private func computeSessionVolume() -> Double {
        session.safeExerciseSets
            .filter { $0.isCompleted }
            .reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
    }

    private var historicalSessions: [StrengthSession] {
        allSessions.filter { $0.persistentModelID != session.persistentModelID }
    }

    /// Aktualisiert alle Set-Caches in einem einzigen safeExerciseSets-Durchlauf.
    /// Muss nach jeder Änderung an completedSets oder selectedExerciseKey aufgerufen werden.
    private func refreshSetCaches() {
        let safeSets = session.safeExerciseSets

        // lastCompletedSet: letzter abgeschlossener Satz
        cachedLastCompletedSet = safeSets.last { $0.isCompleted }

        // currentSet: nächster offener Satz (nach selectedExerciseKey oder global)
        if let key = selectedExerciseKey {
            cachedCurrentSet = safeSets
                .filter { $0.groupKey == key }
                .sorted { $0.setNumber < $1.setNumber }
                .first { !$0.isCompleted }
        } else {
            cachedCurrentSet = session.nextUncompletedSet
        }

        // currentExerciseIndex: Position der aktuellen Übung in cachedGroupedSets
        if let key = selectedExerciseKey,
           let idx = cachedGroupedSets.firstIndex(where: { $0.first?.groupKey == key }) {
            cachedCurrentExerciseIndex = idx
        } else if let current = cachedCurrentSet {
            cachedCurrentExerciseIndex = cachedGroupedSets.firstIndex(where: { group in
                group.contains { $0.id == current.id }
            }) ?? 0
        } else {
            cachedCurrentExerciseIndex = 0
        }
    }

    private func refreshProgressionRecommendations() {
        let engine = ProgressionCalcEngine()
        let exerciseNames = Set(session.safeExerciseSets.map { $0.exerciseName })

        cachedProgressionRecommendations = exerciseNames.compactMap { name in
            guard !dismissedProgressionExercises.contains(name) else { return nil }
            let firstSet = session.safeExerciseSets.first { $0.exerciseName == name }
            let targetRIR = firstSet?.targetRIR ?? 2
            let step = firstSet?.exercise?.progressionStep ?? 2.5
            return engine.recommendation(
                for: name,
                targetRIR: targetRIR,
                progressionStep: step,
                sessions: historicalSessions
            )
        }
    }

    // MARK: - Superset Display Context

    /// Alle für die UI benötigten Superset-Anzeige-Daten in einer einzigen Berechnung
    private struct SupersetDisplayContext {
        let exerciseNames: [String]
        let currentIndex: Int
        let currentRound: Int
        let totalRounds: Int
    }

    /// Berechnet alle Superset-Anzeige-Daten in einem einzigen groupedSets-Durchlauf.
    /// Gibt nil zurück wenn die Übung nicht Teil eines Supersets ist.
    private func supersetDisplayContext(for set: ExerciseSet) -> SupersetDisplayContext? {
        guard let groupId = set.supersetGroupId else { return nil }

        let groups = cachedGroupedSets
            .filter { $0.first?.supersetGroupId == groupId }
            .sorted { ($0.first?.sortOrder ?? 0) < ($1.first?.sortOrder ?? 0) }

        guard groups.count >= 2 else { return nil }

        // Übungsnamen sortiert nach Reihenfolge in der Gruppe
        let names = groups.compactMap { group -> String? in
            guard let first = group.first else { return nil }
            return first.exerciseNameSnapshot.isEmpty ? first.exerciseName : first.exerciseNameSnapshot
        }

        // groupKey-Liste für Index- und Rundenberechnung
        let keys = groups.compactMap { $0.first?.groupKey }
        let currentIndex = keys.firstIndex(of: set.groupKey) ?? 0

        // Aktuelle Runde: Anzahl abgeschlossener Sätze der ersten Übung + 1
        let firstKey = keys.first ?? ""
        let completedRounds = session.safeExerciseSets
            .filter { $0.groupKey == firstKey && $0.isCompleted }
            .count
        let currentRound = completedRounds + 1

        // Gesamtrunden: maximale Satzanzahl über alle Übungen der Gruppe
        let totalRounds = keys.map { key in
            session.safeExerciseSets.filter { $0.groupKey == key }.count
        }.max() ?? 1

        return SupersetDisplayContext(
            exerciseNames: names,
            currentIndex: currentIndex,
            currentRound: currentRound,
            totalRounds: totalRounds
        )
    }

    /// Übungsnamen der nächsten Superset-Runde (nur Übungen mit noch offenen Sätzen)
    private func supersetNextRoundNames(for set: ExerciseSet) -> [String]? {
        guard let groupId = set.supersetGroupId else { return nil }
        let groups = cachedGroupedSets
            .filter { $0.first?.supersetGroupId == groupId }
            .sorted { ($0.first?.sortOrder ?? 0) < ($1.first?.sortOrder ?? 0) }
        let names = groups.compactMap { group -> String? in
            guard group.contains(where: { !$0.isCompleted }) else { return nil }
            let first = group.first
            return first?.exerciseNameSnapshot.isEmpty == false
                ? first?.exerciseNameSnapshot
                : first?.exerciseName
        }
        return names.isEmpty ? nil : names
    }

    private var currentVideoThumb: ExerciseVideoView {
        guard let set = cachedCurrentSet else {
            return ExerciseVideoView(assetName: "", size: 80)
        }
        return .forSet(set, size: 80)
    }

    private var lastCompletedVideoThumb: ExerciseVideoView {
        guard let set = cachedLastCompletedSet else {
            return ExerciseVideoView(assetName: "", size: 56)
        }
        return .forSet(set, size: 56)
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
                    progress: session.progress,
                    sessionVolume: cachedSessionVolume,
                    planTitle: session.sourceTrainingPlan?.title
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
            completionHapticMedium.prepare()
                // Watch-Action-Handler registrieren
            PhoneSessionManager.shared.onAction = { action in
                handleWatchAction(action)
            }
            refreshProgressionRecommendations()

                // RestTimerManager Callbacks konfigurieren
            restTimerManager.onTimerFinished = {
                if self.appSettings.enableRestTimerHaptic {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }

                // Initialer Cache-Aufbau
            cachedGroupedSets = session.groupedSets
            refreshSetCaches()
            cachedSessionVolume = computeSessionVolume()
        }

            // =====================================================================
            // MARK: - onChange Handler (einzige Quelle für Live Activity Updates)
            // =====================================================================
            // Diese Handler reagieren auf State-Änderungen und updaten die Live
            // Activity EINMAL. Die Action-Funktionen ändern nur den State.
            // =====================================================================

        .onChange(of: restTimerManager.isResting) { _, _ in
            syncLiveActivityStates()
        }
        .onChange(of: session.completedSets) { _, _ in
            cachedGroupedSets = session.groupedSets
            refreshSetCaches()
            cachedSessionVolume = computeSessionVolume()
            syncLiveActivityStates()
            sendWatchState()
        }
        .onChange(of: exerciseListRefreshID) { _, _ in
            cachedGroupedSets = session.groupedSets
            refreshSetCaches()
        }
        .onChange(of: selectedExerciseKey) { _, newValue in
            refreshSetCaches()
            sessionManager.setSelectedExerciseKey(newValue)
            syncLiveActivityStates()
            sendWatchState()
        }

            // Foreground-Handler für Rest-Timer: berechnet verbleibende Zeit aus restEndDate
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            restTimerManager.handleForegroundReturn()

            if restTimerManager.isResting {
                syncLiveActivityStates()
            }
        }
        .onDisappear {
            cleanupLocalTimer()
            restTimerManager.cleanup()
            syncDebounceTask?.cancel()
            saveResumeState()
                // Watch-Action-Handler aufräumen
            PhoneSessionManager.shared.onAction = nil
            PhoneSessionManager.shared.sendIdleState()
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
        .alert("Übung löschen?", isPresented: $showDeleteAlert) {
            Button("Löschen", role: .destructive) {
                confirmDelete()
            }
            Button("Abbrechen", role: .cancel) {
                exerciseToDelete = nil
            }
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
            // Sheet zum Hinzufügen einer Übung während des Trainings
        .sheet(isPresented: $showAddExerciseSheet) {
            AddExerciseDuringWorkoutSheet(session: session) {
                    // Nach dem Hinzufügen: UI refreshen und Live Activity updaten
                exerciseListRefreshID = UUID() // Erzwingt Neuaufbau der Liste
                syncLiveActivityStates()
            }
            .environmentObject(appSettings)
        }
            // Progressions-Analyse Sheet
        .sheet(isPresented: $showAnalyseSheet) {
            WorkoutAnalyseView(session: session)
                .environmentObject(appSettings)
        }
    }

    private var setsForCurrentExercise: Int {
        guard let current = cachedCurrentSet else { return 0 }
        return cachedGroupedSets.first(where: { $0.first?.groupKey == current.groupKey })?.count ?? 0
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
            // UUID in Exercise bereinigen
        repairExerciseUUIDSnapshotsIfNeeded()

            // Fallback: falls ResumeStore nix gesetzt hat
        if selectedExerciseKey == nil {
            selectedExerciseKey = sessionManager.getSelectedExerciseKey()
        }

            // ✅ Schritt 2: Guard gegen ungültigen Key (nach dem Setzen!)
        validateSelectedExerciseKey()

        reattachLiveActivityIfNeeded()

            // ✅ Schritt 3: einmaliger Initial-Sync
        syncLiveActivityStates()
        sendWatchState()
    }

        // Zugriff Exercise-Key prüfen
    private func validateSelectedExerciseKey() {
        // groupedSets direkt aufrufen, da setupSession vor dem ersten Cache-Aufbau läuft
        let groups = session.groupedSets
        guard !groups.isEmpty else { return }

        if let key = selectedExerciseKey,
           !groups.contains(where: { $0.first?.groupKey == key }) {
            selectedExerciseKey = nil
        }
    }

    /// Synchronisiert Live Activity und ResumeState mit Debounce.
    /// Mehrere schnelle State-Änderungen (completedSets + selectedExerciseKey)
    /// werden zu einem einzigen Update zusammengefasst.
    private func syncLiveActivityStates() {
        // Laufenden Task abbrechen und durch neuen ersetzen
        syncDebounceTask?.cancel()
        syncDebounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            updateLiveActivity()
            saveResumeState()
        }
    }


    private func startNewSession(sessionID: String) {
        sessionManager.startSession(sessionID: sessionID, workoutType: .strength)
        session.start()

        // context.save() asynchron — blockiert den Main Thread nicht
        Task { @MainActor in
            try? context.save()
        }

            // Live Activity starten
        startLiveActivity()

        saveResumeState()
    }

        // Bereinigung des Local Timers
    private func cleanupLocalTimer() {
        localTimer?.invalidate()
        localTimer = nil
    }

        // ExerciseUUID in der Datei bereinigen.
    private func repairExerciseUUIDSnapshotsIfNeeded() {
        var didChange = false

        for s in session.safeExerciseSets {
            guard let api = s.exercise?.apiID?.uuidString, !api.isEmpty else { continue }

            if s.exerciseUUIDSnapshot != api {
                s.exerciseUUIDSnapshot = api
                didChange = true
            }
        }

        if didChange {
            try? context.save()
            print("🛠️ Repaired exerciseUUIDSnapshot for existing sets.")
        }
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

        // Exercise auswählen
    private func selectExercise(key: String) {
        withAnimation(.easeInOut) {
            selectedExerciseKey = key
        }
        hapticGenerator.impactOccurred()
    }

        // Delete Exercise
    private func deleteExercise(groupKey: String) {
        hapticGenerator.impactOccurred()
        exerciseToDelete = groupKey
        showDeleteAlert = true
    }

        // Löschen bestätigen
    private func confirmDelete() {
        guard let groupKey = exerciseToDelete else { return }

            // Finde alle Sets dieser Übung
        let setsToDelete = session.safeExerciseSets.filter { $0.groupKey == groupKey }

            // Lösche alle Sets
        for set in setsToDelete {
            context.delete(set)
        }

            // Refresh UI
        exerciseListRefreshID = UUID()

            // Falls die gelöschte Übung aktuell ausgewählt war
        if selectedExerciseKey == groupKey {
            selectedExerciseKey = nil
        }

            // Reset Alert State
        exerciseToDelete = nil
        showDeleteAlert = false

        print("🗑️ Übung gelöscht: \(groupKey)")
    }

        // Set komplett abschließen
    private func completeSet(_ set: ExerciseSet) {
        withAnimation(.easeInOut) {
            set.isCompleted = true
        }

        // Cache sofort aktualisieren, damit nachfolgende Berechnungen aktuell sind
        cachedGroupedSets = session.groupedSets

        // context.save() asynchron — blockiert den Main Thread nicht
        Task { @MainActor in
            try? context.save()
        }

        // PR-Prüfung asynchron — blockiert den Main Thread nicht
        let setID = set.persistentModelID
        let exerciseName = set.exerciseName
        let sessions = historicalSessions
        // ExerciseSet ist ein SwiftData-Referenztyp — Zugriff auf MainActor ist sicher
        Task { @MainActor in
            let prService = PRDetectionService(historicalSessions: sessions)
            if prService.isNewPR(set: set) {
                self.prSetIDs.insert(setID)
                self.prBannerExercise = exerciseName
                self.prBannerOneRM = prService.calculatedOneRM(for: set)
                try? await Task.sleep(for: .seconds(3))
                withAnimation(.easeOut) {
                    self.prBannerExercise = nil
                }
            }
        }

        if selectedExerciseKey == nil {
            if let key = cachedGroupedSets
                .first(where: { group in group.contains(where: { $0.id == set.id }) })?
                .first?.groupKey {
                selectedExerciseKey = key
            }
        }

        if selectedExerciseKey == nil {
            selectedExerciseKey = set.groupKey
        }

        completionHapticMedium.impactOccurred()

        // Superset-Rotation hat Vorrang vor normalem Rest-Timer-Handling
        if let groupId = set.supersetGroupId {
            handleSupersetRotation(completedSet: set, supersetGroupId: groupId)
            return
        }

        // Normales Handling (kein Superset): Rest-Timer starten falls weitere Sätze übrig
        let remainingSetsForExercise = session.safeExerciseSets.filter {
            $0.groupKey == set.groupKey && !$0.isCompleted
        }

        if !remainingSetsForExercise.isEmpty {
            restTimerManager.start(seconds: set.restSeconds)
        }
    }

    /// Steuert die Rotation innerhalb eines Supersets.
    ///
    /// Ablauf:
    ///   Übung A (Satz 1) → Übung B (Satz 1) → Übung C (Satz 1) → PAUSE
    ///   Übung A (Satz 2) → Übung B (Satz 2) → Übung C (Satz 2) → PAUSE
    ///   ...
    ///
    /// Regeln:
    /// - Zwischen Superset-Übungen: KEIN Rest-Timer
    /// - Nach vollständiger Runde: Rest-Timer mit restSeconds der letzten Übung
    /// - Nach letztem Satz des gesamten Supersets: zur nächsten Nicht-Superset-Übung
    private func handleSupersetRotation(completedSet: ExerciseSet, supersetGroupId: String) {
        // Alle Übungs-Keys in der Superset-Gruppe, sortiert nach sortOrder
        let supersetKeys: [String] = cachedGroupedSets
            .filter { $0.first?.supersetGroupId == supersetGroupId }
            .sorted { ($0.first?.sortOrder ?? 0) < ($1.first?.sortOrder ?? 0) }
            .compactMap { $0.first?.groupKey }

        guard !supersetKeys.isEmpty else { return }

        // Position der abgeschlossenen Übung in der Rotation
        let currentIndex = supersetKeys.firstIndex(of: completedSet.groupKey) ?? 0

        // Nächste Übung in der aktuellen Runde (nur NACH der aktuellen, kein Wrap-around)
        let nextInRound = Array(supersetKeys.dropFirst(currentIndex + 1)).first { key in
            session.safeExerciseSets.contains { $0.groupKey == key && !$0.isCompleted }
        }

        if let nextKey = nextInRound {
            // Noch nicht am Ende der Runde → direkt weiter, KEIN Rest-Timer
            withAnimation(.easeInOut) {
                selectedExerciseKey = nextKey
            }
            return
        }

        // Runde ist komplett — prüfen ob weitere Runden im Superset existieren
        let anyOpenInGroup = supersetKeys.contains { key in
            session.safeExerciseSets.contains { $0.groupKey == key && !$0.isCompleted }
        }

        if anyOpenInGroup {
            // Weitere Runden vorhanden → Rest-Timer + zur ersten offenen Übung der Gruppe
            restTimerManager.start(seconds: completedSet.restSeconds)
            let firstOpenKey = supersetKeys.first { key in
                session.safeExerciseSets.contains { $0.groupKey == key && !$0.isCompleted }
            }
            if let key = firstOpenKey {
                withAnimation(.easeInOut) {
                    selectedExerciseKey = key
                }
            }
        } else {
            // Gesamtes Superset abgeschlossen → zur nächsten Nicht-Superset-Übung wechseln
            let supersetGroupKeys = Set(supersetKeys)
            let nextExerciseKey = cachedGroupedSets
                .sorted { ($0.first?.sortOrder ?? 0) < ($1.first?.sortOrder ?? 0) }
                .first { group in
                    guard let key = group.first?.groupKey,
                          let firstSet = group.first else { return false }
                    // Nicht Teil des abgeschlossenen Supersets und hat noch offene Sätze
                    return !supersetGroupKeys.contains(key)
                        && firstSet.supersetGroupId != supersetGroupId
                        && group.contains { !$0.isCompleted }
                }?
                .first?.groupKey

            if let key = nextExerciseKey {
                withAnimation(.easeInOut) {
                    selectedExerciseKey = key
                }
            }
        }
    }

    private func finishWorkout() {
        let finalSeconds = sessionManager.endSession()

        session.complete()
        session.duration = finalSeconds / 60
        try? context.save()

        // Smart Plan-Update: Analyse nach Session-Ende
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

            // Complications nach Workout-Abschluss aktualisieren
        WatchComplicationService.updateComplications(allSessions: allSessions)

            // Supabase-Upload (non-blocking, CloudKit bleibt primär)
        Task {
            let success = await SupabaseSessionService.shared.upload(session)
            if success {
                await MainActor.run {
                    session.syncedToSupabase = true
                    try? context.save()
                }
            }
        }

        endLiveActivity()
        SessionResumeStore.clear()

        PhoneSessionManager.shared.sendIdleState()
        dismiss()
    }

    private func cancelWorkout() {
        sessionManager.discardSession()

        context.delete(session)
        try? context.save()

        endLiveActivity()
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
        // MARK: - Watch Integration
        // =========================================================================

        /// Sendet den aktuellen Workout-State an die Apple Watch
    private func sendWatchState() {
        let state: WatchWorkoutState = sessionManager.isPaused ? .paused : .active
        let grouped = cachedGroupedSets
        let currentKey = selectedExerciseKey ?? session.nextUncompletedSet?.groupKey ?? ""
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
            elapsedTime: TimeInterval(sessionManager.elapsedSeconds)
        )
    }

        /// Verarbeitet eingehende Actions von der Apple Watch
    private func handleWatchAction(_ action: WatchAction) {
        switch action {
            case .pauseResume:
                if sessionManager.isPaused {
                    sessionManager.resumeSession()
                } else {
                    sessionManager.pauseSession()
                }

            case .completeSet:
                    // Ersten nicht abgeschlossenen Satz der aktuellen Übung abschließen
                if let set = selectedExerciseSets.first(where: { !$0.isCompleted }) {
                    completeSet(set)
                }

            case .nextExercise:
                let grouped = cachedGroupedSets
                let currentKey = selectedExerciseKey ?? ""
                    // Fallback -1 → nextIdx wird 0 → navigiert zur ersten Übung wenn keine Auswahl
                let currentIdx = grouped.firstIndex(where: { $0.first?.groupKey == currentKey }) ?? -1
                let nextIdx = currentIdx + 1
                guard nextIdx < grouped.count else { return }
                if let nextKey = grouped[safe: nextIdx]?.first?.groupKey {
                    selectExercise(key: nextKey)
                }

            case .previousExercise:
                let grouped = cachedGroupedSets
                let currentKey = selectedExerciseKey ?? ""
                    // Fallback 0 → prevIdx wird -1 → guard greift → kein Wechsel bei unbekanntem Key
                let currentIdx = grouped.firstIndex(where: { $0.first?.groupKey == currentKey }) ?? 0
                let prevIdx = currentIdx - 1
                guard prevIdx >= 0 else { return }
                if let prevKey = grouped[safe: prevIdx]?.first?.groupKey {
                    selectExercise(key: prevKey)
                }
        }
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
        guard let activity = currentActivity else {
            return
        }

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

    private func makeLiveContentState() -> WorkoutActivityAttributes.ContentState {
            // workoutStartDate nur aktualisieren wenn Session aktiv läuft (nicht pausiert, kein Rest).
            // Während Rest/Pause bleibt der Anker stabil – verhindert Flickern im Widget-Timer.
        if !sessionManager.isPaused {
            workoutStartDate = Date().addingTimeInterval(-Double(sessionManager.elapsedSeconds))
        }

        return WorkoutActivityAttributes.ContentState(
            workoutStartDate: workoutStartDate,
            isPaused: sessionManager.isPaused,
            elapsedAtPause: sessionManager.isPaused ? sessionManager.elapsedSeconds : nil,
            currentExercise: cachedCurrentSet?.exerciseName,
            currentSet: cachedCurrentSet.map { "Satz \($0.setNumber)" },
            isResting: restTimerManager.isResting,
            restStartDate: restTimerManager.isResting ? restTimerManager.restStartDate : nil,
            restEndDate: restTimerManager.isResting ? restTimerManager.restEndDate : nil,
            completedSets: session.completedSets,
            totalSets: session.totalSets,
            totalSetsForCurrentExercise: setsForCurrentExercise > 0 ? setsForCurrentExercise : nil
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

            // Rest wiederherstellen über RestTimerManager
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
            workoutStartDate: workoutStartDate,
            isResting: restTimerManager.isResting,
            restStartDate: restTimerManager.isResting ? restTimerManager.restStartDate : nil,
            restEndDate: restTimerManager.isResting ? restTimerManager.restEndDate : nil,
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
                restStartDate: nil,
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
            groupedSets: cachedGroupedSets,
            currentExerciseIndex: cachedCurrentExerciseIndex,
            prSetIDs: prSetIDs,
            onAddExercise: { showAddExerciseSheet = true },
            onSelectExercise: { key in
                selectExercise(key: key)
            },
            onDeleteExercise: { key in
                deleteExercise(groupKey: key)
            }
        )
    }

    @ViewBuilder
    private var progressionBanners: some View {
        if !cachedProgressionRecommendations.isEmpty {
            VStack(spacing: 8) {
                ForEach(cachedProgressionRecommendations, id: \.exerciseName) { rec in
                    ProgressionBannerView(recommendation: rec) {
                        withAnimation(.easeOut) {
                            dismissedProgressionExercises.insert(rec.exerciseName)
                            refreshProgressionRecommendations()
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: cachedProgressionRecommendations.count)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var scrollContent: some View {
        VStack(spacing: 20) {
            heroCard
            progressionBanners
            exercisesOverview

            // Analyse-Button: nur sichtbar wenn historische Daten vorhanden
            if !historicalSessions.isEmpty {
                analyseButton
            }
        }
            // Animiert den Wechsel zwischen ActiveSetCard und RestTimerCard
        .animation(.easeInOut, value: restTimerManager.isResting)
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 100)
    }

    // MARK: - Analyse-Button

    private var analyseButton: some View {
        Button {
            showAnalyseSheet = true
        } label: {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.subheadline)
                Text("Progressions-Analyse")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.purple.opacity(0.15))
            .foregroundStyle(.purple)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private var heroCard: some View {
        if restTimerManager.isResting, let completedSet = cachedLastCompletedSet {
            RestTimerCardContainer(
                restTimerManager: restTimerManager,
                completedSet: completedSet,
                currentSet: cachedCurrentSet,
                setsForCurrentExercise: setsForCurrentExercise,
                supersetNextRoundNames: completedSet.supersetGroupId != nil
                    ? supersetNextRoundNames(for: completedSet)
                    : nil,
                onSkip: {
                    restTimerManager.skip()
                    hapticGenerator.impactOccurred()
                },
                onAdjust: { delta in
                    _ = restTimerManager.adjust(delta: delta)
                    syncLiveActivityStates()
                }
            )
        } else if let activeSet = cachedCurrentSet {
            // Alle Superset-Anzeige-Daten in einem einzigen groupedSets-Durchlauf berechnen
            let ctx = supersetDisplayContext(for: activeSet)
            ActiveSetCard(
                set: activeSet,
                setsForCurrentExercise: setsForCurrentExercise,
                supersetExerciseNames: ctx?.exerciseNames,
                supersetCurrentIndex: ctx?.currentIndex ?? 0,
                supersetCurrentRound: ctx?.currentRound ?? 1,
                supersetTotalRounds: ctx?.totalRounds ?? 1,
                selectedSetForEdit: $selectedSetForEdit,
                onComplete: completeSet
            )
        } else if isSelectedExerciseComplete, !session.allSetsCompleted {
            ExerciseCompletedCard(
                exerciseName: selectedExerciseName,
                onNextExercise: { selectedExerciseKey = nil }
            )
        } else {
            WorkoutCompletedCard(
                onFinishWorkout: finishWorkout,
                onAddExercise: { showAddExerciseSheet = true }
            )
        }
    }
}

    // MARK: - Sheet zum Hinzufügen einer Übung während des Trainings

// MARK: - RestTimerCardContainer

/// Kapselt RestTimerCard mit eigenem @ObservedObject für restTimerManager.
/// Dadurch lösen sekündliche Timer-Ticks nur Re-Renders dieser Sub-View aus,
/// nicht die gesamte ActiveWorkoutView.
private struct RestTimerCardContainer: View {
    @ObservedObject var restTimerManager: RestTimerManager
    let completedSet: ExerciseSet
    let currentSet: ExerciseSet?
    let setsForCurrentExercise: Int
    let supersetNextRoundNames: [String]?
    let onSkip: () -> Void
    let onAdjust: (Int) -> Void

    var body: some View {
        RestTimerCard(
            remainingSeconds: restTimerManager.remainingSeconds,
            targetSeconds: completedSet.restSeconds,
            onSkip: onSkip,
            onAdjust: onAdjust,
            nextExerciseName: currentSet?.exerciseName,
            nextSetNumber: currentSet?.setNumber,
            totalSetsForExercise: setsForCurrentExercise,
            supersetNextRoundNames: supersetNextRoundNames
        )
    }
}

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
                // Anzeige Exercise Video View
            ExerciseVideoView.forExercise(
                exercise,
                size: 56
            )
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
                //Anzeige Exercise Video View
            ExerciseVideoView.forExercise(
                exercise,
                size: 80
            )

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
        let maxSortOrder = session.safeExerciseSets.map { $0.sortOrder }.max() ?? -1
        let newSortOrder = maxSortOrder + 1

            // Gewicht berechnen (bei unilateral: Gesamtgewicht = 2 × Eingabe)
        let isUnilateral = exercise.isUnilateral
        let finalWeight = isUnilateral ? defaultWeight * 2 : defaultWeight

            // Sets erstellen
        for setNumber in 1...numberOfSets {
            let newSet = ExerciseSet(
                exerciseName: exercise.name,
                exerciseNameSnapshot: exercise.name,
                exerciseUUIDSnapshot: exercise.apiID?.uuidString.lowercased() ?? "",
                exerciseMediaAssetName: exercise.mediaAssetName,
                isUnilateralSnapshot: exercise.isUnilateral,
                setNumber: setNumber,
                weight: finalWeight,
                weightPerSide: isUnilateral ? defaultWeight : 0,
                reps: defaultReps,
                restSeconds: restSeconds,
                setKind: .work,
                isCompleted: false, // Nicht abgeschlossen, da während des Trainings
                targetRepsMin: exercise.repRangeMin,
                targetRepsMax: exercise.repRangeMax,
                sortOrder: newSortOrder
            )

            newSet.exercise = exercise
            session.addSet(newSet)      // ✅ setzt session + hängt an optional array korrekt an
            context.insert(newSet)      // kann bleiben (ist ok)
        }

        try? context.save()

            // Haptic Feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

            // Callback ausführen (Live Activity updaten etc.)
        onComplete()
    }
}

    // MARK: - Array Helper

private extension Array {
        /// Gibt das Element am Index zurück, oder nil wenn der Index außerhalb liegt
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
