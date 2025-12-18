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

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    IconType(icon: icon,
                             color: isSelected ? .primary : .secondary,
                             size: 14)
                }

                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))

                // Count Badge
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(isSelected ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2))
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            // Liquid-Glass Hintergrund
            .background(
                Capsule()
                    .fill(
                        Color.white.opacity(
                            colorScheme == .light ? 0.20 : 0.08
                        )
                    )
            )
            .background(
                isSelected
                    ? (colorScheme == .light ? .ultraThinMaterial : .thinMaterial)
                    : (colorScheme == .light ? .thinMaterial : .ultraThinMaterial),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(
                        isSelected
                            ? Color.blue.opacity(0.5)
                            : Color.white.opacity(colorScheme == .light ? 0.45 : 0.30),
                        lineWidth: isSelected ? 1.5 : 0.8
                    )
            }
            .shadow(
                color: isSelected
                    ? Color.blue.opacity(0.2)
                    : Color.black.opacity(colorScheme == .light ? 0.05 : 0.55),
                radius: colorScheme == .light ? 8 : 12,
                x: 0,
                y: 4
            )
            .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .buttonStyle(.plain)
    }
}
