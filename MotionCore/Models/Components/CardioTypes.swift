//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : CardioTypes.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Wertebereiche für das Daten-Modell "CardioWorkoutSession"        /
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
