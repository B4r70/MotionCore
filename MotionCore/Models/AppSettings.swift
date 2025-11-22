//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Einstellungen                                                    /
// Datei . . . . : AppSettings.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 11.11.2025                                                       /
// Beschreibung  : Zentrale Verwaltung der App-Einstellungen                        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Combine
import SwiftUI

// MARK: - App Settings Manager

class AppSettings: ObservableObject {
    // Singleton
    static let shared = AppSettings()

    // MARK: - Display Settings
    // Animationen anzeigen
    @Published var showAnimatedBlob: Bool {
        didSet {
            UserDefaults.standard.set(showAnimatedBlob, forKey: "display.showAnimatedBlob")
        }
    }
    // Erscheinungsbild
    @Published var appTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(appTheme.rawValue, forKey: "display.appTheme")
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

    // Konfig Anzeige leerer Felder
    @Published var showEmptyFields: Bool {
        didSet {
            UserDefaults.standard.set(showEmptyFields, forKey: "workout.showEmptyFields")
        }
    }

    // Benutzergröße in cm
    @Published var userBodyHeight: Int {
        didSet {
            UserDefaults.standard.set(userBodyHeight, forKey: "user.userBodyHeight")
        }
    }

    // Benutzeralter in Jahren
    @Published var userAge: Int {
        didSet {
            UserDefaults.standard.set(userAge, forKey: "user.userAge")
        }
    }

    // Benutzergeschlecht
    @Published var userGender: Gender {
        didSet {
                // Speichert den RawValue (String) der Enum
            UserDefaults.standard.set(userGender.rawValue, forKey: "user.userGender")
        }
    }

    // MARK: - Init
    private init() {
        let defaults = UserDefaults.standard

        // Display: Animierter Hintergrund
        showAnimatedBlob = defaults.bool(forKey: "display.showAnimatedBlob")

        // Theme aus UserDefaults laden (oder .system, wenn nichts gesetzt)
        if let raw = UserDefaults.standard.string(forKey: "display.appTheme"),
           let loaded = AppTheme(rawValue: raw) {
            self.appTheme = loaded
        } else {
            self.appTheme = .system
        }

        // Workout: Device
        let deviceRaw = defaults.integer(forKey: "workout.defaultDevice")
        defaultDevice = WorkoutDevice(rawValue: deviceRaw) ?? .none

        // Workout: Program
        let programRaw = defaults.string(forKey: "workout.defaultProgram") ?? "manual"
        defaultProgram = TrainingProgram(rawValue: programRaw) ?? .manual

        // Workout: Duration
        defaultDuration = defaults.integer(forKey: "workout.defaultDuration")

        // Workout: Intensity
        defaultDifficulty = defaults.integer(forKey: "workout.defaultDifficulty")

        // Workout: Show Empty Fields
        showEmptyFields = defaults.bool(forKey: "workout.showEmptyFields")

        // Initialisiere die Körpergröße
        userBodyHeight = UserDefaults.standard.integer(forKey: "user.userBodyHeight")

        // Initialisiere das Alter
        userAge = UserDefaults.standard.integer(forKey: "user.userAge")

        // Initialisiere das Geschlecht
        if let rawGender = UserDefaults.standard.string(forKey: "user.userGender"),
           let savedGender = Gender(rawValue: rawGender) {
            userGender = savedGender
        } else {
            userGender = .male // Default-Wert
        }
    }
}
