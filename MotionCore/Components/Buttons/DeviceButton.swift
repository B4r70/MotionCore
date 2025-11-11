//
//  DeviceButton.swift
//  MotionCore
//
//  Created by Barto on 11.11.25.
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
                    .fill(isSelected ? Color.blue.opacity(0.15) : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .foregroundStyle(isSelected ? .blue : .primary)
        }
        .buttonStyle(.plain)
    }
}
