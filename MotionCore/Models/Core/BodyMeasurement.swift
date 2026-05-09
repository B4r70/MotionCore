//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : BodyMeasurement.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.05.2026                                                       /
// Beschreibung  : Persistiertes Datenmodell für Körpermaß-Messungen               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Alle Properties haben Defaults oder sind Optional → CloudKit-kompatibel /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@Model
final class BodyMeasurement {

    // MARK: - Identifikation

    var measurementUUID: UUID = UUID()

    // MARK: - Metadaten

    var date: Date = Date()
    var notes: String = ""

    // MARK: - Gewicht

    var bodyWeight: Double?

    // MARK: - Umfänge

    var chestCircumference: Double?
    var waistCircumference: Double?
    var abdomenCircumference: Double?
    var hipCircumference: Double?
    var armCircumferenceLeft: Double?
    var armCircumferenceRight: Double?
    var thighCircumferenceLeft: Double?
    var thighCircumferenceRight: Double?

    // MARK: - Sync-Flags

    var syncedToSupabase: Bool = false
    var needsSupabaseResync: Bool = false

    // MARK: - Berechnete Properties (nicht persistiert)

    var armCircumferenceAverage: Double? {
        switch (armCircumferenceLeft, armCircumferenceRight) {
        case let (l?, r?): return (l + r) / 2
        case let (l?, nil): return l
        case let (nil, r?): return r
        default: return nil
        }
    }

    var thighCircumferenceAverage: Double? {
        switch (thighCircumferenceLeft, thighCircumferenceRight) {
        case let (l?, r?): return (l + r) / 2
        case let (l?, nil): return l
        case let (nil, r?): return r
        default: return nil
        }
    }

    // MARK: - Initialisierung

    init(date: Date = Date()) {
        self.date = date
    }
}
