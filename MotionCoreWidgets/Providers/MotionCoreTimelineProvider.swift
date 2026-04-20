//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Widget Providers                                                 /
// Datei . . . . : MotionCoreTimelineProvider.swift                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-20                                                       /
// Beschreibung  : Gemeinsamer TimelineProvider für alle MotionCore-Widgets         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import WidgetKit
import SwiftUI

// MARK: - MotionCore Timeline Provider

/// Gemeinsamer Provider für alle MotionCore-Widgets.
/// Liest Daten aus dem AppGroup-Container (via WidgetDataStore).
/// Keine Netzwerk-Calls, kein SwiftData-Zugriff aus der Extension.
struct MotionCoreTimelineProvider: TimelineProvider {

    // MARK: - Placeholder

    /// Wird angezeigt während der Widget-Galerie lädt (vor echten Daten)
    func placeholder(in context: Context) -> MotionCoreEntry {
        MotionCoreEntry(date: Date(), snapshot: .preview)
    }

    // MARK: - Snapshot

    /// Wird für Vorschau in der Widget-Galerie verwendet
    func getSnapshot(in context: Context, completion: @escaping (MotionCoreEntry) -> Void) {
        let snapshot = context.isPreview ? .preview : WidgetDataStore.readSnapshot()
        completion(MotionCoreEntry(date: Date(), snapshot: snapshot))
    }

    // MARK: - Timeline

    /// Erstellt eine Timeline mit einem Eintrag + Refresh nach 30 Minuten.
    /// Eigentliche Aktualisierung erfolgt via WidgetCenter.reloadAllTimelines()
    /// im WidgetSnapshotPublisher.
    func getTimeline(in context: Context, completion: @escaping (Timeline<MotionCoreEntry>) -> Void) {
        let snapshot = WidgetDataStore.readSnapshot()
        let entry    = MotionCoreEntry(date: Date(), snapshot: snapshot)

        // Refresh nach 30 Minuten als Fallback (eigentlicher Trigger: Publisher nach Workout)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline    = Timeline(entries: [entry], policy: .after(nextRefresh))

        completion(timeline)
    }
}
