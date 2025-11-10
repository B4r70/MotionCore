//---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : WorkoutCard.swift                                                /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Workout Card Ansicht mit diversen Werten                         /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI

// Neu: Glassmorphic Workout Card
struct WorkoutCard: View {
    let workout: WorkoutSession

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

                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.date, style: .date)
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
                GridItem(.flexible())
            ], spacing: 12) {
                StatBubble(
                    icon: "clock.fill",
                    value: workout.durationFormatted,
                    color: .blue
                )

                StatBubble(
                    icon: "arrow.left.and.right",
                    value: workout.distanceFormatted,
                    color: .green
                )

                StatBubble(
                    icon: "gauge.with.dots.needle.67percent",
                    value: workout.averageSpeedFormatted,
                    color: .orange
                )

                StatBubble(
                    icon: "heart.fill",
                    value: workout.heartRateFormatted,
                    color: .red
                )

                StatBubble(
                    icon: "flame.fill",
                    value: workout.caloriesFormatted,
                    color: .orange
                )

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
                    .foregroundStyle(.secondary)

                ForEach(0..<5) { index in
                    Image(systemName: index < workout.intensity.rawValue ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundStyle(index < workout.intensity.rawValue ? workout.intensity.color : .gray.opacity(0.3))
                }

                Spacer()
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
    }
}
