//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Progression                                           /
// Datei . . . . : ProgressionStateRepository.swift                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.05.2026                                                       /
// Beschreibung  : Protokoll + Implementierung für ExerciseProgressionState-Zugriff /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

// MARK: - ProgressionStateProviding

/// Protokoll für lesenden und schreibenden Zugriff auf ExerciseProgressionState-Objekte.
/// Ermöglicht Dependency-Injection in AutoProgressionApplier und ActiveWorkoutSmartFillViewModel.
protocol ProgressionStateProviding {
    func fetch(exerciseGroupKey: String) -> ExerciseProgressionState?

    @discardableResult
    func createIfMissing(
        exerciseGroupKey: String,
        workingWeight: Double,
        exercise: Exercise
    ) -> ExerciseProgressionState
}

// MARK: - ProgressionStateRepository

/// Konkrete Implementierung des Protokolls mit echtem ModelContext.
final class ProgressionStateRepository: ProgressionStateProviding {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetch(exerciseGroupKey: String) -> ExerciseProgressionState? {
        var descriptor = FetchDescriptor<ExerciseProgressionState>(
            predicate: #Predicate { $0.exerciseGroupKey == exerciseGroupKey }
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    @discardableResult
    func createIfMissing(
        exerciseGroupKey: String,
        workingWeight: Double,
        exercise: Exercise
    ) -> ExerciseProgressionState {
        if let existing = fetch(exerciseGroupKey: exerciseGroupKey) { return existing }

        let minReps = exercise.repRangeMin > 0 ? exercise.repRangeMin : 8
        let maxReps = exercise.repRangeMax > 0 ? exercise.repRangeMax : 12
        let targetReps: Int
        if let custom = exercise.customTargetReps, custom > 0 {
            targetReps = custom
        } else {
            targetReps = max(1, (minReps + maxReps) / 2)
        }

        let state = ExerciseProgressionState(
            exerciseGroupKey: exerciseGroupKey,
            workingWeight: workingWeight
        )
        state.targetReps = targetReps
        state.minTargetReps = minReps
        state.maxTargetReps = maxReps
        state.progressionModeRaw = exercise.progressionModeRaw

        context.insert(state)
        try? context.save()
        return state
    }
}
