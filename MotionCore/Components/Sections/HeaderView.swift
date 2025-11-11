//---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : HeaderView.swift                                                 /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Header View                                                      /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI

struct HeaderView: View {
    var body: some View {
        Text("MotionCore")
            .font(.title)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
            .fixedSize() // ← Füge das hinzu
            .accessibilityAddTraits(.isHeader)
    }
}
