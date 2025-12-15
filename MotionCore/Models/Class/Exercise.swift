//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : Exercise.swift                                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 15.12.2025                                                       /
// Beschreibung  : Model für die einzelnen Trainings                                /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

// Beschreibt eine konkrete Übung (z. B. Brustpresse, Kniebeuge)
@Model
final class Exercise {

    // Anzeigename der Übung
    var name: String

    // Primäre Muskelgruppe (z. B. Brust, Beine)
    var primaryMuscle: String?

    // Optional: Name oder Pfad zu GIF/Animation
    var demoAssetName: String?

    init(
        name: String,
        primaryMuscle: String? = nil,
        demoAssetName: String? = nil
    ) {
        self.name = name
        self.primaryMuscle = primaryMuscle
        self.demoAssetName = demoAssetName
    }
}
