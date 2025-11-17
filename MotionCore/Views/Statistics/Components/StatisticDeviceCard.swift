// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Section  . . : Statistik                                                         /
// Filename . . : StatisticDeviceCard.swift                                         /
// Author . . . : Bartosz Stryjewski                                                /
// Created on . : 11.11.2025                                                        /
// Function . . : Statistik Card Ansicht mit diversen Werten                        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct StatisticDeviceCard: View {
    let allWorkouts: [WorkoutSession]

    private var calcStatistics: StatisticCalcEngine {
        StatisticCalcEngine(workouts: allWorkouts)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workouts je Gerätetyp")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach([WorkoutDevice.crosstrainer, .ergometer], id: \.self) { device in
                    StatisticDeviceRow(
                        device: device,
                        count: calcStatistics.workoutCountDevice(for: device),
                        total: calcStatistics.totalWorkouts
                    )
                }
            }
        }
        .glassCardStyle()
    }
}

#Preview {
    StatisticDeviceCard(allWorkouts: [])
}
