//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
//----------------------------------------------------------------------------------/
// Abschnitt . . : UI-Design                                                        /
// Datei . . . . : GlassFloatingButton.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 17.12.2025                                                       /
// Beschreibung  : Zentrale Bereitstellung für Liquid-Glass-Effekt bei Buttons      /
//----------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
//----------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Glass Floating Button Modifier

private struct GlassButtonModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    let size: CGFloat
    let accentColor: Color
    
    func body(content: Content) -> some View {
        ZStack {
            // Äußerer Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(0.3),
                            accentColor.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.33,
                        endRadius: size * 0.67
                    )
                )
                .frame(width: size * 1.33, height: size * 1.33)
            
            // Haupt-Button mit Liquid-Glass-Effekt
            Circle()
                .fill(
                    Color.white.opacity(
                        colorScheme == .light ? 0.20 : 0.08
                    )
                )
                .frame(width: size, height: size)
            
            Circle()
                .fill(
                    colorScheme == .light ? .thinMaterial : .ultraThinMaterial
                )
                .frame(width: size, height: size)
            
            // Highlight-Ring
            Circle()
                .stroke(
                    Color.white.opacity(
                        colorScheme == .light ? 0.45 : 0.30
                    ),
                    lineWidth: 0.8
                )
                .frame(width: size, height: size)
            
            // Content (Icon)
            content
        }
        .shadow(
            color: Color.black.opacity(
                colorScheme == .light ? 0.05 : 0.55
            ),
            radius: colorScheme == .light ? 12 : 20,
            x: 0,
            y: 6
        )
    }
}

// MARK: - Extension für einfache Verwendung

extension View {
    /// Wendet den Liquid-Glass-Effekt auf einen Button an
    /// - Parameters:
    ///   - size: Größe des Buttons (Standard: 60)
    ///   - accentColor: Farbe für Glow und Icon (Standard: .blue)
    func glassButton(
        size: CGFloat = 60,
        accentColor: Color = .blue
    ) -> some View {
        self.modifier(
            GlassButtonModifier(
                size: size,
                accentColor: accentColor
            )
        )
    }
}
