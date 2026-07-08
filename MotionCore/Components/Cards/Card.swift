//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Design                                                        /
// Datei . . . . : Card.swift                                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.06.2026                                                       /
// Beschreibung  : Standard-Karte (Hairline) — Calm 2026, ersetzt .card()      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - CardStyle (Kern-Modifier · DESIGN.md §5)

/// Solide Fläche, weiche Rundung, 1px-Hairline, flüsterleiser Schatten — ersetzt den
/// alten `.card()`-Stil. Dark-ready: Farben adaptiv aus `Theme`, Schatten nur in
/// Light; in Dark trägt Hairline + Surface-Sprung die Elevation (DESIGN.md §11).
struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat = Space.s6

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(Theme.line, lineWidth: 1)
            )
            // Schatten nur in Light; in Dark übernimmt Hairline + Surface-Sprung die Elevation.
            .shadow(color: scheme == .dark ? .clear : Color(hex: "#16202B").opacity(0.04),
                    radius: 2, y: 1)
    }
}

extension View {
    /// Standard-Karte des Calm-2026-Redesigns (DESIGN.md §5).
    func card(padding: CGFloat = Space.s6) -> some View {
        modifier(CardStyle(padding: padding))
    }
}
