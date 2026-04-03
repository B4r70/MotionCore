//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Berechnung                                            /
// Datei . . . . : StreakCalcEngine.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-02                                                       /
// Beschreibung  : Berechnet Trainings-Streaks und Meilensteine                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Streak-Berechnungs-Engine

/// Pure struct — kein State, kein SwiftUI.
/// Streak-Logik aus SummaryCalcEngine extrahiert.
struct StreakCalcEngine {

    // MARK: - Eingabe

    /// Alle Trainingstage (Rohdaten, darf Duplikate enthalten)
    let allTrainingDays: [Date]

    // MARK: - Initialisierung

    init(allTrainingDays: [Date]) {
        self.allTrainingDays = allTrainingDays
    }

    // MARK: - Bereingte Trainingstage

    /// Einzigartige Trainingstage als sortiertes Array (neueste zuerst)
    var uniqueTrainingDays: [Date] {
        let calendar = Calendar.current
        return Set(allTrainingDays.map { calendar.startOfDay(for: $0) })
            .sorted(by: >)
    }

    // MARK: - Aktuelle Streak

    /// Aktuelle Trainings-Streak (aufeinanderfolgende Tage mit Training).
    /// Zählt auch wenn das letzte Training gestern war (Streak noch aktiv).
    var currentStreak: Int {
        let uniqueDays = uniqueTrainingDays

        guard !uniqueDays.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }

        // Prüfen ob das letzte Training heute oder gestern war
        guard let lastTrainingDay = uniqueDays.first,
              lastTrainingDay == today || lastTrainingDay == yesterday else {
            return 0
        }

        // Streak zählen, beginnend vom letzten Trainingstag
        var streak = 0
        var expectedDate = lastTrainingDay

        for day in uniqueDays {
            if day == expectedDate {
                streak += 1
                guard let next = calendar.date(byAdding: .day, value: -1, to: expectedDate) else { break }
                expectedDate = next
            } else if day < expectedDate {
                // Lücke gefunden — Streak beenden
                break
            }
        }

        return streak
    }

    // MARK: - Längste Streak

    /// Längste Trainings-Streak aller Zeiten
    var longestStreak: Int {
        let uniqueDays = uniqueTrainingDays.sorted() // Älteste zuerst
        guard !uniqueDays.isEmpty else { return 0 }

        let calendar = Calendar.current
        var maxStreak = 1
        var currentStreakCount = 1

        for i in 1..<uniqueDays.count {
            let daysBetween = calendar.dateComponents(
                [.day],
                from: uniqueDays[i - 1],
                to: uniqueDays[i]
            ).day ?? 0

            if daysBetween == 1 {
                currentStreakCount += 1
                maxStreak = max(maxStreak, currentStreakCount)
            } else {
                currentStreakCount = 1
            }
        }

        return maxStreak
    }

    // MARK: - Streak-Meilensteine

    /// Gibt den erreichten Meilenstein zurück (wenn Streak ≥ Meilenstein-Wert)
    func currentMilestone(streak: Int) -> StreakMilestone? {
        StreakCalcEngine.currentMilestone(streak: streak)
    }

    /// Gibt den nächsten zu erreichenden Meilenstein zurück
    func nextMilestone(streak: Int) -> StreakMilestone? {
        StreakCalcEngine.nextMilestone(streak: streak)
    }

    // MARK: - Statische Hilfsmethoden (für XPCalcEngine verwendbar)

    /// Gibt den zuletzt erreichten Meilenstein zurück (statisch)
    static func currentMilestone(streak: Int) -> StreakMilestone? {
        StreakMilestone.allCases
            .filter { streak >= $0.rawValue }
            .max { $0.rawValue < $1.rawValue }
    }

    /// Gibt den nächsten Meilenstein zurück (statisch)
    static func nextMilestone(streak: Int) -> StreakMilestone? {
        StreakMilestone.allCases
            .filter { streak < $0.rawValue }
            .min { $0.rawValue < $1.rawValue }
    }
}
