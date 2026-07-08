//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Hintergrundkonfiguration                                         /
// Datei . . . . : BackgroundSettings.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 11.11.2025                                                       /
// Beschreibung  : Flacher App-Hintergrund (Theme.surfaceApp), Calm 2026            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// Calm 2026: Verlauf + Blob entfernt — flacher `Theme.surfaceApp` als App-Hintergrund.
struct AnimatedBackground: View {
    var body: some View {
        Theme.surfaceApp
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

#Preview {
    AnimatedBackground()
}
