//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Watch Complications                                              /
// Datei . . . . : StreakComplication.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.03.2026                                                       /
// Beschreibung  : Watch Face Complication für den aktuellen Workout-Streak         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct StreakEntry: TimelineEntry {
    let date: Date
    let streakCount: Int
}

// MARK: - Timeline Provider

struct StreakProvider: TimelineProvider {

    private var sharedDefaults: UserDefaults? { WatchAppGroup.defaults }

    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, streakCount: 7)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        // Täglich um Mitternacht neu laden
        let nextUpdate = Calendar.current.startOfDay(for: .now.addingTimeInterval(86400))
        completion(Timeline(entries: [makeEntry()], policy: .after(nextUpdate)))
    }

    private func makeEntry() -> StreakEntry {
        let streak = sharedDefaults?.integer(forKey: WatchComplicationKey.streakCount) ?? 0
        return StreakEntry(date: .now, streakCount: streak)
    }
}

// MARK: - Complication View

struct StreakComplicationEntryView: View {
    var entry: StreakProvider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCorner:
            Label {
                Text("\(entry.streakCount)")
                    .font(.system(.body, design: .rounded).bold())
            } icon: {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.orange)
            }
            .labelStyle(.titleAndIcon)
        case .accessoryCircular:
            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.orange)
                    .font(.caption)
                Text("\(entry.streakCount)")
                    .font(.system(.title3, design: .rounded).bold())
            }
        default:
            Text("\(entry.streakCount)")
        }
    }
}

// MARK: - Widget Definition

struct StreakComplication: Widget {
    let kind: String = "StreakComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Dein aktueller Workout-Streak")
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
    }
}
