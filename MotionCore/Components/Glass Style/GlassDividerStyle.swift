// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : GlassDivider.swift                                               /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 16.11.2025                                                       /
// Function . . : Trennlinie in Liquid Glass Optik                                 /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct GlassDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Rectangle()
            .frame(height: 0.35)
            .foregroundStyle(
                Color.white.opacity(colorScheme == .light ? 0.22 : 0.35)
            )
    }
}
