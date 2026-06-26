//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : FilterChip.swift                                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Darstellung von Filter-Chips                                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftUI

// Filter Chip (Glassmorphic)
struct FilterChip: View {
    let title: String
    var icon: IconTypes? = nil
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.s2) {
                if let icon {
                    IconType(icon: icon,
                             color: isSelected ? Color.white : Theme.textSecondary,
                             size: 14)
                }

                Text(title)
                    .font(AppFont.callout)
                    .fontWeight(isSelected ? .semibold : .medium)

                // Count Badge
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isSelected ? Color.white : Theme.textSecondary)
                    .padding(.horizontal, Space.s2)
                    .padding(.vertical, 2)
                    .background {
                        Capsule()
                            .fill(isSelected ? Color.white.opacity(0.25) : Theme.surfaceSunken)
                    }
            }
            .foregroundStyle(isSelected ? Color.white : Theme.textSecondary)
            .padding(.horizontal, Space.s3)
            .padding(.vertical, Space.s2)
            // Calm 2026: voller Akzent aktiv, surfaceCard + Hairline inaktiv (kein Glas)
            .background(Capsule().fill(isSelected ? Theme.accent : Theme.surfaceCard))
            .overlay(Capsule().stroke(Theme.line, lineWidth: isSelected ? 0 : 1))
        }
        .buttonStyle(.plain)
    }
}
