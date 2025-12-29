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

    @State private var selectedTab: Tab = .workouts
    @State private var showingAddWorkout = false

    @State private var draft = CardioSession(    // Bleibt!
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

    //Filter-States für die Toolbar
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
                    // ListView bekommt Bindings übergeben
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
    }
}

    // MARK: Preview
#Preview("Base View") {
    BaseView()
        .modelContainer(PreviewData.sharedContainer)
}
