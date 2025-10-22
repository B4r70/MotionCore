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
    let workout: WorkoutEntry

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dateFormatter.string(from: workout.date))
                .font(.headline)
                .padding(.bottom, 4)

            HStack(spacing: 8) {
                Label("\(workout.duration) Min", systemImage: "clock")
                Label(String(format: "%.2f km", workout.distance), systemImage: "point.bottomleft.forward.to.point.topright.scurvepath")
                Label("\(workout.calories) kcal", systemImage: "flame")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.bottom, 7)

            HStack {
                Text("Belastung:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(0..<5) { index in
                    Image(systemName: index < workout.intensity ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundStyle(index < workout.intensity ? .orange : .gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
