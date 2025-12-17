//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : ExerciseSet.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 16.12.2025                                                       /
// Beschreibung  : Datenmodell für Übungen im Krafttraining                         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
// MARK: - Einzelner Satz innerhalb einer Session
import Foundation
import SwiftData

@Model
final class ExerciseSet {
    // MARK: - Referenz zur Übung
    
    var exerciseName: String = ""       // Name der Übung
    var exerciseId: String = ""         // Optional: UUID der Exercise
    
    // MARK: - Set-Daten
    
    var setNumber: Int = 1              // Satznummer (1, 2, 3...)
    var weight: Double = 0.0            // Gewicht in kg
    var reps: Int = 0                   // Wiederholungen
    var duration: Int = 0               // Optional: Zeit in Sekunden (für Planks etc.)
    var distance: Double = 0.0          // Optional: Strecke in m (für Farmers Walk)
    
    // MARK: - Set-Status
    
    var isWarmup: Bool = false          // Ist das ein Aufwärmsatz?
    var isCompleted: Bool = true        // Satz abgeschlossen?
    var rpe: Int = 0                    // Rate of Perceived Exertion (0-10)
    var notes: String = ""              // Set-spezifische Notizen
    
    // MARK: - Beziehung
    
    var session: StrengthWorkoutSession?
    
    // MARK: - Berechnete Werte
    
    /// Volumen dieses Sets (Gewicht × Reps)
    var volume: Double {
        weight * Double(reps)
    }
    
    // MARK: - Initialisierung
    
    init(
        exerciseName: String = "",
        exerciseId: String = "",
        setNumber: Int = 1,
        weight: Double = 0.0,
        reps: Int = 0,
        duration: Int = 0,
        distance: Double = 0.0,
        isWarmup: Bool = false,
        isCompleted: Bool = true,
        rpe: Int = 0,
        notes: String = ""
    ) {
        self.exerciseName = exerciseName
        self.exerciseId = exerciseId
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.duration = duration
        self.distance = distance
        self.isWarmup = isWarmup
        self.isCompleted = isCompleted
        self.rpe = rpe
        self.notes = notes
    }
}
