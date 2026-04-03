//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Berechnung                                            /
// Datei . . . . : WeeklyGoalCalcEngine.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-02                                                       /
// Beschreibung  : Berechnet Wochenziel-Status und Konsistenz-Kennzahlen            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Wochenziel-Berechnungs-Engine

/// Pure struct — kein State, kein SwiftUI.
struct WeeklyGoalCalcEngine {

    // MARK: - Eingabe

    let cardioSessions: [CardioSession]
    let strengthSessions: [StrengthSession]
    let outdoorSessions: [OutdoorSession]
    let weeklyGoal: Int

    // MARK: - Aktuelles Wochenziel

    /// Berechnet den aktuellen Wochenziel-Status.
    func currentWeekGoal() -> WeeklyGoal {
        let current = workoutsInCurrentWeek()
        let average = averageLast4Weeks()

        let progressFraction: Double
        if weeklyGoal > 0 {
            progressFraction = Double(current) / Double(weeklyGoal)
        } else {
            progressFraction = 0
        }

        return WeeklyGoal(
            target: weeklyGoal,
            current: current,
            averageLast4Weeks: average,
            isReached: current >= weeklyGoal,
            isAboveAverage: Double(current) > average,
            progressFraction: progressFraction
        )
    }

    // MARK: - Konsistenz-Wochen

    /// Gibt zurück, wie viele aufeinanderfolgende Wochen (rückwärts) das Ziel erreicht wurde.
    func consecutiveWeeksGoalReached() -> Int {
        guard weeklyGoal > 0 else { return 0 }
        let calendar = Calendar.current
        let now = Date()
        var consecutiveCount = 0

        for weekOffset in 1...52 {
            guard
                let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
                let weekEnd = calendar.date(byAdding: .weekOfYear, value: -(weekOffset - 1), to: now)
            else { break }

            let count = workoutsInRange(start: weekStart, end: weekEnd)
            if count >= weeklyGoal {
                consecutiveCount += 1
            } else {
                break
            }
        }

        return consecutiveCount
    }

    // MARK: - Private Helpers

    /// Workouts in der aktuellen Woche (letzten 7 Tage)
    private func workoutsInCurrentWeek() -> Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(byAdding: .day, value: -7, to: now) else { return 0 }
        return workoutsInRange(start: weekStart, end: now)
    }

    /// Durchschnittliche Workouts pro Woche der letzten 4 Wochen
    private func averageLast4Weeks() -> Double {
        let calendar = Calendar.current
        let now = Date()
        var total = 0

        for weekOffset in 1...4 {
            guard
                let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
                let weekEnd = calendar.date(byAdding: .weekOfYear, value: -(weekOffset - 1), to: now)
            else { continue }

            total += workoutsInRange(start: weekStart, end: weekEnd)
        }

        return Double(total) / 4.0
    }

    /// Workouts in einem bestimmten Zeitraum
    private func workoutsInRange(start: Date, end: Date) -> Int {
        let cardio = cardioSessions.filter { $0.date >= start && $0.date < end }.count
        let strength = strengthSessions.filter { $0.date >= start && $0.date < end }.count
        let outdoor = outdoorSessions.filter { $0.date >= start && $0.date < end }.count
        return cardio + strength + outdoor
    }
}
