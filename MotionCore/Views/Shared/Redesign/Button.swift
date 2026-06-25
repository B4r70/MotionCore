//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Shared / Redesign                                        /
// Datei . . . . : Button.swift                                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.06.2026                                                       /
// Beschreibung  : Calm-2026 Button-Stile: primaer / sekundaer / ghost              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Button-Stile (DESIGN.md §9 / §6)

/// Primär: volle Akzentfläche, weiße Schrift. Press 0.97.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, Space.s4)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

/// Sekundär: accentSoft-Fläche, Akzent-Text, 1px Hairline. In Dark heller Akzent-Text.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Content(configuration: configuration) }

    private struct Content: View {
        @Environment(\.colorScheme) private var scheme
        let configuration: ButtonStyleConfiguration
        var body: some View {
            configuration.label
                .font(AppFont.headline)
                .foregroundStyle(scheme == .dark ? Theme.accentHover : Theme.accent)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, Space.s4)
                .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .stroke(Theme.line, lineWidth: 1)
                )
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
        }
    }
}

/// Ghost: transparent, Akzent-Text, Press füllt accentSoft.
struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Content(configuration: configuration) }

    private struct Content: View {
        @Environment(\.colorScheme) private var scheme
        let configuration: ButtonStyleConfiguration
        var body: some View {
            configuration.label
                .font(AppFont.headline)
                .foregroundStyle(scheme == .dark ? Theme.accentHover : Theme.accent)
                .frame(minHeight: 44)
                .padding(.horizontal, Space.s4)
                .background(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(configuration.isPressed ? Theme.accentSoft : Color.clear)
                )
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
        }
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var mcPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
extension ButtonStyle where Self == SecondaryButtonStyle {
    static var mcSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
extension ButtonStyle where Self == GhostButtonStyle {
    static var mcGhost: GhostButtonStyle { GhostButtonStyle() }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Space.s4) {
        Button("Heute trainieren") {}.buttonStyle(.mcPrimary)
        Button("Mehr anzeigen") {}.buttonStyle(.mcSecondary)
        Button("Abbrechen") {}.buttonStyle(.mcGhost)
    }
    .padding()
    .background(Theme.surfaceApp)
}
