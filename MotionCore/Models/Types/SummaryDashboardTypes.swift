//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : SummaryDashboardTypes.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-02                                                       /
// Beschreibung  : Typen für das gamifizierte SummaryView-Dashboard                 /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Rang-System

/// Rang-Stufen im XP-System (aufsteigend nach Level)
enum Rank: Int, CaseIterable {
    case rookie    = 0
    case athlet    = 1
    case warrior   = 2
    case champion  = 3
    case elite     = 4
    case master    = 5
    case legende   = 6

    var icon: String {
        switch self {
        case .rookie:   return "figure.walk"
        case .athlet:   return "figure.run"
        case .warrior:  return "bolt.fill"
        case .champion: return "medal.fill"
        case .elite:    return "star.fill"
        case .master:   return "crown.fill"
        case .legende:  return "flame.fill"
        }
    }

    var displayName: String {
        switch self {
        case .rookie:   return "Rookie"
        case .athlet:   return "Athlet"
        case .warrior:  return "Warrior"
        case .champion: return "Champion"
        case .elite:    return "Elite"
        case .master:   return "Master"
        case .legende:  return "Legende"
        }
    }

    /// Rang-Farbe als Hex-String für UI
    var colorHex: String {
        switch self {
        case .rookie:   return "#9CA3AF"
        case .athlet:   return "#60A5FA"
        case .warrior:  return "#34D399"
        case .champion: return "#A78BFA"
        case .elite:    return "#F59E0B"
        case .master:   return "#F97316"
        case .legende:  return "#EF4444"
        }
    }
}

// MARK: - XP-Level

/// Aktueller XP-Stand mit Level, Rang und Fortschritts-Fraction
struct XPLevel {
    let level: Int
    let totalXP: Int
    let xpForCurrentLevel: Int
    let xpRequiredForNextLevel: Int
    let rank: Rank
    let progressToNextLevel: Double         // 0.0–1.0

    var isMaxLevel: Bool { level >= 50 }
}

// MARK: - Wochenziel

/// Wochenziel-Status mit Fortschritt und Vergleich
struct WeeklyGoal {
    let target: Int
    let current: Int
    let averageLast4Weeks: Double
    let isReached: Bool
    let isAboveAverage: Bool
    let progressFraction: Double            // 0.0–1.0 (kann > 1.0 sein bei Übererfüllung)
}

// MARK: - Aktivitäts-Tag

/// Ein einzelner Tag im Aktivitäts-Grid
struct ActivityDay: Identifiable {
    let id: Date
    let date: Date
    let workoutTypes: [WorkoutType]
    let workoutCount: Int
    let isToday: Bool
}

// MARK: - Trend-Vergleich

/// Vergleich dieser Woche vs. Vorwoche
struct TrendComparison {
    let currentValue: Double
    let previousValue: Double
    let percentageChange: Double
    let trend: TrendDirection
}

/// Richtung eines Trends
enum TrendDirection {
    case up
    case down
    case stable
    case unknown
}

// MARK: - Streak-Meilenstein

/// Vordefinierte Streak-Meilensteine
enum StreakMilestone: Int, CaseIterable {
    case week7   = 7
    case week14  = 14
    case month30 = 30
    case month60 = 60
    case days100 = 100

    var icon: String {
        switch self {
        case .week7:   return "flame"
        case .week14:  return "flame.fill"
        case .month30: return "medal"
        case .month60: return "medal.fill"
        case .days100: return "crown.fill"
        }
    }

    var text: String {
        switch self {
        case .week7:   return "7 Tage Streak!"
        case .week14:  return "2 Wochen Streak!"
        case .month30: return "30 Tage Streak!"
        case .month60: return "2 Monate Streak!"
        case .days100: return "100 Tage Legende!"
        }
    }
}

// MARK: - XP-Gewinn

/// Einzelner XP-Gewinn aus einem Workout
struct XPGain: Identifiable {
    let id: UUID
    let description: String
    let xpAmount: Int
    let date: Date

    init(description: String, xpAmount: Int, date: Date) {
        self.id = UUID()
        self.description = description
        self.xpAmount = xpAmount
        self.date = date
    }
}

// MARK: - Motivations-Kontext

/// Begrüßungs- und Motivationstext für die Hero-Card
struct MotivationalContext {
    let greeting: String
    let motivationalText: String
}
