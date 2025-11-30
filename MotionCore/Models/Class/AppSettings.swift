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

    static let shared = AppSettings()

    // MARK: Anzeigedefaults in AppSettings

    // Anzeigedefaults: Animationen anzeigen
    @Published var showAnimatedBlob: Bool {
        didSet {
            UserDefaults.standard.set(showAnimatedBlob, forKey: "display.showAnimatedBlob")
        }
    }
    // Anzeigedefaults: Erscheinungsbild der App
    @Published var appTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(appTheme.rawValue, forKey: "display.appTheme")
        }
    }

    // MARK: Workoutdefaults in AppSettings
    // Workoutdefaults: Trainingsgerät aus Enumeration
    @Published var defaultDevice: WorkoutDevice {
        didSet {
            UserDefaults.standard.set(defaultDevice.rawValue, forKey: "workout.defaultDevice")
        }
    }

    // Workoutdefaults: Trainingsprogram als Enum
    @Published var defaultProgram: TrainingProgram {
        didSet {
            UserDefaults.standard.set(defaultProgram.rawValue, forKey: "workout.defaultProgram")
        }
    }

    // Workoutdefaults: Trainingsdauer in Minuten
    @Published var defaultDuration: Int {
        didSet {
            UserDefaults.standard.set(defaultDuration, forKey: "workout.defaultDuration")
        }
    }

    // Workoutdefaults: Schwierigkeitsgrad
    @Published var defaultDifficulty: Int {
        didSet {
            UserDefaults.standard.set(defaultDifficulty, forKey: "workout.defaultDifficulty")
        }
    }

    // Workoutdefaults: Anzeige leerer Felder
    @Published var showEmptyFields: Bool {
        didSet {
            UserDefaults.standard.set(showEmptyFields, forKey: "workout.showEmptyFields")
        }
    }

    // MARK: Userdefaults in AppSettings

    // Userdefault: Körpergröße in cm
    @Published var userBodyHeight: Int {
        didSet {
            UserDefaults.standard.set(userBodyHeight, forKey: "user.userBodyHeight")
        }
    }
    // Userdefault: Geburtsdatum des Benutzers
    @Published var userBirthdayDate: Date {
        didSet {
            UserDefaults.standard.set(userBirthdayDate, forKey: "user.userBirthdayDate")
        }
    }

    // Userdefaults: Berechnung des Alters auf Basis des Geburtsdatums
    var userAge: Int {
        let now = Date()
        let calendar = Calendar.current

        let ageComponents = calendar.dateComponents([.year], from: userBirthdayDate, to: now)

        return ageComponents.year ?? 0
    }

    // Userdefault: Benutzergeschlecht
    @Published var userGender: Gender {
        didSet {
                // Speichert den RawValue (String) der Enum
            UserDefaults.standard.set(userGender.rawValue, forKey: "user.userGender")
        }
    }

    // MARK: Health Metrics Einstellungen
    // Userdefaults: Aktivitätslevel
    @Published var userActivityLevel: UserActivityLevel {
        didSet {
            UserDefaults.standard.set(userActivityLevel.rawValue, forKey: "user.activityLevel")
        }
    }

    // Tägliches Kalorienziel
    @Published var dailyActiveCalorieGoal: Int {
        didSet {
            UserDefaults.standard.set(dailyActiveCalorieGoal, forKey: "user.dailyActiveCalorieGoal")
        }
    }

    // Tägliches Ziel an Schritten
    @Published var dailyStepsGoal: Int {
        didSet {
            UserDefaults.standard.set(dailyStepsGoal, forKey: "user.dailyStepsGoal")
        }
    }

        // Im init():

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

        if let savedDate = UserDefaults.standard.object(forKey: "user.userBirthdayDate") as? Date {
            self.userBirthdayDate = savedDate
        } else {
                // Default-Wert, z. B. heute
            self.userBirthdayDate = Date()
        }

        // Initialisiere das Geschlecht
        if let rawGender = UserDefaults.standard.string(forKey: "user.userGender"),
           let savedGender = Gender(rawValue: rawGender) {
            userGender = savedGender
        } else {
            userGender = .male // Default-Wert
        }

        // Initialisierung des Aktivitätslevel des Benutzers
        if let rawLevel = UserDefaults.standard.object(forKey: "user.activityLevel") as? Double,
           let savedLevel = UserActivityLevel(rawValue: rawLevel) {
            userActivityLevel = savedLevel
        } else {
            userActivityLevel = .moderatelyActive // Default
        }

        // Initialisiere das tägliche Kalorienziel
        dailyActiveCalorieGoal = UserDefaults.standard.integer(forKey: "user.dailyActiveCalorieGoal")

        // Initialisiere das tägliche Ziel an Schritten
        dailyStepsGoal = UserDefaults.standard.integer(forKey: "user.dailyStepsGoal")
    }
}

