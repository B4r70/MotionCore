//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Widget Providers                                                 /
// Datei . . . . : MotionCoreEntry.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-20                                                       /
// Beschreibung  : Gemeinsamer TimelineEntry für alle MotionCore-Widgets            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import WidgetKit

// MARK: - MotionCore Timeline Entry

/// Gemeinsamer Entry für alle MotionCore-Home-Screen- und Lock-Screen-Widgets.
struct MotionCoreEntry: TimelineEntry {
    /// Datum des Eintrags (WidgetKit-Pflichtfeld)
    let date: Date
    /// Aktueller Widget-Snapshot mit allen Anzeige-Daten
    let snapshot: WidgetSnapshot
}
