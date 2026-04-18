//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : ProgressionMode.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Progressions-Modus für ExerciseProgressionState                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

enum ProgressionMode: String, Codable, CaseIterable {
    case smart
    case advanced
    case off
}
