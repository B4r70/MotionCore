///---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : AppSettings.swift                                                /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 11.11.2025                                                       /
// Function . . : Zentrale Verwaltung der App-Einstellungen                        /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI
import Combine

// MARK: - App Settings Manager
class AppSettings: ObservableObject {
    // Singleton
    static let shared = AppSettings()

    // MARK: - Display Settings
    @AppStorage("display.showAnimatedBlob")
    var showAnimatedBlob: Bool = false

    // MARK: - Workout Settings
    @AppStorage("workout.defaultDevice")
    var defaultDevice: Int = 0  // WorkoutDevice.none

    @AppStorage("workout.defaultProgram")
    var defaultProgram: String = "manual"

    @AppStorage("workout.showEmptyFields")
    var showEmptyFields: Bool = false

    private init() {}
}
