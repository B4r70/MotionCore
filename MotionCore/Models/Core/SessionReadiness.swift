//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : SessionReadiness.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Readiness-Snapshot pro Session —                                 /
//                 Phase 2 befüllt, in Phase 1 ungenutzt                            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Alle Properties haben Defaults → CloudKit-kompatibel              /
//                Matching via sessionUUID String in Phase 2 — kein @Relationship.  /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@Model
final class SessionReadiness {

    // MARK: - Identifikation

    var id: UUID = UUID()

    // MARK: - Session-Referenz

    // Soft-Link zur StrengthSession via sessionUUID String (Phase 2)
    var sessionUUID: String?
    var capturedAt: Date = Date()

    // MARK: - Metrik-Scores

    var hrvScore: Double?
    var sleepScore: Double?
    var restingHRScore: Double?
    var activityScore: Double?

    // MARK: - User-Input

    var userEnergyLevel: Int?
    var userStressLevelRaw: String?

    // MARK: - Gesamt-Score

    // 0–100, wird durch ReadinessCalcEngine befüllt (Phase 2)
    var overallScore: Int = 50
    var isCalibrating: Bool = false

    // MARK: - Initialisierung

    init() {}
}
