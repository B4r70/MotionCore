// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : ColorHexExtension.swift                                          /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 16.11.2025                                                       /
// Function . . : Alpha und Hex Support bei Farbgebung                             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

extension Color {
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        var rgba: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgba)

        let length = hexString.count

        let r, g, b, a: Double

        switch length {
        case 6:
            r = Double((rgba >> 16) & 0xFF) / 255.0
            g = Double((rgba >> 8) & 0xFF) / 255.0
            b = Double(rgba & 0xFF) / 255.0
            a = 1.0

        case 8:
            a = Double((rgba >> 24) & 0xFF) / 255.0
            r = Double((rgba >> 16) & 0xFF) / 255.0
            g = Double((rgba >> 8) & 0xFF) / 255.0
            b = Double(rgba & 0xFF) / 255.0

        default:
            r = 0.5; g = 0.5; b = 0.5; a = 1.0
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
