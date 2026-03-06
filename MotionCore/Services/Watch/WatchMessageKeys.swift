//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Watch Integration                                                /
// Datei . . . . : WatchMessageKeys.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.03.2026                                                       /
// Beschreibung  : Gemeinsame Message-Konstanten für WatchConnectivity              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - State Keys (iPhone → Watch)

/// Keys für State-Updates vom iPhone zur Watch
enum WatchStateKey {
    static let workoutState   = "workoutState"
    static let exerciseName   = "exerciseName"
    static let setIndex       = "setIndex"
    static let totalSets      = "totalSets"
    static let exerciseIndex  = "exerciseIndex"
    static let totalExercises = "totalExercises"
    static let elapsedTime    = "elapsedTime"
}

/// Mögliche Werte für workoutState
enum WatchWorkoutState: String {
    case idle   = "idle"
    case active = "active"
    case paused = "paused"
}

// MARK: - Action Keys (Watch → iPhone)

/// Keys für Actions von der Watch zum iPhone
enum WatchActionKey {
    static let action = "action"
}

/// Mögliche Actions von der Watch
enum WatchAction: String {
    case pauseResume      = "pauseResume"
    case completeSet      = "completeSet"
    case nextExercise     = "nextExercise"
    case previousExercise = "previousExercise"
}

// MARK: - App Group UserDefaults Keys (für Complications)

/// Keys für Complications-Daten in der App Group
enum WatchComplicationKey {
    static let streakCount        = "watch_streak_count"
    static let weeklyWorkoutCount = "watch_weekly_workout_count"
    static let weeklyWorkoutGoal  = "watch_weekly_workout_goal"
}
