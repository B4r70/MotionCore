//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
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
        let genderMetrics = GenderSymbolView(gender: userGender).iconMetrics

        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    // Hero Card für Kalorienbilanz (nur wenn HealthKit-Daten verfügbar)
                    if let consumed = healthKitManager.dietaryConsumedCalories,
                       let basal = healthKitManager.basalBurnedCalories,
                       let active = healthKitManager.activeBurnedCalories {
                        // Berechnung in CalcEngine
                        let balance = calcHealthMetrics.calculateCalorieBalance(
                            consumed: consumed,
                            basal: basal,
                            active: active
                        )

                        HealthMetricHeroCard(
                            date: Date(),
                            calorieBalance: balance
                        )
                        .padding(.top, 10)
                    }
                    LazyVGrid(columns: gridColumns, spacing: 20) {

                        // Anzahl aller Workouts
                        HealthMetricGridCard(
                            icon: "figure.wave",
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
                                icon: "figure",
                                title: "Körpergewicht",
                                valueView: Text(String(format: "%.1f kg", calcHealthMetrics.userBodyWeight ?? 0.0)),
                                color: .gray
                        )
                        // Geschlecht des Benutzers
                        HealthMetricGridCard(
                            icon: genderMetrics.name,
                            title: "Geschlecht",
                            valueView: Text(userGender.description), // Nutzt die description Eigenschaft der Enum
                            color: genderMetrics.color
                        )

                        // Alter des Benutzers
                        HealthMetricGridCard(
                            icon: "flame.fill", // Beispiel-Icon
                            title: "Alter",
                            valueView: Text(String(format: "%d Jahre", appSettings.userAge)),
                            color: .red // Kann nach Belieben angepasst werden
                        )

                        // Letzte Herzfrequenz (aus HealthKit)
                        HealthMetricGridCard(
                            icon: "heart.fill",
                            title: "Aktuelle Herzfrequenz",
                            valueView: Text(
                                healthKitManager.latestHeartRate.map { String(format: "%.0f bpm", $0) } ?? "-"
                            ),
                            color: .red
                        )
                        // Eingenommene Kalorien
                        HealthMetricGridCard(
                            icon: "fork.knife",
                            title: "Eingenommene Kalorien",
                            valueView: Text(
                                healthKitManager.dietaryConsumedCalories.map {
                                    String(format: "%d kcal", $0)
                                } ?? "-"
                            ),
                            color: .green
                        )
                    }

                    // Kalorien-Fortschritt vs. Kalorienumsatz
                    HealthMetricProgressCard(
                        icon: "flame.fill",
                        title: "Aktive Kalorien / Tagesziel",
                        currentValue: Double(healthKitManager.activeBurnedCalories ?? 0),
                        targetValue: Double(appSettings.dailyActiveCalorieGoal),
                        unit: "kcal",
                        color: .orange,
                        showPercentage: true
                    )

                    // Schritte-Fortschritt
                    HealthMetricProgressCard(
                        icon: "shoeprints.fill",
                        title: "Schritte / Tagesziel",
                        currentValue: Double(healthKitManager.latestStepCount ?? 0),
                        targetValue: Double(appSettings.dailyStepsGoal),
                        unit: "Schritte",
                        color: .black,
                        showPercentage: true
                    )

                    // Gesamtumsatz Kalorien Card
                    HealthMetricCard(
                        icon: "flame.fill",
                        title: "Grundumsatz (BMR)",
                        valueView: Text(
                            healthKitManager.basalBurnedCalories.map { "\($0) kcal" } ?? "-"
                        ),
                        color: .green
                    )

                    // Body-Mass-Index (BMI)
                    HealthMetricCard(
                        icon: "figure", 
                        title: "Body-Mass-Index (BMI)",
                        valueView: Text(
                            String(format: "%.2f", calcHealthMetrics.userBodyMassIndex ?? 0.0)
                        ),
                        color: .blue // Kann nach Belieben angepasst werden
                    )
                    // BMR Card
                    HealthMetricCard(
                        icon: "flame.fill",
                        title: "Grundumsatz (BMR)",
                        valueView: Text(
                            String(format: "%.0f kcal/Tag", calcHealthMetrics.userCalorieMetabolicRate ?? 0.0)
                        ),
                        color: .red
                    )
                        // Hier kannst du später weitere Cards hinzufügen
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 100)
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
