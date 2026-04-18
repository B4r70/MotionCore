//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Calculation                                           /
// Datei . . . . : ProgressionCalcEngine.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Pure, stateless Engine für Gewichts-/Reps-Empfehlung             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Progression Calc Engine

/// Deterministische Input → Output Engine.
/// Kein SwiftUI-Import, keine State-Mutation, keine Side Effects.
/// Date() wird lokal in recentProgression-Check gelesen (dokumentiertes Verhalten).
struct ProgressionCalcEngine {

    // MARK: - I/O-Typen

    struct Input {
        /// Persistenter Progressions-Zustand der Übung
        let progressionState: ExerciseProgressionState
        /// Abgeschlossene Sätze der letzten Session dieser Übung (alle setKind, ungefiltert)
        let lastSessionSets: [ExerciseSet]
        /// Zugewiesenes Gerät — nil wenn keine Equipment-Zuweisung
        let studioEquipment: StudioEquipment?
        /// Fallback-Schrittgröße wenn kein Equipment zugewiesen (aus Exercise.progressionStep oder 2.5)
        let exerciseFallbackStep: Double
        /// Readiness-Faktor 0.0–1.0; < 0.9 → Entlastungs-Zweig
        let readinessModifier: Double
        /// Index des aktuell zu befüllenden Satzes in der laufenden Session (0-basiert)
        let currentSessionSetIndex: Int
        /// Bereits abgeschlossene Sätze der aktuellen Session (für "folge vorherigem Satz"-Logik)
        let currentSessionPreviousSets: [ExerciseSet]
    }

    struct Output {
        let suggestedWeight: Double
        let suggestedReps: Int
        let reasoning: ProgressionReasoning
        /// True wenn die Engine eine Gewichtssteigerung empfiehlt
        let isProgressionStep: Bool
        /// True wenn Rollback auf previousWorkingWeight empfohlen wird
        let isRollbackCandidate: Bool
    }

    // MARK: - Einstiegspunkt

    static func calculate(input: Input) -> Output {
        let state = input.progressionState

        // -----------------------------------------------------------------------
        // Schritt 1: Laufende Session — folge vorherigem abgeschlossenen Work-Set
        // -----------------------------------------------------------------------
        // Nur feuern wenn wir nicht beim ersten Satz sind (index > 0)
        // und es tatsächlich abgeschlossene Work-Sets in dieser Session gibt.
        let completedWorkSetsThisSession = input.currentSessionPreviousSets
            .filter { $0.isCompleted && $0.setKindRaw == "work" }
            .sorted { $0.sortOrder < $1.sortOrder }

        if input.currentSessionSetIndex > 0, let prev = completedWorkSetsThisSession.last {
            return Output(
                suggestedWeight: prev.weight,
                suggestedReps: state.targetReps,
                reasoning: .holdWeight,
                isProgressionStep: false,
                isRollbackCandidate: false
            )
        }

        // -----------------------------------------------------------------------
        // Schritt 2: Keine Vorsessions-Daten → erster Einsatz dieser Übung
        // -----------------------------------------------------------------------
        if input.lastSessionSets.isEmpty {
            return Output(
                suggestedWeight: state.workingWeight,
                suggestedReps: state.targetReps,
                reasoning: .firstSession,
                isProgressionStep: false,
                isRollbackCandidate: false
            )
        }

        // -----------------------------------------------------------------------
        // Schritt 3: Modus .off oder .advanced → keine Engine-Empfehlung
        // -----------------------------------------------------------------------
        switch state.progressionMode {
        case .off, .advanced:
            return Output(
                suggestedWeight: state.workingWeight,
                suggestedReps: state.targetReps,
                reasoning: .noProgression,
                isProgressionStep: false,
                isRollbackCandidate: false
            )
        case .smart:
            break
        }

        // -----------------------------------------------------------------------
        // Schritt 4: Readiness-Reduktion — Gewicht proportional senken (floor)
        // -----------------------------------------------------------------------
        // Barto-Entscheidung 18.04.2026: .floor bei readinessReduced (konsequente Entlastung)
        if input.readinessModifier < 0.9 {
            let raw = state.workingWeight * input.readinessModifier
            let rounded = EquipmentWeightRounding.roundToValidWeight(
                raw,
                equipment: input.studioEquipment,
                fallbackStep: input.exerciseFallbackStep,
                rule: .floor
            )
            return Output(
                suggestedWeight: rounded,
                suggestedReps: state.targetReps,
                reasoning: .readinessReduced,
                isProgressionStep: false,
                isRollbackCandidate: false
            )
        }

        // -----------------------------------------------------------------------
        // Schritt 5: Letzte-Session-Analyse
        // -----------------------------------------------------------------------
        let workSets = input.lastSessionSets
            .filter { $0.isCompleted && $0.setKindRaw == "work" }
            .sorted { $0.sortOrder < $1.sortOrder }

        guard !workSets.isEmpty else {
            // Nur Warmup-Sätze in letzter Session → Gewicht halten
            return Output(
                suggestedWeight: state.workingWeight,
                suggestedReps: state.targetReps,
                reasoning: .holdWeight,
                isProgressionStep: false,
                isRollbackCandidate: false
            )
        }

        // Letzter Work-Set: isLastSetOfExercise bevorzugt (für korrekte RIR-Quelle),
        // Fallback auf workSets.last für Legacy-Sessions vor 1.4 (isLastSetOfExercise war noch nicht gesetzt)
        let lastSet = workSets.first(where: { $0.isLastSetOfExercise }) ?? workSets.last!

        // hasRIRData-Guard: rpe == 0 ist Default-Wert, bedeutet "nicht gesetzt".
        // calculatedRIR = 10 - 0 = 10 wäre fälschlich "sehr frisch" → alle Progressions-Checks abschalten.
        let hasRIRData = lastSet.rpe > 0
        let lastRIR = lastSet.calculatedRIR

        let allHitTarget = workSets.allSatisfy { $0.reps >= state.targetReps }
        let repsBelowMin = workSets.contains { $0.reps < state.minTargetReps }
        let increment = input.studioEquipment?.increment ?? input.exerciseFallbackStep

        // -----------------------------------------------------------------------
        // 5a: Alle Reps erreicht + RIR ≤ 1 → 1× Increment erhöhen
        // -----------------------------------------------------------------------
        if allHitTarget && hasRIRData && lastRIR <= 1 {
            let raw = state.workingWeight + increment
            let rounded = EquipmentWeightRounding.roundToValidWeight(
                raw,
                equipment: input.studioEquipment,
                fallbackStep: input.exerciseFallbackStep,
                rule: .nearest
            )
            return Output(
                suggestedWeight: rounded,
                suggestedReps: state.targetReps,
                reasoning: .increaseWeight,
                isProgressionStep: true,
                isRollbackCandidate: false
            )
        }

        // -----------------------------------------------------------------------
        // 5b: Alle Reps erreicht + RIR ≥ 3 → 2× Increment erhöhen (bigIncrease)
        // -----------------------------------------------------------------------
        // RIR 2 (mittel) + alle Reps erreicht → fällt in Fallback .holdWeight (Concept-konform)
        if allHitTarget && hasRIRData && lastRIR >= 3 {
            let raw = state.workingWeight + 2 * increment
            let rounded = EquipmentWeightRounding.roundToValidWeight(
                raw,
                equipment: input.studioEquipment,
                fallbackStep: input.exerciseFallbackStep,
                rule: .nearest
            )
            return Output(
                suggestedWeight: rounded,
                suggestedReps: state.targetReps,
                reasoning: .bigIncrease,
                isProgressionStep: true,
                isRollbackCandidate: false
            )
        }

        // -----------------------------------------------------------------------
        // 5c/5d: Reps unter Minimum
        // -----------------------------------------------------------------------
        if repsBelowMin {
            // recentProgression: Proxy-Kriterium (Engine kennt keine Session-Zahl).
            // Finale Prüfung erfolgt in Schritt 1.15 (RollbackDetectionCalcEngine).
            let recentProgression: Bool
            if let lastProgDate = state.lastProgressionDate {
                let daysSince = Calendar.current.dateComponents([.day], from: lastProgDate, to: Date()).day ?? 999
                recentProgression = daysSince < 14
            } else {
                recentProgression = false
            }

            if recentProgression {
                // 5d: Rollback vorschlagen — Gewicht auf previousWorkingWeight zurück
                let target = state.previousWorkingWeight ?? state.workingWeight
                let rounded = EquipmentWeightRounding.roundToValidWeight(
                    target,
                    equipment: input.studioEquipment,
                    fallbackStep: input.exerciseFallbackStep,
                    rule: .nearest
                )
                return Output(
                    suggestedWeight: rounded,
                    suggestedReps: state.targetReps,
                    reasoning: .rollbackSuggested,
                    isProgressionStep: false,
                    isRollbackCandidate: true
                )
            } else {
                // 5c: Progression zu neu — Gewicht halten, mehr Anpassungszeit geben
                return Output(
                    suggestedWeight: state.workingWeight,
                    suggestedReps: state.targetReps,
                    reasoning: .holdWeight,
                    isProgressionStep: false,
                    isRollbackCandidate: false
                )
            }
        }

        // -----------------------------------------------------------------------
        // Schritt 6: Fallback — Gewicht halten
        // -----------------------------------------------------------------------
        // Tritt auf wenn: allHitTarget=true, hasRIRData=false (kein RPE gesetzt)
        // oder RIR == 2 (mittlere Reserve, kein klarer Signal für Steigerung)
        return Output(
            suggestedWeight: state.workingWeight,
            suggestedReps: state.targetReps,
            reasoning: .holdWeight,
            isProgressionStep: false,
            isRollbackCandidate: false
        )
    }
}

// MARK: - Testszenarien (Concept 4.1, Instruction 1.14)
//
// 1. lastSessionSets.isEmpty .......................... → .firstSession
// 2. progressionMode == .off .......................... → .noProgression
// 3. alle Sätze ≥ targetReps + lastSet rpe=9 (RIR 1) .. → .increaseWeight
// 4. alle Sätze ≥ targetReps + lastSet rpe=6 (RIR 4) .. → .bigIncrease
// 5. reps < minTargetReps + rpe=10, lastProgDate > 14d . → .holdWeight (5c)
// 6. reps < minTargetReps + lastProgDate heute-5d ...... → .rollbackSuggested (5d)
// 7. readinessModifier=0.85 ........................... → .readinessReduced (floor-gerundet)
// 8. currentSessionSetIndex=1 + prev=60kg ............. → suggestedWeight=60, .holdWeight
