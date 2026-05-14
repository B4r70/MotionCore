//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Basisdarstellung                                                 /
// Datei . . . . : BaseView.swift                                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 02.11.2025                                                       /
// Beschreibung  : Hauptdisplay für die App                                         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . :  SummaryView als erster Tab hinzugefügt.                          /
//                 Statistik und Rekorde in einem Tab kombiniert.                   /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct BaseView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var activeSessionManager: ActiveSessionManager
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var didRepair = false

    // Plan-Import Manager (einmalige Instanz, lifetime: App)
    @StateObject private var planImportManager = PlanImportManager()

    //  Default-Tab auf .summary geändert
    @State private var selectedTab: Tab = .summary

    // Workout-Erstellung
    @State private var showingWorkoutPicker = false
    @State private var showingAddCardio = false
    @State private var showingAddOutdoor = false
    @State private var outdoorDraft: OutdoorSession?
    @State private var showingTrainingPlanPicker = false
    @State private var selectedPlanToStart: TrainingPlan?

    // State für aktive Session-Wiederherstellung
    @State private var showActiveWorkout = false
    @State private var restoredStrengthSession: StrengthSession?

    // State für neue StrengthSession aus Trainingsplan
    @State private var newStrengthSession: StrengthSession?

    @State private var draft = CardioSession(
        date: .now,
        duration: 0,
        distance: 0.0,
        calories: 0,
        difficulty: 1,
        heartRate: 0,
        bodyWeight: 0.0,
        intensity: .none,
        trainingProgram: .manual,
        cardioDevice: .none
    )

    // Filter-States für die Toolbar
    @State private var selectedDeviceFilter: CardioDevice = .none
    @State private var selectedTimeFilter: TimeFilter = .all

    // Widget-Snapshot: alle abgeschlossenen Sessions (für Publisher)
    @Query(filter: #Predicate<StrengthSession> { $0.isCompleted }, sort: \StrengthSession.date, order: .reverse)
    private var completedSessionsForWidget: [StrengthSession]

    // MARK: Vorabeinstellungen Farbgebung Tabbar
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        appearance.stackedLayoutAppearance.selected.iconColor = .systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
        ]

        appearance.stackedLayoutAppearance.normal.iconColor = .systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray,
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    //  Tab-Enum angepasst (5 Tabs: summary, workouts, stats, body, training)
    enum Tab: Hashable {
        case summary, workouts, stats, body, training
    }

    var body: some View {
        ZStack(alignment: .top) {
        TabView(selection: $selectedTab) {

            // MARK: Tab 1 - Summary (NEU)
            NavigationStack {
                SummaryView(onStartWorkoutTap: { showingWorkoutPicker = true })
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            HeaderView(
                                title: "MotionCore",
                                subtitle: "Übersicht"
                            )
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            NavigationLink {
                                MainSettingsView()
                            } label: {
                                ToolbarButton(icon: .system("gearshape"))
                            }
                        }
                    }
            }
            .tabItem {
                Label("Übersicht", systemImage: "square.grid.2x2")
            }
            .tag(Tab.summary)

            // MARK: Tab 2 - Workouts
            NavigationStack {
                ListViewWrapper(
                    selectedDeviceFilter: $selectedDeviceFilter,
                    selectedTimeFilter: $selectedTimeFilter
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        FilterSection(selectedTimeFilter: $selectedTimeFilter)
                    }

                    ToolbarItem(placement: .principal) {
                        HeaderView(
                            title: "MotionCore",
                            subtitle: "Workouts"
                        )
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            MainSettingsView()
                        } label: {
                            ToolbarButton(icon: .system("gearshape"))
                        }
                    }
                }
                .floatingActionButton(
                    icon: .system("plus"),
                    color: .primary
                ) {
                    showingWorkoutPicker = true
                }
            }
            .tabItem {
                Label("Workouts", systemImage: "figure.run")
            }
            .tag(Tab.workouts)

            // MARK: Tab 3 - Statistiken & Rekorde ( Kombiniert)
            NavigationStack {
                StatsAndRecordsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            HeaderView(
                                title: "MotionCore",
                                subtitle: "Statistik"
                            )
                        }
                    }
            }
            .tabItem {
                Label("Statistik", systemImage: "chart.bar.fill")
            }
            .tag(Tab.stats)

            // MARK: Tab 4 - Body
            NavigationStack {
                BodyView(onStartWorkoutTap: { showingWorkoutPicker = true })
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            HeaderView(
                                title: "MotionCore",
                                subtitle: "Body"
                            )
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            NavigationLink {
                                MainSettingsView()
                            } label: {
                                ToolbarButton(icon: .system("gearshape"))
                            }
                        }
                    }
            }
            .tabItem {
                Label("Body", systemImage: "figure.arms.open")
            }
            .tag(Tab.body)

            // MARK: Tab 5 - Trainingsplan
            NavigationStack {
                TrainingListView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            HeaderView(
                                title: "MotionCore",
                                subtitle: "Training"
                            )
                        }
                    }
            }
            .tabItem {
                Label("Training", systemImage: "figure.run.square.stack.fill")
            }
            .tag(Tab.training)
        }
        // MARK: - Sheets

        // Workout-Typ Auswahl
        .sheet(isPresented: $showingWorkoutPicker) {
            NewWorkoutSheet(
                onCardioSelected: {
                    showingWorkoutPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingAddCardio = true
                    }
                },
                onStrengthSelected: {
                    showingWorkoutPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingTrainingPlanPicker = true
                    }
                },
                onOutdoorSelected: {
                    showingWorkoutPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        outdoorDraft = OutdoorSession()
                        showingAddOutdoor = true
                    }
                }
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }

        // Cardio-Formular
        .sheet(isPresented: $showingAddCardio) {
            NavigationStack {
                FormView(mode: .add, workout: draft)
            }
            .environmentObject(appSettings)
            .onDisappear {
                draft = CardioSession(
                    date: .now,
                    duration: 0,
                    distance: 0.0,
                    calories: 0,
                    difficulty: 1,
                    heartRate: 0,
                    bodyWeight: 0.0,
                    intensity: .none,
                    trainingProgram: .manual,
                    cardioDevice: .none
                )
            }
        }

        // Outdoor-Formular (E-Bike Tour)
        .sheet(isPresented: $showingAddOutdoor) {
            if let draft = outdoorDraft {
                NavigationStack {
                    OutdoorFormView(mode: .add, session: draft)
                }
                .environmentObject(appSettings)
            }
        }
        .onChange(of: showingAddOutdoor) { _, isShowing in
            if !isShowing {
                outdoorDraft = nil
            }
        }

        // Trainingsplan-Auswahl für Strength
        .sheet(isPresented: $showingTrainingPlanPicker) {
            PlanPickerSheet(selectedPlan: $selectedPlanToStart)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }

        // Aktive StrengthSession (neu gestartet oder wiederhergestellt)
        .fullScreenCover(isPresented: $showActiveWorkout) {
            if let session = restoredStrengthSession ?? newStrengthSession {
                NavigationStack {
                    ActiveWorkoutView(session: session)
                }
                .environmentObject(appSettings)
                .environmentObject(activeSessionManager)
            }
        }

        // MARK: - State Observers

        // Wenn ein Plan ausgewählt wurde, Session starten
        .onChange(of: selectedPlanToStart) { oldValue, newValue in
            if let plan = newValue {
                // Kurze Verzögerung damit Sheet-Animation fertig ist
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    startStrengthSession(from: plan)
                    selectedPlanToStart = nil
                }
            }
        }

        // Listener für Session-Wiederherstellung
        .onReceive(NotificationCenter.default.publisher(for: .restoreActiveSession)) { notification in
            handleSessionRestoration(notification)
        }
        .onAppear {
            guard !didRepair else { return }
            didRepair = true

                // Wichtig: leicht verzögert starten, damit SwiftData/CloudKit beim Booten fertig wird
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                repairSnapshotsOnLaunch(context: context)
                // Ausstehende Supabase-Updates nach App-Start syncen
                Task {
                    await SupabaseResyncService.shared.syncPendingChanges(in: context)
                }
                // Widget-Snapshot beim App-Start aktualisieren
                WidgetSnapshotPublisher.publish(allSessions: completedSessionsForWidget)
                // Täglichen Muskel-Erholungs-Snapshot beim initialen Launch hochladen
                triggerDailyMuscleRecoverySnapshotIfNeeded()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await SupabaseResyncService.shared.syncPendingChanges(in: context)
                }
                // Widget-Snapshot beim Foreground-Wechsel aktualisieren
                WidgetSnapshotPublisher.publish(allSessions: completedSessionsForWidget)
                // Täglichen Muskel-Erholungs-Snapshot hochladen (max. 1× pro Tag ab 6 Uhr)
                triggerDailyMuscleRecoverySnapshotIfNeeded()
                // Plan-Import Polling beim Foreground-Wechsel
                Task {
                    await planImportManager.poll(context: context)
                }
            }
        }

        // MARK: - Plan-Import Sheets (item: — niemals isPresented: — Sheet-Race-Gotcha)

        // Preview-Sheet für einzelnen Import
        .sheet(item: $planImportManager.activeImport) { dto in
            PlanImportPreviewSheet(
                dto: dto,
                onAccept: {
                    Task { await planImportManager.acceptImport(dto, context: context) }
                },
                onReject: {
                    Task { await planImportManager.rejectImport(dto) }
                },
                onLater: {
                    planImportManager.laterImport(dto)
                }
            )
        }

        // List-Sheet für ≥2 Imports
        .sheet(item: $planImportManager.listTrigger) { _ in
            PlanImportListSheet()
                .environmentObject(planImportManager)
        }

        // Plan-Import Polling beim App-Start
        .task {
            await planImportManager.poll(context: context)
        }

        // MARK: - Plan-Import Banner (über TabView, Schema-Mismatch-Info)

        if planImportManager.schemaMismatchVisible {
            VStack {
                PlanImportSchemaMismatchBanner(
                    onDismiss: { planImportManager.schemaMismatchVisible = false }
                )
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .zIndex(1)
        }

        } // Ende ZStack
        .environmentObject(planImportManager)
    }

    // MARK: - Muskel-Erholungs-Snapshot

    /// Lädt genau einmal pro Tag (ab 6:00 Uhr) einen Muskel-Erholungs-Snapshot nach Supabase.
    /// UserDefaults-Key wird NUR bei erfolgreichem Upload gesetzt → Retry beim nächsten App-Open.
    private func triggerDailyMuscleRecoverySnapshotIfNeeded() {
        let key = "lastMuscleRecoverySnapshotDate"
        let last = UserDefaults.standard.object(forKey: key) as? Date

        let calendar = Calendar.current
        guard let todaySixAM = calendar.date(
            bySettingHour: 6, minute: 0, second: 0, of: Date()
        ) else { return }

        // Bereits ein Snapshot heute seit 6:00 Uhr vorhanden → überspringen
        if let last, last >= todaySixAM { return }

        Task {
            let descriptor = FetchDescriptor<StrengthSession>(
                predicate: #Predicate { $0.isCompleted }
            )
            let sessions = (try? context.fetch(descriptor)) ?? []
            let analysis = MuscleRecoveryCalcEngine.analyze(sessions: sessions)

            let success = await SupabaseMuscleRecoveryService.shared.uploadSnapshot(
                analysis: analysis,
                triggerSource: "app_open"
            )
            // NUR bei Erfolg setzen — bei Fehler greift der nächste App-Open
            if success {
                UserDefaults.standard.set(Date(), forKey: key)
            }
        }
    }

    // MARK: - Session Wiederherstellung

    private func handleSessionRestoration(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let sessionID = userInfo["sessionID"] as? String,
              let workoutType = userInfo["workoutType"] as? WorkoutType else {
            return
        }

        switch workoutType {
        case .strength:
            restoreStrengthSession(sessionID: sessionID)
        case .cardio:
            restoreCardioSession(sessionID: sessionID)
        case .outdoor:
            restoreOutdoorSession(sessionID: sessionID)
        }
    }

    private func restoreStrengthSession(sessionID: String) {
        let descriptor = FetchDescriptor<StrengthSession>()

        do {
            let sessions = try context.fetch(descriptor)

            if let session = sessions.first(where: {
                $0.sessionUUID.uuidString == sessionID
            }) {
                restoredStrengthSession = session
                newStrengthSession = nil
                showActiveWorkout = true
            } else {
                activeSessionManager.discardSession()
            }
        } catch {
            activeSessionManager.discardSession()
        }
    }

    private func restoreCardioSession(sessionID: String) {
        // TODO: Implementieren wenn CardioSession Live-Tracking unterstützt
    }

    private func restoreOutdoorSession(sessionID: String) {
        // TODO: Implementieren wenn OutdoorSession Live-Tracking unterstützt
    }

    // MARK: - Neue Session starten

    private func startStrengthSession(from plan: TrainingPlan) {
        let session = plan.createSession()

        context.insert(session)
        try? context.save()

        newStrengthSession = session
        restoredStrengthSession = nil
        showActiveWorkout = true
    }

    // MARK: - Snapshot-Heilung beim App-Start
    //
    // Twin-Familie: SupabaseFullBackupService.deduplicateAllSyncUUIDs /
    // .deduplicateExerciseUUIDs dedupliziert UUIDs vor dem Backup-Lauf.
    // Diese Routine hier heilt fehlende/ungültige Snapshots in
    // ExerciseSet beim App-Start.
    private func repairSnapshotsOnLaunch(context: ModelContext) {
        // MARK: - Bestand-Heilung für ExerciseSet.exerciseUUIDSnapshot
        //
        // Konstruktive Reparatur. Twin-Familie in
        // SupabaseFullBackupService.deduplicateAllSyncUUIDs /
        // .deduplicateExerciseUUIDs. Diese hier bleibt in BaseView, weil
        // einmaliger Boot-Zeit-Repair, unabhängig von der Mirror-Pipeline.
        do {
            if context.hasChanges { try context.save() }
            let sets = try context.fetch(FetchDescriptor<ExerciseSet>())
            let allExercises = try context.fetch(FetchDescriptor<Exercise>())

            var healedViaRelation = 0
            var healedViaLookup = 0
            var ambiguous = 0
            var clearedInvalid = 0

            for s in sets {
                let current = s.exerciseUUIDSnapshot
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let currentIsValid = !current.isEmpty
                    && UUID(uuidString: current) != nil

                if currentIsValid { continue }

                // Strategie 1: Relationship vorhanden
                if let ex = s.exercise {
                    s.exerciseUUIDSnapshot = (ex.apiID ?? ex.exerciseUUID).uuidString
                    healedViaRelation += 1
                    continue
                }

                // Strategie 2: Namens-Lookup
                let searchName = s.exerciseNameSnapshot.isEmpty
                    ? s.exerciseName
                    : s.exerciseNameSnapshot
                guard !searchName.isEmpty else {
                    if !current.isEmpty {
                        s.exerciseUUIDSnapshot = ""
                        clearedInvalid += 1
                    }
                    continue
                }

                let matches = allExercises.filter {
                    $0.name == s.exerciseName
                    || $0.name == s.exerciseNameSnapshot
                }

                if matches.count == 1 {
                    let ex = matches[0]
                    s.exercise = ex
                    s.exerciseUUIDSnapshot = (ex.apiID ?? ex.exerciseUUID).uuidString
                    healedViaLookup += 1
                } else if matches.count > 1 {
                    ambiguous += 1
                    print("⚠️ Repair: ambiguous match for \"\(searchName)\" (\(matches.count) candidates) — set \(s.setUUID) not healed")
                } else {
                    if !current.isEmpty {
                        s.exerciseUUIDSnapshot = ""
                        clearedInvalid += 1
                    }
                }
            }

            let total = healedViaRelation + healedViaLookup + clearedInvalid
            if total > 0 || ambiguous > 0 {
                try context.save()
                print("🛠️ Repair: \(healedViaRelation) via relation, \(healedViaLookup) via name-lookup, \(ambiguous) ambiguous, \(clearedInvalid) invalid cleared")
            }
        } catch {
            print("⚠️ Repair failed:", error)
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let restoreActiveSession = Notification.Name("restoreActiveSession")
}

// MARK: Preview
#Preview("Base View") {
    BaseView()
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
        .environmentObject(ActiveSessionManager.shared)
}
