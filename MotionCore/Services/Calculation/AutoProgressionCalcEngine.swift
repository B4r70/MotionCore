//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Calculation                                           /
// Datei . . . . : AutoProgressionCalcEngine.swift                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Prüft ob workingWeight automatisch erhöht werden kann.           /
//                 Pure, stateless. Kriterien: 2 Sessions, Modus-Gewicht,           /
//                 Ziel-Reps, RIR erfasst, Cooldowns. (Phase 1.5)                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

struct AutoProgressionCalcEngine {

    // MARK: - I/O

    struct Input {
        /// Persistenter Progressions-Zustand der Übung
        let progressionState: ExerciseProgressionState
        /// Letzte 2 abgeschlossene Sessions als Set-Arrays, neueste zuerst
        let last2Sessions: [[ExerciseSet]]
        let studioEquipment: StudioEquipment?
        let exerciseFallbackStep: Double
    }

    struct Output {
        let shouldAutoProgress: Bool
        let newWeight: Double
        let amount: Double
        let reasoning: Reasoning

        var localizedReasoning: String { reasoning.localized }

        enum Reasoning: String {
            case consistentReadiness
            case bigIncreaseSignal

            var localized: String {
                switch self {
                case .consistentReadiness: return "2 Sessions mit RIR 0–2 und Ziel-Reps erreicht"
                case .bigIncreaseSignal:   return "Letzte Session zu leicht, großer Sprung empfohlen"
                }
            }
        }
    }

    // MARK: - Einstiegspunkt

    static func calculate(input: Input) -> Output {
        let state = input.progressionState
        let noProgress = Output(shouldAutoProgress: false, newWeight: state.workingWeight, amount: 0, reasoning: .consistentReadiness)

        // 1: Mindestens 2 Sessions
        guard input.last2Sessions.count >= 2 else { return noProgress }

        let increment = input.studioEquipment?.increment ?? input.exerciseFallbackStep

        // 2+3+4: Modus-Gewicht = workingWeight, alle Reps ≥ targetReps, RIR erfasst
        guard
            let newest = modeWeightAnalysis(input.last2Sessions[0], targetReps: state.targetReps, workingWeight: state.workingWeight),
            let older  = modeWeightAnalysis(input.last2Sessions[1], targetReps: state.targetReps, workingWeight: state.workingWeight)
        else { return noProgress }

        // 5: lastAutoProgressionDate ≥ 7 Tage zurück
        if let lastAuto = state.lastAutoProgressionDate {
            let days = Calendar.current.dateComponents([.day], from: lastAuto, to: Date()).day ?? 0
            if days < 7 { return noProgress }
        }

        // 6: lastRollbackDate > 14 Tage zurück
        if let lastRollback = state.lastRollbackDate {
            let days = Calendar.current.dateComponents([.day], from: lastRollback, to: Date()).day ?? 0
            if days <= 14 { return noProgress }
        }

        _ = older  // explizit konsumiert (Kriterien 2–4 bereits geprüft)

        // Increment-Höhe: bigIncrease wenn letzte Session RIR ≥ 3 + Reps über Ziel
        let newestRIR = newest.lastRecordedRIR
        let overTarget = newest.sets.contains { $0.reps > state.targetReps }
        let isBig = newestRIR >= 3 && overTarget
        let totalAmount = isBig ? 2 * increment : increment

        let raw = state.workingWeight + totalAmount
        let newWeight = EquipmentWeightRounding.roundToValidWeight(
            raw,
            equipment: input.studioEquipment,
            fallbackStep: input.exerciseFallbackStep,
            rule: .nearest
        )

        return Output(
            shouldAutoProgress: true,
            newWeight: newWeight,
            amount: newWeight - state.workingWeight,
            reasoning: isBig ? .bigIncreaseSignal : .consistentReadiness
        )
    }

    // MARK: - Privater Analyse-Helper

    private struct SessionAnalysis {
        let sets: [ExerciseSet]
        let lastRecordedRIR: Int
    }

    /// Prüft Kriterien 2–4 für eine Session. Gibt nil zurück wenn ein Kriterium nicht erfüllt ist.
    private static func modeWeightAnalysis(
        _ sessionSets: [ExerciseSet],
        targetReps: Int,
        workingWeight: Double
    ) -> SessionAnalysis? {
        let workSets = sessionSets
            .filter { $0.isCompleted && $0.setKindRaw == "work" }
            .sorted { $0.sortOrder < $1.sortOrder }
        guard !workSets.isEmpty else { return nil }

        // Modus-Gewicht berechnen
        var counts: [Double: Int] = [:]
        workSets.forEach { counts[$0.weight, default: 0] += 1 }
        let maxCount = counts.values.max()!
        guard let modeW = counts.filter({ $0.value == maxCount }).keys.min() else { return nil }

        // Kriterium 2: Modus-Gewicht == workingWeight
        guard abs(modeW - workingWeight) < 0.01 else { return nil }

        let modeSets = workSets.filter { $0.weight == modeW }

        // Kriterium 3: alle Modus-Sätze ≥ targetReps
        guard modeSets.allSatisfy({ $0.reps >= targetReps }) else { return nil }

        // Kriterium 4: letzter Modus-Satz hat rpeRecorded = true
        guard let lastSet = modeSets.last(where: { $0.rpeRecorded }) ?? modeSets.last,
              lastSet.rpeRecorded else { return nil }

        return SessionAnalysis(sets: modeSets, lastRecordedRIR: lastSet.calculatedRIR)
    }
}
