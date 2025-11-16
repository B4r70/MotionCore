// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : StatBubble.swift                                                 /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Workout Card Ansicht mit diversen Werten                         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct StatBubble: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            Text(value)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
        }
    }
}
