//---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : AppTheme.swift                                                   /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 11.11.2025                                                       /
// Function . . : Wiederverwendbare Hintergrund-Komponenten                        /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Gradient Background
struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.green.opacity(0.3),
                Color.white.opacity(0.7),
                Color.blue.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Animated Background (mit optionalem Blob)
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

