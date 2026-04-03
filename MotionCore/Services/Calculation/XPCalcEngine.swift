//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Berechnung                                            /
// Datei . . . . : XPCalcEngine.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-02                                                       /
// Beschreibung  : Berechnet XP, Level und motivationalen Kontext                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - XP-Berechnungs-Engine

/// Pure struct — kein State, kein SwiftUI.
struct XPCalcEngine {

    // MARK: - Eingabe

    let cardioSessions: [CardioSession]
    let strengthSessions: [StrengthSession]
    let outdoorSessions: [OutdoorSession]
    let weeklyGoal: Int
    let strengthRecordDates: [Date]

    // MARK: - Hilfskonstanten

    /// XP-Basis pro Workout
    private let baseXP = 100
    /// XP pro Trainingsminute
    private let xpPerMinute = 1
    /// Streak-Bonus pro Tag (begrenzt)
    private let streakBonusPerDay = 10
    /// Maximaler Streak-Bonus
    private let maxStreakBonus = 500
    /// XP für persönlichen Rekord
    private let prXP = 250
    /// XP für erreichtes Wochenziel
    private let weeklyGoalXP = 200
    /// Konsistenz-Bonus (4 Wochen in Folge Ziel erreicht)
    private let consistencyBonusXP = 500

    // MARK: - Gesamt-XP Berechnung

    /// Berechnet den gesamten XP-Stand aus allen Sessions.
    /// Iteriert chronologisch über alle Session-Typen.
    func calculateTotalXP() -> Int {
        // Alle Sessions chronologisch sortieren
        var allEvents: [(date: Date, xp: Int)] = []

        for session in cardioSessions {
            allEvents.append((session.date, xpForCardio(session)))
        }

        for session in strengthSessions {
            allEvents.append((session.date, xpForStrength(session)))
        }

        for session in outdoorSessions {
            allEvents.append((session.date, xpForOutdoor(session)))
        }

        // PR-Bonus für Rekord-Daten
        for _ in strengthRecordDates {
            allEvents.append((Date(), prXP))
        }

        // Wochenziel-Boni berechnen
        let weeklyBonusXP = calculateWeeklyGoalBonuses()
        allEvents.append((Date(), weeklyBonusXP))

        // Gesamt-XP summieren
        return allEvents.map { $0.xp }.reduce(0, +)
    }

    // MARK: - Level-Berechnung

    /// Berechnet Level und Rang aus Gesamt-XP.
    /// Schwelle Level N: 500 × N × (N+1) / 2
    func calculateLevel(totalXP: Int) -> XPLevel {
        let maxLevel = 50
        var level = 0

        // Level-Schwellen aufsteigend prüfen
        for n in 1...maxLevel {
            let threshold = 500 * n * (n + 1) / 2
            if totalXP >= threshold {
                level = n
            } else {
                break
            }
        }

        // XP für aktuelles und nächstes Level berechnen
        let xpForCurrent = level > 0 ? 500 * level * (level + 1) / 2 : 0
        let xpForNext = level < maxLevel ? 500 * (level + 1) * (level + 2) / 2 : xpForCurrent + 1
        let xpInCurrentLevel = totalXP - xpForCurrent
        let xpRequiredForNext = xpForNext - xpForCurrent

        // Fortschritts-Fraction berechnen
        let progress: Double
        if level >= maxLevel {
            progress = 1.0
        } else {
            progress = xpRequiredForNext > 0
                ? min(1.0, Double(xpInCurrentLevel) / Double(xpRequiredForNext))
                : 0.0
        }

        // Rang bestimmen (7 Ränge, gleichmäßig auf 50 Level verteilt)
        let rankIndex = min(Rank.allCases.count - 1, level * Rank.allCases.count / (maxLevel + 1))
        let rank = Rank(rawValue: rankIndex) ?? .rookie

        return XPLevel(
            level: level,
            totalXP: totalXP,
            xpForCurrentLevel: xpForCurrent,
            xpRequiredForNextLevel: xpRequiredForNext,
            rank: rank,
            progressToNextLevel: progress
        )
    }

    // MARK: - Letzte XP-Gewinne

    /// Gibt die letzten N Workouts als XPGain-Liste zurück.
    func recentXPGains(lastCount: Int = 6) -> [XPGain] {
        // Alle Sessions zusammenführen und sortieren
        var gains: [XPGain] = []

        for session in cardioSessions {
            gains.append(XPGain(
                description: session.cardioDevice == .none ? "Cardio" : session.cardioDevice.description,
                xpAmount: xpForCardio(session),
                date: session.date
            ))
        }

        for session in strengthSessions {
            gains.append(XPGain(
                description: "Krafttraining",
                xpAmount: xpForStrength(session),
                date: session.date
            ))
        }

        for session in outdoorSessions {
            gains.append(XPGain(
                description: session.outdoorActivity.description,
                xpAmount: xpForOutdoor(session),
                date: session.date
            ))
        }

        // Nach Datum absteigend sortieren, nur letzte N zurückgeben
        return gains
            .sorted { $0.date > $1.date }
            .prefix(lastCount)
            .map { $0 }
    }

    // MARK: - Motivations-Kontext

    /// Erstellt kontextabhängigen Begrüßungs- und Motivationstext.
    /// Prioritäts-Reihenfolge: Streak-Meilenstein → Wochenziel → Streak-aktiv → Willkommen-zurück → Standard
    func motivationalContext(
        streak: Int,
        workoutsThisWeek: Int,
        weeklyGoal: Int,
        lastWorkoutDate: Date?
    ) -> MotivationalContext {
        let greeting = todayGreeting()

        // 1. Streak-Meilenstein
        if let milestone = StreakCalcEngine.currentMilestone(streak: streak) {
            return MotivationalContext(
                greeting: greeting,
                motivationalText: "\(milestone.icon) \(milestone.text) Beeindruckend!"
            )
        }

        // 2. Wochenziel heute erreicht
        if workoutsThisWeek >= weeklyGoal && weeklyGoal > 0 {
            return MotivationalContext(
                greeting: greeting,
                motivationalText: "Wochenziel erreicht! Du hast \(workoutsThisWeek)/\(weeklyGoal) Workouts abgeschlossen."
            )
        }

        // 3. Aktive Streak > 3
        if streak > 3 {
            return MotivationalContext(
                greeting: greeting,
                motivationalText: "\(streak) Tage in Folge — bleib dran!"
            )
        }

        // 4. Willkommen-zurück nach Pause
        if let lastDate = lastWorkoutDate {
            let days = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            if days >= 3 {
                return MotivationalContext(
                    greeting: greeting,
                    motivationalText: "Willkommen zurück! Heute ist ein guter Tag zum Trainieren."
                )
            }
        }

        // 5. Standard-Motivationstext
        let texts = [
            "Leg los — jedes Workout zählt.",
            "Heute besser als gestern.",
            "Konsistenz schlägt Intensität.",
            "Du bist \(workoutsThisWeek) von \(weeklyGoal) Workouts diese Woche."
        ]
        let index = Calendar.current.component(.weekday, from: Date()) % texts.count
        return MotivationalContext(greeting: greeting, motivationalText: texts[index])
    }

    // MARK: - Private Helpers

    /// XP für eine Cardio-Session berechnen
    private func xpForCardio(_ session: CardioSession) -> Int {
        var xp = baseXP
        xp += session.duration * xpPerMinute
        return xp
    }

    /// XP für eine Kraft-Session berechnen
    private func xpForStrength(_ session: StrengthSession) -> Int {
        var xp = baseXP
        xp += session.duration * xpPerMinute
        return xp
    }

    /// XP für eine Outdoor-Session berechnen
    private func xpForOutdoor(_ session: OutdoorSession) -> Int {
        var xp = baseXP
        xp += session.duration * xpPerMinute
        return xp
    }

    /// Wochenziel-Boni der letzten 4 Wochen summieren
    private func calculateWeeklyGoalBonuses() -> Int {
        guard weeklyGoal > 0 else { return 0 }
        let calendar = Calendar.current
        let now = Date()
        var totalBonus = 0
        var consecutiveWeeks = 0

        for weekOffset in 1...4 {
            guard
                let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
                let weekEnd = calendar.date(byAdding: .weekOfYear, value: -(weekOffset - 1), to: now)
            else { continue }

            let cardioCount = cardioSessions.filter { $0.date >= weekStart && $0.date < weekEnd }.count
            let strengthCount = strengthSessions.filter { $0.date >= weekStart && $0.date < weekEnd }.count
            let outdoorCount = outdoorSessions.filter { $0.date >= weekStart && $0.date < weekEnd }.count
            let total = cardioCount + strengthCount + outdoorCount

            if total >= weeklyGoal {
                totalBonus += weeklyGoalXP
                consecutiveWeeks += 1
            }
        }

        // Konsistenz-Bonus: 4 Wochen in Folge
        if consecutiveWeeks >= 4 {
            totalBonus += consistencyBonusXP
        }

        return totalBonus
    }

    /// Tageszeit-abhängige Begrüßung
    private func todayGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Guten Morgen"
        case 12..<17: return "Guten Tag"
        case 17..<22: return "Guten Abend"
        default:      return "Hallo"
        }
    }
}
