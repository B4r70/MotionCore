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

    private var calcHealthMetrics: HealthMetricCalcEngine {
        HealthMetricCalcEngine(workouts: allWorkouts)
    }

    // Lesen der Einstellungen für Userdefaults
    @ObservedObject private var appSettings = AppSettings.shared
    // Lesen der HealthKit-Daten
    @ObservedObject private var healthKitManager = HealthKitManager.shared

    // Anzahl der Cards je Zeile im Grid
    private let gridColumns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {

        let userGender = calcHealthMetrics.userGender
        let genderMetrics = GenderSymbolView(gender: userGender).iconMetrics

        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    LazyVGrid(columns: gridColumns, spacing: 20) {

                        // Anzahl aller Workouts
                        HealthMetricGridCard(
                            icon: "figure.wave",
                            title: "Körpergröße",
                            valueView: Text(
                                String(
                                    format: "%.2f m",
                                    Double(calcHealthMetrics.userBodyHeight) / 100.0
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
                            valueView: Text(String(format: "%d Jahre", calcHealthMetrics.userAge)),
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
                    }
                }
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
