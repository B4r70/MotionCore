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
// Der `showAnimatedBlob`-Parameter bleibt vorerst aus Kompatibilität bestehen, wird
// aber ignoriert (Flag stillgelegt). UI-Toggle-Bereinigung in AP 8, finale Entfernung
// von AnimatedBlob/diesen Resten in AP 11.

// MARK: - Gradient Background (flach)
struct GradientBackground: View {
    var body: some View {
        Theme.surfaceApp
            .ignoresSafeArea()
    }
}

// MARK: - Animated Background (flach, Blob stillgelegt)
struct AnimatedBackground: View {
    let showAnimatedBlob: Bool

    var body: some View {
        Theme.surfaceApp
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

#Preview {
    GradientBackground()
}
