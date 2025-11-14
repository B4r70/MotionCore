//---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : RecordCard.swift                                                 /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 11.11.2025                                                       /
// Function . . : Record Card Ansicht mit diversen Werten                          /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Record Card Component
struct RecordCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let workout: WorkoutSession

    var body: some View {
        VStack(spacing: 20) {
            // Header mit Icon
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(color)

                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Workout Details
            VStack(alignment: .leading, spacing: 12) {
                // Trainingsgerät mit Icon, Beschreibung und entsprechender Farbe
                DetailRow(
                    icon: workout.workoutDevice.symbol,
                    label: "Gerät",
                    value: workout.workoutDevice.description,
                    color: workout.workoutDevice.tint
                )
                // Kalorien
                DetailRow(
                    icon: "flame.fill",
                    label: "Kalorien",
                    value: "\(workout.calories) kcal",
                    color: .orange
                )
                // Dauer des Workouts
                DetailRow(
                    icon: "clock.fill",
                    label: "Dauer",
                    value: "\(workout.duration) min",
                    color: .blue
                )
                // Zurückgelegte Distanz
                DetailRow(
                    icon: "arrow.left.and.right",
                    label: "Distanz",
                    value: String(format: "%.2f km", workout.distance),
                    color: .green
                )
                // Datum des Workouts
                DetailRow(
                    icon: "calendar",
                    label: "Datum",
                    value: workout.date.formatted(date: .abbreviated, time: .omitted),
                    color: .purple
                )
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
    }
}
