//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Rekorde                                                          /
// Datei . . . . : RecordCalcEngine.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 17.11.2025                                                       /
// Beschreibung  : Zentrale Berechnungen für die Rekordanzeige                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

struct RecordCalcEngine {

    // MARK: - Input

    // Alle Workouts, die als Datenquelle für die Statistiken verwendet werden.
    let allWorkouts: [CardioWorkoutSession]

    // MARK: - Initializer
    init(workouts: [CardioWorkoutSession]) {
        self.allWorkouts = workouts
    }

    // Berechnung: Bestes Workout mit der längsten Distanz (geräteübergreifend)
    var bestErgometerWorkout: CardioWorkoutSession? {
        allWorkouts
            .filter { $0.cardioDevice == .ergometer }
            .max(by: { $0.distance < $1.distance })
    }

    // Berechnung: Bestes Crosstrainer Workout mit der längsten Distanz
    var bestCrosstrainerWorkout: CardioWorkoutSession? {
        allWorkouts
            .filter { $0.cardioDevice == .crosstrainer }
            .max(by: { $0.distance < $1.distance })
    }

    // Berechnung: Bestes Workout mit der höchsten Durchschnittsgeschwindigkeit (gerätespezifisch)
    func fastestCardioDevice(for device: CardioDevice) -> CardioWorkoutSession? {
            allWorkouts
                .filter { $0.cardioDevice == device }
                .filter { $0.averageSpeed > 0.0 }
                .max(by: { $0.averageSpeed < $1.averageSpeed }) // <-- Logik korrigiert
        }

    // MARK: Geräteübergreifende Rekorde

    // Berechnung: Niedrigstes Körpergewicht
    var lowestBodyWeight: CardioWorkoutSession? {
        let recordedWorkouts = allWorkouts.filter { $0.bodyWeight > 0.0 }
        return recordedWorkouts.min(by: { $0.bodyWeight < $1.bodyWeight })
    }

    // Berechnung: Höchstes Körpergewicht
    var highestBodyWeight: CardioWorkoutSession? {
        let recordedWorkouts = allWorkouts.filter { $0.bodyWeight > 0.0 }
        return recordedWorkouts.max(by: { $0.bodyWeight < $1.bodyWeight })
    }

    // Höchster Kalorienverbrauch im Workout
    var highestBurnedCaloriesWorkout: CardioWorkoutSession? {
        allWorkouts
            .max(by: { $0.calories < $1.calories })
    }

        // Berechnung: Bestes Workout mit der längsten Distanz (geräteübergreifend)
    var longestDistanceWorkout: CardioWorkoutSession? {
        allWorkouts
            .max(by: { $0.distance < $1.distance })
    }

        // NEU: Berechnung: Bestes Workout mit der längsten Dauer (geräteübergreifend)
    var longestDurationWorkout: CardioWorkoutSession? {
        allWorkouts
            .max(by: { $0.duration < $1.duration })
    }
}
