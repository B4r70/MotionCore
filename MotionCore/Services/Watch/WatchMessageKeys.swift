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
// Hinweis: Diese Datei ist in beiden Targets identisch (MotionCore + MotionCoreWatch).
// Änderungen müssen in beiden Dateien synchron gepflegt werden.

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
    /// Gibt an ob gerade ein Rest-Timer auf dem iPhone läuft
    static let isResting      = "isResting"
    /// Absolutes Enddatum des Rest-Timers als TimeInterval (Date.timeIntervalSinceReferenceDate)
    static let restEndDate    = "restEndDate"
}

/// Mögliche Werte für workoutState
enum WatchWorkoutState: String {
    case idle
    case active
    case paused
}

// MARK: - Action Keys (Watch → iPhone)

/// Keys für Actions von der Watch zum iPhone
enum WatchActionKey {
    static let action = "action"
}

/// Mögliche Actions von der Watch
enum WatchAction: String {
    case pauseResume
    case completeSet
    case nextExercise
    case previousExercise
    /// Überspringt den aktuell laufenden Rest-Timer auf dem iPhone
    case skipRest
}

// MARK: - App Group

/// Zentrale Konstante für den App-Group-Identifier und den zugehörigen UserDefaults-Container
enum WatchAppGroup {
    static let identifier = "group.com.barto.motioncore"
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }
}

// MARK: - App Group UserDefaults Keys (für Complications)

/// Keys für Complications-Daten in der App Group
enum WatchComplicationKey {
    static let streakCount        = "watch_streak_count"
    static let weeklyWorkoutCount = "watch_weekly_workout_count"
    static let weeklyWorkoutGoal  = "watch_weekly_workout_goal"
}
