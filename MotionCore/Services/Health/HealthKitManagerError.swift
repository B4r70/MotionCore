//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : HealthKit                                                        /
// Datei . . . . : HealthKitManagerError.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Fehlertypen für HealthKitManager-Readiness-Abfragen (Phase 2)   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

enum HealthKitManagerError: Error {
    case notAuthorized
    case noData
    case queryFailed(Error)
}
