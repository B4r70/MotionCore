//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Active / Components                                              /
// Datei . . . . : ReadinessLabelStyle.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Color + Icon pro ReadinessLabel (UI-Extension, Phase 2)          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

extension ReadinessLabel {
    var color: Color {
        switch self {
        case .veryLow:   return Theme.danger
        case .low:       return Theme.warning
        case .normal:    return Theme.warning
        case .good:      return Theme.success
        case .excellent: return Theme.success
        }
    }

    var systemIcon: String {
        switch self {
        case .veryLow:   return "battery.0percent"
        case .low:       return "battery.25percent"
        case .normal:    return "battery.50percent"
        case .good:      return "battery.75percent"
        case .excellent: return "bolt.heart.fill"
        }
    }
}
