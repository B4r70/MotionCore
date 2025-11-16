// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : DeviceButton.swift                                               /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Toolbar Button in Liquid Glass                                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct DeviceButton: View {
    let device: WorkoutDevice
    let isSelected: Bool
    let action: () -> Void

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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected
                            ? Color.blue.opacity(0.15)
                            : Color.white.opacity(0.22) // HELLER statt grau
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.blue : Color.white.opacity(0.25),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .foregroundStyle(isSelected ? .blue : .primary)
        }
        .buttonStyle(.plain)
    }
}
