//---------------------------------------------------------------------------------/
//  # CrossStats                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : WorkoutSession.swift                                             /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Datenmodell zu CrossStats                                        /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
// Notes  . . . : Enums für dieses Model findet man im File WorkoutTypes.swift     /
//                Die UI-Ausgabe dieser Enums im File WorkoutTypesUI.swift         /
//                Die formatierten Werte aus dem Model sind in WorkoutSessionUI    /
//                Die UI-Ausgabe dieser Enums im File WorkoutTypesUI.swift         /
//---------------------------------------------------------------------------------/

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
    var date: Date
    var duration: Int                               // Minuten
    var distance: Double {                          // Zurückgelegte Strecke
        didSet { distance = max(distance, 0) }
    }
    var calories: Int {                             // Kalorien
        didSet { calories = max(calories, 0) }
    }

    // MARK: - Trainingsparameter
    var difficulty: Int = 1 {                       // Schwierigkeitsgrad (1–25)
        didSet { difficulty = difficulty.clamped(to: 1...25) }
    }
    var heartRate: Int                              // ∅ Herzfrequenz (Apple Watch)
    var bodyWeight: Int                             // Körpergewicht (am Gerät eingegeben)

    // MARK: - Persistente ENUM-Rohwerte
    private var workoutDeviceRaw: Int = WorkoutDevice.none.rawValue      // 0=none, 1=Crosstrainer, 2=Ergometer
    private var intensityRaw: Int = Intensity.none.rawValue              // 0=none … 5=veryHard
    private var trainingProgramRaw: String = TrainingProgram.random.rawValue

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

    // MARK: - Initialisierung
    init(
        date: Date = .now,
        duration: Int,
        distance: Double,
        calories: Int,
        difficulty: Int = 1,
        heartRate: Int,
        bodyWeight: Int,
        intensity: Intensity,
        trainingProgram: TrainingProgram,
        workoutDevice: WorkoutDevice = .none
    ) {
        self.date = date
        self.duration = duration
        self.distance = distance
        self.calories = calories
        self.difficulty = difficulty
        self.heartRate = heartRate
        self.bodyWeight = bodyWeight
        self.intensity = intensity
        self.trainingProgram = trainingProgram
        self.workoutDevice = workoutDevice
    }
}
