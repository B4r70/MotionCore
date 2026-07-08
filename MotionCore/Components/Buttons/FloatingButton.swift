//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
//----------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : FloatingButton.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.12.2025                                                       /
// Beschreibung  : Floating Action Button (Calm 2026, .mcFAB) fuer primaere Aktion  /
//----------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
//----------------------------------------------------------------------------------/
//
import SwiftUI

struct FloatingButton: View {
    let icon: IconTypes
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        // Calm-2026 FAB: solider accent-Kreis, weisses Icon, Press 0.92 (FABButtonStyle).
        Button(action: action) {
            IconType(icon: icon, color: .white, size: size * 0.4)
        }
        .buttonStyle(FABButtonStyle(size: size))
    }
}

// MARK: - Extension für einfache Platzierung

extension View {
    // Platziert einen Floating Action Button unten rechts über der Tab Bar.
    func floatingActionButton(
        icon: IconTypes,
        size: CGFloat = 60,
        action: @escaping () -> Void
    ) -> some View {
        self.safeAreaInset(edge: .bottom, alignment: .trailing, spacing: 0) {
            FloatingButton(icon: icon, size: size, action: action)
                .padding(.trailing, 20)
                .padding(.bottom, 20) // Über der Tab Bar
        }
    }
}
