// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : RecordView.swift                                                 /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 11.11.2025                                                       /
// Function . . : Persönliche Rekorde                                              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct RecordView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var workouts: [WorkoutSession]

    @ObservedObject private var settings = AppSettings.shared

    // Berechnung: Bestes Workout mit der längsten Distanz (geräteübergreifend)
    private var bestErgometerWorkout: WorkoutSession? {
        workouts
            .filter { $0.workoutDevice == .ergometer }
            .max(by: { $0.distance < $1.distance })
    }

    // Berechnung: Bestes Crosstrainer Workout mit der längsten Distanz
    private var bestCrosstrainerWorkout: WorkoutSession? {
        workouts
            .filter { $0.workoutDevice == .crosstrainer }
            .max(by: { $0.distance < $1.distance })
    }

    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: settings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    // Beste Leistung nach Distanz auf dem Crosstrainer
                    if let best = bestCrosstrainerWorkout {
                        RecordCard(
                            title: "Beste Leistung",
                            subtitle: "Längste Distanz auf dem Crosstrainer",
                            icon: best.workoutDevice.symbol,
                            color: best.workoutDevice.tint,
                            workout: best
                        )
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    // Beste Leistung nach Distanz auf dem Ergometer
                    if let best = bestErgometerWorkout {
                        RecordCard(
                            title: "Beste Leistung",
                            subtitle: "Längste Distanz auf dem Ergometer",
                            icon: best.workoutDevice.symbol,
                            color: best.workoutDevice.tint,
                            workout: best
                        )
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    // Hier kannst du später weitere Rekord-Cards hinzufügen
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
        RecordView()
    }
}
