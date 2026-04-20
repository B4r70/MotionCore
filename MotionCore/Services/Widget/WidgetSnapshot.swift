//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Widget                                                /
// Datei . . . . : WidgetSnapshot.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-20                                                       /
// Beschreibung  : Codable Snapshot-Struct für Widget-Daten (App-Target)            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Identische Struct-Definitionen existieren im Widget-Extension     /
//                Target (MotionCoreWidgets/Shared/WidgetSnapshot.swift).            /
//                Änderungen müssen in beiden Dateien synchron gepflegt werden.     /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Widget Snapshot

/// Vollständiger Snapshot aller Widget-relevanten Daten.
/// Wird vom WidgetSnapshotPublisher (Main App) geschrieben
/// und vom MotionCoreTimelineProvider (Widget Extension) gelesen.
struct WidgetSnapshot: Codable {

    // MARK: - Streak-Daten

    let streak: StreakInfo

    // MARK: - Wöchentlicher Fortschritt

    let weeklyProgress: WeeklyProgress

    // MARK: - Letztes Workout

    let lastWorkout: LastWorkoutSummary?

    // MARK: - Big-3 PRs

    let big3PRs: [PRItem]

    // MARK: - 4-Wochen-Volumen-Trend

    let volumeTrend: [VolumeTrendPoint]

    // MARK: - Zeitstempel

    let updatedAt: Date
}

// MARK: - Sub-Structs

/// Streak-Informationen für Anzeige und Ring-Fortschritt
struct StreakInfo: Codable {
    let currentStreak: Int
    let longestStreak: Int
}

/// Wöchentlicher Trainings-Fortschritt
struct WeeklyProgress: Codable {
    let completed: Int
    let goal: Int

    /// Fortschritt als Wert zwischen 0.0 und 1.0
    var fraction: Double {
        guard goal > 0 else { return 0 }
        return min(Double(completed) / Double(goal), 1.0)
    }
}

/// Zusammenfassung des letzten abgeschlossenen Workouts
struct LastWorkoutSummary: Codable {
    let date: Date
    let durationMinutes: Int
    let totalVolumeKg: Double
    let topExerciseName: String
    let completedSets: Int
}

/// Ein PR-Eintrag (Big-3)
struct PRItem: Codable, Identifiable {
    var id: String { exerciseName }
    let exerciseName: String
    /// Geschätztes 1RM in kg (Epley-Formel)
    let weight1RMkg: Double
}

/// Ein Wochenvolumen-Datenpunkt für den 4-Wochen-Trend-Chart
struct VolumeTrendPoint: Codable, Identifiable {
    var id: String { weekLabel }
    let weekLabel: String
    let volumeKg: Double
}
