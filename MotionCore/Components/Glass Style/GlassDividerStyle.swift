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

struct GlassDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Rectangle()
            .frame(height: 0.35)
            .foregroundStyle(
                Color.white.opacity(colorScheme == .light ? 0.22 : 0.35)
            )
    }
}
