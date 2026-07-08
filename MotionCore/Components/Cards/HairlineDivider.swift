//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Design                                                        /
// Datei . . . . : HairlineDivider.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 16.11.2025                                                       /
// Beschreibung  : Zentrale duenne Hairline-Trennlinie (Calm 2026, Theme.line)       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI


// MARK: - HairlineDivider View (wie Divider() verwendbar)
// Eigenständige View für horizontale Trennlinien im Glass-Stil.
// Kann überall wie `Divider()` verwendet werden:

struct HairlineDivider: View {

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
        // Calm 2026: feine Theme.line-Hairline (adaptiv Light/Dark ueber Asset-Colorset)
        Rectangle()
            .fill(Theme.line)
            .frame(height: lineHeight)
            .padding(.vertical, paddingVertical)
            .padding(.horizontal, paddingHorizontal)
    }
}

// MARK: - Kompakte Varianten
extension HairlineDivider {
    // Kompakter Divider ohne vertikales Padding
    static var compact: HairlineDivider {
        HairlineDivider(paddingVertical: 0)
    }

    // Divider mit wenig Abstand
    static var tight: HairlineDivider {
        HairlineDivider(paddingVertical: 6)
    }

    // Divider mit viel Abstand
    static var loose: HairlineDivider {
        HairlineDivider(paddingVertical: 20)
    }
}

// MARK: - View Extension (Modifier-Variante)
// Modifier-Variante für bestehenden Code.
// Fügt einen HairlineDivider unterhalb der View ein:
extension View {
    func hairlineDivider(
        paddingTop: CGFloat = 12,
        paddingBottom: CGFloat = 12,
        paddingHorizontal: CGFloat = 0
    ) -> some View {
        VStack(spacing: 0) {
            self

            Spacer()
                .frame(height: paddingTop)

            HairlineDivider(
                paddingVertical: 0,
                paddingHorizontal: paddingHorizontal
            )

            Spacer()
                .frame(height: paddingBottom)
        }
    }
}

    // MARK: - Preview

#Preview("HairlineDivider Varianten") {
    ZStack {
        Theme.surfaceApp

        VStack(spacing: 0) {
            Text("Standard")
                .padding()

            HairlineDivider()

            Text("Compact")
                .padding()

            HairlineDivider.compact

            Text("Tight")
                .padding()

            HairlineDivider.tight

            Text("Loose")
                .padding()

            HairlineDivider.loose

            Text("Custom")
                .padding()

            HairlineDivider(lineHeight: 2, paddingVertical: 8, paddingHorizontal: 20)

            Text("Als Modifier")
                .padding()
                .hairlineDivider()

            Text("Ende")
                .padding()
        }
        .card()
        .padding()
    }
}
