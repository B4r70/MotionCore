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

    // Anzeigedefaults: Anzeige Exercise Display
    @Published var showExerciseVideos: Bool {
        didSet {
            UserDefaults.standard.set(showExerciseVideos, forKey: "display.showExerciseVideos")
        }
    }

    // MARK: Workoutdefaults in AppSettings
    // Workoutdefaults: Trainingsgerät aus Enumeration
    @Published var defaultDevice: CardioDevice {
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

    // Workoutdefaults: Haptic Feedback beim Rest-Timer
    @Published var enableRestTimerHaptic: Bool {
        didSet {
            UserDefaults.standard.set(enableRestTimerHaptic, forKey: "workout.enableRestTimerHaptic")
        }
    }

    // Workoutdefaults: Standard-Pausenzeit in Sekunden (falls nicht im Set definiert)
    @Published var defaultRestTime: Int {
        didSet {
            UserDefaults.standard.set(defaultRestTime, forKey: "workout.defaultRestTime")
        }
    }

    // MARK: Userdefaults in AppSettings
/*
    // Userdefault: Vorname des Benutzers
    @Published var userSurname: String {
        didSet {
            UserDefaults.standard.set(userSurname, forKey: "user.userSurname")
        }
    }

        // Userdefault: Nachname des Benutzers
    @Published var userLastName: String {
        didSet {
            UserDefaults.standard.set(userLastName, forKey: "user.userLastName")
        }
    }
*/
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

    // MARK: - Wochenziel

    // Wochenziel: Anzahl Workouts pro Woche (Range 1–7, Default: 4)
    @Published var weeklyWorkoutGoal: Int {
        didSet {
            UserDefaults.standard.set(weeklyWorkoutGoal, forKey: "workout.weeklyWorkoutGoal")
        }
    }

    // MARK: - Smart Plan-Update

    // Smart Plan-Update: aktiviert/deaktiviert den automatischen Vorschlag nach Session-Ende
    @Published var smartPlanUpdateEnabled: Bool {
        didSet {
            UserDefaults.standard.set(smartPlanUpdateEnabled, forKey: "workout.smartPlanUpdateEnabled")
        }
    }

    // Minimale Gewichtsdifferenz (in kg) damit eine Änderung als Trend gilt
    @Published var planUpdateMinWeightDelta: Double {
        didSet {
            UserDefaults.standard.set(planUpdateMinWeightDelta, forKey: "workout.planUpdateMinWeightDelta")
        }
    }

    // Minimale Wiederholungsdifferenz damit eine Änderung als Trend gilt
    @Published var planUpdateMinRepsDelta: Int {
        didSet {
            UserDefaults.standard.set(planUpdateMinRepsDelta, forKey: "workout.planUpdateMinRepsDelta")
        }
    }

    // Anzahl der Sessions die für die Trend-Erkennung herangezogen werden
    @Published var planUpdateTrendSessionCount: Int {
        didSet {
            UserDefaults.standard.set(planUpdateTrendSessionCount, forKey: "workout.planUpdateTrendSessionCount")
        }
    }

    // MARK: - E-Bike Profil

    // E-Bike: Name des Fahrrads
    @Published var eBikeName: String {
        didSet { UserDefaults.standard.set(eBikeName, forKey: "ebike.name") }
    }

    // E-Bike: Fahrradtyp als Rohwert (String)
    @Published var eBikeTypeRaw: String {
        didSet { UserDefaults.standard.set(eBikeTypeRaw, forKey: "ebike.type") }
    }

    // E-Bike: Typisierter Fahrradtyp (berechnete Property)
    var eBikeType: BikeType {
        get { BikeType(rawValue: eBikeTypeRaw) ?? .eBikeTrekking }
        set { eBikeTypeRaw = newValue.rawValue }
    }

    // E-Bike: Rahmengröße in cm
    @Published var eBikeFrameSize: Int {
        didSet { UserDefaults.standard.set(eBikeFrameSize, forKey: "ebike.frameSize") }
    }

    // E-Bike: Gewicht des Fahrrads in kg
    @Published var eBikeWeight: Double {
        didSet { UserDefaults.standard.set(eBikeWeight, forKey: "ebike.weight") }
    }

    // E-Bike: Akkukapazität in Wh
    @Published var eBikeBatteryCapacity: Int {
        didSet { UserDefaults.standard.set(eBikeBatteryCapacity, forKey: "ebike.batteryCapacity") }
    }

    // E-Bike: Reifengröße als Rohwert (String)
    @Published var eBikeTireSizeRaw: String {
        didSet { UserDefaults.standard.set(eBikeTireSizeRaw, forKey: "ebike.tireSize") }
    }

    // E-Bike: Typisierte Reifengröße (berechnete Property)
    var eBikeTireSize: TireSize {
        get { TireSize(rawValue: eBikeTireSizeRaw) ?? .t28 }
        set { eBikeTireSizeRaw = newValue.rawValue }
    }

    // E-Bike: Fahrradzustand als Rohwert (Int)
    @Published var eBikeConditionRaw: Int {
        didSet { UserDefaults.standard.set(eBikeConditionRaw, forKey: "ebike.condition") }
    }

    // E-Bike: Typisierter Fahrradzustand (berechnete Property)
    var eBikeCondition: BikeCondition {
        get { BikeCondition(rawValue: eBikeConditionRaw) ?? .good }
        set { eBikeConditionRaw = newValue.rawValue }
    }

    // E-Bike: Aktueller Kilometerstand
    @Published var eBikeKilometers: Double {
        didSet { UserDefaults.standard.set(eBikeKilometers, forKey: "ebike.kilometers") }
    }

    // E-Bike: Kaufdatum (optional)
    @Published var eBikePurchaseDate: Date? {
        didSet { UserDefaults.standard.set(eBikePurchaseDate, forKey: "ebike.purchaseDate") }
    }

    // E-Bike: Wartungsintervall in km
    @Published var eBikeMaintenanceIntervalKm: Double {
        didSet { UserDefaults.standard.set(eBikeMaintenanceIntervalKm, forKey: "ebike.maintenanceIntervalKm") }
    }

    // E-Bike: Datum der letzten Wartung (optional)
    @Published var eBikeLastMaintenanceDate: Date? {
        didSet { UserDefaults.standard.set(eBikeLastMaintenanceDate, forKey: "ebike.lastMaintenanceDate") }
    }

    // E-Bike: Freitextnotizen zum Fahrrad
    @Published var eBikeNotes: String {
        didSet { UserDefaults.standard.set(eBikeNotes, forKey: "ebike.notes") }
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

    // MARK: - Tagesform / Medikation

    // Nutzer nimmt kreislaufwirksame Medikamente (z.B. Betablocker) — modifiziert Readiness-Berechnung ab Phase 2
    @Published var takesCardioMedication: Bool {
        didSet {
            UserDefaults.standard.set(takesCardioMedication, forKey: "health.takesCardioMedication")
        }
    }

    // Debug-Override für den Readiness-Score (nur im DEBUG-Build).
    // -1 = kein Override (echter Score wird verwendet).
    @Published var debugReadinessScoreOverride: Int {
        didSet {
            UserDefaults.standard.set(debugReadinessScoreOverride, forKey: "debug.readinessScoreOverride")
        }
    }

        // Im init():

    // MARK: - Init
    private init() {
        let defaults = UserDefaults.standard

        // Display: Animierter Hintergrund
        showAnimatedBlob = defaults.bool(forKey: "display.showAnimatedBlob")

        // Display: Theme aus UserDefaults laden (oder .system, wenn nichts gesetzt)
        if let raw = defaults.string(forKey: "display.appTheme"),
           let loaded = AppTheme(rawValue: raw) {
            appTheme = loaded
        } else {
            appTheme = .system
        }

        // Display: Übungsvideos anzeigen (Default: true)
        showExerciseVideos = defaults.object(forKey: "display.showExerciseVideos") as? Bool ?? true

        // Workout: Device
        let deviceRaw = defaults.integer(forKey: "workout.defaultDevice")
        defaultDevice = CardioDevice(rawValue: deviceRaw) ?? .none

        // Workout: Program
        let programRaw = defaults.string(forKey: "workout.defaultProgram") ?? "manual"
        defaultProgram = TrainingProgram(rawValue: programRaw) ?? .manual

        // Workout: Duration
        defaultDuration = defaults.integer(forKey: "workout.defaultDuration")

        // Workout: Intensity
        defaultDifficulty = defaults.integer(forKey: "workout.defaultDifficulty")

        // Workout: Show Empty Fields
        showEmptyFields = defaults.bool(forKey: "workout.showEmptyFields")

        // Rest-Timer: Haptic Feedback (Default: true)
        enableRestTimerHaptic = defaults.object(forKey: "workout.enableRestTimerHaptic") as? Bool ?? true

        // Rest-Timer: Standard-Pausenzeit (Default: 90 Sekunden)
        defaultRestTime = defaults.object(forKey: "workout.defaultRestTime") as? Int ?? 90

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

        // Wochenziel: Workouts pro Woche (Default: 4)
        weeklyWorkoutGoal = defaults.object(forKey: "workout.weeklyWorkoutGoal") as? Int ?? 4

        // Smart Plan-Update: aktiviert (Default: true)
        smartPlanUpdateEnabled = defaults.object(forKey: "workout.smartPlanUpdateEnabled") as? Bool ?? true

        // Smart Plan-Update: Gewichts-Schwelle (Default: 2.5 kg)
        planUpdateMinWeightDelta = defaults.object(forKey: "workout.planUpdateMinWeightDelta") as? Double ?? 2.5

        // Smart Plan-Update: Reps-Schwelle (Default: 2)
        planUpdateMinRepsDelta = defaults.object(forKey: "workout.planUpdateMinRepsDelta") as? Int ?? 2

        // Smart Plan-Update: Trend-Sessions (Default: 3)
        planUpdateTrendSessionCount = defaults.object(forKey: "workout.planUpdateTrendSessionCount") as? Int ?? 3

        // Initialisiere das tägliche Kalorienziel
        dailyActiveCalorieGoal = UserDefaults.standard.integer(forKey: "user.dailyActiveCalorieGoal")

        // Initialisiere das tägliche Ziel an Schritten
        dailyStepsGoal = UserDefaults.standard.integer(forKey: "user.dailyStepsGoal")

        // E-Bike Profil
        eBikeName = defaults.string(forKey: "ebike.name") ?? ""
        eBikeTypeRaw = defaults.string(forKey: "ebike.type") ?? BikeType.eBikeTrekking.rawValue
        eBikeFrameSize = defaults.integer(forKey: "ebike.frameSize")
        eBikeWeight = defaults.double(forKey: "ebike.weight")
        eBikeBatteryCapacity = defaults.integer(forKey: "ebike.batteryCapacity")
        eBikeTireSizeRaw = defaults.string(forKey: "ebike.tireSize") ?? TireSize.t28.rawValue
        eBikeConditionRaw = defaults.object(forKey: "ebike.condition") as? Int ?? BikeCondition.good.rawValue
        eBikeKilometers = defaults.double(forKey: "ebike.kilometers")
        eBikePurchaseDate = defaults.object(forKey: "ebike.purchaseDate") as? Date
        eBikeMaintenanceIntervalKm = defaults.object(forKey: "ebike.maintenanceIntervalKm") as? Double ?? 1000.0
        eBikeLastMaintenanceDate = defaults.object(forKey: "ebike.lastMaintenanceDate") as? Date
        eBikeNotes = defaults.string(forKey: "ebike.notes") ?? ""

        // Tagesform: Kreislaufwirksame Medikamente (Default: false)
        takesCardioMedication = defaults.bool(forKey: "health.takesCardioMedication")

        // Debug: Readiness-Score-Override (Default: -1 = kein Override)
        debugReadinessScoreOverride = defaults.object(forKey: "debug.readinessScoreOverride") as? Int ?? -1
    }
}

