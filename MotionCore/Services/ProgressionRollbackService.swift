//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : ProgressionRollbackService.swift                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Service fuer Rollback-Aktionen auf ExerciseProgressionState.     /
//                 Pure static funcs, alle Writes ueber ModelContext.               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

struct ProgressionRollbackService {

    // MARK: - Rollback

    /// "Zurueck auf X kg" — Rollback + Cooldown + lastProgressionDate nullen.
    /// lastProgressionDate wird genullt, um Re-Detection durch RollbackDetectionCalcEngine zu verhindern.
    static func applyRollback(state: ExerciseProgressionState, in context: ModelContext) {
        guard let previous = state.previousWorkingWeight else { return }
        state.workingWeight = previous
        state.lastRollbackDate = Date()
        state.consecutiveFailCount = 0
        state.lastProgressionDate = nil
        state.updatedAt = Date()
        try? context.save()
    }

    // MARK: - Dismiss

    /// "Weiter versuchen" — Dismiss-Cooldown via lastRollbackDate + Fail-Count-Reset.
    static func dismissSuggestion(state: ExerciseProgressionState, in context: ModelContext) {
        state.lastRollbackDate = Date()
        state.consecutiveFailCount = 0
        state.updatedAt = Date()
        try? context.save()
    }

    // MARK: - Advanced-Switch

    /// "Ich trage selbst ein" — Progression-Mode auf Advanced setzen.
    static func switchToAdvanced(state: ExerciseProgressionState, in context: ModelContext) {
        state.progressionMode = .advanced
        state.updatedAt = Date()
        try? context.save()
    }

    // MARK: - Manueller Rollback

    /// Manueller Rollback (StrengthDetailView) — Guard + identisch zu applyRollback.
    static func manualRollback(state: ExerciseProgressionState, in context: ModelContext) {
        guard state.previousWorkingWeight != nil else { return }
        applyRollback(state: state, in: context)
    }
}
