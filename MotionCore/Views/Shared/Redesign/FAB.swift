//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Shared / Redesign                                        /
// Datei . . . . : FAB.swift                                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.06.2026                                                       /
// Beschreibung  : Calm-2026 Floating Action Button (solider Akzent-Kreis)          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - FAB (DESIGN.md §6 / §9)

/// Floating Action Button: solider `accent`-Kreis, weißes Icon, Press 0.92,
/// Schatten nur in Light. Auf einen `Button` mit Icon-Label anwenden.
/// Löst den `GlassButton`-basierten FAB ab.
struct FABButtonStyle: ButtonStyle {
    var size: CGFloat = 56

    func makeBody(configuration: Configuration) -> some View {
        Content(configuration: configuration, size: size)
    }

    private struct Content: View {
        @Environment(\.colorScheme) private var scheme
        let configuration: ButtonStyleConfiguration
        let size: CGFloat

        var body: some View {
            configuration.label
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Theme.accent, in: Circle())
                // Schatten nur in Light; in Dark trägt die Fläche selbst.
                .shadow(color: scheme == .dark ? .clear : Theme.accent.opacity(0.30),
                        radius: 8, y: 4)
                .scaleEffect(configuration.isPressed ? 0.92 : 1)
                .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
        }
    }
}

extension ButtonStyle where Self == FABButtonStyle {
    static var mcFAB: FABButtonStyle { FABButtonStyle() }
}

// MARK: - Preview

#Preview {
    ZStack(alignment: .bottomTrailing) {
        Theme.surfaceApp.ignoresSafeArea()
        Button { } label: { Image(systemName: "plus") }
            .buttonStyle(.mcFAB)
            .padding(Space.s6)
    }
}
