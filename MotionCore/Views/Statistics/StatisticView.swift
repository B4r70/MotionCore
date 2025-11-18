// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : StatisticView.swift                                              /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 11.11.2025                                                       /
// Function . . : Statistik-Übersicht                                              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
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
    
    @ObservedObject private var settings = AppSettings.shared

    // Anzahl der Cards je Zeile im Grid
    private let gridColumns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: settings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    LazyVGrid(columns: gridColumns) {
                            // Eine einzelne Statistik-Card
                            StatisticCardDoubleGrid(
                                icon: "figure.run",
                                title: "Gesamt Workouts",
                                value: "\(calcStatistics.totalWorkouts)",
                                color: .blue
                            )
                            // Verbrauchte Gesamtkalorien
                            StatisticCardDoubleGrid(
                                icon: "flame.fill",
                                title: "Gesamt Kalorien",
                                value: "\(calcStatistics.totalCalories)",
                                color: .orange
                        )
                            // Trainierte Distanz
                        StatisticCardDoubleGrid(
                                icon: "arrow.left.and.right",
                                title: "Gesamt Strecke",
                                value: "\(calcStatistics.totalDistance)",
                                color: .green
                            )
                            // Durchschnittliche Herzfrequenz
                        StatisticCardDoubleGrid(
                                icon: "heart.fill",
                                title: "⌀ Herzfrequenz",
                                value: "\(calcStatistics.averageHeartRate)",
                                color: .red
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                    // Anzahl Trainings je Gerät
                    StatisticDeviceCard(allWorkouts: allWorkouts)
                        .padding(.horizontal)
                        .padding(.top, 5)

                    // Workouts je Belastungsintensität
                    StatisticIntensityCard(allWorkouts: allWorkouts)
                        .padding(.horizontal)
                        .padding(.top, 5)

                    // Trend Chart für die Herzfrequenz
                    StatisticTrendChart(
                        title: "Herzfrequenz-Trend",
                        yLabel: "Puls",
                        data: calcStatistics.trendHeartRate
                    )
                    .padding(.horizontal)
                    .padding(.top, 5)

                    // Trend Chart Kalorien
                    StatisticTrendChart(
                        title: "Kalorien-Trend",
                        yLabel: "kcal",
                        data: calcStatistics.trendCalories
                    )
                    .padding(.horizontal)
                    .padding(.top, 5)

                    // Trend Chart Distanz
                    StatisticTrendChart(
                        title: "Distanz-Trend",
                        yLabel: "km",
                        data: calcStatistics.trendDistance
                    )
                    .padding(.horizontal)
                    .padding(.top, 5)
                    
                    // Hier kannst du später weitere Cards hinzufügen
                }
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
