//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Shared / Redesign                                        /
// Datei . . . . : MCChip.swift                                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Kompakte Kennzahl-Pille mit Icon, Wert und Bezeichnung           /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/

import SwiftUI

// MARK: - MCChip

struct MCChip: View {

    // MARK: Properties

    let icon: Image
    let value: String
    let label: String
    var tint: Color = .primary

    // MARK: Body

    var body: some View {
        HStack(spacing: 8) {
            icon
                .foregroundStyle(tint)
                .font(.system(size: 15))

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .strokeBorder(.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        MCChip(
            icon: Image(systemName: "bolt.fill"),
            value: "78",
            label: "Bereitschaft",
            tint: MCColor.mcEnergy
        )
        MCChip(
            icon: Image(systemName: "heart.fill"),
            value: "62 bpm",
            label: "Ruhepuls",
            tint: MCColor.mcStreak
        )
        MCChip(
            icon: Image(systemName: "flame.fill"),
            value: "12",
            label: "Tage Serie",
            tint: MCColor.mcStat
        )
    }
    .padding()
}
