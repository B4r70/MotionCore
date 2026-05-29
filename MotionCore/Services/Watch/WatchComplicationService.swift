//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Watch Integration                                                /
// Datei . . . . : WatchComplicationService.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.03.2026                                                       /
// Beschreibung  : Schreibt Complication-Daten in App Group UserDefaults            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import WidgetKit

// MARK: - Watch Complication Service

/// Berechnet und schreibt Complication-Daten nach jedem Workout-Abschluss
struct WatchComplicationService {

    // MARK: - Update

    /// Aktualisiert alle Complication-Daten nach einem Workout-Abschluss
    /// - Parameters:
    ///   - allSessions: Alle abgeschlossenen StrengthSessions (aus @Query)
    ///   - weeklyGoal: Wöchentliches Workout-Ziel (Default: 5)
    static func updateComplications(allSessions: [StrengthSession], weeklyGoal: Int = 5) {
        guard let defaults = WatchAppGroup.defaults else { return }

        let streak      = calculateStreak(sessions: allSessions)
        let weeklyCount = calculateWeeklyCount(sessions: allSessions)

        defaults.set(streak,       forKey: WatchComplicationKey.streakCount)
        defaults.set(weeklyCount,  forKey: WatchComplicationKey.weeklyWorkoutCount)
        defaults.set(weeklyGoal,   forKey: WatchComplicationKey.weeklyWorkoutGoal)

        // Complications sofort neu laden
        WidgetCenter.shared.reloadTimelines(ofKind: "StreakComplication")
        WidgetCenter.shared.reloadTimelines(ofKind: "WeeklyProgressComplication")

        print("WatchComplicationService: Streak=\(streak), Weekly=\(weeklyCount)/\(weeklyGoal)")
    }

    // MARK: - Berechnungen

    /// Berechnet die aktuelle Trainings-Streak (aufeinanderfolgende Tage)
    private static func calculateStreak(sessions: [StrengthSession]) -> Int {
        let calendar  = Calendar.current
        let completed = sessions.filter { $0.isCompleted }

        // Unique Trainingstage (ohne Uhrzeit), absteigend sortiert
        let uniqueDays = Array(
            Set(completed.map { calendar.startOfDay(for: $0.date) })
        ).sorted(by: >)

        guard !uniqueDays.isEmpty else { return 0 }

        let today     = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Streak ist unterbrochen wenn letztes Training nicht heute oder gestern war
        guard let lastDay = uniqueDays.first,
              lastDay == today || lastDay == yesterday else { return 0 }

        var streak   = 0
        var expected = lastDay

        for day in uniqueDays {
            if day == expected {
                streak  += 1
                expected = calendar.date(byAdding: .day, value: -1, to: expected)!
            } else if day < expected {
                break
            }
        }

        return streak
    }

    /// Berechnet die Anzahl Workouts in der aktuellen Woche (Montag bis Sonntag)
    private static func calculateWeeklyCount(sessions: [StrengthSession]) -> Int {
        let calendar    = Calendar.current
        let startOfWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)
        ) ?? .now

        return sessions.filter {
            $0.isCompleted && $0.date >= startOfWeek
        }.count
    }
}
