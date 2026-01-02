//
//  ActiveWorkoutResumeState.swift
//  MotionCore
//
//  Created by Barto on 02.01.26.
//


import Foundation

struct ActiveWorkoutResumeState: Codable {
    let sessionID: String
    let workoutType: String

    let isPaused: Bool
    let elapsedSeconds: Int

    let workoutStartDate: Date

    let isResting: Bool
    let restEndDate: Date?

    let selectedExerciseIndex: Int?

    let updatedAt: Date
}