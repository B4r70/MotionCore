//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Rekorde                                                          /
// Datei . . . . : OutdoorRecordCalcEngine.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-30                                                       /
// Beschreibung  : Berechnungen für Outdoor-spezifische Rekorde und Aggregatwerte  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Outdoor-Rekord Struct

/// Repräsentiert einen Outdoor-Rekord mit Session-Referenz und aufbereitetem Anzeigewert.
struct OutdoorRecord {
    /// Die Session, in der der Rekord erzielt wurde.
    let session: OutdoorSession
    /// Rohwert für interne Vergleiche.
    let value: Double
    /// Formatierter Wert für die Anzeige in der UI.
    let formattedValue: String
}

// MARK: - OutdoorRecordCalcEngine

struct OutdoorRecordCalcEngine {

    // MARK: - Input

    let sessions: [OutdoorSession]

    // MARK: - Initializer

    init(sessions: [OutdoorSession]) {
        self.sessions = sessions
    }

    // MARK: - Aggregierte Werte

    /// Gesamtdistanz aller Touren in Kilometern.
    var totalDistance: Double {
        sessions.reduce(0.0) { $0 + $1.distance }
    }

    /// Gesamter Höhengewinn aller Touren in Metern.
    var totalElevationGain: Double {
        sessions.reduce(0.0) { $0 + $1.elevationGain }
    }

    /// Anzahl der erfassten Touren.
    var tourCount: Int { sessions.count }

    // MARK: - Rekorde

    /// Längste Tour nach Distanz.
    var longestTour: OutdoorRecord? {
        guard let session = sessions.max(by: { $0.distance < $1.distance }),
              session.distance > 0 else { return nil }
        return OutdoorRecord(
            session: session,
            value: session.distance,
            formattedValue: String(format: "%.1f km", session.distance)
        )
    }

    /// Schnellste Tour nach Durchschnittsgeschwindigkeit.
    var fastestTour: OutdoorRecord? {
        guard let session = sessions.max(by: { $0.averageSpeed < $1.averageSpeed }),
              session.averageSpeed > 0 else { return nil }
        return OutdoorRecord(
            session: session,
            value: session.averageSpeed,
            formattedValue: String(format: "%.1f km/h", session.averageSpeed)
        )
    }

    /// Tour mit dem höchsten Höhengewinn.
    var highestElevationTour: OutdoorRecord? {
        guard let session = sessions.max(by: { $0.elevationGain < $1.elevationGain }),
              session.elevationGain > 0 else { return nil }
        return OutdoorRecord(
            session: session,
            value: session.elevationGain,
            formattedValue: String(format: "%.0f m", session.elevationGain)
        )
    }

    /// Tour mit den meisten verbrannten Kalorien.
    var mostCaloriesTour: OutdoorRecord? {
        guard let session = sessions.max(by: { $0.calories < $1.calories }),
              session.calories > 0 else { return nil }
        return OutdoorRecord(
            session: session,
            value: Double(session.calories),
            formattedValue: "\(session.calories) kcal"
        )
    }
}
