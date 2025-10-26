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
            // Überschrift mit Datum und Uhrzeit des Workouts
        VStack(alignment: .leading, spacing: 4) {
            Text(dateFormatter.string(from: workout.date))
                .font(.headline)
                .padding(.bottom, 4)
                /// 1. Zeile mit Dauer, Distanz und Kalorien
            HStack(spacing: 8) {
                Label(workout.durationFormatted, systemImage: "clock")
                Label(workout.distanceFormatted, systemImage: "point.bottomleft.forward.to.point.topright.scurvepath")
                Label(workout.averageSpeedFormatted, systemImage: "gauge.with.dots.needle.67percent")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.bottom, 7)
                /// 2. Zeile mit ∅ Herzfrequenz, ∅ Geschwindigkeit, METS (Metabolisches Äquivalent)
            HStack(spacing: 8) {
                Label(workout.heartRateFormatted, systemImage: "heart")
                Label(workout.caloriesFormatted, systemImage: "flame")
                Label(workout.metsFormatted, systemImage: "function")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.bottom, 7)
                /// 3. Zeile mit Belastungsskala
            HStack {
                Text("Belastung:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(0..<5) { index in
                    Image(systemName: index < workout.intensity.rawValue ? "star.fill" : "star") //rawValue nimmt die nackte Zahl aus dem Model
                        .font(.caption2)
                        .foregroundStyle(
                            index < workout.intensity.rawValue
                            ? workout.intensity.color //verwendet die definierte Farbe aus WorkoutTypesUI
                            : .gray //nicht gesetzte Sterne bleiben grau
                        )
                }
            }
        }
        .padding(.vertical, 4)
    }
}
