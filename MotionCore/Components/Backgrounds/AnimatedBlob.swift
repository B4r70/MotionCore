// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : AnimatedBlob.swift                                               /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 10.11.2025                                                       /
// Function . . : Animierter Hintergrund im Liquid Effekt                          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// Animated Blob (Optional - für extra Liquid-Effekt)
struct AnimatedBlob: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(0.3),
                            Color.purple.opacity(0.2),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: animate ? -100 : 100, y: animate ? -150 : 150)
                .animation(
                    .easeInOut(duration: 8)
                        .repeatForever(autoreverses: true),
                    value: animate
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.cyan.opacity(0.3),
                            Color.blue.opacity(0.2),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 350, height: 350)
                .blur(radius: 50)
                .offset(x: animate ? 120 : -120, y: animate ? 100 : -100)
                .animation(
                    .easeInOut(duration: 7)
                        .repeatForever(autoreverses: true),
                    value: animate
                )
        }
        .onAppear {
            animate = true
        }
    }
}
