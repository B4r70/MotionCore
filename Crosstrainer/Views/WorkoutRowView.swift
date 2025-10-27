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
                // MARK: - Überschrift mit Datum + Programm-Icon rechts
            HStack { // // geändert: HStack statt nur Text
                Text(dateFormatter.string(from: workout.date))
                    .font(.headline).bold()
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: workout.trainingProgram.symbol) // // NEU: Programm-Icon
                    .imageScale(.medium)
                    .font(.headline)                               // optisch zur Headline passend
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(workout.trainingProgram.description)
            }
            .padding(.bottom, 4)
            // MARK: - Werte im Grid
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 5) {
                // 1. Zeile – Zeit, Distanz, Tempo
                GridRow {
                    Label(workout.durationFormatted, systemImage: "clock")
                    Label(workout.distanceFormatted, systemImage: "point.bottomleft.forward.to.point.topright.scurvepath")
                    Label(workout.averageSpeedFormatted, systemImage: "gauge.with.dots.needle.67percent")
                }
                .gridCellColumns(1)
                // 2. Zeile – Puls, Kalorien, METs
                GridRow {
                    Label(workout.heartRateFormatted, systemImage: "heart")
                    Label(workout.caloriesFormatted, systemImage: "flame")
                    Label(workout.metsFormatted, systemImage: "function")
                }
            }
            .font(.caption)
            .monospacedDigit()
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
