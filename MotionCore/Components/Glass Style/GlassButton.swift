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
            // Ã„uÃŸerer Glow
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

    // MARK: - Preview mit verschiedenen Hintergründen

#Preview("Glass Button Transparenz-Test") {
    ZStack {
            // Hintergrund mit Farbverlauf (wie in deiner App)
        LinearGradient(
            colors: [
                Color(hex: "#F0F7FF"),
                Color(hex: "#C9E6FF"),
                Color(hex: "#9BD2FF")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 40) {
            Text("Glass Button Transparenz-Test")
                .font(.title2.bold())
                .padding(.top, 40)

                // Verschiedene Button-Größen und Farben
            VStack(spacing: 30) {
                    // Plus Button (wie Floating Action Button)
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue)
                    .glassButton(size: 60, accentColor: .primary)

                    // Filter Button
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(.blue)
                    .glassButton(size: 36, accentColor: .primary)

                    // Settings Button
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundStyle(.blue)
                    .glassButton(size: 36, accentColor: .primary)
            }

                // Test: Buttons über verschiedenen Hintergründen
            HStack(spacing: 20) {
                    // Über Blau
                ZStack {
                    Color.blue.opacity(0.3)
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)

                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .glassButton(size: 44, accentColor: .primary)
                }

                    // Über Grün
                ZStack {
                    Color.green.opacity(0.3)
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)

                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .glassButton(size: 44, accentColor: .primary)
                }

                    // Über Pink
                ZStack {
                    Color.pink.opacity(0.3)
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)

                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .glassButton(size: 44, accentColor: .primary)
                }
            }

            Text("Der Hintergrund sollte durch die Buttons durchscheinen")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 20)

            Spacer()
        }
    }
}

#Preview("Dark Mode Test") {
    ZStack {
            // Dark Mode Hintergrund
        LinearGradient(
            colors: [
                Color(hex: "#050814"),
                Color(hex: "#081024"),
                Color(hex: "#0E1A36")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 40) {
            Text("Glass Button - Dark Mode")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .padding(.top, 40)

            Image(systemName: "plus")
                .font(.system(size: 24))
                .foregroundStyle(.blue)
                .glassButton(size: 60, accentColor: .primary)

            Image(systemName: "gearshape")
                .font(.system(size: 14))
                .foregroundStyle(.primary)
                .glassButton(size: 36, accentColor: .primary)

            Spacer()
        }
    }
    .preferredColorScheme(.dark)
}
