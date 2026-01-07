//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : SummaryTypes.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 07.01.2026                                                       /
// Beschreibung  : Typen und Enums für die Summary-Ansicht                          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Summary Timeframe

/// Zeitraum-Auswahl für Summary
enum SummaryTimeframe: String, CaseIterable, Identifiable {
    case week = "week"
    case month = "month"
    case year = "year"
    case all = "all"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .week: return "Woche"
        case .month: return "Monat"
        case .year: return "Jahr"
        case .all: return "Gesamt"
        }
    }
}
