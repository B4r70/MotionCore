//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : ExerciseSetFlagUpdater.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Haelt isLastSetOfExercise-Flags konsistent wenn Saetze           /
//                 hinzugefuegt, geloescht oder umsortiert werden.                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

enum ExerciseSetFlagUpdater {
    static func updateLastSetFlags(
        forExerciseGroup groupKey: String,
        in session: StrengthSession
    ) {
        let workSets = session.safeExerciseSets
            .filter { $0.groupKey == groupKey && $0.setKind == .work }
            .sorted { $0.setNumber < $1.setNumber }

        workSets.forEach { $0.isLastSetOfExercise = false }
        // Nur für Weight-Sätze — zeitbasierte Sätze brauchen kein RIR-Flag
        let lastWeightWorkSet = workSets.filter { !$0.isTimeBased }.last
        lastWeightWorkSet?.isLastSetOfExercise = true
    }
}
