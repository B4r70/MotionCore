//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Berechnung                                                       /
// Datei . . . . : SessionPlanSyncCalcEngine.swift                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 28.04.2026                                                       /
// Beschreibung  : Vergleicht eine einzelne StrengthSession mit ihrem sourceTrainingPlan
//                 und liefert einen PlanUpdateProposal (Option A — direkter 1:1-Sync)
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Session-Plan Sync Calc Engine (Option A)

struct SessionPlanSyncCalcEngine {

    /// Analysiert Session ↔ Plan und liefert einen Vorschlag.
    /// - Parameters:
    ///   - session: Die abgeschlossene Session als Referenz
    ///   - plan: Der zugehörige TrainingPlan (sourceTrainingPlan)
    /// - Returns: PlanUpdateProposal mit allen Diffs; leeres changes-Array wenn Plan == Session
    func analyze(session: StrengthSession, plan: TrainingPlan) -> PlanUpdateProposal {

        // Nur abgeschlossene Work-Sets der Session berücksichtigen
        let sessionWorkSets = session.safeExerciseSets.filter { $0.setKind == .work && $0.isCompleted }

        // Session-Übungen nach groupKey gruppieren
        let sessionGroups = Dictionary(grouping: sessionWorkSets) { $0.groupKey }

        // Plan-Übungen nach groupKey gruppieren (nur Work-Sets)
        let planWorkSets = plan.safeTemplateSets.filter { $0.setKind == .work }
        let planGroups = Dictionary(grouping: planWorkSets) { $0.groupKey }

        var changes: [PlanUpdateChange] = []

        // --- Schritt 1: Neue Übungen (in Session, nicht im Plan) → vorselektiert ---
        for (groupKey, sessionSets) in sessionGroups where planGroups[groupKey] == nil {
            guard let firstSet = sessionSets.first else { continue }
            let exerciseName = firstSet.exerciseNameSnapshot.isEmpty
                ? firstSet.exerciseName
                : firstSet.exerciseNameSnapshot

            let snapshots = sessionSets
                .sorted { $0.setNumber < $1.setNumber }
                .map { set in
                    ExerciseSetSnapshot(
                        exerciseName: set.exerciseName,
                        exerciseNameSnapshot: set.exerciseNameSnapshot,
                        exerciseUUIDSnapshot: set.exerciseUUIDSnapshot,
                        exerciseMediaAssetName: set.exerciseMediaAssetName,
                        isUnilateralSnapshot: set.isUnilateralSnapshot,
                        setNumber: set.setNumber,
                        weight: set.weight,
                        weightPerSide: set.weightPerSide,
                        reps: set.reps,
                        targetRepsMin: set.targetRepsMin,
                        targetRepsMax: set.targetRepsMax,
                        targetRIR: set.targetRIR,
                        setKind: set.setKind,
                        restSeconds: set.restSeconds,
                        sortOrder: set.sortOrder,
                        groupId: set.groupId,
                        supersetGroupId: set.supersetGroupId
                    )
                }

            changes.append(PlanUpdateChange(
                exerciseGroupKey: groupKey,
                exerciseName: exerciseName,
                changeType: .exerciseAdded(sets: snapshots),
                isSelected: true // Neue Übungen aus direkter Session-Analyse vorselektieren
            ))
        }

        // --- Schritt 2: Gewichts-Update + Satzanzahl-Update pro Plan-Übung ---
        for (groupKey, planSets) in planGroups {
            guard let firstPlanSet = planSets.first else { continue }
            let exerciseName = firstPlanSet.exerciseNameSnapshot.isEmpty
                ? firstPlanSet.exerciseName
                : firstPlanSet.exerciseNameSnapshot

            guard let sessionSets = sessionGroups[groupKey], !sessionSets.isEmpty else {
                // Schritt 4: Übung übersprungen → exerciseSkipped (nur informativ)
                continue
            }

            // Gewicht: Modus der Work-Sets in der Session
            let sessionMode = modeWeight(of: sessionSets)
            let planMedian = medianWeight(of: planSets)

            let weightDelta = sessionMode - planMedian
            if abs(weightDelta) >= 1.0 {
                let isSelected = weightDelta > 0 // Erhöhung vorselektieren
                changes.append(PlanUpdateChange(
                    exerciseGroupKey: groupKey,
                    exerciseName: exerciseName,
                    changeType: .weightUpdate(from: planMedian, to: sessionMode),
                    isSelected: isSelected
                ))
            }

            // Satzanzahl
            let planCount = planSets.count
            let sessionCount = sessionSets.count
            if sessionCount != planCount {
                let isSelected = sessionCount > planCount // Erhöhung vorselektieren
                changes.append(PlanUpdateChange(
                    exerciseGroupKey: groupKey,
                    exerciseName: exerciseName,
                    changeType: .setCountUpdate(from: planCount, to: sessionCount),
                    isSelected: isSelected
                ))
            }
        }

        // --- Schritt 3: Nicht trainierte Übungen aus dem Plan ---
        for (groupKey, planSets) in planGroups where sessionGroups[groupKey] == nil {
            guard let firstPlanSet = planSets.first else { continue }
            let exerciseName = firstPlanSet.exerciseNameSnapshot.isEmpty
                ? firstPlanSet.exerciseName
                : firstPlanSet.exerciseNameSnapshot

            // Übung nicht trainiert → exerciseRemoved (NICHT vorselektiert)
            changes.append(PlanUpdateChange(
                exerciseGroupKey: groupKey,
                exerciseName: exerciseName,
                changeType: .exerciseRemoved,
                isSelected: false
            ))
        }

        return PlanUpdateProposal(
            plan: plan,
            changes: changes,
            analyzedSessionCount: 1,
            analyzedSessionDates: [session.date],
            sourceSessionUUID: session.sessionUUID.uuidString
        )
    }

    // MARK: - Hilfs-Methoden

    /// Modus-Gewicht: häufigstes Gewicht in den Sets (stabil für 1:1-Session-Vergleich)
    private func modeWeight(of sets: [ExerciseSet]) -> Double {
        guard !sets.isEmpty else { return 0 }
        var counts: [Double: Int] = [:]
        for set in sets { counts[set.weight, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key ?? sets[0].weight
    }

    private func medianWeight(of sets: [ExerciseSet]) -> Double {
        let weights = sets.map { $0.weight }.sorted()
        guard !weights.isEmpty else { return 0 }
        let mid = weights.count / 2
        if weights.count % 2 == 0 {
            return (weights[mid - 1] + weights[mid]) / 2.0
        } else {
            return weights[mid]
        }
    }
}
