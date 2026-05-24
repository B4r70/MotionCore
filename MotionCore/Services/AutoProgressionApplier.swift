//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : AutoProgressionApplier.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Wendet Auto-Progression auf ExerciseProgressionStates an und     /
//                 erlaubt Undo. Transaktional pro Aufruf. (Phase 1.5)              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

enum AutoProgressionApplier {

    // MARK: - Apply

    /// Prüft alle Übungen der Session via AutoProgressionCalcEngine und aktualisiert
    /// workingWeight wenn alle Kriterien erfüllt sind.
    /// Setzt vorher alle alten undoable-States zurück (nur eine Karte gleichzeitig sichtbar).
    @discardableResult
    static func apply(
        forSession session: StrengthSession,
        allPreviousSessions: [StrengthSession],
        studioEquipments: [StudioEquipment],
        context: ModelContext,
        repository: ProgressionStateProviding,
        readinessModifier: Double = 1.0
    ) -> [ExerciseProgressionState] {
        // Kein Auto-Progress bei eingeschränkter Tagesform — Gewicht soll nicht steigen
        // wenn der User schon reduzierte Loads trainiert hat (Phase 2)
        guard readinessModifier >= 1.0 else { return [] }
        let equipmentByID: [UUID: StudioEquipment] = Dictionary(
            uniqueKeysWithValues: studioEquipments.map { ($0.id, $0) }
        )

        let groupKeys = Set(
            session.safeExerciseSets.filter { $0.setKind == .work }.map { $0.groupKey }
        )

        var applied: [ExerciseProgressionState] = []

        for groupKey in groupKeys {
            guard let state = repository.fetch(exerciseGroupKey: groupKey),
                  state.progressionMode == .smart else { continue }

            // Letzte 2 abgeschlossene Sessions (exkl. aktuelle) mit Sets dieser Übung
            let sessionSets = allPreviousSessions
                .filter { $0.isCompleted }
                .sorted { $0.date > $1.date }
                .compactMap { s -> [ExerciseSet]? in
                    let sets = s.safeExerciseSets.filter { $0.groupKey == groupKey }
                    return sets.isEmpty ? nil : sets
                }
            let last2 = Array(sessionSets.prefix(2))

            // Equipment via Set-Relationship
            let firstSet = session.safeExerciseSets.first { $0.groupKey == groupKey }
            let exercise = firstSet?.exercise
            let studioEquipment = exercise?.studioEquipmentID.flatMap { equipmentByID[$0] }
            let fallbackStep = exercise?.progressionStep ?? 2.5

            let output = AutoProgressionCalcEngine.calculate(input: .init(
                progressionState: state,
                last2Sessions: last2,
                studioEquipment: studioEquipment,
                exerciseFallbackStep: fallbackStep
            ))

            guard output.shouldAutoProgress else { continue }

            state.previousWorkingWeight = state.workingWeight
            state.workingWeight = output.newWeight
            state.lastAutoProgressionDate = Date()
            state.lastAutoProgressionAmount = output.amount
            state.autoProgressionUndoable = true
            state.updatedAt = Date()

            applied.append(state)
        }

        if !applied.isEmpty {
            try? context.save()
        }

        return applied
    }

    // MARK: - Undo (einzeln)

    static func undo(state: ExerciseProgressionState, context: ModelContext) {
        if let prev = state.previousWorkingWeight {
            state.workingWeight = prev
        }
        state.autoProgressionUndoable = false
        state.updatedAt = Date()
        try? context.save()
    }

    // MARK: - Undo (alle)

    static func undoAll(context: ModelContext) {
        let allStates = (try? context.fetch(FetchDescriptor<ExerciseProgressionState>())) ?? []
        let undoable = allStates.filter { $0.autoProgressionUndoable }
        guard !undoable.isEmpty else { return }
        for state in undoable {
            if let prev = state.previousWorkingWeight {
                state.workingWeight = prev
            }
            state.autoProgressionUndoable = false
            state.updatedAt = Date()
        }
        try? context.save()
    }

    // MARK: - Reset (beim Start neuer Session)

    static func resetAllUndoable(context: ModelContext) {
        let allStates = (try? context.fetch(FetchDescriptor<ExerciseProgressionState>())) ?? []
        let undoable = allStates.filter { $0.autoProgressionUndoable }
        guard !undoable.isEmpty else { return }
        undoable.forEach { $0.autoProgressionUndoable = false }
        try? context.save()
    }
}
