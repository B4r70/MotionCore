//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : StrengthWorkoutSession.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 17.12.2025                                                       /
// Beschreibung  : Datenmodell für Krafttrainings                                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Enums für dieses Model findet man im File StrengthTypes.swift     /
//                Die UI-Ausgabe dieser Enums im File TypesUI.swift                 /
//                Die formatierten Werte aus dem Model sind in SessionUI            /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@Model
final class StrengthSession {
    // MARK: - Grunddaten
    
    var date: Date = Date()
    var duration: Int = 0               // Gesamtdauer in Minuten
    var calories: Int = 0               // Geschätzte Kalorien
    var notes: String = ""              // Session-Notizen
    
    // MARK: - Körperdaten
    
    var bodyWeight: Double = 0.0        // Körpergewicht in kg
    var heartRate: Int = 0              // Durchschnittliche Herzfrequenz (optional)
    
    // MARK: - Beziehungen
    
    @Relationship(deleteRule: .cascade)
    var exerciseSets: [ExerciseSet] = [] // Alle Sets dieser Session
    
    // MARK: - Persistente ENUM-Rohwerte
    
    var workoutTypeRaw: String = "fullBody"
    var intensityRaw: Int = 0
    
    // MARK: - Typisierte ENUM-Properties
    
    var workoutType: StrengthWorkoutType {
        get { StrengthWorkoutType(rawValue: workoutTypeRaw) ?? .fullBody }
        set { workoutTypeRaw = newValue.rawValue }
    }
    
    var intensity: Intensity {
        get { Intensity(rawValue: intensityRaw) ?? .none }
        set { intensityRaw = newValue.rawValue }
    }
    
    // MARK: - Berechnete Werte
    
    /// Anzahl der Sets in dieser Session
    var totalSets: Int {
        exerciseSets.count
    }
    
    /// Anzahl der verschiedenen Übungen
    var exercisesPerformed: Int {
        Set(exerciseSets.map { $0.exerciseName }).count
    }
    
    /// Gesamtes Trainingsvolumen (Summe: Gewicht × Reps)
    var totalVolume: Double {
        exerciseSets.reduce(0.0) { sum, set in
            sum + (set.weight * Double(set.reps))
        }
    }

    /// Trainierte Muskelgruppe
    var trainedMuscleGroups: [MuscleGroup] {
        var groups = Set<MuscleGroup>()

        for set in exerciseSets {
            // Später: Aus Exercise-Bibliothek holen
            // Jetzt: Mapping über exerciseName
            if let primary = set.primaryMuscleGroup {
                groups.insert(primary)
            }
        }

        return Array(groups).sorted { $0.rawValue < $1.rawValue }
    }

    // MARK: - Initialisierung
    
    init(
        date: Date = Date(),
        duration: Int = 0,
        calories: Int = 0,
        notes: String = "",
        bodyWeight: Double = 0.0,
        heartRate: Int = 0,
        workoutType: StrengthWorkoutType = .fullBody,
        intensity: Intensity = .none
    ) {
        self.date = date
        self.duration = max(duration, 0)
        self.calories = max(calories, 0)
        self.notes = notes
        self.bodyWeight = bodyWeight
        self.heartRate = heartRate
        self.workoutTypeRaw = workoutType.rawValue
        self.intensityRaw = intensity.rawValue
    }
}
