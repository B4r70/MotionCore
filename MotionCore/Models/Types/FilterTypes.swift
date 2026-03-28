//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : FilterTypes.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.12.2025                                                       /
// Beschreibung  : Enumerationen bezüglich Zeitspannen/Zeitfilter                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// Filter für die Anzeige der Workouts je Trainingsgerät
enum CardioDevice: Int, Codable, CaseIterable, Identifiable {
    case none = 0
    case crosstrainer = 1
    case ergometer = 2

    var id: Self { self }
}

// Filter für die Anzeige der Workouts innerhalb einer Zeitspanne
enum TimeFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case thisWeek = "thisWeek"
    case thisMonth = "thisMonth"
    case thisYear = "thisYear"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .all: return "Gesamt"
        case .thisWeek: return "Woche"
        case .thisMonth: return "Monat"
        case .thisYear: return "Jahr"
        }
    }

    var intervalSymbol: String {
        switch self {
        case .all: return "calendar"
        case .thisWeek: return "calendar.badge.clock"
        case .thisMonth: return "calendar.badge.minus"
        case .thisYear: return "clock.arrow.circlepath"
        }
    }

    // Berechnung der jeweiligen Zeitspannen im Filter
    func dateRange() -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .all:
            return nil
        case .thisWeek:
            guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
                return nil
            }
            return (start: startOfWeek, end: now)
        case .thisMonth:
            guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
                return nil
            }
            return (start: startOfMonth, end: now)
        case .thisYear:
            guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)) else {
                return nil
            }
            return (start: startOfYear, end: now)
        }
    }
}
