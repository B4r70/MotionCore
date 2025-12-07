//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : UserTypes.swift                                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.11.2025                                                       /
// Beschreibung  : Benutzerspezifische Angaben wie Gender, Activity, etc.           /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

enum Gender: String, CaseIterable, Identifiable {
    case male = "Männlich"
    case female = "Weiblich"
    case other = "Divers"

    var id: String { self.rawValue }
    
    // Für die Anzeige in der Picker-View
    var description: String {
        self.rawValue
    }

    // Anzeige des passenden GenderIcons aus Assetts
    var icon: String {
        switch self {
            case .male:
                return "GenderMetrics/male"
            case .female:
                return "GenderMetrics/female"
            case .other:
                return "GenderMetrics/divers"
        }
    }
    // Gender Color
    var color: Color {
        switch self {
        case .male: return .blue
        case .female: return .pink
        case .other: return .purple
        }
    }
}

    // NEU: Aktivitätslevel für TDEE-Berechnung
enum UserActivityLevel: Double, CaseIterable, Identifiable {
    case sedentary = 1.2        // Sitzend, wenig Bewegung
    case lightlyActive = 1.375  // Leichtes Training 1-3x/Woche
    case moderatelyActive = 1.55 // Moderates Training 3-5x/Woche
    case veryActive = 1.725     // Intensives Training 6-7x/Woche
    case extraActive = 1.9      // Sehr intensiv + körperliche Arbeit

    var id: Double { self.rawValue }

    var description: String {
        switch self {
            case .sedentary:
                return "Sitzend (wenig Bewegung)"
            case .lightlyActive:
                return "Leicht aktiv (1-3x/Woche)"
            case .moderatelyActive:
                return "Moderat aktiv (3-5x/Woche)"
            case .veryActive:
                return "Sehr aktiv (6-7x/Woche)"
            case .extraActive:
                return "Extrem aktiv (täglich intensiv)"
        }
    }

    // Kürzere Beschreibung für Wheel
    var shortDescription: String {
        switch self {
            case .sedentary:
                return "Sitzend"
            case .lightlyActive:
                return "Leicht aktiv"
            case .moderatelyActive:
                return "Moderat aktiv"
            case .veryActive:
                return "Sehr aktiv"
            case .extraActive:
                return "Extrem aktiv"
        }
    }
}
