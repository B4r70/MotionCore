// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : RecordCard.swift                                                 /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 11.11.2025                                                       /
// Function . . : Record Card Ansicht mit diversen Werten                          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Record Card Component

struct RecordCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let allWorkouts: WorkoutSession

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
                RecordDetailRow(
                    icon: allWorkouts.workoutDevice.symbol,
                    label: "Gerät",
                    value: allWorkouts.workoutDevice.description,
                    color: allWorkouts.workoutDevice.tint
                )
                // Kalorien
                RecordDetailRow(
                    icon: "flame.fill",
                    label: "Kalorien",
                    value: "\(allWorkouts.calories) kcal",
                    color: .orange
                )
                // Dauer des Workouts
                RecordDetailRow(
                    icon: "clock.fill",
                    label: "Dauer",
                    value: "\(allWorkouts.duration) min",
                    color: .blue
                )
                // Zurückgelegte Distanz
                RecordDetailRow(
                    icon: "arrow.left.and.right",
                    label: "Distanz",
                    value: String(format: "%.2f km", allWorkouts.distance),
                    color: .green
                )
                // Datum des Workouts
                RecordDetailRow(
                    icon: "calendar",
                    label: "Datum",
                    value: allWorkouts.date.formatted(AppFormatters.dateGermanShort),
                    color: .purple
                )
            }
        }
        .glassCardStyle()
    }
}
