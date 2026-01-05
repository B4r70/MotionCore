// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Models                                                           /
// Datei . . . . : ActiveWorkoutResumeState.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 02.01.2026                                                       /
// Beschreibung  : Datenmodell für den Wiederherstellungszustand aktiver Workouts   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

struct SessionResumeState: Codable {
    let sessionID: String
    let workoutType: String

    let isPaused: Bool
    let elapsedSeconds: Int

    let workoutStartDate: Date

    let isResting: Bool
    let restEndDate: Date?

    let selectedExerciseKey: String?

    let updatedAt: Date
}
