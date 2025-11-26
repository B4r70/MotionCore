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
                            // 2er Grid mit jeweils einer Statistik-Card
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
                            // Verbrauchte Gesamtkalorien
                        HealthMetricGridCard(
                                icon: "figure",
                                title: "Körpergewicht",
                                valueView: Text(String(format: "%.1f kg", calcHealthMetrics.userBodyWeight ?? 0.0)),
                                color: .gray
                        )
                        // Gender
                        HealthMetricGridCard(
                            icon: genderMetrics.name,
                            title: "Geschlecht",
                            valueView: Text(userGender.description), // Nutzt die description Eigenschaft der Enum
                            color: genderMetrics.color
                        )

                        // NEU: HealthMetricGridCard für den Grundumsatz (BMR)
                        HealthMetricGridCard(
                            icon: "flame.fill", // Beispiel-Icon
                            title: "Alter",
                            valueView: Text(String(format: "%d Jahre", calcHealthMetrics.userAge)),
                            color: .red // Kann nach Belieben angepasst werden
                        )
                    }
                        // HealthMetricGridCard für den Grundumsatz (BMR)
                    HealthMetricCard(
                        icon: "flame.fill", // Beispiel-Icon
                        title: "Grundumsatz (BMR)",
                        valueView: Text(
                            String(format: "%.0f kcal/Tag", calcHealthMetrics.userCalorieMetabolicRate ?? 0.0)
                        ),
                        color: .red // Kann nach Belieben angepasst werden
                    )
                        // HealthMetricGridCard für den Grundumsatz (BMR)
                    HealthMetricCard(
                        icon: "figure", // Beispiel-Icon
                        title: "Body-Mass-Index (BMI)",
                        valueView: Text(
                            String(format: "%.2f", calcHealthMetrics.userBodyMassIndex ?? 0.0)
                        ),
                        color: .blue // Kann nach Belieben angepasst werden
                    )
                        // Hier kannst du später weitere Cards hinzufügen
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)

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
