//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Design                                                        /
// Datei . . . . : GlassDivider.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 16.11.2025                                                       /
// Beschreibung  : Zentrale Bereitstellung für Liquid-Glass-Effekt bei Trennlinien  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI


// MARK: - GlassDivider View (wie Divider() verwendbar)
// Eigenständige View für horizontale Trennlinien im Glass-Stil.
// Kann überall wie `Divider()` verwendet werden:

struct GlassDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    // Konfiguration
    let lineHeight: CGFloat
    let paddingVertical: CGFloat
    let paddingHorizontal: CGFloat

    init(
        lineHeight: CGFloat = 0.5,
        paddingVertical: CGFloat = 12,
        paddingHorizontal: CGFloat = 0
    ) {
        self.lineHeight = lineHeight
        self.paddingVertical = paddingVertical
        self.paddingHorizontal = paddingHorizontal
    }

    var body: some View {
        Color.clear
            .frame(height: 1)
            .background(
                colorScheme == .light ? .thinMaterial : .ultraThinMaterial
            )
            .overlay(
                Rectangle()
                    .frame(height: lineHeight)
                    .foregroundStyle(
                        Color.gray.opacity(colorScheme == .light ? 0.35 : 0.50)
                    )
            )
            .padding(.vertical, paddingVertical)
            .padding(.horizontal, paddingHorizontal)
    }
}

// MARK: - Kompakte Varianten
extension GlassDivider {
    // Kompakter Divider ohne vertikales Padding
    static var compact: GlassDivider {
        GlassDivider(paddingVertical: 0)
    }

    // Divider mit wenig Abstand
    static var tight: GlassDivider {
        GlassDivider(paddingVertical: 6)
    }

    // Divider mit viel Abstand
    static var loose: GlassDivider {
        GlassDivider(paddingVertical: 20)
    }
}

// MARK: - View Extension (Modifier-Variante)
// Modifier-Variante für bestehenden Code.
// Fügt einen GlassDivider unterhalb der View ein:
extension View {
    func glassDivider(
        paddingTop: CGFloat = 12,
        paddingBottom: CGFloat = 12,
        paddingHorizontal: CGFloat = 0
    ) -> some View {
        VStack(spacing: 0) {
            self

            Spacer()
                .frame(height: paddingTop)

            GlassDivider(
                paddingVertical: 0,
                paddingHorizontal: paddingHorizontal
            )

            Spacer()
                .frame(height: paddingBottom)
        }
    }
}

    // MARK: - Preview

#Preview("GlassDivider Varianten") {
    ZStack {
        AnimatedBackground(showAnimatedBlob: true)

        VStack(spacing: 0) {
            Text("Standard")
                .padding()

            GlassDivider()

            Text("Compact")
                .padding()

            GlassDivider.compact

            Text("Tight")
                .padding()

            GlassDivider.tight

            Text("Loose")
                .padding()

            GlassDivider.loose

            Text("Custom")
                .padding()

            GlassDivider(lineHeight: 2, paddingVertical: 8, paddingHorizontal: 20)

            Text("Als Modifier")
                .padding()
                .glassDivider()

            Text("Ende")
                .padding()
        }
        .glassCard()
        .padding()
    }
}
