//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Design                                                        /
// Datei . . . . : GlassCardStyle.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 16.11.2025                                                       /
// Beschreibung  : Zentrale Bereitstellung für Liquid-Glass-Effekt bei Cards        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

private struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    private let cardPadding: CGFloat = 16
    private let cornerRadius: CGFloat = 22
    private let lineWidth: CGFloat = 0.8

    private var cardShape: some Shape {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        }

    func body(content: Content) -> some View {
        content
            .padding(cardPadding)

            // 1. Explizite Füllung/Tönung (für den "Liquid"-Effekt)
            .background(
                cardShape
                    .fill(
                        Color.white.opacity(
                            colorScheme == .light ? 0.20 : 0.08
                        )
                    )
            )
            // 2. Material (Blur-Effekt)
            .background(
                colorScheme == .light ? .thinMaterial : .ultraThinMaterial,
                in: cardShape
            )
            // 3. Overlay (Highlight-Stroke)
            .overlay(
                cardShape
                    .stroke(
                        Color.white.opacity(
                            colorScheme == .light ? 0.45 : 0.30
                        ),
                        lineWidth: lineWidth
                    )
            )
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

extension View {
    func glassCard() -> some View {
        self.modifier(GlassCardModifier())
    }
}
