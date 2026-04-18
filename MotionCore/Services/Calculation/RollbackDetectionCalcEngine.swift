//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Calculation                                           /
// Datei . . . . : RollbackDetectionCalcEngine.swift                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Erkennt, ob nach einer kuerzlichen Progression ein Rollback      /
//                 sinnvoll ist (2 Sessions unter Ziel-Reps).                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

struct RollbackDetectionCalcEngine {

    // MARK: - I/O-Typen

    struct Input {
        let progressionState: ExerciseProgressionState
        /// Die letzten 2 Sessions (neueste zuerst), jeweils als Array aller ExerciseSets dieser Session
        let last2Sessions: [[ExerciseSet]]
    }

    struct Output {
        let shouldSuggestRollback: Bool
        let previousWeight: Double?
        let reasoning: String
    }

    // MARK: - Entscheidungslogik

    static func detect(input: Input) -> Output {
        let state = input.progressionState

        // Kein Rollback ohne vergangene Progression
        guard let progDate = state.lastProgressionDate else {
            return Output(shouldSuggestRollback: false, previousWeight: nil,
                          reasoning: "Keine vergangene Progression, kein Rollback möglich")
        }

        // Mindestens 2 Sessions nötig
        guard input.last2Sessions.count >= 2 else {
            return Output(shouldSuggestRollback: false, previousWeight: nil,
                          reasoning: "Weniger als 2 Sessions vorhanden")
        }

        // 14-Tage-Proxy: Progression muss noch frisch sein (konsistent mit ProgressionCalcEngine)
        let daysSince = Calendar.current.dateComponents([.day], from: progDate, to: Date()).day ?? 999
        guard daysSince < 14 else {
            return Output(shouldSuggestRollback: false, previousWeight: nil,
                          reasoning: "Letzte Progression liegt mehr als 14 Tage zurück")
        }

        // Prüfe beide Sessions: lastSet.reps < minTargetReps
        var sessionsBelowMin = 0
        for sessionSets in input.last2Sessions.prefix(2) {
            if let set = lastWorkSet(of: sessionSets), set.reps < state.minTargetReps {
                sessionsBelowMin += 1
            }
        }

        switch sessionsBelowMin {
        case 2:
            return Output(
                shouldSuggestRollback: true,
                previousWeight: state.previousWorkingWeight,
                reasoning: "Zwei Sessions unter Zielreps seit letzter Progression — Rollback sinnvoll"
            )
        case 1:
            return Output(shouldSuggestRollback: false, previousWeight: nil,
                          reasoning: "Nur eine der letzten 2 Sessions unter Zielreps")
        default:
            return Output(shouldSuggestRollback: false, previousWeight: nil,
                          reasoning: "Kein Rollback-Trigger (Bedingungen nicht erfüllt)")
        }
    }

    // MARK: - Hilfen

    /// Letzter abgeschlossener Work-Set einer Session.
    /// Priorität: isLastSetOfExercise == true, Fallback: letzter nach sortOrder (Legacy-Sessions).
    private static func lastWorkSet(of sets: [ExerciseSet]) -> ExerciseSet? {
        let workSets = sets
            .filter { $0.isCompleted && $0.setKindRaw == "work" }
            .sorted { $0.sortOrder < $1.sortOrder }
        return workSets.first(where: { $0.isLastSetOfExercise }) ?? workSets.last
    }
}

// MARK: - Testszenarien (Concept 4.3, Instruction 1.15)
// 1. lastProgressionDate == nil .......................... → kein Rollback (keine Progression)
// 2. last2Sessions.count < 2 ............................. → kein Rollback (zu wenige Sessions)
// 3. lastProgressionDate > 14 Tage alt ................... → kein Rollback (Datums-Proxy)
// 4. Beide Sessions: letzter Satz < minTargetReps ........ → Rollback, previousWeight zurück
// 5. Nur eine Session: letzter Satz < minTargetReps ...... → kein Rollback (1 von 2)
// 6. Beide Sessions: letzter Satz >= minTargetReps ....... → kein Rollback (Bedingungen nicht erfüllt)
