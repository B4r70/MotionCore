//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : HealthBaseline.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Rollende Baseline (Mean/StdDev) pro Health-Metrik —              /
//                 Phase 2 befüllt, in Phase 1 ungenutzt                            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Alle Properties haben Defaults → CloudKit-kompatibel              /
//                Kein @Relationship — standalone Model, kein Inverse-Zwang.        /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@Model
final class HealthBaseline {

    // MARK: - Identifikation

    var id: UUID = UUID()

    // MARK: - Metrik-Typ

    // Rohwert für CloudKit-Kompatibilität (String statt Enum)
    var metricTypeRaw: String = ""

    // MARK: - Rolling-Statistik

    var rollingMean: Double = 0.0
    var rollingStdDev: Double = 0.0
    var sampleCount: Int = 0

    // MARK: - Metadaten

    var lastUpdated: Date = Date()

    // MARK: - Typisierter Accessor

    // Gibt den typisierten Metrik-Typ zurück, Fallback auf .hrv
    var metricType: HealthMetricType {
        get { HealthMetricType(rawValue: metricTypeRaw) ?? .hrv }
        set { metricTypeRaw = newValue.rawValue }
    }

    // MARK: - Initialisierung

    init(metricType: HealthMetricType = .hrv) {
        self.metricTypeRaw = metricType.rawValue
    }
}
