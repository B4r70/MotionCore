//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Shared / Redesign                                        /
// Datei . . . . : Chip.swift                                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.06.2026                                                       /
// Beschreibung  : Calm-2026 Chip: Capsule, inaktiv Hairline, aktiv voller Akzent   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Chip (DESIGN.md §9)

/// Capsule-Chip: inaktiv `surfaceCard` + 1px Hairline, aktiv voller Akzent + weiße Schrift.
struct Chip: View {
    let title: String
    var systemImage: String? = nil
    var isSelected: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.s1) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(AppFont.callout)
            .fontWeight(.medium)
            .foregroundStyle(isSelected ? Color.white : Theme.textSecondary)
            .padding(.horizontal, Space.s3)
            .padding(.vertical, Space.s2)
            .background(Capsule().fill(isSelected ? Theme.accent : Theme.surfaceCard))
            .overlay(Capsule().stroke(Theme.line, lineWidth: isSelected ? 0 : 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: Space.s2) {
        Chip(title: "Alle", isSelected: true)
        Chip(title: "Kraft", systemImage: "dumbbell.fill")
        Chip(title: "Cardio")
    }
    .padding()
    .background(Theme.surfaceApp)
}
