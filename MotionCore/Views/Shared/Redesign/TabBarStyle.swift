//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Shared / Redesign                                        /
// Datei . . . . : TabBarStyle.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.06.2026                                                       /
// Beschreibung  : Calm-2026 gefrostete TabBar (ultraThinMaterial)                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Gefrostete TabBar (DESIGN.md §6 / §8)

extension View {
    /// Durchscheinende TabBar (`.ultraThinMaterial`) statt Vollfläche.
    /// SwiftUI-nativ (kein UITabBarAppearance-Proxy → kein Legacy-Render-Pfad).
    func frostedTabBar() -> some View {
        self
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }
}

// MARK: - Preview

#Preview {
    TabView {
        Theme.surfaceApp.ignoresSafeArea()
            .tabItem { Label("Übersicht", systemImage: "square.grid.2x2") }
        Theme.surfaceApp.ignoresSafeArea()
            .tabItem { Label("Workouts", systemImage: "figure.run") }
    }
    .frostedTabBar()
    .tint(Theme.accent)
}
