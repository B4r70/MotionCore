//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Berechnung                                            /
// Datei . . . . : BodyMeasurementRadarCalcEngine.swift                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.05.2026                                                       /
// Beschreibung  : Radar-Chart-Daten aus Körpermaßen (6 Achsen, normalisiert [0,1]) /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - RadarAxis

struct RadarAxis: Hashable {
    let label: String
}

// MARK: - BodyMeasurementRadarData

struct BodyMeasurementRadarData: Hashable {
    /// Immer genau 6 Achsen
    let axes: [RadarAxis]
    /// 6 Werte, normalisiert [0, 1] — aktuellste Messung im Timeframe
    let currentPolygon: [Double]
    /// Vergleichs-Polygon (älteste Messung im Timeframe), nil bei < 2 Messungen
    let previousPolygon: [Double]?
    /// Roh-Maxima über ALLE Messungen (für Normalisierungs-Referenz)
    let allTimeMax: [Double]
}

// MARK: - BodyMeasurementRadarCalcEngine

struct BodyMeasurementRadarCalcEngine {

    // MARK: - Achsen-Definition (Reihenfolge fest)

    private let axes: [(label: String, keyPath: KeyPath<BodyMeasurement, Double?>)] = [
        ("Brust",         \.chestCircumference),
        ("Taille",        \.waistCircumference),
        ("Bauch",         \.abdomenCircumference),
        ("Hüfte",         \.hipCircumference),
        ("Arm",           \.armCircumferenceAverage),
        ("Oberschenkel",  \.thighCircumferenceAverage),
    ]

    // MARK: - Haupt-Berechnung

    func computeRadar(
        measurements: [BodyMeasurement],
        timeframe: SummaryTimeframe
    ) -> BodyMeasurementRadarData {

        let radarAxes = axes.map { RadarAxis(label: $0.label) }

        // 1. allTimeMax über ALLE Messungen (unabhängig vom Timeframe)
        let allTimeMax: [Double] = axes.map { axis in
            measurements.compactMap { $0[keyPath: axis.keyPath] }.max() ?? 0
        }

        // 2. Timeframe-Slice, absteigend nach Datum (jüngste zuerst)
        let slice = filterMeasurements(measurements, for: timeframe)
            .sorted { $0.date > $1.date }

        // 3. currentPolygon: erster nicht-nil Wert pro Achse im Slice
        let currentValues: [Double?] = axes.map { axis in
            slice.compactMap { $0[keyPath: axis.keyPath] }.first
        }

        // 4. compareValues: letzter (ältester) nicht-nil Wert pro Achse, nur wenn slice.count >= 2
        var compareValues: [Double?] = Array(repeating: nil, count: axes.count)
        if slice.count >= 2 {
            for (i, axis) in axes.enumerated() {
                // Ältester Eintrag mit nicht-nil Wert, der nicht der jüngste Eintrag insgesamt ist
                compareValues[i] = slice.compactMap { $0[keyPath: axis.keyPath] }.last
            }
        }

        // 5. Normalisierung
        func normalize(_ value: Double?, axisIndex: Int) -> Double {
            guard let v = value else { return 0 }
            let max = allTimeMax[axisIndex]
            guard max > 0 else { return 0 }
            // clamped to [0, 1]
            return Swift.max(0, Swift.min(1, v / max))
        }

        let currentPolygon = (0..<axes.count).map { normalize(currentValues[$0], axisIndex: $0) }

        // 6. previousPolygon: nil wenn compareValues überall nil oder identisch mit current
        let hasCompareData = compareValues.contains { $0 != nil }
        let previousPolygon: [Double]? = hasCompareData
            ? (0..<axes.count).map { normalize(compareValues[$0], axisIndex: $0) }
            : nil

        return BodyMeasurementRadarData(
            axes: radarAxes,
            currentPolygon: currentPolygon,
            previousPolygon: previousPolygon,
            allTimeMax: allTimeMax
        )
    }

    // MARK: - Timeframe-Filter

    private func filterMeasurements(
        _ measurements: [BodyMeasurement],
        for timeframe: SummaryTimeframe
    ) -> [BodyMeasurement] {
        let calendar = Calendar.current
        let now = Date()

        switch timeframe {
        case .week:
            let startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return measurements.filter { $0.date >= startDate }
        case .month:
            let startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return measurements.filter { $0.date >= startDate }
        case .year:
            let startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return measurements.filter { $0.date >= startDate }
        case .all:
            return measurements
        }
    }
}
