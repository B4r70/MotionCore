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
    private var workouts: [WorkoutSession]

    @ObservedObject private var settings = AppSettings.shared

    // Anzahl der Cards je Zeile im Grid
    private let gridColumns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    // Berechnung: Gesamtzahl Workouts
    private var totalWorkouts: Int {
        workouts.count
    }

    // Berechnung: Gesamtzahl Kalorien
    private var totalCalories: Int {
        workouts.reduce(0) { $0 + $1.calories }
    }

    // Berechnung: Gesamtzahl Distanz
    private var totalDistance: Double {
        workouts.reduce(0.0) { $0 + $1.distance }
    }

    // Durchschnittliche Herzfrequenz
    private var averageHeartRate: Int {
        guard !workouts.isEmpty else { return 0 }
        let total = workouts.reduce(0) { $0 + $1.heartRate }
        return total / workouts.count
    }

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
                                value: "\(totalWorkouts)",
                                color: .blue
                            )
                            // Verbrauchte Gesamtkalorien
                            StatisticCardDoubleGrid(
                                icon: "flame.fill",
                                title: "Gesamt Kalorien",
                                value: "\(totalCalories)",
                                color: .orange
                        )
                            // Trainierte Distanz
                        StatisticCardDoubleGrid(
                                icon: "arrow.left.and.right",
                                title: "Gesamt Strecke",
                                value: "\(totalDistance)",
                                color: .green
                            )
                            // Durchschnittliche Herzfrequenz
                        StatisticCardDoubleGrid(
                                icon: "heart.fill",
                                title: "⌀ Herzfrequenz",
                                value: "\(averageHeartRate)",
                                color: .red
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                    // Anzahl Trainings je Gerät
                    StatisticDeviceCard(workouts: workouts)
                        .padding(.horizontal)
                        .padding(.top, 5)

                    // Workouts je Belastungsintensität
                    StatisticIntensityCard(workouts: workouts)
                        .padding(.horizontal)
                        .padding(.top, 5)
                    // Hier kannst du später weitere Cards hinzufügen
                }
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)

            // Empty State
            if workouts.isEmpty {
                EmptyState()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StatisticView()
    }
}
