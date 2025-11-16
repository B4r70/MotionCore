// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : StatisticDeviceCard.swift                                        /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 11.11.2025                                                       /
// Function . . : Statistik Card Ansicht mit diversen Werten                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct StatisticDeviceCard: View {
    let workouts: [WorkoutSession]

    private var totalWorkouts: Int {
        workouts.count
    }

    private func count(for device: WorkoutDevice) -> Int {
        workouts.filter { $0.workoutDevice == device }.count
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
                        count: count(for: device),
                        total: totalWorkouts
                    )
                }
            }
        }
        .glassCardStyle()
    }
}

#Preview {
    StatisticDeviceCard(workouts: [])
}
