//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Berechnung                                                       /
// Datei . . . . : PlanUpdateApplicator.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 21.03.2026                                                       /
// Beschreibung  : Wendet Plan-Update-Änderungen auf einen TrainingPlan an          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

// MARK: - Plan-Update Applicator

struct PlanUpdateApplicator {

    /// Wendet die ausgewählten Änderungen auf den Plan an.
    /// - Parameters:
    ///   - changes: Nur die vorher gefilterten (isSelected == true) Änderungen
    ///   - plan: Der zu aktualisierende TrainingPlan
    ///   - context: SwiftData ModelContext für Inserts/Deletes
    ///   - sourceSessionUUID: UUID-String der auslösenden Session (für Tracking)
    static func apply(
        changes: [PlanUpdateChange],
        to plan: TrainingPlan,
        context: ModelContext,
        sourceSessionUUID: String? = nil
    ) {
        for change in changes {
            switch change.changeType {

            case .weightUpdate(_, let newWeight):
                // Work-Sets mit passendem groupKey aktualisieren
                let matchingSets = plan.safeTemplateSets.filter {
                    $0.groupKey == change.exerciseGroupKey && $0.setKind == .work
                }
                for set in matchingSets {
                    set.weight = newWeight
                }

            case .setCountUpdate(let oldCount, let newCount):
                let matchingSets = plan.safeTemplateSets
                    .filter { $0.groupKey == change.exerciseGroupKey && $0.setKind == .work }
                    .sorted { $0.setNumber < $1.setNumber }

                if newCount > oldCount {
                    // Mehr Sätze: letzten Satz klonen und anhängen
                    let setsToAdd = newCount - oldCount
                    guard let lastSet = matchingSets.last else { continue }
                    for i in 0..<setsToAdd {
                        let newSet = lastSet.cloneForPlanEditing()
                        newSet.setNumber = oldCount + i + 1
                        newSet.sortOrder = lastSet.sortOrder
                        plan.addTemplateSet(newSet)
                        context.insert(newSet)
                    }
                } else if newCount < oldCount {
                    // Weniger Sätze: überzählige Sätze vom Ende entfernen
                    let setsToRemove = oldCount - newCount
                    let toDelete = Array(matchingSets.suffix(setsToRemove))
                    for set in toDelete {
                        context.delete(set)
                    }
                }

            case .exerciseAdded(let snapshots):
                // Neue Übung aus Snapshots als Template-Sets anlegen
                let nextOrder = plan.nextSortOrder
                for snapshot in snapshots {
                    let newSet = ExerciseSet(
                        exerciseName: snapshot.exerciseName,
                        exerciseNameSnapshot: snapshot.exerciseNameSnapshot,
                        exerciseUUIDSnapshot: snapshot.exerciseUUIDSnapshot,
                        exerciseMediaAssetName: snapshot.exerciseMediaAssetName,
                        isUnilateralSnapshot: snapshot.isUnilateralSnapshot,
                        setNumber: snapshot.setNumber,
                        weight: snapshot.weight,
                        weightPerSide: snapshot.weightPerSide,
                        reps: snapshot.reps,
                        restSeconds: snapshot.restSeconds,
                        setKind: snapshot.setKind,
                        isCompleted: false,
                        targetRepsMin: snapshot.targetRepsMin,
                        targetRepsMax: snapshot.targetRepsMax,
                        targetRIR: snapshot.targetRIR,
                        groupId: snapshot.groupId,
                        sortOrder: nextOrder,
                        supersetGroupId: snapshot.supersetGroupId
                    )
                    context.insert(newSet)
                    plan.addTemplateSet(newSet)
                }

            case .exerciseSkipped:
                // Übersprungene Übungen nur informativ — keine Aktion
                break
            }
        }

        // Tracking-Felder aktualisieren
        plan.lastUpdatedFromSession = Date()
        plan.lastUpdateSourceSessionUUID = sourceSessionUUID
    }
}
