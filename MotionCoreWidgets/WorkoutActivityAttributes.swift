//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Live Activity                                                    /
// Datei . . . . : WorkoutActivityAttributes.swift                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 02.01.2026                                                       /
// Beschreibung  : Datenstruktur für Workout Live Activity                          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import ActivityKit
import Foundation

public struct WorkoutActivityAttributes: ActivityAttributes {

    // MARK: - Dynamic data (changes during the workout)

    public struct ContentState: Codable, Hashable {

        // Workout timer (system-side ticking via Date)
        public var workoutStartDate: Date

        // Pause handling
        public var isPaused: Bool
        public var elapsedAtPause: Int?

        // Current exercise
        public var currentExercise: String?
        public var currentSet: String?

        // Rest timer (system-side countdown via Date)
        public var isResting: Bool
        public var restEndDate: Date?

        // Progress
        public var completedSets: Int
        public var totalSets: Int

        // MARK: - Public initializer

        public init(
            workoutStartDate: Date,
            isPaused: Bool,
            elapsedAtPause: Int? = nil,
            currentExercise: String? = nil,
            currentSet: String? = nil,
            isResting: Bool,
            restEndDate: Date? = nil,
            completedSets: Int,
            totalSets: Int
        ) {
            self.workoutStartDate = workoutStartDate
            self.isPaused = isPaused
            self.elapsedAtPause = elapsedAtPause
            self.currentExercise = currentExercise
            self.currentSet = currentSet
            self.isResting = isResting
            self.restEndDate = restEndDate
            self.completedSets = completedSets
            self.totalSets = totalSets
        }
    }

    // MARK: - Static data (does not change)
    public var sessionID: String
    public var workoutType: String
    public var planName: String?

    public init(
        sessionID: String,
        workoutType: String,
        planName: String?
    ) {
        self.sessionID = sessionID
        self.workoutType = workoutType
        self.planName = planName
    }
    
}
