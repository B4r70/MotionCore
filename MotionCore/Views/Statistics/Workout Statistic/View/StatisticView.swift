//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StatisticView.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 11.11.2025                                                       /
// Beschreibung  : Hauptdisplay für den Bereich Statistik                           /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct StatisticView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var allWorkouts: [WorkoutSession]

    private var calcStatistics: StatisticCalcEngine {
        StatisticCalcEngine(workouts: allWorkouts)
    }

    @EnvironmentObject private var appSettings: AppSettings

    // Anzahl der Cards je Zeile im Grid
    private let gridColumns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    LazyVGrid(columns: gridColumns, spacing: 20) {
                            // 2er Grid mit jeweils einer Statistik-Card
                            // Anzahl aller Workouts
                            StatisticGridCard(
                                icon: "figure.run",
                                title: "Gesamt Workouts",
                                valueView: Text("\(calcStatistics.totalWorkouts)"),
                                color: .blue
                            )
                            // Verbrauchte Gesamtkalorien
                            StatisticGridCard(
                                icon: "flame.fill",
                                title: "Gesamt Kalorien",
                                valueView: Text("\(calcStatistics.totalCalories)"),
                                color: .orange
                        )
                            // Trainierte Distanz
                        StatisticGridCard(
                                icon: "arrow.left.and.right",
                                title: "Gesamt Strecke",
                                valueView: Text(String(format: "%.2f km", calcStatistics.totalDistance)),
                                color: .green
                            )
                            // Durchschnittliche Herzfrequenz
                        StatisticGridCard(
                                icon: "heart.fill",
                                title: "⌀ Herzfrequenz",
                                valueView: Text("\(calcStatistics.averageHeartRate)"),
                                color: .red
                            )
                        // Durchschnittles metabolisches Äquivalent
                        StatisticGridCard(
                            icon: "bolt.fill",
                            title: "⌀ METs",
                            valueView: Text(String(format: "%.2f METs", calcStatistics.averageMETS)),
                            color: .yellow
                        )
                        // Durchschnittliche Workout-Dauer
                        StatisticGridCard(
                            icon: "clock.fill",
                            title: "⌀ Dauer",
                            valueView: Text("\(calcStatistics.averageDuration) min"
                            ),
                            color: .indigo
                        )
                    }
                    // Durchschnittliche Belastungsintensität in Sternen
                    StatisticCard(
                        icon: "figure.strengthtraining.traditional",
                        title: "⌀ Belastung",
                        valueView: ShowStarRating(
                            starRating: calcStatistics.averageIntensity,
                            starMaxRating: Intensity.maxRating,
                            starColor: .orange
                        ),
                        color: .black
                    )
                    // Durchschnittliche relative Kaloriendichte zum Körpergewicht
                    StatisticCard(
                        icon: "flame.fill",
                        title: "⌀ Kaloriendichte",
                        valueView: Text(String(format: "%.3f", calcStatistics.averageCaloricDensity)),
                        color: .purple
                    )
                    // Anzahl Trainings je Gerät
                    StatisticDeviceCard(allWorkouts: allWorkouts)

                    // Workouts je Belastungsintensität
                    StatisticIntensityCard(allWorkouts: allWorkouts)

                    // Trend Chart für die Herzfrequenz
                    StatisticTrendChart(
                        title: "Herzfrequenz-Trend",
                        yLabel: "Puls",
                        data: calcStatistics.trendHeartRate
                    )

                    // Trend Chart Kalorien
                    StatisticTrendChart(
                        title: "Kalorien-Trend",
                        yLabel: "kcal",
                        data: calcStatistics.trendCalories
                    )

                    // Trend Chart Distanz auf dem Crosstrainer
                    StatisticTrendChart(
                        title: "Distanz auf dem Crosstrainer",
                        yLabel: "km",
                        data: calcStatistics.trendDistanceDevice(for: .crosstrainer)
                    )
                    // Trend Chart Distanz auf dem Ergometer
                    StatisticTrendChart(
                        title: "Distanz auf dem Ergometer",
                        yLabel: "km",
                        data: calcStatistics.trendDistanceDevice(for: .ergometer)
                    )

                    // Donut für Anzahl Workouts je Programm
                    StatisticDonutChart(
                        title: "Workouts je Trainingsprogramm",
                        data: calcStatistics.programData
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
#Preview("Statistiken") {
    StatisticView()
        .modelContainer(PreviewData.sharedContainer)
}
