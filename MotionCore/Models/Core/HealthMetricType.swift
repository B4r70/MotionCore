//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : HealthMetricType.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Metrik-Typen für HealthBaseline (HRV, Schlaf, Ruhepuls,          /
//                 Aktivität)                                                        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

enum HealthMetricType: String, Codable, CaseIterable {
    case hrv
    case sleep
    case restingHR
    case activity
}
