//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : EBikeProfileTypes.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 30.03.2026                                                       /
// Beschreibung  : Enumerationen für das E-Bike-Profil                              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftUI

// MARK: - Fahrradtyp

enum BikeType: String, Codable, CaseIterable, Identifiable {
    case eBikeTrekking
    case eBikeCity
    case eBikeMountain
    case eBikeRoad
    case eBikeCargo

    var id: Self { self }

    var description: String {
        switch self {
        case .eBikeTrekking:  return "E-Trekking"
        case .eBikeCity:      return "E-City"
        case .eBikeMountain:  return "E-Mountainbike"
        case .eBikeRoad:      return "E-Rennrad"
        case .eBikeCargo:     return "E-Lastenrad"
        }
    }

    var icon: String {
        switch self {
        case .eBikeTrekking:  return "figure.outdoor.cycle"
        case .eBikeCity:      return "bicycle"
        case .eBikeMountain:  return "mountain.2"
        case .eBikeRoad:      return "road.lanes"
        case .eBikeCargo:     return "shippingbox"
        }
    }
}

// MARK: - Zustand des Fahrrads

enum BikeCondition: Int, Codable, CaseIterable, Identifiable {
    case excellent    = 5
    case good         = 4
    case fair         = 3
    case needsService = 2
    case poor         = 1

    var id: Self { self }

    var description: String {
        switch self {
        case .excellent:    return "Hervorragend"
        case .good:         return "Gut"
        case .fair:         return "Befriedigend"
        case .needsService: return "Wartung nötig"
        case .poor:         return "Schlecht"
        }
    }

    var color: Color {
        switch self {
            case .excellent:    return Color.green
            case .good:         return Color.blue
            case .fair:         return Color.yellow
            case .needsService: return Color.orange
            case .poor:         return Color.red
        }
    }
}

// MARK: - Reifengröße

enum TireSize: String, Codable, CaseIterable, Identifiable {
    case t26  = "26\""
    case t275 = "27.5\""
    case t28  = "28\""
    case t29  = "29\""

    var id: Self { self }

    // Rohdaten-Wert wird direkt als Beschreibung verwendet
    var description: String { rawValue }
}
