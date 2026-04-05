//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : OutdoorTypes.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 16.12.2025                                                       /
// Beschreibung  : Enumerationen für Outdoor-Aktivitäten                            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Outdoor-Aktivität

enum OutdoorActivity: String, Codable, CaseIterable, Identifiable {
    case cycling        // Radfahren (allgemein)
    case roadBike       // Rennrad
    case mountainBike   // Mountainbike
    case eBike          // E-Bike
    case running        // Laufen
    case trailRunning   // Traillauf
    case hiking         // Wandern
    case walking        // Spazieren
    case other          // Sonstiges

    var id: Self { self }

    var description: String {
        switch self {
        case .cycling:      return "Radfahren"
        case .roadBike:     return "Rennrad"
        case .mountainBike: return "Mountainbike"
        case .eBike:        return "E-Bike"
        case .running:      return "Laufen"
        case .trailRunning: return "Traillauf"
        case .hiking:       return "Wandern"
        case .walking:      return "Spazieren"
        case .other:        return "Sonstiges"
        }
    }

    var icon: String {
        switch self {
        case .cycling:      return "bicycle"
        case .roadBike:     return "bicycle"
        case .mountainBike: return "bicycle"
        case .eBike:        return "figure.outdoor.cycle"
        case .running:      return "figure.run"
        case .trailRunning: return "figure.hiking"
        case .hiking:       return "figure.hiking"
        case .walking:      return "figure.walk"
        case .other:        return "figure.outdoor.cycle"
        }
    }

    var tint: Color {
        switch self {
        case .cycling:      return .blue
        case .roadBike:     return .purple
        case .mountainBike: return .brown
        case .eBike:        return Color.green
        case .running:      return Color.orange
        case .trailRunning: return Color.red
        case .hiking:       return Color.mint
        case .walking:      return .teal
        case .other:        return Color.gray
        }
    }
}

// MARK: - Wetterbedingungen

enum WeatherCondition: String, Codable, CaseIterable, Identifiable {
    case unknown        // Unbekannt
    case sunny          // Sonnig
    case partlyCloudy   // Teilweise bewölkt
    case cloudy         // Bewölkt
    case rainy          // Regnerisch
    case windy          // Windig
    case cold           // Kalt
    case hot            // Heiß
    case snow           // Schnee

    var id: Self { self }

    var description: String {
        switch self {
        case .unknown:      return "Unbekannt"
        case .sunny:        return "Sonnig"
        case .partlyCloudy: return "Teilweise bewölkt"
        case .cloudy:       return "Bewölkt"
        case .rainy:        return "Regnerisch"
        case .windy:        return "Windig"
        case .cold:         return "Kalt"
        case .hot:          return "Heiß"
        case .snow:         return "Schnee"
        }
    }

    var icon: String {
        switch self {
        case .unknown:      return "questionmark.circle"
        case .sunny:        return "sun.max"
        case .partlyCloudy: return "cloud.sun"
        case .cloudy:       return "cloud"
        case .rainy:        return "cloud.rain"
        case .windy:        return "wind"
        case .cold:         return "thermometer.snowflake"
        case .hot:          return "thermometer.sun"
        case .snow:         return "snowflake"
        }
    }
}
