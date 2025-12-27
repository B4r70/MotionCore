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
    var exerciseGifAssetName: String = "" // Name des GIF-Assets um die Übung innerhalb der App darzustellen

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
    
    var session: StrengthSession?

    // Beziehung zum TrainingPlan (wenn Template)
    var trainingPlan: TrainingPlan?

    // Direkte Referenz zur Übung aus der Bibliothek
    @Relationship(deleteRule: .nullify)
    var exercise: Exercise?

    // Hilfsfunktion - Ist dies ein Template oder durchgeführt?
    var isTemplate: Bool {
        trainingPlan != nil && session == nil
    }

    // Convenience-Initializer mit Exercise
    convenience init(from exercise: Exercise, setNumber: Int = 1, weight: Double = 0, reps: Int = 0) {
        self.init(
            exerciseName: exercise.name,
            exerciseId: exercise.persistentModelID.hashValue.description,
            exerciseGifAssetName: exercise.gifAssetName,
            setNumber: setNumber,
            weight: weight,
            reps: reps
        )
        self.exercise = exercise
    }

    // MARK: - Berechnete Werte
    
    /// Volumen dieses Sets (Gewicht × Reps)
    var volume: Double {
        weight * Double(reps)
    }

    // Muskelgruppen-Info (wird später durch Exercise-Bibliothek ersetzt)
    var primaryMuscleGroup: MuscleGroup? {
            // TODO: Später aus Exercise-Bibliothek holen
            // Für jetzt: Einfaches Mapping
        MuscleGroupMapper.primaryMuscle(for: exerciseName)
    }

    var secondaryMuscleGroups: [MuscleGroup] {
        // TODO: Später aus Exercise-Bibliothek holen
        MuscleGroupMapper.secondaryMuscles(for: exerciseName)
    }

    // MARK: - Initialisierung
    
    init(
        exerciseName: String = "",
        exerciseId: String = "",
        exerciseGifAssetName: String = "",
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
        self.exerciseGifAssetName = exerciseGifAssetName
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
