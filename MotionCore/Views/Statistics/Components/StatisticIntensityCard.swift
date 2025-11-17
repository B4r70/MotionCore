// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Section  . . : Statistik                                                         /
// Filename . . : StatisticIntensityCard.swift                                      /
// Author . . . : Bartosz Stryjewski                                                /
// Created on . : 16.11.2025                                                        /
// Function . . : Belastungsintensität Card (je Stern die Anzahl der Workouts       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct StatisticIntensityCard: View {
    let allWorkouts: [WorkoutSession]

    // MARK: Aufruf der Berechnungen für Statistiken
    private var calcStatistics: StatisticCalcEngine {
        StatisticCalcEngine(workouts: allWorkouts)
    }

    private let intensities: [Intensity] = [
        .veryEasy, .easy, .medium, .hard, .veryHard
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workouts je Belastungsintensität")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(intensities, id: \.self) { intensity in
                    let summary = calcStatistics.intensitySummary(for: intensity)
                    StatisticIntensityRow(summary: summary)
                }
            }
        }
        .glassCardStyle()
    }
}

#Preview {
    StatisticIntensityCard(allWorkouts: [])
}
