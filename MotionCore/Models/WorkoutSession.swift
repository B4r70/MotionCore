//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : WorkoutSession.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Datenmodell SwiftData für die MotionCore-App                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Notes  . . . : Enums für dieses Model findet man im File WorkoutTypes.swift      /
//                Die UI-Ausgabe dieser Enums im File WorkoutTypesUI.swift          /
//                Die formatierten Werte aus dem Model sind in WorkoutSessionUI     /
//                Die UI-Ausgabe dieser Enums im File WorkoutTypesUI.swift          /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

// Universelle Wertebegrenzung
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

@Model
final class WorkoutSession {
    // MARK: - Grunddaten

    var date: Date = Date() // Datum
    var duration: Int = 0 // Minuten
    var distance: Double = 0.0 // Zurückgelegte Strecke
    var calories: Int = 0 // Kalorien

    // MARK: - Trainingsparameter

    var difficulty: Int = 1 // Schwierigkeitsgrad (1–25)
    var heartRate: Int = 0 // ∅ Herzfrequenz (Apple Watch)
    var bodyWeight: Int = 0 // Körpergewicht (am Gerät eingegeben)

    // MARK: - Persistente ENUM-Rohwerte

    var workoutDeviceRaw: Int = 0 // 0=none, 1=Crosstrainer, 2=Ergometer
    var intensityRaw: Int = 0 // 0=none … 5=veryHard
    var trainingProgramRaw: String = "random"

    // MARK: - Typisierte ENUM-Properties

    var workoutDevice: WorkoutDevice {
        get { WorkoutDevice(rawValue: workoutDeviceRaw) ?? .none }
        set { workoutDeviceRaw = newValue.rawValue }
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

    /// METs (Metabolisches Äquivalent) ≈ kcal pro Stunde pro kg
    var mets: Double {
        guard bodyWeight > 0, duration > 0 else { return 0 }
        return (Double(calories) / (Double(duration) / 60.0)) / Double(bodyWeight)
    }

    /// Durchschnittliche Geschwindigkeit (m/min)
    var averageSpeed: Double {
        guard duration > 0 else { return 0 }
        return (distance * 1000.0) / Double(duration) // km → m, dann / Minuten
    }

    // MARK: - Initialisierung mit Default-Werten für CloudKit

    init(
        date: Date = Date(),
        duration: Int = 0,
        distance: Double = 0.0,
        calories: Int = 0,
        difficulty: Int = 1,
        heartRate: Int = 0,
        bodyWeight: Int = 0,
        intensity: Intensity = .none,
        trainingProgram: TrainingProgram = .random,
        workoutDevice: WorkoutDevice = .none
    ) {
        self.date = date
        self.duration = max(duration, 0)
        self.distance = max(distance, 0.0)
        self.calories = max(calories, 0)
        self.difficulty = difficulty.clamped(to: 1 ... 25)
        self.heartRate = heartRate
        self.bodyWeight = bodyWeight
        intensityRaw = intensity.rawValue
        trainingProgramRaw = trainingProgram.rawValue
        workoutDeviceRaw = workoutDevice.rawValue
    }
}
