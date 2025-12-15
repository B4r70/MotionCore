//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : StrengthSet.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 15.12.2025                                                       /
// Beschreibung  : Model für Krafttraining                                          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

// Ein Satz innerhalb eines Krafttrainings-Blocks (WorkoutEntry.kind == .strength)
@Model
final class StrengthSet {

    // MARK: - Beziehung zum Trainingsblock

    // Zugehöriger Trainingsblock (z. B. Brustpresse)
    var entry: WorkoutEntry?

    // MARK: - Satzdaten

    // Laufende Satznummer (0-basiert oder 1-basiert – du entscheidest später)
    var setIndex: Int = 0

    // Wiederholungen
    var reps: Int = 0

    // Gewicht in Kilogramm
    var weightKg: Double = 0

    // Optional: Notiz (z. B. Technikhinweis)
    var note: String?

    init(setIndex: Int, reps: Int, weightKg: Double, note: String? = nil) {
        self.setIndex = max(setIndex, 0)
        self.reps = max(reps, 0)
        self.weightKg = max(weightKg, 0)
        self.note = note
    }
}
