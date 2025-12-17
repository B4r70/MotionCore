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
import Foundation

// MARK: - Outdoor-Aktivität

enum OutdoorActivity: String, Codable, CaseIterable, Identifiable {
    case cycling        // Radfahren (allgemein)
    case roadBike       // Rennrad
    case mountainBike   // Mountainbike
    case running        // Laufen
    case trailRunning   // Traillauf
    case hiking         // Wandern
    case walking        // Spazieren
    case other          // Sonstiges
    
    var id: Self { self }
}

// MARK: - Wetterbedingungen

enum WeatherCondition: String, Codable, CaseIterable {
    case unknown        // Unbekannt
    case sunny          // Sonnig
    case partlyCloudy   // Teilweise bewölkt
    case cloudy         // Bewölkt
    case rainy          // Regnerisch
    case windy          // Windig
    case cold           // Kalt
    case hot            // Heiß
    case snow           // Schnee
}
