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
//
import SwiftData
import SwiftUI

struct BaseView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @EnvironmentObject private var activeSessionManager: ActiveSessionManager // NEU
    @Environment(\.modelContext) private var context // NEU

    @State private var selectedTab: Tab = .workouts
    @State private var showingAddWorkout = false

    // NEU: State für aktive Session-Wiederherstellung
    @State private var showActiveWorkout = false
    @State private var restoredStrengthSession: StrengthSession?

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

    enum Tab: Hashable {
        case workouts, statistics, health, records, training
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            // MARK: Tab 1 - Workouts
            NavigationStack {
                ListViewWrapper(
                    selectedDeviceFilter: $selectedDeviceFilter,
                    selectedTimeFilter: $selectedTimeFilter
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // MARK: Aufbau des App-Headers
                    // Links oben - Filter-Button
                    ToolbarItem(placement: .topBarLeading) {
                        FilterSection(
                            selectedDeviceFilter: $selectedDeviceFilter,
                            selectedTimeFilter: $selectedTimeFilter
                        )
                    }

                    // Mitte: HeaderView
                    ToolbarItem(placement: .principal) {
                        HeaderView(
                            title: "MotionCore",
                            subtitle: "Workouts"
                        )
                    }

                    // Rechts oben - Einstellungsbutton
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
                    showingAddWorkout = true
                }
            }
            .tabItem {
                Label("Workouts", systemImage: "figure.run")
            }
            .tag(Tab.workouts)

            // MARK: Tab 2 - Statistiken

            NavigationStack {
                StatisticView()
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
                Label("Statistiken", systemImage: "chart.bar.fill")
            }
            .tag(Tab.statistics)

            // MARK: Tab 3 - Gesundheitsdaten

            NavigationStack {
                HealthMetricView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            HeaderView(
                                title: "MotionCore",
                                subtitle: "Gesundheitsdaten"
                            )
                        }
                    }
            }
            .tabItem {
                Label("Health", systemImage: "bolt.heart")
            }
            .tag(Tab.health)

            // MARK: Tab 4 - Rekorde

            NavigationStack {
                RecordView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            HeaderView(
                                title: "MotionCore",
                                subtitle: "Rekorde"
                            )
                        }
                    }
            }
            .tabItem {
                Label("Rekorde", systemImage: "trophy.fill")
            }
            .tag(Tab.records)

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
        .sheet(isPresented: $showingAddWorkout) {
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
        // NEU: FullScreenCover für wiederhergestellte aktive Session
        .fullScreenCover(isPresented: $showActiveWorkout) {
            if let session = restoredStrengthSession {
                NavigationStack {
                    ActiveWorkoutView(session: session)
                }
                .environmentObject(appSettings)
                .environmentObject(activeSessionManager)
            }
        }
        // NEU: Listener für Session-Wiederherstellung
        .onReceive(NotificationCenter.default.publisher(for: .restoreActiveSession)) { notification in
            handleSessionRestoration(notification)
        }
    }

    // MARK: - Session Wiederherstellung

    // Behandelt die Wiederherstellung einer aktiven Session
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

    // Stellt eine StrengthSession wieder her und öffnet die ActiveWorkoutView
    private func restoreStrengthSession(sessionID: String) {
        let descriptor = FetchDescriptor<StrengthSession>()

        do {
            let sessions = try context.fetch(descriptor)

            // Session anhand der sessionUUID finden
            if let session = sessions.first(where: {
                $0.sessionUUID.uuidString == sessionID
            }) {
                restoredStrengthSession = session
                showActiveWorkout = true
            } else {
                // Session nicht gefunden - State zurücksetzen
                activeSessionManager.discardSession()
            }
        } catch {
            activeSessionManager.discardSession()
        }
    }

    // Stellt eine CardioSession wieder her (TODO: Implementierung)
    private func restoreCardioSession(sessionID: String) {
        // TODO: Implementieren wenn CardioSession Live-Tracking unterstützt
        print("BaseView: CardioSession-Wiederherstellung noch nicht implementiert")
    }

    // Stellt eine OutdoorSession wieder her (TODO: Implementierung)
    private func restoreOutdoorSession(sessionID: String) {
        // TODO: Implementieren wenn OutdoorSession Live-Tracking unterstützt
        print("BaseView: OutdoorSession-Wiederherstellung noch nicht implementiert")
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    // Notification um eine aktive Session wiederherzustellen
    static let restoreActiveSession = Notification.Name("restoreActiveSession")
}

// MARK: Preview
#Preview("Base View") {
    BaseView()
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
        .environmentObject(ActiveSessionManager.shared)
}
