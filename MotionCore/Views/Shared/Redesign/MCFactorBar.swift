//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Shared / Redesign                                        /
// Datei . . . . : MCFactorBar.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Animierter horizontaler Balken für Faktor-Darstellungen          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/

import SwiftUI

// MARK: - MCFactorBar

struct MCFactorBar: View {

    // MARK: Properties

    let label: String
    let subLabel: String?
    let value: Double   // 0…1
    let color: Color

    @State private var animatedValue: Double = 0

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                if let sub = subLabel {
                    Text(sub)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.secondary.opacity(0.18))

                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * animatedValue)
                }
            }
            .frame(height: 6)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animatedValue = max(0, min(1, value))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        MCFactorBar(
            label: "Schlafqualität",
            subLabel: "Niedrig",
            value: 0.2,
            color: MCColor.mcStreak
        )
        MCFactorBar(
            label: "HRV",
            subLabel: "Mittel",
            value: 0.55,
            color: MCColor.mcEnergy
        )
        MCFactorBar(
            label: "Muskel-Erholung",
            subLabel: "Hoch",
            value: 0.9,
            color: MCColor.mcBody
        )
    }
    .padding()
}
