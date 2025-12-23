//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
//----------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : FloatingActionButton.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.12.2025                                                       /
// Beschreibung  : Floating Action Button für primäre Aktionen                      /
//----------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
//----------------------------------------------------------------------------------/
//
import SwiftUI

struct FloatingButton: View {
    let icon: IconTypes
    let color: Color
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // Icon mit Glass-Effekt
            IconType(icon: icon, color: color, size: size * 0.4)
                .glassButton(size: size, accentColor: .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Extension für einfache Platzierung

extension View {
    // Platziert einen Floating Action Button unten rechts über der Tab Bar
    // - Parameters:
    //   - icon: Das anzuzeigende Icon
    //   - color: Farbe für Glow und Icon (Standard: .blue)
    //   - size: Größe des Buttons (Standard: 60)
    //   - action: Aktion beim Tippen
    func floatingActionButton(
        icon: IconTypes,
        color: Color = .blue,
        size: CGFloat = 60,
        action: @escaping () -> Void
    ) -> some View {
        self.overlay(alignment: .bottomTrailing) {
            FloatingButton(
                icon: icon,
                color: color,
                size: size,
                action: action
            )
            .padding(.trailing, 20)
            .padding(.bottom, 20) // Über der Tab Bar
        }
    }
}
