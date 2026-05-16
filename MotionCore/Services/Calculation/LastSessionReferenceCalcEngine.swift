//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Calculation                                           /
// Datei . . . . : LastSessionReferenceCalcEngine.swift                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 16.05.2026                                                       /
// Beschreibung  : Ermittelt historische Referenz-Werte (Reps/Gewicht) fuer         /
//                 einen aktiven Satz, basierend auf der letzten Session.            /
//                 Gating: nur wenn >= 2 Work-Saetze von Plan abwichen.             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

struct LastSessionReferenceCalcEngine {

    // MARK: - Typen

    struct Reference {
        let reps: Int
        let weight: Double
    }

    struct Input {
        /// Satznummer des aktuell anzuzeigenden Satzes
        let activeSetNumber: Int
        /// Alle Saetze der letzten abgeschlossenen Session fuer diese Uebung
        let lastSessionSets: [ExerciseSet]
        /// Alle Plan-Template-Saetze fuer diese Uebung (aus sourceTrainingPlan)
        let planTemplateSets: [ExerciseSet]
    }

    // MARK: - Kernlogik

    static func resolve(input: Input) -> Reference? {
        // 1. Nur Work-Sets beruecksichtigen
        let lastWork = input.lastSessionSets.filter { $0.setKind == .work }
        let planWork = input.planTemplateSets.filter { $0.setKind == .work }

        // 2. Paare per setNumber zusammenfuehren (strikt: kein Match → kein Paar)
        var pairs: [Int: (last: ExerciseSet, plan: ExerciseSet)] = [:]
        for planSet in planWork {
            if let lastSet = lastWork.first(where: { $0.setNumber == planSet.setNumber }) {
                pairs[planSet.setNumber] = (last: lastSet, plan: planSet)
            }
        }

        // 3. Abweichungen zaehlen (Gewicht: >= 0.01 Differenz; Reps: ungleich)
        let deviationCount = pairs.values.filter { pair in
            abs(pair.last.weight - pair.plan.weight) >= 0.01 || pair.last.reps != pair.plan.reps
        }.count

        // 4. Gating: mindestens 2 abweichende Saetze erforderlich
        guard deviationCount >= 2 else { return nil }

        // 5. Referenz fuer den angeforderten Satz liefern
        guard let pair = pairs[input.activeSetNumber] else { return nil }
        return Reference(reps: pair.last.reps, weight: pair.last.weight)
    }
}
