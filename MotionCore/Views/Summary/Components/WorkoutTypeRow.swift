//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : WorkoutTypeRow.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 07.01.2026                                                       /
// Beschreibung  : Zeile für einen Workout-Typ in der Aufschlüsselung               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Workout Type Row

/// Einzelne Zeile für einen Workout-Typ in der Aufschlüsselung
struct WorkoutTypeRow: View {
    let summary: SummaryCalcEngine.WorkoutTypeSummary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: summary.workoutType.icon)
                .font(.title2)
                .foregroundStyle(colorForType(summary.workoutType))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(summary.workoutType.description)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(summary.calories) kcal • \(summary.duration) Min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(summary.count)")
                    .font(.headline)

                Text(String(format: "%.0f%%", summary.percentage))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func colorForType(_ type: WorkoutType) -> Color {
        switch type {
        case .cardio: return .blue
        case .strength: return .orange
        case .outdoor: return .green
        }
    }
}
