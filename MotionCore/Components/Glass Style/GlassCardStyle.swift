// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Filename . . : GlassCardStyle.swift                                              /
// Author . . . : Bartosz Stryjewski                                                /
// Created on . : 16.11.2025                                                        /
// Function . . : Farbgebung von Cards innerhalb der App im LiquidGlass Style       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

private struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        Color.white.opacity(
                            colorScheme == .light ? 0.20 : 0.08
                        )
                    )
            )
            .background(
                colorScheme == .light ? .thinMaterial : .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        Color.white.opacity(
                            colorScheme == .light ? 0.45 : 0.30
                        ),
                        lineWidth: 0.8
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
    func glassCardStyle() -> some View {
        self.modifier(GlassCardModifier())
    }
}
