//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Shared / Redesign                                        /
// Datei . . . . : Badge.swift                                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.06.2026                                                       /
// Beschreibung  : Calm-2026 Badge: kleine Capsule, soft (getoent) oder solid       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Badge (DESIGN.md §9)

/// Kleine uppercase-Capsule. `soft` = getönte Fläche, `solid` = volle Fläche + weiße Schrift.
struct Badge: View {
    enum Style { case soft, solid }

    let text: String
    var style: Style = .soft
    var color: Color = Theme.accent

    var body: some View {
        Text(text)
            .font(AppFont.eyebrow)
            .textCase(.uppercase)
            .tracking(0.6)
            .foregroundStyle(style == .solid ? Color.white : color)
            .padding(.horizontal, Space.s2)
            .padding(.vertical, Space.s1)
            .background(Capsule().fill(style == .solid ? color : color.opacity(0.12)))
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: Space.s2) {
        Badge(text: "Neu", style: .solid)
        Badge(text: "PR", color: Theme.warning)
        Badge(text: "Erholt", style: .soft, color: Theme.success)
    }
    .padding()
    .background(Theme.surfaceApp)
}
