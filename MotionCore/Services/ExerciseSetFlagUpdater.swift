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
        workSets.last?.isLastSetOfExercise = true
    }
}
