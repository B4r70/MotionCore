//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : ToolbarButton.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Toolbar-Button für unterschiedliche Darstellungen im Display     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// Glass Button (für Toolbar)
struct ToolbarButton: View {
    let icon: IconTypes
    
    var body: some View {
        IconType(icon: icon, color: .blue, size: 14)
            .glassButton(size: 36, accentColor: .primary)
    }
}
