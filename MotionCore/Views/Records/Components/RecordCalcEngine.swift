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
    let allWorkouts: [WorkoutSession]

    // MARK: - Initializer
    init(workouts: [WorkoutSession]) {
        self.allWorkouts = workouts
    }

    // Berechnung: Bestes Workout mit der längsten Distanz (geräteübergreifend)
    var bestErgometerWorkout: WorkoutSession? {
        allWorkouts
            .filter { $0.workoutDevice == .ergometer }
            .max(by: { $0.distance < $1.distance })
    }

    // Berechnung: Bestes Crosstrainer Workout mit der längsten Distanz
    var bestCrosstrainerWorkout: WorkoutSession? {
        allWorkouts
            .filter { $0.workoutDevice == .crosstrainer }
            .max(by: { $0.distance < $1.distance })
    }

    // Berechnung: Bestes Workout mit der höchsten Durchschnittsgeschwindigkeit (gerätespezifisch)
    func fastestWorkoutDevice(for device: WorkoutDevice) -> WorkoutSession? {
            allWorkouts
                .filter { $0.workoutDevice == device }
                .filter { $0.averageSpeed > 0.0 }
                .max(by: { $0.averageSpeed < $1.averageSpeed }) // <-- Logik korrigiert
        }

        // MARK: Geräteübergreifende Rekorde

        // Höchster Kalorienverbrauch im Workout
    var highestBurnedCaloriesWorkout: WorkoutSession? {
        allWorkouts
            .max(by: { $0.calories < $1.calories })
    }

        // Berechnung: Bestes Workout mit der längsten Distanz (geräteübergreifend)
    var longestDistanceWorkout: WorkoutSession? {
        allWorkouts
            .max(by: { $0.distance < $1.distance })
    }

        // NEU: Berechnung: Bestes Workout mit der längsten Dauer (geräteübergreifend)
    var longestDurationWorkout: WorkoutSession? {
        allWorkouts
            .max(by: { $0.duration < $1.duration })
    }
}
