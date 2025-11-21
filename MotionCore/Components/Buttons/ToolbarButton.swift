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
    let icon: String

    var body: some View {
        Image(systemName: icon)
            .font(.body)
            .foregroundStyle(.primary)
            .frame(width: 36, height: 36)
            .background {
                Circle()
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 1)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4) // NEU und zu Testen
            }
    }
}
