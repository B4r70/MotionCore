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
    // MARK: - Referenz zur Übung (Snapshots für stabile Statistiken)

    var exerciseName: String = ""                // Name der Übung
    var exerciseNameSnapshot: String = ""        // Snapshot des Namens bei Erstellung
    var exerciseUUIDSnapshot: String = ""        // UUID-Snapshot für stabile Verknüpfung
    var exerciseMediaAssetName: String = ""      // Name des Media-Assets

    // Snapshot für unilateral (damit Edit ohne Relationship korrekt ist)
    var isUnilateralSnapshot: Bool = false

    // MARK: - Set-Daten

    var setNumber: Int = 1                       // Satznummer (1, 2, 3...)
    var weight: Double = 0.0                     // Gewicht in kg
    var weightPerSide: Double = 0.0              // Gewicht pro Seite (für unilaterale Übungen)
    var reps: Int = 0                            // Wiederholungen
    var duration: Int = 0                        // Optional: Zeit in Sekunden (für Planks etc.)
    var distance: Double = 0.0                   // Optional: Strecke in m (für Farmers Walk)
    var restSeconds: Int = 90                    // Pause in Sekunden

    // MARK: - Zielwerte für Progression

    var targetRepsMin: Int = 0                   // Untere Zielgrenze (unter → Gewicht reduzieren)
    var targetRepsMax: Int = 0                   // Obere Zielgrenze (über → Gewicht erhöhen)
    var targetRIR: Int = 2                       // Ziel-RIR (Reps In Reserve)

    // MARK: - Gruppierung

    var groupId: String = ""                     // Gruppen-ID für Supersets etc.
    var sortOrder: Int = 0                       // Sortierung innerhalb des Plans

    // MARK: - Set-Status

    var setKindRaw: String = "work"              // Satztyp (work/warmup/drop/amrap)
    var isCompleted: Bool = true                 // Satz abgeschlossen?
    var rpe: Int = 0                             // Rate of Perceived Exertion (0-10)
    var notes: String = ""                       // Set-spezifische Notizen

    // MARK: - Typisierte Set-Kind Property

    var setKind: SetKind {
        get { SetKind(rawValue: setKindRaw) ?? .work }
        set { setKindRaw = newValue.rawValue }
    }

    // Deprecated: Wird durch setKind ersetzt, bleibt für Kompatibilität
    var isWarmup: Bool {
        get { setKind == .warmup }
        set { if newValue { setKind = .warmup } else if setKind == .warmup { setKind = .work } }
    }

    // MARK: - Beziehungen
    @Relationship(deleteRule: .nullify)
    var session: StrengthSession?

    @Relationship(deleteRule: .nullify)
    var trainingPlan: TrainingPlan?

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
            exerciseNameSnapshot: exercise.name,
            exerciseUUIDSnapshot: exercise.persistentModelID.hashValue.description,
            exerciseMediaAssetName: exercise.mediaAssetName,
            isUnilateralSnapshot: exercise.isUnilateral, // NEU
            setNumber: setNumber,
            weight: weight,
            reps: reps,
            targetRepsMin: exercise.repRangeMin,
            targetRepsMax: exercise.repRangeMax
        )
        self.exercise = exercise
    }

    // MARK: - Berechnete Werte

    // Volumen dieses Sets (Gewicht x Reps)
    var volume: Double {
        weight * Double(reps)
    }

    // Effektives Gewicht (berücksichtigt unilateral)
    var effectiveWeight: Double {
        weightPerSide > 0 ? weightPerSide * 2 : weight
    }

    // RIR berechnet aus RPE
    var calculatedRIR: Int {
        max(0, 10 - rpe)
    }

    // Ist im Zielbereich?
    var isInTargetRange: Bool {
        guard targetRepsMin > 0 && targetRepsMax > 0 else { return true }
        return reps >= targetRepsMin && reps <= targetRepsMax
    }

    // Empfehlung für nächstes Workout
    var progressionHint: String {
        guard targetRepsMin > 0 && targetRepsMax > 0 else { return "" }
        if reps < targetRepsMin {
            return "Gewicht reduzieren"
        } else if reps > targetRepsMax {
            return "Gewicht erhöhen"
        }
        return "Im Zielbereich"
    }

    // Muskelgruppen-Info (wird später durch Exercise-Bibliothek ersetzt)
    // Nutzt NUR Snapshots - Exercise-Relationship kann zu Crashes führen
    // wenn die Exercise gelöscht wurde aber die Referenz noch existiert
    var primaryMuscleGroup: MuscleGroup? {
        // Immer über MuscleGroupMapper - sicher und konsistent
        return MuscleGroupMapper.primaryMuscle(for: exerciseNameSnapshot.isEmpty ? exerciseName : exerciseNameSnapshot)
    }

    var secondaryMuscleGroups: [MuscleGroup] {
        // Immer über MuscleGroupMapper - sicher und konsistent
        return MuscleGroupMapper.secondaryMuscles(for: exerciseNameSnapshot.isEmpty ? exerciseName : exerciseNameSnapshot)
    }

    // MARK: - Initialisierung

    init(
        exerciseName: String = "",
        exerciseNameSnapshot: String = "",
        exerciseUUIDSnapshot: String = "",
        exerciseMediaAssetName: String = "",
        isUnilateralSnapshot: Bool = false,
        setNumber: Int = 1,
        weight: Double = 0.0,
        weightPerSide: Double = 0.0,
        reps: Int = 0,
        duration: Int = 0,
        distance: Double = 0.0,
        restSeconds: Int = 90,
        setKind: SetKind = .work,
        isCompleted: Bool = false,
        rpe: Int = 0,
        notes: String = "",
        targetRepsMin: Int = 0,
        targetRepsMax: Int = 0,
        targetRIR: Int = 2,
        groupId: String = "",
        sortOrder: Int = 0
    ) {
        self.exerciseName = exerciseName
        self.exerciseNameSnapshot = exerciseNameSnapshot.isEmpty ? exerciseName : exerciseNameSnapshot
        self.exerciseUUIDSnapshot = exerciseUUIDSnapshot
        self.exerciseMediaAssetName = exerciseMediaAssetName
        self.isUnilateralSnapshot = isUnilateralSnapshot
        self.setNumber = setNumber
        self.weight = weight
        self.weightPerSide = weightPerSide
        self.reps = reps
        self.duration = duration
        self.distance = distance
        self.restSeconds = restSeconds
        self.setKindRaw = setKind.rawValue
        self.isCompleted = isCompleted
        self.rpe = rpe
        self.notes = notes
        self.targetRepsMin = targetRepsMin
        self.targetRepsMax = targetRepsMax
        self.targetRIR = targetRIR
        self.groupId = groupId
        self.sortOrder = sortOrder
    }
}

extension ExerciseSet {
    /// Creates a detached copy for editing in the plan sheet.
    /// No relationships are copied (exercise/trainingPlan/session).
    func cloneForPlanEditing() -> ExerciseSet {
        let copy = ExerciseSet(
            exerciseName: exerciseName,
            exerciseNameSnapshot: exerciseNameSnapshot,
            exerciseUUIDSnapshot: exerciseUUIDSnapshot,
            exerciseMediaAssetName: exerciseMediaAssetName,
            setNumber: setNumber,
            weight: weight,
            weightPerSide: weightPerSide,
            reps: reps,
            duration: duration,
            distance: distance,
            restSeconds: restSeconds,
            setKind: setKind,
            isCompleted: isCompleted,
            rpe: rpe,
            notes: notes,
            targetRepsMin: targetRepsMin,
            targetRepsMax: targetRepsMax,
            targetRIR: targetRIR,
            groupId: groupId,
            sortOrder: sortOrder
        )

        // NEW: your snapshot flag
        copy.isUnilateralSnapshot = isUnilateralSnapshot

        // Important: detach relations
        copy.exercise = nil
        copy.trainingPlan = nil
        copy.session = nil

        return copy
    }
}

extension ExerciseSet {
    // Stable grouping key for UI grouping & counting.
    var groupKey: String {
        if !exerciseUUIDSnapshot.isEmpty { return exerciseUUIDSnapshot }
        if !exerciseNameSnapshot.isEmpty { return exerciseNameSnapshot }
        return exerciseName
    }
}
// Clone for Session um Datenkorruption zu vermeiden
// MARK: - Clone for Session (verhindert Datenkorruption zwischen Plan & Session)
extension ExerciseSet {
    /// Creates a fresh set instance for a StrengthSession, based on a template.
    /// Copies all relevant fields + snapshots.
    /// Does NOT keep `trainingPlan` relationship.
    func cloneForSession() -> ExerciseSet {
        let copy = ExerciseSet(
            exerciseName: exerciseName,
            exerciseNameSnapshot: exerciseNameSnapshot,
            exerciseUUIDSnapshot: exerciseUUIDSnapshot,
            exerciseMediaAssetName: exerciseMediaAssetName,
            isUnilateralSnapshot: isUnilateralSnapshot,
            setNumber: setNumber,
            weight: weight,
            weightPerSide: weightPerSide,
            reps: reps,
            duration: duration,
            distance: distance,
            restSeconds: restSeconds,
            setKind: setKind,
            isCompleted: false,          // sinnvoll: neue Sets sind erstmal nicht abgeschlossen
            rpe: 0,                      // neutral starten
            notes: notes,                // optional: kannst du auch "" setzen
            targetRepsMin: targetRepsMin,
            targetRepsMax: targetRepsMax,
            targetRIR: targetRIR,
            groupId: groupId,
            sortOrder: sortOrder
        )

        // Relationship: Exercise darf mit rüber (optional, aber praktisch)
        copy.exercise = self.exercise

        // Ownership: Session kommt später via session.addSet(...)
        copy.session = nil
        copy.trainingPlan = nil

        return copy
    }
}
