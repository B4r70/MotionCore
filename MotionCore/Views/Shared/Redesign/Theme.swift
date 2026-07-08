//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Shared / Redesign                                        /
// Datei . . . . : Theme.swift                                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.06.2026                                                       /
// Beschreibung  : Design-Tokens: Theme, AppFont, Space, Radius (Calm 2026)         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Theme (Farb-Tokens · DESIGN.md §2)

/// Zentrale Farbquelle des Calm-2026-Redesigns. Jedes Token ist ein
/// Asset-Catalog-Colorset mit Light- UND Dark-Appearance (Werte: DESIGN.md §2).
/// Im UI-Code ausschließlich diese semantischen Namen verwenden, nie rohe Hexwerte.
/// `Color(hex:)` (ColorHexExtension) bleibt für Einzelfälle bestehen.
enum Theme {
    // Flächen
    static let surfaceApp    = Color("surfaceApp")    // Seiten-Hintergrund
    static let surfaceCard   = Color("surfaceCard")   // Karte
    static let surfaceSunken = Color("surfaceSunken") // Inset · Track · sekundär

    // Text (kühles Navy-Slate, nie reines Schwarz/Weiß)
    static let textPrimary   = Color("textPrimary")
    static let textSecondary = Color("textSecondary")
    static let textTertiary  = Color("textTertiary")

    // Linien
    static let line     = Color("line")     // Hairline (Standard)
    static let lineSoft = Color("lineSoft")

    // Akzent — EINE Quelle, app-weit. Tiefblau #2C6BCB.
    static let accent      = Color("accent")
    static let accentHover = Color("accentHover")
    static let accentPress = Color("accentPress")
    static let accentSoft  = Color("accentSoft")          // weiche Fläche
    static var accentWash: Color { accent.opacity(0.08) } // 7–13 % Tönung

    // Status / Domäne
    static let success = Color("success")   // Erfolg · Erholung · Body
    static let warning = Color("warning")   // Streak · Rekorde · Kalorien (Amber)
    static let danger  = Color("danger")    // nur Fehler · Puls-Herz

    // Datenreihen (Charts) — in dieser Reihenfolge verwenden
    static let series: [Color] = [
        Color("series1"), // Blau
        Color("series2"), // Teal
        Color("series3"), // Violett
        Color("series4"), // Amber
        Color("series5"), // Rosé
    ]
    static let chartGrid = Color("chartGrid")
}

// MARK: - AppFont (Typografie · DESIGN.md §3)

/// Native SF Pro; große Zahlen in SF Pro Rounded. Zahlen immer `.monospacedDigit()`.
enum AppFont {
    static let hero     = Font.system(size: 48, weight: .bold,     design: .rounded)
    static let metric   = Font.system(size: 32, weight: .bold,     design: .rounded)
    static let title    = Font.system(size: 22, weight: .bold)      // tracking -0.5
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body     = Font.system(size: 15, weight: .regular)
    static let callout  = Font.system(size: 13, weight: .regular)
    static let caption  = Font.system(size: 12, weight: .regular)
    static let eyebrow  = Font.system(size: 10, weight: .bold)      // UPPERCASE, tracking +0.6
}

// MARK: - Space / Radius (Raster · DESIGN.md §4)

/// 8pt-Raster. Stapel-Abstand 14–16, Karten-Polster 20–24.
enum Space {
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 20
    static let s6: CGFloat = 24
    static let s8: CGFloat = 32
}

/// Kachel `md` · Karte `lg` · Sheet/Hero `xl` · Pille = `Capsule()`.
enum Radius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let xl: CGFloat = 26
}
