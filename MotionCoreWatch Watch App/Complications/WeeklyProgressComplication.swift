//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Watch Complications                                              /
// Datei . . . . : WeeklyProgressComplication.swift                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.03.2026                                                       /
// Beschreibung  : Watch Face Complication für den wöchentlichen Workout-Fortschritt/
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct WeeklyProgressEntry: TimelineEntry {
    let date: Date
    let workoutCount: Int
    let workoutGoal: Int
}

// MARK: - Timeline Provider

struct WeeklyProgressProvider: TimelineProvider {

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.barto.motioncore")
    }

    func placeholder(in context: Context) -> WeeklyProgressEntry {
        WeeklyProgressEntry(date: .now, workoutCount: 3, workoutGoal: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeeklyProgressEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyProgressEntry>) -> Void) {
        // Täglich um Mitternacht neu laden
        let nextUpdate = Calendar.current.startOfDay(for: .now.addingTimeInterval(86400))
        completion(Timeline(entries: [makeEntry()], policy: .after(nextUpdate)))
    }

    private func makeEntry() -> WeeklyProgressEntry {
        let count = sharedDefaults?.integer(forKey: WatchComplicationKey.weeklyWorkoutCount) ?? 0
        let goal  = sharedDefaults?.integer(forKey: WatchComplicationKey.weeklyWorkoutGoal) ?? 0
        return WeeklyProgressEntry(date: .now, workoutCount: count, workoutGoal: goal > 0 ? goal : 5)
    }
}

// MARK: - Complication View

struct WeeklyProgressEntryView: View {
    var entry: WeeklyProgressProvider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: Double(entry.workoutCount), in: 0...Double(max(entry.workoutGoal, 1))) {
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(.blue)
            } currentValueLabel: {
                Text("\(entry.workoutCount)")
                    .font(.system(.caption, design: .rounded).bold())
            }
            .gaugeStyle(.accessoryCircular)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)
                    Text("Workouts")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(entry.workoutCount)/\(entry.workoutGoal)")
                        .font(.caption.bold())
                }
                ProgressView(value: Double(entry.workoutCount), total: Double(max(entry.workoutGoal, 1)))
                    .tint(.blue)
            }
        default:
            Text("\(entry.workoutCount)/\(entry.workoutGoal)")
        }
    }
}

// MARK: - Widget Definition

struct WeeklyProgressComplication: Widget {
    let kind: String = "WeeklyProgressComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyProgressProvider()) { entry in
            WeeklyProgressEntryView(entry: entry)
        }
        .configurationDisplayName("Wöchentlicher Fortschritt")
        .description("Workouts diese Woche vs. Ziel")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}
