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
    @State private var selectedTab: Tab = .workouts
    @State private var showingAddWorkout = false
    @State private var previousTab: Tab = .workouts

    @State private var draft = WorkoutSession(
        date: .now,
        duration: 0,
        distance: 0.0,
        calories: 0,
        difficulty: 1,
        heartRate: 0,
        bodyWeight: 0,
        intensity: .none,
        trainingProgram: .manual,
        workoutDevice: .none
    )

    // MARK: Vorabeinstellungen Farbgebung Tabbar

    init() {
        // Tab Bar Appearance konfigurieren
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        // Farbe für ausgewählten Tab
        appearance.stackedLayoutAppearance.selected.iconColor = .systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
        ]

        // Farbe für nicht-ausgewählte Tabs
        appearance.stackedLayoutAppearance.normal.iconColor = .systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray,
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    enum Tab: Hashable {
        case workouts, statistics, add, records, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: Tab 1 - Workouts

            NavigationStack {
                ListView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            HeaderView(
                                title: "MotionCore",
                                subtitle: "Workouts"
                            )
                        }
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

            // MARK: Tab 3 - Neues Workout

            Color.clear
                .tabItem {
                    Label("Neu", systemImage: "plus.diamond.fill")
                }
                .tag(Tab.add)

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

            // MARK: Tab 5 - Einstellungen

            NavigationStack {
                MainSettingsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            HeaderView(
                                title: "MotionCore",
                                subtitle: "Einstellungen"
                            )
                        }
                    }
            }
            .tabItem {
                Label("Mehr", systemImage: "gearshape.fill")
            }
            .tag(Tab.settings)
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .add {
                showingAddWorkout = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTab = previousTab
                }
            } else {
                previousTab = newValue
            }
        }
        .sheet(isPresented: $showingAddWorkout) {
            NavigationStack {
                FormView(mode: .add, workout: draft)
            }
            .onDisappear {
                draft = WorkoutSession(
                    date: .now,
                    duration: 0,
                    distance: 0.0,
                    calories: 0,
                    difficulty: 1,
                    heartRate: 0,
                    bodyWeight: 0,
                    intensity: .none,
                    trainingProgram: .manual,
                    workoutDevice: .none
                )
            }
        }
    }
}
    // MARK: Statistic Preview
#Preview("Base View") {
    BaseView()
        .modelContainer(PreviewData.sharedContainer)
}
