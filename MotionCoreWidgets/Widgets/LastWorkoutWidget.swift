//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Widgets                                                          /
// Datei . . . . : LastWorkoutWidget.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-20                                                       /
// Beschreibung  : Medium Home-Screen Widget — Letztes Workout                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import WidgetKit
import SwiftUI

// MARK: - Last Workout Widget View

struct LastWorkoutWidgetView: View {
    let entry: MotionCoreEntry

    var body: some View {
        if let last = entry.snapshot.lastWorkout {
            HStack(spacing: 16) {
                // Linke Spalte: Datum + Top-Übung
                VStack(alignment: .leading, spacing: 4) {
                    Text("Letztes Training")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(last.date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(last.topExerciseName.isEmpty ? "Workout" : last.topExerciseName)
                        .font(.headline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text("\(last.completedSets) Sätze")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Rechte Spalte: Volumen + Dauer
                VStack(alignment: .leading, spacing: 10) {
                    statRow(
                        icon: "scalemass.fill",
                        value: formattedVolume(last.totalVolumeKg),
                        label: "Volumen"
                    )

                    statRow(
                        icon: "clock.fill",
                        value: "\(last.durationMinutes) min",
                        label: "Dauer"
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .padding(14)
            .widgetURL(URL(string: "motioncore://workouts"))
        } else {
            // Empty State
            VStack(spacing: 8) {
                Image(systemName: "dumbbell")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Noch kein Training")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Hilfsfunktionen

    private func statRow(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)
                .frame(width: 14)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.subheadline.bold())
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formattedVolume(_ kg: Double) -> String {
        if kg >= 1000 {
            return String(format: "%.1f t", kg / 1000)
        } else {
            return String(format: "%.0f kg", kg)
        }
    }
}

// MARK: - Last Workout Widget

struct LastWorkoutWidget: Widget {
    let kind: String = "LastWorkoutWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MotionCoreTimelineProvider()) { entry in
            LastWorkoutWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Letztes Workout")
        .description("Datum, Volumen, Dauer und Top-Übung des letzten Trainings.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    LastWorkoutWidget()
} timeline: {
    MotionCoreEntry(date: .now, snapshot: .preview)
}
