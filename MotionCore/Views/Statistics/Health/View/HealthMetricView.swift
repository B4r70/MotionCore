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
    @Query(sort: \CardioSession.date, order: .reverse)
    private var allWorkouts: [CardioSession]

    @StateObject private var healthManager = HealthKitManager.shared

        // Lesen der globalen Einstellungen für Userdefaults
    @EnvironmentObject private var appSettings: AppSettings

    private var calcHealthMetrics: HealthMetricCalcEngine {
        HealthMetricCalcEngine(
            workouts: allWorkouts,
            birthday: appSettings.userBirthdayDate,
            age: appSettings.userAge,
            gender: appSettings.userGender,
            bodyHeight: appSettings.userBodyHeight,
            activityLevel: appSettings.userActivityLevel
        )
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
                            color: Theme.accent
                        )

                            // Körpergewicht des Benutzers
                        HealthMetricGridCard(
                            icon: .system("figure"),
                            title: "Körpergewicht",
                            valueView: Text(String(format: "%.1f kg", calcHealthMetrics.userBodyWeight ?? 0.0)),
                            color: Theme.textTertiary
                        )
                            // Geschlecht des Benutzers
                        HealthMetricGridCard(
                            icon: genderMetrics.gender.icon,
                            title: "Geschlecht",
                            valueView: Text(userGender.description), // Nutzt die description Eigenschaft der Enum
                            color: genderMetrics.gender.color
                        )

                            // Alter des Benutzers
                        HealthMetricGridCard(
                            icon: .system("flame.fill"), // Beispiel-Icon
                            title: "Alter",
                            valueView: Text(String(format: "%d Jahre", appSettings.userAge)),
                            color: Theme.danger
                        )

                            // Letzte Herzfrequenz (aus HealthKit)
                        HealthMetricGridCard(
                            icon: .system("heart.fill"),
                            title: "Aktuelle Herzfrequenz",
                            valueView: Text(
                                healthKitManager.latestHeartRate.map { String(format: "%.0f bpm", $0) } ?? "-"
                            ),
                            color: Theme.danger
                        )
                            // Body-Mass-Index (BMI)
                        HealthMetricGridCard(
                            icon: .system("figure"),
                            title: "Body-Mass-Index (BMI)",
                            valueView: Text(
                                String(format: "%.2f", calcHealthMetrics.userBodyMassIndex ?? 0.0)
                            ),
                            color: Theme.series[0]
                        )
                    }
                        // Kalorienbilanz als Übersicht
                    if let balance = calcHealthMetrics.calculateTodayCalorieBalance(
                        consumed: healthKitManager.dietaryConsumedCalories,
                        basal: healthKitManager.basalBurnedCalories,
                        active: healthKitManager.activeBurnedCalories
                    ) {
                        HealthMetricHeroCard(
                            date: Date(),
                            calorieBalance: balance
                        )
                        .padding(.top, 10)
                    }
                    //Schlafzusammenfassung
                    if let summary = healthManager.todaySleepSummary {
                        HealthMetricSleepHeroCard(sleepSummary: summary)
                    } else {
                            // Optional: Placeholder
                        Text("Keine Schlafdaten verfügbar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                        // Kalorien-Fortschritt vs. Kalorienumsatz
                    HealthMetricProgressCard(
                        icon: .system("flame.fill"),
                        title: "Aktive Kalorien / Tagesziel",
                        currentValue: Double(healthKitManager.activeBurnedCalories ?? 0),
                        targetValue: Double(appSettings.dailyActiveCalorieGoal),
                        unit: "kcal",
                        color: Theme.warning,
                        showPercentage: true
                    )

                        // Schritte-Fortschritt
                    HealthMetricProgressCard(
                        icon: .system("shoeprints.fill"),
                        title: "Schritte / Tagesziel",
                        currentValue: Double(healthKitManager.latestStepCount ?? 0),
                        targetValue: Double(appSettings.dailyStepsGoal),
                        unit: "Schritte",
                        color: Theme.series[1],
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
                        await healthManager.fetchTodaySleepSummary()
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
                await healthManager.fetchTodaySleepSummary()
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
