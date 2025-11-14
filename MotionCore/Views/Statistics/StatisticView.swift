//---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : StatisticView.swift                                              /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 11.11.2025                                                       /
// Function . . : Statistik-Übersicht                                              /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

struct StatisticView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var workouts: [WorkoutSession]

    @ObservedObject private var settings = AppSettings.shared

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

    // Berechnung der Workouts je Gerät
    private func workoutsPerDevice(for device: WorkoutDevice) -> Int {
        workouts.filter{ $0.workoutDevice == device}.count
    }

    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: settings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    // Eine einzelne Statistik-Card
                    StatisticCard(
                        icon: "figure.run",
                        title: "Gesamt Workouts",
                        value: "\(totalWorkouts)",
                        color: .blue
                    )
                    .padding(.horizontal)
                    .padding(.top, 5)
                     // Verbrauchte Gesamtkalorien
                    StatisticCard(
                            icon: "flame.fill",
                            title: "Gesamt Kalorien",
                            value: "\(totalCalories)",
                            color: .orange
                        )
                        .padding(.horizontal)
                        .padding(.top, 5)
                    // Trainierte Distanz
                    StatisticCard(
                            icon: "arrow.left.and.right",
                            title: "Gesamt Strecke",
                            value: "\(totalDistance)",
                            color: .green
                        )
                        .padding(.horizontal)
                        .padding(.top, 5)
                    // Anzahl Trainings je Gerät
                    DeviceStatisticsRow(
                        device: .crosstrainer,
                        count: workoutsPerDevice(for: .crosstrainer),
                        total: totalWorkouts
                    )
                    .padding(.horizontal)
                    .padding(.top, 5)
                    // Anzahl Trainings je Gerät
                    DeviceStatisticsRow(
                        device: .ergometer,
                        count: workoutsPerDevice(for: .ergometer),
                        total: totalWorkouts
                    )
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
