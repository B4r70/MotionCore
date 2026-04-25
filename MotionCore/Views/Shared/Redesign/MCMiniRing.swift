//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Shared / Redesign                                        /
// Datei . . . . : MCMiniRing.swift                                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Kleiner animierter Ring für Prozentwerte (z.B. Muskel-Erholung) /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/

import SwiftUI

// MARK: - MCMiniRing

struct MCMiniRing: View {

    // MARK: Properties

    let value: Int          // 0…100
    let label: String
    var size: CGFloat = 62
    var stroke: CGFloat = 6
    var tint: Color? = nil

    @State private var animatedProgress: Double = 0

    // MARK: Helpers

    private var ringColor: Color {
        tint ?? recoveryColor(percent: Double(value))
    }

    // MARK: Body

    var body: some View {
        ZStack {
            // Hintergrundring
            Circle()
                .stroke(ringColor.opacity(0.2), lineWidth: stroke)

            // Fortschrittsring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Innenbeschriftung
            VStack(spacing: 1) {
                Text("\(value)")
                    .font(.system(size: size * 0.26, weight: .bold))
                    .monospacedDigit()

                Text(label)
                    .font(.system(size: size * 0.15))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                animatedProgress = Double(value) / 100.0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 20) {
        MCMiniRing(value: 0, label: "Brust")
        MCMiniRing(value: 55, label: "Rücken")
        MCMiniRing(value: 92, label: "Beine")
    }
    .padding()
}
