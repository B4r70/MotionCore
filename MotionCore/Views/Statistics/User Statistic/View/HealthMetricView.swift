//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Gesundheitsmetriken                                              /
// Datei . . . . : HealthMetricView.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 23.11.2025                                                       /
// Beschreibung  : Hauptdisplay für die benutzerspezifischen Gesundheitsdaten       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct HealthMetricView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var allWorkouts: [WorkoutSession]

    // Lesen der globalen Einstellungen für Userdefaults
    @EnvironmentObject private var appSettings: AppSettings

    private var calcHealthMetrics: HealthMetricCalcEngine {
        HealthMetricCalcEngine(workouts: allWorkouts, settings: appSettings)
    }

    // Lesen der HealthKit-Daten
    @ObservedObject private var healthKitManager = HealthKitManager.shared

    // Anzahl der Cards je Zeile im Grid
    private let gridColumns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {

        let userGender = appSettings.userGender
        let genderMetrics = GenderIconView(gender: userGender)

        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    LazyVGrid(columns: gridColumns, spacing: 20) {

                        // Anzahl aller Workouts
                        HealthMetricGridCard(
                            icon: .system("figure.wave"),
                            title: "Körpergröße",
                            valueView: Text(
                                String(
                                    format: "%.2f m",
                                    Double(appSettings.userBodyHeight) / 100.0
                                )
                            ),
                            color: .indigo
                        )

                        // Körpergewicht des Benutzers
                        HealthMetricGridCard(
                            icon: .system("figure"),
                                title: "Körpergewicht",
                                valueView: Text(String(format: "%.1f kg", calcHealthMetrics.userBodyWeight ?? 0.0)),
                                color: .gray
                        )
                        // Geschlecht des Benutzers
                        HealthMetricGridCard(
                            icon: .asset(genderMetrics.gender.icon),
                            title: "Geschlecht",
                            valueView: Text(userGender.description), // Nutzt die description Eigenschaft der Enum
                            color: genderMetrics.gender.color
                        )

                        // Alter des Benutzers
                        HealthMetricGridCard(
                            icon: .system("flame.fill"), // Beispiel-Icon
                            title: "Alter",
                            valueView: Text(String(format: "%d Jahre", appSettings.userAge)),
                            color: .red // Kann nach Belieben angepasst werden
                        )

                        // Letzte Herzfrequenz (aus HealthKit)
                        HealthMetricGridCard(
                            icon: .system("heart.fill"),
                            title: "Aktuelle Herzfrequenz",
                            valueView: Text(
                                healthKitManager.latestHeartRate.map { String(format: "%.0f bpm", $0) } ?? "-"
                            ),
                            color: .red
                        )
                        // Body-Mass-Index (BMI)
                        HealthMetricGridCard(
                            icon: .system("figure"),
                            title: "Body-Mass-Index (BMI)",
                            valueView: Text(
                                String(format: "%.2f", calcHealthMetrics.userBodyMassIndex ?? 0.0)
                            ),
                            color: .blue // Kann nach Belieben angepasst werden
                        )
                    }
                    // Kalorienbilanz als Übersicht
                    if let balance = calcHealthMetrics.calculateTodayCalorieBalance(from: healthKitManager) {
                        HealthMetricHeroCard(
                            date: Date(),
                            calorieBalance: balance
                        )
                        .padding(.top, 10)
                    }

                    // Kalorien-Fortschritt vs. Kalorienumsatz
                    HealthMetricProgressCard(
                        icon: .system("flame.fill"),
                        title: "Aktive Kalorien / Tagesziel",
                        currentValue: Double(healthKitManager.activeBurnedCalories ?? 0),
                        targetValue: Double(appSettings.dailyActiveCalorieGoal),
                        unit: "kcal",
                        color: .orange,
                        showPercentage: true
                    )

                    // Schritte-Fortschritt
                    HealthMetricProgressCard(
                        icon: .system("shoeprints.fill"),
                        title: "Schritte / Tagesziel",
                        currentValue: Double(healthKitManager.latestStepCount ?? 0),
                        targetValue: Double(appSettings.dailyStepsGoal),
                        unit: "Schritte",
                        color: .cyan,
                        showPercentage: true
                    )
                        // Hier kannst du später weitere Cards hinzufügen
                }
                .scrollViewContentPadding() // Einheitlicher Abstand
            }
            .scrollIndicators(.hidden)
            // Berechtigungsanfrage für HealthKit
            .onAppear {
                Task {
                    let authorized = await healthKitManager.requestAuthorization()
                    if authorized {
                        await healthKitManager.fetchLatestHeartRate()
                        await healthKitManager.fetchTodayStepCount()
                        await healthKitManager.fetchTodayBurnedCalories()
                        await healthKitManager.fetchTodayConsumedCalories()
                        await healthKitManager.fetchTodayBasalBurnedCalories()
                    }
                }
            }
            // Aktualisierung der Daten aus HealthKit
            .refreshable {
                await healthKitManager.fetchLatestHeartRate()
                await healthKitManager.fetchTodayStepCount()
                await healthKitManager.fetchTodayBurnedCalories()
                await healthKitManager.fetchTodayConsumedCalories()
                await healthKitManager.fetchTodayBasalBurnedCalories()
            }

            // Empty State
            if allWorkouts.isEmpty {
                EmptyState()
            }
        }
    }
}

// MARK: Statistic Preview
#Preview("HealthMetric") {
    HealthMetricView()
        .modelContainer(PreviewData.sharedContainer)
}
