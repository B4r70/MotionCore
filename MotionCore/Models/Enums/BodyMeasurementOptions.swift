//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell / Enums                                             /
// Datei . . . . : BodyMeasurementOptions.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.05.2026                                                       /
// Beschreibung  : Optionen für die Erfassung von Körpermaßen                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

enum BodyMeasurementSideMode: String, CaseIterable, Identifiable {
    case singleSide
    case bothSides

    var id: String { rawValue }

    var label: String {
        switch self {
        case .singleSide: return "Nur ein Wert"
        case .bothSides:  return "Rechts + Links getrennt"
        }
    }
}
