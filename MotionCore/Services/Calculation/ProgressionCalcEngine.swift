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

        let modeW = Self.modeWeight(from: workSets) ?? workSets.last!.weight
        let modeWeightSets = workSets.filter { $0.weight == modeW }

        // RIR-Quelle: letzter Modus-Satz mit rpeRecorded, Fallback auf letzten Modus-Satz
        let lastSet = modeWeightSets.last(where: { $0.rpeRecorded }) ?? modeWeightSets.last ?? workSets.last!

        // hasRIRData via rpeRecorded-Flag (Phase 1.5): disambiguiert rpe=0 ("RIR 10 = leicht" vs. "nicht erfasst").
        let hasRIRData = lastSet.rpeRecorded
        let lastRIR = lastSet.calculatedRIR

        let allHitTarget = modeWeightSets.allSatisfy { $0.reps >= state.targetReps }
        let repsBelowMin = modeWeightSets.contains { $0.reps < state.minTargetReps }
        let increment = input.studioEquipment?.increment ?? input.exerciseFallbackStep

        // -----------------------------------------------------------------------
        // 5a: Alle Reps erreicht + RIR ≤ 1 → 1× Increment erhöhen
        // -----------------------------------------------------------------------
        if allHitTarget && hasRIRData && lastRIR <= 1 {
            let raw = modeW + increment
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
            let raw = modeW + 2 * increment
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
                    suggestedWeight: modeW,
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
            suggestedWeight: modeW,
            suggestedReps: state.targetReps,
            reasoning: .holdWeight,
            isProgressionStep: false,
            isRollbackCandidate: false
        )
    }

    // MARK: - Private Helpers

    /// Häufigstes Gewicht aus den übergebenen Sätzen. Bei Gleichstand: niedrigstes (konservativ).
    private static func modeWeight(from sets: [ExerciseSet]) -> Double? {
        guard !sets.isEmpty else { return nil }
        var counts: [Double: Int] = [:]
        for set in sets { counts[set.weight, default: 0] += 1 }
        let maxCount = counts.values.max()!
        return counts.filter { $0.value == maxCount }.keys.min()
    }
}

// MARK: - Testszenarien (Concept 4.1, Instruction 1.14)
//
// 1. lastSessionSets.isEmpty .......................... → .firstSession
// 2. progressionMode == .off .......................... → .noProgression
// 3. Modus 30kg, alle ≥ targetReps, rpeRecorded=true, rpe=9 (RIR 1) ..... → .increaseWeight (modeW+inc)
// 4. Modus 30kg, alle ≥ targetReps, rpeRecorded=true, rpe=6 (RIR 4) ..... → .bigIncrease (modeW+2*inc)
// 5. Modus 30kg, reps < minTargetReps, rpeRecorded=false, progDate>14d ... → .holdWeight 30kg (5c)
// 6. Modus 30kg, reps < minTargetReps, lastProgDate heute-5d ............. → .rollbackSuggested (5d)
// 9. Sätze: 30/30/32.5kg → modeW=30, Auswertung nur auf 30kg-Sätze ........ → korrekte Baseline
// 7. readinessModifier=0.85 ........................... → .readinessReduced (floor-gerundet)
// 8. currentSessionSetIndex=1 + prev=60kg ............. → suggestedWeight=60, .holdWeight
