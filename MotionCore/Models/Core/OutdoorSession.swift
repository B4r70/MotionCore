//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : OutdoorWorkoutSession.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 16.12.2025                                                       /
// Beschreibung  : Datenmodell für Outdoor-Aktivitäten (Radfahren, Laufen, etc.)    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@Model
final class OutdoorSession {

    // MARK: - Identifikation
    // Stabile UUID für Session-Tracking (überlebt App-Neustarts)
    var sessionUUID: UUID = UUID()

    // MARK: - Grunddaten
    var date: Date = Date()
    var duration: Int = 0 // Minuten
    var distance: Double = 0.0 // Kilometer
    var calories: Int = 0 // Kalorien

    // MARK: - Outdoor-spezifische Daten
    var elevationGain: Double = 0.0 // Höhenmeter
    var averageSpeed: Double = 0.0 // km/h (für Radfahren)
    var maxSpeed: Double = 0.0 // km/h

    // MARK: - Gesundheitsdaten
    var heartRate: Int = 0 // Durchschnittliche Herzfrequenz
    var maxHeartRate: Int = 0 // Maximale Herzfrequenz
    var bodyWeight: Double = 0.0 // Körpergewicht in kg

    // MARK: - Route/Location
    var routeName: String = "" // z.B. "Rheinufer-Tour"
    var startLocation: String = "" // Optional: Startpunkt
    var endLocation: String = "" // Optional: Zielpunkt
    var notes: String = "" // Notizen zur Session

    // MARK: - Wetter (optional)
    var temperature: Double? = nil // Grad Celsius
    var weatherConditionRaw: String = "unknown"

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
    var outdoorActivityRaw: String = "cycling"
    var intensityRaw: Int = 0

    // MARK: - Typisierte ENUM-Properties
    var outdoorActivity: OutdoorActivity {
        get { OutdoorActivity(rawValue: outdoorActivityRaw) ?? .cycling }
        set { outdoorActivityRaw = newValue.rawValue }
    }

    var intensity: Intensity {
        get { Intensity(rawValue: intensityRaw) ?? .none }
        set { intensityRaw = newValue.rawValue }
    }

    var weatherCondition: WeatherCondition {
        get { WeatherCondition(rawValue: weatherConditionRaw) ?? .unknown }
        set { weatherConditionRaw = newValue.rawValue }
    }

    // MARK: - Berechnete Werte

    // METs (Metabolisches Äquivalent)
    var mets: Double {
        guard bodyWeight > 0.0, duration > 0 else { return 0 }
        return (Double(calories) / (Double(duration) / 60.0)) / bodyWeight
    }

    // Pace in min/km (für Laufen/Wandern)
    var pacePerKm: Double {
        guard distance > 0, duration > 0 else { return 0 }
        return Double(duration) / distance
    }

    // Durchschnittliche Geschwindigkeit in m/min
    var averageSpeedMetersPerMinute: Double {
        guard duration > 0 else { return 0 }
        return (distance * 1000.0) / Double(duration)
    }

    // Tatsächliche Trainingsdauer in Minuten (berechnet)
    var actualDuration: Int? {
        guard let start = startedAt, let end = completedAt else { return nil }
        return Calendar.current.dateComponents([.minute], from: start, to: end).minute
    }

    // MARK: - Initialisierung
    init(
        date: Date = Date(),
        duration: Int = 0,
        distance: Double = 0.0,
        calories: Int = 0,
        elevationGain: Double = 0.0,
        averageSpeed: Double = 0.0,
        maxSpeed: Double = 0.0,
        heartRate: Int = 0,
        maxHeartRate: Int = 0,
        bodyWeight: Double = 0.0,
        routeName: String = "",
        startLocation: String = "",
        endLocation: String = "",
        notes: String = "",
        temperature: Double? = nil,
        isCompleted: Bool = false,
        isLiveSession: Bool = false,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        perceivedExertion: Int? = nil,
        energyLevelBefore: Int? = nil,
        healthKitWorkoutUUID: UUID? = nil,
        deviceSource: String = "manual",
        outdoorActivity: OutdoorActivity = .cycling,
        intensity: Intensity = .none,
        weatherCondition: WeatherCondition = .unknown
    ) {
        self.date = date
        self.duration = max(duration, 0)
        self.distance = max(distance, 0.0)
        self.calories = max(calories, 0)
        self.elevationGain = max(elevationGain, 0.0)
        self.averageSpeed = max(averageSpeed, 0.0)
        self.maxSpeed = max(maxSpeed, 0.0)
        self.heartRate = heartRate
        self.maxHeartRate = maxHeartRate
        self.bodyWeight = bodyWeight
        self.routeName = routeName
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.notes = notes
        self.temperature = temperature
        self.isCompleted = isCompleted
        self.isLiveSession = isLiveSession
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.perceivedExertion = perceivedExertion
        self.energyLevelBefore = energyLevelBefore
        self.healthKitWorkoutUUID = healthKitWorkoutUUID
        self.deviceSource = deviceSource
        self.outdoorActivityRaw = outdoorActivity.rawValue
        self.intensityRaw = intensity.rawValue
        self.weatherConditionRaw = weatherCondition.rawValue
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
