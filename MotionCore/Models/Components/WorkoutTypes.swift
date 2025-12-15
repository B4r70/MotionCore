//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : WorkoutTypes.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Wertebereiche für das Daten-Modell "WorkoutSession"              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

enum Intensity: Int, Codable, CaseIterable {
    case none = 0
    case veryEasy = 1
    case easy = 2
    case medium = 3
    case hard = 4
    case veryHard = 5
}

enum TrainingProgram: String, Codable, CaseIterable, Identifiable {
    case manual
    case fatBurn
    case cardio
    case hill
    case random
    case fitTest

    var id: Self { self }
}

/// Art eines Trainingsblocks innerhalb einer Workout-Session
///
/// - cardio: Klassisches Cardiotraining (z. B. Crosstrainer, Ergometer)
/// - strength: Krafttraining mit Übungen, Sätzen und Gewichten
/// - outdoor: Outdoor-Training (z. B. Laufen, Radfahren, Wandern)
///
/// Hinweis:
/// Der Enum wird als Int persistiert (SwiftData-kompatibel).
/// Die Reihenfolge der RawValues darf sich später NICHT ändern.
enum WorkoutEntryKind: Int, Codable {
    case cardio = 0
    case strength = 1
    case outdoor = 2
}
