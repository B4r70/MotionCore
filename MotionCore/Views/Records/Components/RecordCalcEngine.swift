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
}
