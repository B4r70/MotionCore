//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : CardioSession.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Datenmodell SwiftData für die MotionCore-App                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Enums für dieses Model findet man im File WorkoutTypes.swift      /
//                Die UI-Ausgabe dieser Enums im File TypesUI.swift                 /
//                Die formatierten Werte aus dem Model sind in SessionUI            /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@Model
final class CardioSession {
    // MARK: - Identifikation

    // Stabile UUID für Session-Tracking (überlebt App-Neustarts)
    var sessionUUID: UUID = UUID()

    // MARK: - Grunddaten
    // Trainingsblöcke innerhalb einer Session (z. B. Cardio + Kraft)
    var date: Date = Date() // Datum
    var duration: Int = 0 // Minuten
    var distance: Double = 0.0 // Zurückgelegte Strecke
    var calories: Int = 0 // Kalorien
    var difficulty: Int = 1 // Schwierigkeitsgrad (1–25)
    var heartRate: Int = 0 // ∅ Herzfrequenz (Apple Watch)
    var maxHeartRate: Int = 0 // Maximale Herzfrequenz
    var bodyWeight: Double = 0.0 // Körpergewicht (am Gerät eingegeben)
    var notes: String = "" // Session-Notizen

    // MARK: - Session-Status (NEU)

    var isCompleted: Bool = false // Training abgeschlossen?
    var isLiveSession: Bool = false // Live getrackt vs. manuell eingetragen
    var startedAt: Date? // Wann gestartet?
    var completedAt: Date? // Wann beendet?

    // MARK: - Subjektive Bewertung für ML (NEU)

    var perceivedExertion: Int? // RPE 1-10 (Rate of Perceived Exertion)
    var energyLevelBefore: Int? // Energielevel vor Training (1-5)

    // MARK: - HealthKit-Integration (NEU)

    var healthKitWorkoutUUID: UUID? // Verknüpfung zur HKWorkout
    var deviceSource: String = "manual" // "iPhone", "AppleWatch", "manual"

    // MARK: - Persistente ENUM-Rohwerte

    var cardioDeviceRaw: Int = 0 // 0=none, 1=Crosstrainer, 2=Ergometer
    var intensityRaw: Int = 0 // 0=none … 5=veryHard
    var trainingProgramRaw: String = "random"

    // MARK: - Typisierte ENUM-Properties

    var cardioDevice: CardioDevice {
        get { CardioDevice(rawValue: cardioDeviceRaw) ?? .none }
        set { cardioDeviceRaw = newValue.rawValue }
    }

    var intensity: Intensity {
        get { Intensity(rawValue: intensityRaw) ?? .none }
        set { intensityRaw = newValue.rawValue }
    }

    var trainingProgram: TrainingProgram {
        get { TrainingProgram(rawValue: trainingProgramRaw) ?? .random }
        set { trainingProgramRaw = newValue.rawValue }
    }

    // MARK: - Abgeleitete Trainingsergebnisse

    // METs (Metabolisches Äquivalent) ≈ kcal pro Stunde pro kg
    var mets: Double {
        guard bodyWeight > 0.0, duration > 0 else { return 0 }
        return (Double(calories) / (Double(duration) / 60.0)) / bodyWeight
    }

    // Durchschnittliche Geschwindigkeit (m/min)
    var averageSpeed: Double {
        guard duration > 0 else { return 0 }
        return (distance * 1000.0) / Double(duration) // km → m, dann / Minuten
    }

    // Tatsächliche Trainingsdauer in Minuten (berechnet) (NEU)
    var actualDuration: Int? {
        guard let start = startedAt, let end = completedAt else { return nil }
        return Calendar.current.dateComponents([.minute], from: start, to: end).minute
    }

    // MARK: - Initialisierung mit Default-Werten für CloudKit

    init(
        date: Date = Date(),
        duration: Int = 0,
        distance: Double = 0.0,
        calories: Int = 0,
        difficulty: Int = 1,
        heartRate: Int = 0,
        maxHeartRate: Int = 0,
        bodyWeight: Double = 0.0,
        notes: String = "",
        isCompleted: Bool = false,
        isLiveSession: Bool = false,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        perceivedExertion: Int? = nil,
        energyLevelBefore: Int? = nil,
        healthKitWorkoutUUID: UUID? = nil,
        deviceSource: String = "manual",
        intensity: Intensity = .none,
        trainingProgram: TrainingProgram = .random,
        cardioDevice: CardioDevice = .none
    ) {
        self.date = date
        self.duration = max(duration, 0)
        self.distance = max(distance, 0.0)
        self.calories = max(calories, 0)
        self.difficulty = difficulty.clamped(to: 1 ... 25)
        self.heartRate = heartRate
        self.maxHeartRate = maxHeartRate
        self.bodyWeight = bodyWeight
        self.notes = notes
        self.isCompleted = isCompleted
        self.isLiveSession = isLiveSession
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.perceivedExertion = perceivedExertion
        self.energyLevelBefore = energyLevelBefore
        self.healthKitWorkoutUUID = healthKitWorkoutUUID
        self.deviceSource = deviceSource
        intensityRaw = intensity.rawValue
        trainingProgramRaw = trainingProgram.rawValue
        cardioDeviceRaw = cardioDevice.rawValue
    }

    // MARK: - Session-Steuerung (NEU)

    // Training starten
    func start() {
        startedAt = Date()
        isCompleted = false
        isLiveSession = true
    }

    // Training beenden
    func complete() {
        completedAt = Date()
        isCompleted = true

        // Dauer berechnen und speichern
        if let minutes = actualDuration {
            duration = minutes
        }
    }
}
