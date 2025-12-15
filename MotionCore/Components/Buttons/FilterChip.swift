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
            .background {
                Capsule()
                    .fill(isSelected ? .ultraThinMaterial : .thinMaterial)
            }
            .overlay {
                Capsule()
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1.5)
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .buttonStyle(.plain)
    }
}
