//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Shared / Redesign                                        /
// Datei . . . . : MCHeroRing.swift                                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Grosser Hero-Ring als zentrales visuelles Element einer Card    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/

import SwiftUI

// MARK: - MCHeroRing

struct MCHeroRing: View {

    // MARK: Properties

    let value: Int
    let label: String?
    let subText: String?
    var size: CGFloat = 170
    var stroke: CGFloat = 13
    let tint: Color

    @State private var animatedProgress: Double = 0

    // MARK: Body

    var body: some View {
        ZStack {
            // Subtiler Glow-Hintergrund
            Circle()
                .fill(tint.opacity(0.08))

            // Hintergrundring
            Circle()
                .stroke(tint.opacity(0.2), lineWidth: stroke)

            // Fortschrittsring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(tint, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Innenbeschriftung
            VStack(spacing: 3) {
                Text("\(value)")
                    .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(tint)

                if let label {
                    Text(label)
                        .font(.system(size: size * 0.1, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                if let subText {
                    Text(subText)
                        .font(.system(size: size * 0.09))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) {
                animatedProgress = Double(value) / 100.0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        MCHeroRing(
            value: 78,
            label: "Bereit",
            subText: "Erholung",
            tint: MCColor.mcBody
        )

        MCHeroRing(
            value: 45,
            label: "Readiness",
            subText: nil,
            size: 140,
            tint: MCColor.mcEnergy
        )
    }
    .padding()
}
