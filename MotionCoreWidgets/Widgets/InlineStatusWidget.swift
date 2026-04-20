//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Widgets                                                          /
// Datei . . . . : InlineStatusWidget.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-20                                                       /
// Beschreibung  : Lock Screen Widgets — accessoryCircular + accessoryInline        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import WidgetKit
import SwiftUI

// MARK: - accessoryCircular View

struct CircularStatusWidgetView: View {
    let entry: MotionCoreEntry

    var body: some View {
        let progress = entry.snapshot.weeklyProgress

        ZStack {
            // Fortschrittsring
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 5)

            Circle()
                .trim(from: 0, to: progress.fraction)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Streak-Zahl in der Mitte
            VStack(spacing: 0) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                Text("\(entry.snapshot.streak.currentStreak)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
        }
    }
}

// MARK: - accessoryInline View

struct InlineStatusWidgetView: View {
    let entry: MotionCoreEntry

    var body: some View {
        let weekly = entry.snapshot.weeklyProgress
        let streak = entry.snapshot.streak

        // Format: "3/5 Woche · 🔥12"
        Text("\(weekly.completed)/\(weekly.goal) · \(Image(systemName: "flame.fill"))\(streak.currentStreak)")
            .minimumScaleFactor(0.7)
    }
}

// MARK: - accessoryCircular Widget

struct CircularStatusWidget: Widget {
    let kind: String = "CircularStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MotionCoreTimelineProvider()) { entry in
            CircularStatusWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Streak Ring")
        .description("Wochenziel-Fortschritt als Ring mit aktueller Streak.")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - accessoryInline Widget

struct InlineStatusWidget: Widget {
    let kind: String = "InlineStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MotionCoreTimelineProvider()) { entry in
            InlineStatusWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Status")
        .description("Kompakte Statuszeile: Wochenziel und aktuelle Streak.")
        .supportedFamilies([.accessoryInline])
    }
}

// MARK: - Previews

#Preview(as: .accessoryCircular) {
    CircularStatusWidget()
} timeline: {
    MotionCoreEntry(date: .now, snapshot: .preview)
}

#Preview(as: .accessoryInline) {
    InlineStatusWidget()
} timeline: {
    MotionCoreEntry(date: .now, snapshot: .preview)
}
