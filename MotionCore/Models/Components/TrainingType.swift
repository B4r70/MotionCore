//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : TrainingTypes.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 23.12.2025                                                       /
// Beschreibung  : Benutzerspezifische Angaben wie Gender, Activity, etc.           /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftUI

// MARK: - Plan Type Enum

enum PlanType: String, Codable, CaseIterable, Identifiable {
    case cardio = "cardio"              // Nur Cardio
    case strength = "strength"          // Nur Kraft
    case outdoor = "outdoor"            // Nur Outdoor
    case mixed = "mixed"                // Gemischt

    var id: String { rawValue }

    var description: String {
        switch self {
        case .cardio: return "Cardio-Plan"
        case .strength: return "Kraft-Plan"
        case .outdoor: return "Outdoor-Plan"
        case .mixed: return "Gemischter Plan"
        }
    }

    var icon: String {
        switch self {
        case .cardio: return "figure.indoor.cycle"
        case .strength: return "dumbbell.fill"
        case .outdoor: return "figure.outdoor.cycle"
        case .mixed: return "figure.mixed.cardio"
        }
    }

    var color: String {
        switch self {
        case .cardio: return "blue"
        case .strength: return "orange"
        case .outdoor: return "green"
        case .mixed: return "purple"
        }
    }
}

    // MARK: - Workout Type Enum

enum WorkoutType: String, Codable, CaseIterable, Identifiable {
    case cardio = "cardio"
    case strength = "strength"
    case outdoor = "outdoor"

    var id: String { rawValue }

    var description: String {
        switch self {
            case .cardio: return "Cardio"
            case .strength: return "Kraft"
            case .outdoor: return "Outdoor"
        }
    }

    var icon: String {
        switch self {
            case .cardio: return "figure.indoor.cycle"
            case .strength: return "dumbbell.fill"
            case .outdoor: return "figure.outdoor.cycle"
        }
    }
}
