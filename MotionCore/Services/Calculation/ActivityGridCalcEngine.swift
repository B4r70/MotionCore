//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Berechnung                                            /
// Datei . . . . : ActivityGridCalcEngine.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-02                                                       /
// Beschreibung  : Berechnet Aktivitäts-Grid und Wochen-Strip aus Session-Daten     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Aktivitäts-Grid-Berechnungs-Engine

/// Pure struct — kein State, kein SwiftUI.
struct ActivityGridCalcEngine {

    // MARK: - Eingabe

    let cardioSessions: [CardioSession]
    let strengthSessions: [StrengthSession]
    let outdoorSessions: [OutdoorSession]

    // MARK: - 7-Tage-Strip

    /// Gibt die letzten 7 Tage (heute + 6 Vortage) als ActivityDay-Array zurück.
    /// Reihenfolge: ältester Tag zuerst → jüngster Tag zuletzt.
    func currentWeekStrip() -> [ActivityDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).reversed().compactMap { offset -> ActivityDay? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return activityDay(for: date)
        }
    }

    // MARK: - Monats-Grid

    /// Gibt ein 2D-Array für den Kalender-Grid des angegebenen Monats zurück.
    /// 7 Spalten (Mo–So), nil-Platzhalter für leere Zellen am Anfang und Ende.
    func monthGrid(for month: Date) -> [[ActivityDay?]] {
        let calendar = Calendar.current
        guard
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
            let range = calendar.range(of: .day, in: .month, for: monthStart)
        else { return [] }

        // Wochentag des ersten Monatstags (Mo=0 ... So=6)
        let firstWeekday = (calendar.component(.weekday, from: monthStart) + 5) % 7

        // Alle Tage des Monats als ActivityDay aufbauen
        var days: [ActivityDay?] = Array(repeating: nil, count: firstWeekday)

        for day in range {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            days.append(activityDay(for: date))
        }

        // Auf Vielfaches von 7 auffüllen
        while days.count % 7 != 0 {
            days.append(nil)
        }

        // In Wochen-Zeilen aufteilen
        var grid: [[ActivityDay?]] = []
        var row: [ActivityDay?] = []
        for (index, day) in days.enumerated() {
            row.append(day)
            if (index + 1) % 7 == 0 {
                grid.append(row)
                row = []
            }
        }

        return grid
    }

    // MARK: - Monats-Statistiken

    /// Anzahl Trainingstage und Durchschnitt pro Woche im angegebenen Monat.
    func monthStats(for month: Date) -> (trainingDays: Int, averagePerWeek: Double) {
        let calendar = Calendar.current
        guard
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
            let range = calendar.range(of: .day, in: .month, for: monthStart)
        else { return (0, 0) }

        var trainingDayCount = 0

        for day in range {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            let activity = activityDay(for: date)
            if activity.workoutCount > 0 {
                trainingDayCount += 1
            }
        }

        let weeksInMonth = Double(range.count) / 7.0
        let average = weeksInMonth > 0 ? Double(trainingDayCount) / weeksInMonth : 0

        return (trainingDayCount, average)
    }

    // MARK: - Private Helpers

    /// Erstellt einen ActivityDay für ein bestimmtes Datum
    private func activityDay(for date: Date) -> ActivityDay {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

        // Workouts des Tages ermitteln
        var types: [WorkoutType] = []

        let cardioCount = cardioSessions.filter { $0.date >= dayStart && $0.date < dayEnd }.count
        let strengthCount = strengthSessions.filter { $0.date >= dayStart && $0.date < dayEnd }.count
        let outdoorCount = outdoorSessions.filter { $0.date >= dayStart && $0.date < dayEnd }.count

        if cardioCount > 0 { types.append(.cardio) }
        if strengthCount > 0 { types.append(.strength) }
        if outdoorCount > 0 { types.append(.outdoor) }

        let totalCount = cardioCount + strengthCount + outdoorCount

        return ActivityDay(
            id: dayStart,
            date: dayStart,
            workoutTypes: types,
            workoutCount: totalCount,
            isToday: dayStart == today
        )
    }
}
