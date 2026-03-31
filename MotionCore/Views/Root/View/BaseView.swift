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

    //  Tab-Enum angepasst (5 Tabs: summary, workouts, stats, analyse, training)
    enum Tab: Hashable {
        case summary, workouts, stats, analyse, training
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            // MARK: Tab 1 - Summary (NEU)
            NavigationStack {
                SummaryView()
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

            // MARK: Tab 4 - Progressions-Analyse
            NavigationStack {
                ProgressionAnalyseView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            HeaderView(
                                title: "MotionCore",
                                subtitle: "Analyse"
                            )
                        }
                    }
            }
            .tabItem {
                Label("Analyse", systemImage: "brain.head.profile")
            }
            .tag(Tab.analyse)

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
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await SupabaseResyncService.shared.syncPendingChanges(in: context)
                }
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

    private func repairSnapshotsOnLaunch(context: ModelContext) {
        do {
            // Nur auf cleanem Context arbeiten
            if context.hasChanges {
                try context.save()
            }

            let sets = try context.fetch(FetchDescriptor<ExerciseSet>())

            var changed = 0
            for s in sets {
                let uuid = s.exerciseUUIDSnapshot.trimmingCharacters(in: .whitespacesAndNewlines)
                if !uuid.isEmpty && UUID(uuidString: uuid) == nil {
                    s.exerciseUUIDSnapshot = ""
                    changed += 1
                }
            }

            if changed > 0 {
                try context.save()
                print("🧹 Repair: cleaned \(changed) invalid exerciseUUIDSnapshot values")
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
