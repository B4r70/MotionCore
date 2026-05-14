//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Hilftools                                                        /
// Datei . . . . : MuscleRecoveryUI.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 14.05.2026                                                       /
// Beschreibung  : SwiftUI-Hilfsfunktionen für MuscleRecovery-Typen                 /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Farb-Hilfsfunktion

/// HSL-Interpolation: rot (0%) → grün (100%)
func recoveryColor(percent: Double) -> Color {
    // Hue 0° (rot) bei 0%, Hue 120° (grün) bei 100%
    let hue = (percent / 100.0) * 120.0 / 360.0
    return Color(hue: hue, saturation: 0.75, brightness: 0.85)
}
