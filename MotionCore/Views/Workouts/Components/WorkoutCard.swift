// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : WorkoutCard.swift                                                /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Workout Card Ansicht mit diversen Werten                         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftUI

// Workout Card
struct WorkoutCard: View {
    let workout: WorkoutSession
    let deFormat = Date.FormatStyle.dateTime
        .day(.twoDigits)
        .month(.wide)
        .year()
        .locale(Locale(identifier: "de_DE"))

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header mit Device Badge
            HStack {
                // Device Icon mit Glas-Effekt
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)

                    Image(systemName: workout.workoutDevice.symbol)
                        .font(.title3)
                        .foregroundStyle(workout.workoutDevice.tint)
                }
                // Anzeige Datum und Uhrzeit
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.date.formatted(deFormat))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(workout.date, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                // Training Program Icon
                Image(systemName: workout.trainingProgram.symbol)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Divider()
                .background(.white.opacity(0.2))

            // Stats Grid mit Icons
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                // Workout-Dauer
                StatBubble(
                    icon: "clock.fill",
                    value: workout.durationFormatted,
                    color: .blue
                )
                // Workout-Distanz
                StatBubble(
                    icon: "arrow.left.and.right",
                    value: workout.distanceFormatted,
                    color: .green
                )
                // Workout-Geschwindigkeit
                StatBubble(
                    icon: "gauge.with.dots.needle.67percent",
                    value: workout.averageSpeedFormatted,
                    color: .orange
                )
                // Workout-Herzfrequenz (Durchschnitt)
                StatBubble(
                    icon: "heart.fill",
                    value: workout.heartRateFormatted,
                    color: .red
                )
                // Workout-Kalorien
                StatBubble(
                    icon: "flame.fill",
                    value: workout.caloriesFormatted,
                    color: .orange
                )
                // Workout-METS
                StatBubble(
                    icon: "bolt.fill",
                    value: workout.metsFormatted,
                    color: .yellow
                )
            }

            // Intensity Stars
            HStack(spacing: 4) {
                Text("Belastung:")
                    .font(.caption2)
                    .foregroundStyle(.primary)

                ForEach(0 ..< 5) { index in
                    Image(systemName: index < workout.intensity.rawValue ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundStyle(index < workout.intensity.rawValue ? workout.intensity.color : .gray.opacity(0.3))
                }

                Spacer()
            }
        }
        .glassCardStyle()
    }
}
