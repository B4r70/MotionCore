//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Plan                                                  /
// Datei . . . . : ProgressionStateEnsurer.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 28.04.2026                                                       /
// Beschreibung  : Stellt ExerciseProgressionState für alle Übungen eines Plans sicher.
//                 Idempotent — vorhandene States werden nicht verändert.           /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : workingWeight wird aus sessionSets (Modus) oder Plan-Template-Sets
//                initialisiert. Nie aus dem Nichts — 0.0 nur wenn keine Daten.    /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

// MARK: - Progression State Ensurer

struct ProgressionStateEnsurer {

    /// Stellt für jede Übungsgruppe im Plan einen ExerciseProgressionState sicher.
    /// Existierende States werden NICHT verändert (idempotent).
    /// - Parameters:
    ///   - plan: Der TrainingPlan, für den States sichergestellt werden sollen
    ///   - sessionSets: Optionale Session-Sets für initiales workingWeight (Modus). Falls nil → Plan-Template-Sets.
    ///   - context: SwiftData ModelContext für Fetches und Inserts
    static func ensureStates(
        forPlan plan: TrainingPlan,
        sessionSets: [ExerciseSet]?,
        context: ModelContext
    ) {
        // Alle bekannten ExerciseGroupKeys im Plan ermitteln
        let planGroupKeys = Set(plan.safeTemplateSets.map { $0.groupKey })
        guard !planGroupKeys.isEmpty else { return }

        // Alle existierenden States für diese Plan-Übungen laden
        let existingKeys = fetchExistingGroupKeys(context: context)

        // Fehlende States anlegen
        for groupKey in planGroupKeys where !existingKeys.contains(groupKey) {
            let initialWeight = resolveInitialWeight(
                groupKey: groupKey,
                sessionSets: sessionSets,
                planSets: plan.safeTemplateSets
            )

            let state = ExerciseProgressionState(
                exerciseGroupKey: groupKey,
                workingWeight: initialWeight
            )
            context.insert(state)
        }

        // Speichern — Fehler werden geloggt, Ensurer läuft weiter (not mission-critical)
        do {
            try context.save()
        } catch {
            print("⚠️ ProgressionStateEnsurer: save fehlgeschlagen für Plan '\(plan.title)': \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers

    /// Lädt alle bereits vorhandenen exerciseGroupKeys aus SwiftData.
    private static func fetchExistingGroupKeys(context: ModelContext) -> Set<String> {
        let descriptor = FetchDescriptor<ExerciseProgressionState>()
        let states = (try? context.fetch(descriptor)) ?? []
        return Set(states.map { $0.exerciseGroupKey })
    }

    /// Ermittelt das initiale workingWeight für eine Übungsgruppe.
    /// Priorität: Modus aus sessionSets → Modus aus Plan-Work-Sets → 0.0
    private static func resolveInitialWeight(
        groupKey: String,
        sessionSets: [ExerciseSet]?,
        planSets: [ExerciseSet]
    ) -> Double {
        // 1. Modus aus Session-Sets (falls vorhanden)
        if let session = sessionSets {
            let matching = session.filter { $0.groupKey == groupKey && $0.setKind == .work }
            if !matching.isEmpty {
                return modeWeight(of: matching)
            }
        }

        // 2. Modus aus Plan-Work-Sets
        let planWorkSets = planSets.filter { $0.groupKey == groupKey && $0.setKind == .work }
        if !planWorkSets.isEmpty {
            return modeWeight(of: planWorkSets)
        }

        return 0.0
    }

    /// Modus-Gewicht: häufigstes Gewicht in den Sets.
    private static func modeWeight(of sets: [ExerciseSet]) -> Double {
        guard !sets.isEmpty else { return 0.0 }
        var counts: [Double: Int] = [:]
        for set in sets { counts[set.weight, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key ?? sets[0].weight
    }
}
