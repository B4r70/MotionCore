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

    // MARK: - Movement Pattern Enum (Push/Pull/etc.)

enum MovementPattern: String, Codable, CaseIterable, Identifiable {
    case push = "push"                      // Drückbewegung
    case pull = "pull"                      // Zugbewegung
    case squat = "squat"                    // Kniebeuge-Muster
    case hinge = "hinge"                    // Hüftgelenk-Muster (Deadlift etc.)
    case carry = "carry"                    // Tragen
    case rotation = "rotation"              // Rotation
    case isometric = "isometric"            // Statisch halten
    case other = "other"                    // Sonstiges

    var id: String { rawValue }

    var description: String {
        switch self {
            case .push: return "Drücken"
            case .pull: return "Ziehen"
            case .squat: return "Kniebeuge"
            case .hinge: return "Hüftgelenk"
            case .carry: return "Tragen"
            case .rotation: return "Rotation"
            case .isometric: return "Isometrisch"
            case .other: return "Sonstiges"
        }
    }

    var icon: String {
        switch self {
            case .push: return "arrow.up.circle.fill"
            case .pull: return "arrow.down.circle.fill"
            case .squat: return "figure.strengthtraining.functional"
            case .hinge: return "figure.cooldown"
            case .carry: return "figure.walk"
            case .rotation: return "arrow.triangle.2.circlepath"
            case .isometric: return "pause.circle.fill"
            case .other: return "ellipsis.circle"
        }
    }
}

// MARK: - Body Position Enum

enum BodyPosition: String, Codable, CaseIterable, Identifiable {
    case standing = "standing"              // Stehend
    case seated = "seated"                  // Sitzend
    case lying = "lying"                    // Liegend
    case incline = "incline"                // Schrägbank
    case decline = "decline"                // Negative Schrägbank
    case kneeling = "kneeling"              // Kniend
    case hanging = "hanging"                // Hängend
    case plank = "plank"                    // Plank-Position
    case other = "other"                    // Sonstiges

    var id: String { rawValue }

    var description: String {
        switch self {
            case .standing: return "Stehend"
            case .seated: return "Sitzend"
            case .lying: return "Liegend"
            case .incline: return "Schrägbank"
            case .decline: return "Negative Schräge"
            case .kneeling: return "Kniend"
            case .hanging: return "Hängend"
            case .plank: return "Plank"
            case .other: return "Sonstiges"
        }
    }

    var icon: String {
        switch self {
            case .standing: return "figure.stand"
            case .seated: return "figure.seated.side"
            case .lying: return "bed.double.fill"
            case .incline: return "arrow.up.right"
            case .decline: return "arrow.down.right"
            case .kneeling: return "figure.roll"
            case .hanging: return "figure.climbing"
            case .plank: return "figure.core.training"
            case .other: return "ellipsis.circle"
        }
    }
}

// MARK: - Set Kind Enum (für ExerciseSet)

enum SetKind: String, Codable, CaseIterable, Identifiable {
    case work = "work"                      // Arbeitssatz
    case warmup = "warmup"                  // Aufwärmsatz
    case drop = "drop"                      // Dropsatz
    case amrap = "amrap"                    // As Many Reps As Possible
    case rest = "rest"                      // Pausensatz (z.B. Rest-Pause)
    case failure = "failure"                // Bis zum Muskelversagen

    var id: String { rawValue }

    var description: String {
        switch self {
            case .work: return "Arbeitssatz"
            case .warmup: return "Aufwärmen"
            case .drop: return "Dropsatz"
            case .amrap: return "AMRAP"
            case .rest: return "Rest-Pause"
            case .failure: return "Bis Versagen"
        }
    }

    var shortName: String {
        switch self {
            case .work: return "W"
            case .warmup: return "A"
            case .drop: return "D"
            case .amrap: return "∞"
            case .rest: return "R"
            case .failure: return "F"
        }
    }

    var color: Color {
        switch self {
            case .work: return .blue
            case .warmup: return .orange
            case .drop: return .purple
            case .amrap: return .green
            case .rest: return .gray
            case .failure: return .red
        }
    }
}







