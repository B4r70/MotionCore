//---------------------------------------------------------------------------------/
//  # CrossStats                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : WorkoutTypesUI.swift                                             /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Zusätzliche Wertebereiche für Daten aus WorkoutSession           /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
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
            case .none: .gray
            case .veryEasy: .green
            case .easy: .mint
            case .medium: .yellow
            case .hard: .orange
            case .veryHard: .red
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
            case .hill: "mountain2.fill"
            case .random: "dice.fill"
            case .fitTest: "figure.run.treadmill"
        }
    }
}

