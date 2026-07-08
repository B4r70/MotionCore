//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Hilftools                                                        /
// Datei . . . . : PlanTypeUI.swift                                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 03.07.2026                                                       /
// Beschreibung  : PlanType UI-Erweiterung: ruhiger Typ-Ton (Calm 2026)             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: PlanType — ruhiger Typ-Ton (an WorkoutType/AP 4 angeglichen)

extension PlanType {
    // Gesättigter Akzent-Ton je Plan-Typ.
    var calmTint: Color {
        switch self {
        case .strength: Theme.accent
        case .cardio:   Theme.series[1]
        case .outdoor:  Theme.success
        case .mixed:    Theme.series[2]
        }
    }

    // Weiche Tönung hinter dem Plan-Tile (Buchstaben-/Icon-Kachel).
    var calmTileBackground: Color {
        switch self {
        case .strength: Theme.accent.opacity(0.14)
        case .cardio:   Theme.series[1].opacity(0.14)
        case .outdoor:  Theme.success.opacity(0.14)
        case .mixed:    Theme.series[2].opacity(0.14)
        }
    }
}
