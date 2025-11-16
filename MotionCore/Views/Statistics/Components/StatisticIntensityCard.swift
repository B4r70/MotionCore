// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : StatisticIntensityCard.swift                                     /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 16.11.2025                                                       /
// Function . . : Belastungsintensität Card (je Stern die Anzahl der Workouts      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct StatisticIntensityCard: View {
    let workouts: [WorkoutSession]

    // Gesamtzahl Workouts (für Prozent/Verteilung)
    private var totalWorkouts: Int {
        workouts.count
    }

    // Berechnung der Workouts je Belastungsintensität
    private func intensityCount(_ intensity: Intensity) -> Int {
        workouts.filter { $0.intensity == intensity }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workouts je Belastungsintensität")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(
                    [Intensity.veryEasy, .easy, .medium, .hard, .veryHard],
                    id: \.self
                ) { intensity in
                    StatisticIntensityRow(
                        intensity: intensity,
                        count: intensityCount(intensity),
                        total: totalWorkouts
                    )
                }
            }
        }
        // GlassCard Style zentral für alle Cards
        .glassCardStyle()
    }
}

#Preview {
    // Leere Preview ist okay – zeigt einfach 0-Werte
    StatisticIntensityCard(workouts: [])
}
