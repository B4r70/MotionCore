//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StatisticIntensityCard.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 16.11.2025                                                       /
// Beschreibung  : Darstellung von Cards mit Workouts je Belastungsintensität       /
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
        .glassCard()
    }
}

#Preview {
    StatisticIntensityCard(allWorkouts: [])
}
