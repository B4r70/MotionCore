//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Progressions-Analyse                                            /
// Datei . . . . : ProgressionExerciseCard.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-17                                                       /
// Beschreibung  : Kompakte Card für eine Übung in der Progressions-Liste          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ProgressionExerciseCard: View {
    let analysis: ProgressionAnalysis

    private var trendColor: Color {
        switch analysis.trend {
        case .improving:    return .green
        case .stable:       return .blue
        case .declining:    return .orange
        case .volatile:     return .yellow
        case .insufficient: return .secondary
        }
    }

    private var confidenceColor: Color {
        switch analysis.confidenceLevel {
        case .high:         return .green
        case .medium:       return .yellow
        case .low:          return .orange
        case .insufficient: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {

            // Trend-Icon
            Image(systemName: analysis.trend.icon)
                .font(.title3)
                .foregroundStyle(trendColor)
                .frame(width: 28)

            // Übungsname + empfohlene Aktion
            VStack(alignment: .leading, spacing: 2) {
                Text(analysis.exerciseName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(analysis.recommendedAction.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Aktuelles Gewicht
            if analysis.currentWeight > 0 {
                Text(String(format: "%.1f kg", analysis.currentWeight))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }

            // Konfidenz-Icon
            Image(systemName: analysis.confidenceLevel.icon)
                .font(.caption)
                .foregroundStyle(confidenceColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassCard()
    }
}
