//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : ToolbarButton.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Toolbar-Icon-Button (Calm 2026, accent auf surfaceCard-Kreis)    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// Calm 2026: accent-Icon auf solidem surfaceCard-Kreis mit Theme.line-Hairline.
struct ToolbarButton: View {
    let icon: IconTypes

    var body: some View {
        IconType(icon: icon, color: Theme.accent, size: 14)
            .frame(width: 36, height: 36)
            .background(Theme.surfaceCard, in: Circle())
            .overlay(Circle().stroke(Theme.line, lineWidth: 1))
    }
}
