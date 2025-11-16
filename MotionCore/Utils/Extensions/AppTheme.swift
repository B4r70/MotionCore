// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Filename . . : AppTheme.swift                                                   /
// Author . . . : Bartosz Stryjewski                                                /
// Created on . : 22.10.2025                                                        /
// Function . . : Formatierte Werte für die Ausgabe aus @Model WorkoutSession       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Hell"
        case .dark:   return "Dunkel"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
