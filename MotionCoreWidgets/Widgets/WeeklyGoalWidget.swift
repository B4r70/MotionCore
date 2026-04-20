//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Widgets                                                          /
// Datei . . . . : WeeklyGoalWidget.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-20                                                       /
// Beschreibung  : Small Home-Screen Widget — Wochenziel Fortschritt (fix 5)        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import WidgetKit
import SwiftUI

// MARK: - Weekly Goal Widget View

struct WeeklyGoalWidgetView: View {
    let entry: MotionCoreEntry

    var body: some View {
        let progress = entry.snapshot.weeklyProgress

        VStack(spacing: 8) {
            // Ring-Fortschritt
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress.fraction)
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress.fraction)

                VStack(spacing: 0) {
                    Text("\(progress.completed)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("/\(progress.goal)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 72, height: 72)

            Text("Diese Woche")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "motioncore://summary"))
    }
}

// MARK: - Weekly Goal Widget

struct WeeklyGoalWidget: Widget {
    let kind: String = "WeeklyGoalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MotionCoreTimelineProvider()) { entry in
            WeeklyGoalWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Wochenziel")
        .description("Dein Trainings-Fortschritt für diese Woche (Ziel: 5).")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    WeeklyGoalWidget()
} timeline: {
    MotionCoreEntry(date: .now, snapshot: .preview)
}
