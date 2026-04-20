//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Widgets                                                          /
// Datei . . . . : StreakWidget.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-20                                                       /
// Beschreibung  : Small Home-Screen Widget — Trainings-Streak                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import WidgetKit
import SwiftUI

// MARK: - Streak Widget View

struct StreakWidgetView: View {
    let entry: MotionCoreEntry

    var body: some View {
        let streak = entry.snapshot.streak

        VStack(alignment: .leading, spacing: 6) {
            // Icon + Streak-Zahl
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.title2)

                Text("\(streak.currentStreak)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(.primary)
            }

            Text(streak.currentStreak == 1 ? "Tag Streak" : "Tage Streak")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            // Best-Streak als Subtitle
            if streak.longestStreak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text("Best: \(streak.longestStreak)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(URL(string: "motioncore://stats"))
    }
}

// MARK: - Streak Widget

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MotionCoreTimelineProvider()) { entry in
            StreakWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Streak")
        .description("Deine aktuelle Trainings-Streak in Tagen.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    StreakWidget()
} timeline: {
    MotionCoreEntry(date: .now, snapshot: .preview)
}
