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
    @Published var showAnimatedBlob: Bool {
        didSet {
            UserDefaults.standard.set(showAnimatedBlob, forKey: "display.showAnimatedBlob")
        }
    }

    // MARK: - Workout Settings
    // Default Device als Enum
    @Published var defaultDevice: WorkoutDevice {
        didSet {
            UserDefaults.standard.set(defaultDevice.rawValue, forKey: "workout.defaultDevice")
        }
    }

    // Default Program als Enum
    @Published var defaultProgram: TrainingProgram {
        didSet {
            UserDefaults.standard.set(defaultProgram.rawValue, forKey: "workout.defaultProgram")
        }
    }

    // Default Duration in Minuten
    @Published var defaultDuration: Int {
        didSet {
            UserDefaults.standard.set(defaultDuration, forKey: "workout.defaultDuration")
        }
    }

        // Default Schwierigkeitsgrad
    @Published var defaultDifficulty: Int {
            didSet {
                UserDefaults.standard.set(defaultDifficulty, forKey: "workout.defaultDifficulty")
            }
        }

    @Published var showEmptyFields: Bool {
        didSet {
            UserDefaults.standard.set(showEmptyFields, forKey: "workout.showEmptyFields")
        }
    }

    // MARK: - Init

    private init() {
        let defaults = UserDefaults.standard

        // Display
        self.showAnimatedBlob = defaults.bool(forKey: "display.showAnimatedBlob")

        // Workout: Device
        let deviceRaw = defaults.integer(forKey: "workout.defaultDevice")
        self.defaultDevice = WorkoutDevice(rawValue: deviceRaw) ?? .none

        // Workout: Program
        let programRaw = defaults.string(forKey: "workout.defaultProgram") ?? "manual"
        self.defaultProgram = TrainingProgram(rawValue: programRaw) ?? .manual

        // Workout: Duration
        self.defaultDuration = defaults.integer(forKey: "workout.defaultDuration")

        // Workout: Intensity
        self.defaultDifficulty = defaults.integer(forKey: "workout.defaultDifficulty")

        // Workout: Show Empty Fields
        self.showEmptyFields = defaults.bool(forKey: "workout.showEmptyFields")
    }
}
