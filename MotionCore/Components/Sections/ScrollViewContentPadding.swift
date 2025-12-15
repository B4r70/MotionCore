//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Design                                                        /
// Datei . . . . : ScrollViewTopPadding.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.12.2025                                                       /
// Beschreibung  : Einheitlicher Top-Abstand für ScrollViews unter Navigation Bar   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - ViewModifier für ScrollView Content
struct ScrollViewContentPadding: ViewModifier {
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let horizontalPadding: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
    }
}

// MARK: - Extension für einfache Verwendung
extension View {
    // Fügt einheitliches Padding für ScrollView-Content hinzu
    // Parameters:
    //   - top: Abstand nach oben (Standard: 20)
    //   - bottom: Abstand nach unten (Standard: 100 für Tab Bar)
    //   - horizontal: Horizontaler Abstand (Standard: 16)
    func scrollViewContentPadding(
        top: CGFloat = 22,
        bottom: CGFloat = 100,
        horizontal: CGFloat = 13
    ) -> some View {
        self.modifier(
            ScrollViewContentPadding(
                topPadding: top,
                bottomPadding: bottom,
                horizontalPadding: horizontal
            )
        )
    }
}
