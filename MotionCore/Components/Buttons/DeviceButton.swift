//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : DeviceButton.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Button für die Darstellung des Gerätetyps im Display             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct DeviceButton: View {
    let device: CardioDevice
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: device.symbol)
                    .font(.title2)
                
                Text(device.description)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
                // Liquid-Glass Hintergrund
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        Color.white.opacity(
                            colorScheme == .light ? 0.20 : 0.08
                        )
                    )
            )
            .background(
                colorScheme == .light ? .thinMaterial : .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected
                        ? device.tint.opacity(0.5)
                        : Color.white.opacity(colorScheme == .light ? 0.45 : 0.30),
                        lineWidth: isSelected ? 2 : 0.8
                    )
            )
            .shadow(
                color: isSelected
                ? device.tint.opacity(0.3)
                : Color.black.opacity(colorScheme == .light ? 0.05 : 0.55),
                radius: isSelected ? 16 : (colorScheme == .light ? 12 : 20),
                x: 0,
                y: 6
            )
            .foregroundStyle(isSelected ? device.tint : .primary)
        }
        .buttonStyle(.plain)
    }
}
