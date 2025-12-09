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
enum WorkoutDevice: Int, Codable, CaseIterable, Identifiable {
    case none = 0
    case crosstrainer = 1
    case ergometer = 2

    var id: Self { self }
}

// Filter für die Anzeige der Workouts innerhalb einer Zeitspanne
enum TimeFilter: String, CaseIterable, Identifiable {
    case all = "Alle"
    case today = "Heute"
    case thisWeek = "Letzte Woche"
    case thisMonth = "Letzter Monat"
    case last30Days = "Letzte 30 Tage"
    case last90Days = "Letzte 90 Tage"
    case last180Days = "Letzte 180 Tage"
    case thisYear = "Dieses Jahr"

    var id: String { rawValue }

    var description: String { rawValue }

    var intervalSymbol: String {
        switch self {
            case .all: return "calendar"
            case .today: return "calendar.badge"
            case .thisWeek: return "7.calendar"
            case .thisMonth: return "30.calendar"
            case .last30Days: return "30.calendar"
            case .last90Days: return "calendar.badge"
            case .last180Days: return "calendar.badge"
            case .thisYear: return "calendar"
        }
    }

    // Berechnung der jeweiligen Zeitspannen im Filter
    func dateRange() -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
            case .all:
                return nil

            // Zeige nur Workouts von heute an
            case .today:
                let startOfDay = calendar.startOfDay(for: now)
                return (start: startOfDay, end: now)

            // Zeige nur Workouts von dieser Woche an
            case .thisWeek:
                guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
                    return nil
                }
                return (start: startOfWeek, end: now)

            // Zeige nur Workouts von diesem Monat an
            case .thisMonth:
                guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
                    return nil
                }
                return (start: startOfMonth, end: now)

            // Zeige Workouts der letzten 30 Tage an
            case .last30Days:
                guard let start = calendar.date(byAdding: .day, value: -30, to: now) else {
                    return nil
                }
                return (start: start, end: now)

            // Zeige Workouts der letzten 90 Tage an
            case .last90Days:
                guard let start = calendar.date(byAdding: .day, value: -90, to: now) else {
                    return nil
                }
                return (start: start, end: now)

            // Zeige Workouts der letzten 180 Tage an
            case .last180Days:
                guard let start = calendar.date(byAdding: .day, value: -180, to: now) else {
                    return nil
                }
                return (start: start, end: now)

            // Zeige nur Workouts aus diesem Jahr an
            case .thisYear:
                guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)) else {
                    return nil
                }
                return (start: startOfYear, end: now)
        }
    }
}
