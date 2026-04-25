//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Shared / Redesign                                        /
// Datei . . . . : MCColorPalette.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Zentrale Farbpalette für das Dashboard-Redesign                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/

import SwiftUI

// MARK: - MCColor

enum MCColor {

    // MARK: Energy (Gelb — Energie / Readiness)
    static let mcEnergy     = Color(hex: "#F5B400")
    static let mcEnergySoft = Color(hex: "#F5B400").opacity(0.18)
    static let mcEnergyInk  = Color(hex: "#F5B400").opacity(0.85)

    // MARK: Body (Grün — Muskelstatus / Erholung)
    static let mcBody     = Color(hex: "#5CC63F")
    static let mcBodySoft  = Color(hex: "#5CC63F").opacity(0.18)
    static let mcBodyInk   = Color(hex: "#5CC63F").opacity(0.85)

    // MARK: Stat (Blau — Statistik / Volumen)
    static let mcStat     = Color(hex: "#2E6DF0")
    static let mcStatSoft  = Color(hex: "#2E6DF0").opacity(0.18)
    static let mcStatInk   = Color(hex: "#2E6DF0").opacity(0.85)

    // MARK: Streak (Orange-Rot — Serien / Motivation)
    static let mcStreak     = Color(hex: "#FF6B4A")
    static let mcStreakSoft = Color(hex: "#FF6B4A").opacity(0.18)
    static let mcStreakInk  = Color(hex: "#FF6B4A").opacity(0.85)
}
