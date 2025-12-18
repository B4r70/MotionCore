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

struct GlassDividerModifier: View {
    @Environment(\.colorScheme) private var colorScheme

    // Konstante für die Höhe der sichtbaren Linie
    let lineHeight: CGFloat

    init(
        lineHeight: CGFloat = 0.5,
    ) {
        self.lineHeight = lineHeight
    }

    var body: some View {
        Color.clear
            // Begrenzte Höhe des Material-Containers
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
    }
}

// MARK: Horizontaler Trenner im Liquid Glass Optik
// diese Extension wird wie folgt aufgerufen:
// .glassDivider()
// .
extension View {
    func glassDivider(
        paddingTop: CGFloat = 12,
        paddingBottom: CGFloat = 12,
        paddingHorizontal: CGFloat = 0
    ) -> some View {
        VStack(spacing: 0) {
            // 1. Originalinhalt
            self
            // 2. Abstand nach OBEN (wird durch paddingTop gesteuert)
            Spacer()
                .frame(height: paddingTop)
            // 3. Der GlassDivider selbst
            GlassDividerModifier()
                .padding(.horizontal, paddingHorizontal)
            // 4. Abstand nach UNTEN (wird durch paddingBottom gesteuert)
            Spacer()
                .frame(height: paddingBottom)
        }
    }
}
