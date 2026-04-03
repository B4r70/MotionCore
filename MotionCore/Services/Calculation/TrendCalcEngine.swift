//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Berechnung                                            /
// Datei . . . . : TrendCalcEngine.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-02                                                       /
// Beschreibung  : Berechnet Wochentrends für Volumen, Kalorien und Dauer           /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Trend-Berechnungs-Engine

/// Pure struct — kein State, kein SwiftUI.
/// Vergleicht diese Woche mit der Vorwoche.
struct TrendCalcEngine {

    // MARK: - Eingabe

    let cardioSessions: [CardioSession]
    let strengthSessions: [StrengthSession]
    let outdoorSessions: [OutdoorSession]

    // MARK: - Volumen-Trend (nur Kraft)

    /// Vergleich Volumen (kg × Reps) dieser Woche vs. Vorwoche
    var volumeTrend: TrendComparison {
        let current = strengthVolume(in: currentWeekRange)
        let previous = strengthVolume(in: previousWeekRange)
        return buildComparison(current: current, previous: previous)
    }

    // MARK: - Kalorien-Trend

    /// Vergleich Gesamtkalorien dieser Woche vs. Vorwoche
    var caloriesTrend: TrendComparison {
        let current = totalCalories(in: currentWeekRange)
        let previous = totalCalories(in: previousWeekRange)
        return buildComparison(current: current, previous: previous)
    }

    // MARK: - Dauer-Trend

    /// Vergleich Gesamtdauer (Minuten) dieser Woche vs. Vorwoche
    var durationTrend: TrendComparison {
        let current = totalDuration(in: currentWeekRange)
        let previous = totalDuration(in: previousWeekRange)
        return buildComparison(current: current, previous: previous)
    }

    // MARK: - Private Helpers

    /// Datumsbereich dieser Woche (Mo–So, oder letzten 7 Tage)
    private var currentWeekRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        guard let start = calendar.date(byAdding: .day, value: -7, to: now) else {
            return now...now
        }
        return start...now
    }

    /// Datumsbereich der Vorwoche
    private var previousWeekRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        guard
            let end = calendar.date(byAdding: .day, value: -7, to: now),
            let start = calendar.date(byAdding: .day, value: -14, to: now)
        else {
            return now...now
        }
        return start...end
    }

    /// Volumen aller Kraft-Sessions in einem Zeitraum
    private func strengthVolume(in range: ClosedRange<Date>) -> Double {
        let sessions = strengthSessions.filter { range.contains($0.date) }
        let sets = sessions.flatMap { $0.safeExerciseSets }
        let workSets = sets.filter { $0.isCompleted && $0.setKind == .work }
        return workSets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
    }

    /// Gesamtkalorien aller Sessions in einem Zeitraum
    private func totalCalories(in range: ClosedRange<Date>) -> Double {
        let cardio = cardioSessions.filter { range.contains($0.date) }.map { Double($0.calories) }.reduce(0, +)
        let strength = strengthSessions.filter { range.contains($0.date) }.map { Double($0.calories) }.reduce(0, +)
        let outdoor = outdoorSessions.filter { range.contains($0.date) }.map { Double($0.calories) }.reduce(0, +)
        return cardio + strength + outdoor
    }

    /// Gesamtdauer aller Sessions in einem Zeitraum (Minuten)
    private func totalDuration(in range: ClosedRange<Date>) -> Double {
        let cardio = cardioSessions.filter { range.contains($0.date) }.map { Double($0.duration) }.reduce(0, +)
        let strength = strengthSessions.filter { range.contains($0.date) }.map { Double($0.duration) }.reduce(0, +)
        let outdoor = outdoorSessions.filter { range.contains($0.date) }.map { Double($0.duration) }.reduce(0, +)
        return cardio + strength + outdoor
    }

    /// Erstellt TrendComparison aus zwei Werten
    private func buildComparison(current: Double, previous: Double) -> TrendComparison {
        let percentageChange: Double
        let trend: TrendDirection

        if previous > 0 {
            percentageChange = ((current - previous) / previous) * 100.0
        } else if current > 0 {
            percentageChange = 100.0
        } else {
            percentageChange = 0.0
        }

        // Stabil wenn Änderung < 5%
        if abs(percentageChange) < 5.0 {
            trend = .stable
        } else if percentageChange > 0 {
            trend = .up
        } else {
            trend = .down
        }

        return TrendComparison(
            currentValue: current,
            previousValue: previous,
            percentageChange: percentageChange,
            trend: trend
        )
    }
}
