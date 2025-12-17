//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : StrengthTypes.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 17.12.2025                                                       /
// Beschreibung  : Enumerationen für die Krafttraining-Klasse                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: Workout-Typen für Krafttrainings

enum StrengthWorkoutType: String, Codable, CaseIterable, Identifiable {
    case fullBody       // Ganzkörper
    case upper          // Oberkörper
    case lower          // Unterkörper
    case push           // Push (Druck-Übungen)
    case pull           // Pull (Zug-Übungen)
    case legs           // Beine
    case core           // Core/Bauch
    case custom         // Individuell

    var id: Self { self }
}
