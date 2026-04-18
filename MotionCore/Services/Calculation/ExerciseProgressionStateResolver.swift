//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Calculation                                           /
// Datei . . . . : ExerciseProgressionStateResolver.swift                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Pure Helper zum Laden und Anlegen von ExerciseProgressionState   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

// MARK: - ExerciseProgressionStateResolver

/// Stateless Helper für FetchDescriptor-Zugriff auf ExerciseProgressionState.
/// Kein SwiftUI-Import, keine State-Mutation außer bei createIfMissing.
enum ExerciseProgressionStateResolver {

    // MARK: - Fetch

    /// Lädt den persistenten Progressions-Zustand für einen Übungsgruppen-Schlüssel.
    /// Gibt nil zurück wenn noch kein State angelegt wurde.
    static func fetch(in context: ModelContext, exerciseGroupKey: String) -> ExerciseProgressionState? {
        var descriptor = FetchDescriptor<ExerciseProgressionState>(
            predicate: #Predicate { $0.exerciseGroupKey == exerciseGroupKey }
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    // MARK: - Create If Missing

    /// Legt einen neuen ExerciseProgressionState an, falls noch keiner existiert.
    /// Ziel-Reps werden aus den Exercise-Properties abgeleitet.
    /// Bei bereits vorhandenem State wird dieser unverändert zurückgegeben.
    @discardableResult
    static func createIfMissing(
        in context: ModelContext,
        exerciseGroupKey: String,
        workingWeight: Double,
        exercise: Exercise
    ) -> ExerciseProgressionState {
        // Idempotent: vorhandenen State direkt zurückgeben
        if let existing = fetch(in: context, exerciseGroupKey: exerciseGroupKey) {
            return existing
        }

        let state = ExerciseProgressionState(
            exerciseGroupKey: exerciseGroupKey,
            workingWeight: workingWeight
        )

        // Ziel-Reps aus Exercise ableiten
        let minReps = exercise.repRangeMin > 0 ? exercise.repRangeMin : 8
        let maxReps = exercise.repRangeMax > 0 ? exercise.repRangeMax : 12
        let targetReps: Int
        if let custom = exercise.customTargetReps, custom > 0 {
            targetReps = custom
        } else {
            let avg = (minReps + maxReps) / 2
            targetReps = max(1, avg)
        }

        state.targetReps = targetReps
        state.minTargetReps = minReps
        state.maxTargetReps = maxReps
        state.progressionModeRaw = exercise.progressionModeRaw

        context.insert(state)
        try? context.save()
        return state
    }
}
