//---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : ToolbarButton.swift                                              /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Toolbar Button in Liquid Glass                                   /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI

// Glass Button (für Toolbar)
struct ToolbarButton: View {
    let icon: String

    var body: some View {
        Image(systemName: icon)
            .font(.body)
            .foregroundStyle(.primary)
            .frame(width: 36, height: 36)
            .background {
                Circle()
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            }
    }
}
