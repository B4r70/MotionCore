//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Hilftools                                                        /
// Datei . . . . : TypesUI.swift                                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 23.10.2025                                                       /
// Beschreibung  : Wertebereiche für Daten aus WorkoutSession                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: Intensity UI-Erweiterungen für die Anzeige im Display

extension Intensity {
    // Beschreibung der Belastung
    var description: String {
        switch self {
        case .none: "Keine Belastung"
        case .veryEasy: "Sehr leicht"
        case .easy: "Einfach"
        case .medium: "Mittel"
        case .hard: "Schwer"
        case .veryHard: "Sehr schwer"
        }
    }

    // Farbe Schwierigkeitsgrad
    var color: Color {
        switch self {
            case .none: Color.gray
            case .veryEasy: Color.green
            case .easy: Color.mint
            case .medium: Color.yellow
            case .hard: Color.orange
            case .veryHard: Color.red
        }
    }
    // Anzahl der maximalen Belastungsintensität
    static var maxRating: Int {
            return Intensity.allCases
                .max(by: { $0.rawValue < $1.rawValue })?
                .rawValue ?? 5
        }
}

// MARK: ExerciseQualityRating UI-Erweiterungen für die Anzeige im Display

extension ExerciseQualityRating {
    // Farbe der Bewertungsstufe
    var color: Color {
        switch self {
        case .poor:    return Color.red
        case .neutral: return Color.orange
        case .good:    return Color.green
        }
    }
}

// MARK: TrainingProgramm UI-Erweiterungen für die Anzeige im Display

extension TrainingProgram {
    // Beschreibung des Trainingsprogramms
    var description: String {
        switch self {
        case .manual: "Manuell"
        case .fatBurn: "Fettabbau"
        case .cardio: "Cardio"
        case .hill: "Hügel"
        case .random: "Zufall"
        case .fitTest: "Fit Test"
        }
    }

    // Symbol für das Trainingsprogramm
    var symbol: String {
        switch self {
        case .manual: "slider.horizontal.3"
        case .fatBurn: "flame.fill"
        case .cardio: "heart.fill"
        case .hill: "mountain.2.fill"
        case .random: "dice.fill"
        case .fitTest: "figure.run.treadmill"
        }
    }

    // Symbolfarbe für das Trainingsprogramm
    var tint: Color {
        switch self {
            case .manual: .blue
            case .fatBurn: Color.red
            case .cardio: .pink
            case .hill: Color.mint
            case .random: .indigo
            case .fitTest: Color.yellow
        }
    }
}

// MARK: TrainingProgramm UI-Erweiterungen für die Anzeige im Display

extension CardioDevice {
    // Beschreibung des Trainingsprogramms
    var description: String {
        switch self {
        case .none: "Unbekannt"
        case .crosstrainer: "Crosstrainer"
        case .ergometer: "Ergometer"
        }
    }

    var symbol: String {
        switch self {
        case .none: "questionmark.circle"
        case .crosstrainer: "figure.elliptical"
        case .ergometer: "figure.indoor.cycle"
        }
    }

    var tint: Color {
        switch self {
        case .crosstrainer: .blue
        case .ergometer: Color.green
        case .none: .secondary
        }
    }
}
