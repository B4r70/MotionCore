// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : AppTheme.swift                                                   /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 11.11.2025                                                       /
// Function . . : Wiederverwendbare Hintergrund-Komponenten                        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Gradient Background (Light + Dark)
struct GradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

        /// Liefert je nach Light/Dark Mode die passenden Farben
    private var backgroundColors: [Color] {
        if colorScheme == .light {
                // Deine bisherigen hellen Farben
            return [
                Color(hex: "#F0F7FF"), // sehr hell
                Color(hex: "#C9E6FF"), // softes Blau
                Color(hex: "#9BD2FF")  // etwas kräftiger
            ]
        } else {
                // Eigener Verlauf für Dark Mode
            return [
                Color(hex: "#050814"), // fast schwarz-blau
                Color(hex: "#081024"),
                Color(hex: "#0E1A36")  // tiefes Nachtblau
            ]
        }
    }

    var body: some View {
        LinearGradient(
            colors: backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

    // MARK: - Animated Background (optional mit Blob)
struct AnimatedBackground: View {
    let showAnimatedBlob: Bool

    var body: some View {
        ZStack {
            GradientBackground()

            if showAnimatedBlob {
                AnimatedBlob()
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    GradientBackground()
}
