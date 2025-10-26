//---------------------------------------------------------------------------------/
//  # CrossStats                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : WorkoutRowView.swift                                             /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Workout Row View                                                 /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI

struct WorkoutRowView: View {
    let workout: WorkoutSession

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // MARK: - Überschrift mit Datum
            Text(dateFormatter.string(from: workout.date))
                .font(.headline)
                .padding(.bottom, 4)

            // MARK: - Werte im Grid
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                // 1. Zeile – Zeit, Distanz, Tempo
                GridRow {
                    Label(workout.durationFormatted, systemImage: "clock")
                    Label(workout.distanceFormatted, systemImage: "point.bottomleft.forward.to.point.topright.scurvepath")
                    Label(workout.averageSpeedFormatted, systemImage: "gauge.with.dots.needle.67percent")
                }

                // 2. Zeile – Puls, Kalorien, METs
                GridRow {
                    Label(workout.heartRateFormatted, systemImage: "heart")
                    Label(workout.caloriesFormatted, systemImage: "flame")
                    Label(workout.metsFormatted, systemImage: "function")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.bottom, 6)

            // MARK: - Belastungsskala
            HStack {
                Text("Belastung:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(0..<5) { index in
                    Image(systemName: index < workout.intensity.rawValue ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundStyle(
                            index < workout.intensity.rawValue
                            ? workout.intensity.color
                            : .gray
                        )
                }
            }
        }
        .padding(.vertical, 4)
    }
}
