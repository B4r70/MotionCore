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

// Erweiterung für Wertebegrenzung – universell einsetzbar
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

@Model
final class WorkoutSession {

    // MARK: - Grunddaten
    var date: Date
    var duration: Int // Minuten
    var distance: Double {
        didSet { distance = max(distance, 0) }
    } // Zurückgelegte Strecke
    var calories: Int {
        didSet { calories = max(calories, 0) }
    } // Kalorien

    // MARK: - Trainingsparameter
    var difficulty: Int = 1 {
        didSet { difficulty = difficulty.clamped(to: 1...25) }
    } // Schwierigkeitsgrad
    var heartRate: Int // durchschnittliche Herzfrequenz lt. Apple Watch
    var bodyWeight: Int // Eingegebenes Körpergewicht am Life Fitness Gerät

    // MARK: - Persistente ENUM-Werte
    private var intensityRaw: Int = Intensity.none.rawValue // 0=Default --> Keine Belastung
    private var trainingProgramRaw: String = TrainingProgram.random.rawValue // Default --> Zufall

    // MARK: - Berechnete ENUM-Werte
    var intensity: Intensity {
        get { Intensity(rawValue: intensityRaw) ?? .none }
        set { intensityRaw = newValue.rawValue }
    }

    var trainingProgram: TrainingProgram {
        get { TrainingProgram(rawValue: trainingProgramRaw) ?? .random }
        set { trainingProgramRaw = newValue.rawValue }
    }

    // MARK: - Abgeleitete Trainingsergebnisse
    var mets: Double {
        guard bodyWeight > 0, duration > 0 else { return 0 }
        return (Double(calories) / (Double(duration) / 60)) / Double(bodyWeight)
    }

        // Durchschnittliche Geschwindigkeit Meter/Minute
    var averageSpeed: Double {
        guard duration > 0 else { return 0 }
        // km -> m -> geteilt durch die Minuten
        return (distance * 1000) / Double(duration)
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
        trainingProgram: TrainingProgram
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
    }
}
