//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : ExerciseTypes.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.12.2025                                                       /
// Beschreibung  : Enumerationen bezüglich Zeitspannen/Zeitfilter                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftUI

// MARK: - Exercise Category Enum

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case compound = "compound"              // Mehrgelenkübung
    case isolation = "isolation"            // Isolationsübung
    case bodyweight = "bodyweight"          // Körpergewicht
    case cardio = "cardio"                  // Kardio-Übung
    case stretching = "stretching"          // Dehnung
    case core = "core"                      // Core-Übung

    var id: String { rawValue }

    var description: String {
        switch self {
        case .compound: return "Mehrgelenkübung"
        case .isolation: return "Isolationsübung"
        case .bodyweight: return "Körpergewicht"
        case .cardio: return "Kardio"
        case .stretching: return "Dehnung"
        case .core: return "Core"
        }
    }

    var icon: String {
        switch self {
        case .compound: return "dumbbell.fill"
        case .isolation: return "figure.strengthtraining.traditional"
        case .bodyweight: return "figure.arms.open"
        case .cardio: return "heart.fill"
        case .stretching: return "figure.flexibility"
        case .core: return "figure.core.training"
        }
    }
}

// MARK: - Exercise Equipment Enum

enum ExerciseEquipment: String, Codable, CaseIterable, Identifiable {
    case barbell = "barbell"                // Langhantel
    case dumbbell = "dumbbell"              // Kurzhantel
    case machine = "machine"                // Maschine
    case cable = "cable"                    // Kabelzug
    case bodyweight = "bodyweight"          // Körpergewicht
    case kettlebell = "kettlebell"          // Kettlebell
    case band = "band"                      // Widerstandsband
    case other = "other"                    // Sonstiges

    var id: String { rawValue }

    var description: String {
        switch self {
        case .barbell: return "Langhantel"
        case .dumbbell: return "Kurzhantel"
        case .machine: return "Maschine"
        case .cable: return "Kabelzug"
        case .bodyweight: return "Körpergewicht"
        case .kettlebell: return "Kettlebell"
        case .band: return "Widerstandsband"
        case .other: return "Sonstiges"
        }
    }

    var icon: String {
        switch self {
        case .barbell: return "figure.strengthtraining.traditional"
        case .dumbbell: return "dumbbell.fill"
        case .machine: return "gearshape.fill"
        case .cable: return "cable.connector"
        case .bodyweight: return "figure.arms.open"
        case .kettlebell: return "figure.mixed.cardio"
        case .band: return "arrow.left.and.right"
        case .other: return "ellipsis.circle"
        }
    }
}

// MARK: - Exercise Difficulty Enum

enum ExerciseDifficulty: String, Codable, CaseIterable, Identifiable {
    case beginner = "beginner"              // Anfänger
    case intermediate = "intermediate"      // Fortgeschritten
    case advanced = "advanced"              // Profi
    case expert = "expert"                  // Experte

    var id: String { rawValue }

    var description: String {
        switch self {
        case .beginner: return "Anfänger"
        case .intermediate: return "Fortgeschritten"
        case .advanced: return "Profi"
        case .expert: return "Experte"
        }
    }

    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "yellow"
        case .advanced: return "orange"
        case .expert: return "red"
        }
    }

    var stars: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .expert: return 4
        }
    }
}
