//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Widgets                                                          /
// Datei . . . . : TrainingOverviewWidget.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-20                                                       /
// Beschreibung  : Large Home-Screen Widget — Trainings-Überblick                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import WidgetKit
import SwiftUI
import Charts

// MARK: - Training Overview Widget View

struct TrainingOverviewWidgetView: View {
    let entry: MotionCoreEntry

    var body: some View {
        let snapshot = entry.snapshot

        VStack(alignment: .leading, spacing: 12) {
            // MARK: Header: Wochenziel-Ring + Streak
            HStack(spacing: 16) {
                // Wochenziel-Ring
                weeklyGoalRing(snapshot.weeklyProgress)

                VStack(alignment: .leading, spacing: 4) {
                    Text("MotionCore")
                        .font(.headline)
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                        Text("\(snapshot.streak.currentStreak) Tage Streak")
                            .font(.subheadline)
                    }
                    Text("\(snapshot.weeklyProgress.completed)/\(snapshot.weeklyProgress.goal) diese Woche")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider()

            // MARK: 4-Wochen Volumen-Chart
            if !snapshot.volumeTrend.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Volumen (4 Wochen)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Chart(snapshot.volumeTrend) { point in
                        BarMark(
                            x: .value("Woche", point.weekLabel),
                            y: .value("Volumen", point.volumeKg / 1000)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .cornerRadius(4)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(String(format: "%.1ft", v))
                                        .font(.system(size: 8))
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let label = value.as(String.self) {
                                    Text(label)
                                        .font(.system(size: 9))
                                }
                            }
                        }
                    }
                    .frame(height: 80)
                }
            }

            Divider()

            // MARK: Big-3 PRs
            if !snapshot.big3PRs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Big-3 PRs (1RM est.)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    HStack(spacing: 0) {
                        ForEach(snapshot.big3PRs) { pr in
                            VStack(spacing: 2) {
                                Text(String(format: "%.0f kg", pr.weight1RMkg))
                                    .font(.system(.subheadline, design: .rounded).bold())
                                Text(pr.exerciseName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)

                            if pr.id != snapshot.big3PRs.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .widgetURL(URL(string: "motioncore://summary"))
    }

    // MARK: - Weekly Goal Ring

    private func weeklyGoalRing(_ progress: WeeklyProgress) -> some View {
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.2), lineWidth: 7)
            Circle()
                .trim(from: 0, to: progress.fraction)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(progress.completed)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("/\(progress.goal)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 60, height: 60)
    }
}

// MARK: - Training Overview Widget

struct TrainingOverviewWidget: Widget {
    let kind: String = "TrainingOverviewWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MotionCoreTimelineProvider()) { entry in
            TrainingOverviewWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Trainings-Überblick")
        .description("Wochenziel, Streak, Volumen-Trend und Big-3 PRs auf einen Blick.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemLarge) {
    TrainingOverviewWidget()
} timeline: {
    MotionCoreEntry(date: .now, snapshot: .preview)
}
