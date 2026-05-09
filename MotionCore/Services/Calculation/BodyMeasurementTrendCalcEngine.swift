//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Berechnung                                            /
// Datei . . . . : BodyMeasurementTrendCalcEngine.swift                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.05.2026                                                       /
// Beschreibung  : Trend- und Sparkline-Berechnung für Körpermaße                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - BodyMeasurementTrend

/// Ergebnis-Struktur für einen einzelnen Körpermaß-Trend
struct BodyMeasurementTrend: Hashable {
    let currentValue: Double?
    let currentDate: Date?
    let previousValue: Double?
    let absoluteDelta: Double?
    let percentageDelta: Double?
    let direction: TrendDirection
}

// MARK: - BodyMeasurementTrendCalcEngine

/// Pure, zustandslose Engine zur Berechnung von Körpermaß-Trends und Sparkline-Daten
struct BodyMeasurementTrendCalcEngine {

    // MARK: - Trend

    /// Berechnet den Trend für ein bestimmtes Körpermaß.
    ///
    /// - Parameters:
    ///   - measurements: Liste aller gespeicherten Messungen (beliebige Reihenfolge)
    ///   - keyPath: KeyPath auf das gewünschte Maß (z.B. `\.bodyWeight`)
    ///   - comparisonDays: Vergleichszeitraum in Tagen (Standard: 30)
    /// - Returns: Trend-Ergebnis mit aktuellem Wert, Vergleichswert und Richtung
    func trend(
        for measurements: [BodyMeasurement],
        keyPath: KeyPath<BodyMeasurement, Double?>,
        comparisonDays: Int = 30
    ) -> BodyMeasurementTrend {
        // Absteigend nach Datum sortieren (neueste zuerst)
        let sorted = measurements.sorted { $0.date > $1.date }

        // Aktuellster Eintrag mit einem nicht-nil Wert
        guard let currentEntry = sorted.first(where: { $0[keyPath: keyPath] != nil }),
              let currentValue = currentEntry[keyPath: keyPath]
        else {
            return BodyMeasurementTrend(
                currentValue: nil,
                currentDate: nil,
                previousValue: nil,
                absoluteDelta: nil,
                percentageDelta: nil,
                direction: .unknown
            )
        }

        let currentDate = currentEntry.date

        // Zieldatum: comparisonDays Tage vor der aktuellen Messung
        guard let targetDate = Calendar.current.date(
            byAdding: .day,
            value: -comparisonDays,
            to: currentDate
        ) else {
            return BodyMeasurementTrend(
                currentValue: currentValue,
                currentDate: currentDate,
                previousValue: nil,
                absoluteDelta: nil,
                percentageDelta: nil,
                direction: .unknown
            )
        }

        // Vergleichseintrag: nicht-nil, mit minimalem Abstand zum Zieldatum (max ±5 Tage)
        let toleranceDays: Double = 5 * 86400  // 5 Tage in Sekunden
        let previousEntry = sorted
            .filter { $0[keyPath: keyPath] != nil && $0.date != currentEntry.date }
            .min { a, b in
                abs(a.date.timeIntervalSince(targetDate)) < abs(b.date.timeIntervalSince(targetDate))
            }

        guard let previousEntry,
              abs(previousEntry.date.timeIntervalSince(targetDate)) <= toleranceDays,
              let previousValue = previousEntry[keyPath: keyPath]
        else {
            return BodyMeasurementTrend(
                currentValue: currentValue,
                currentDate: currentDate,
                previousValue: nil,
                absoluteDelta: nil,
                percentageDelta: nil,
                direction: .unknown
            )
        }

        // Delta und Richtung berechnen
        let delta = currentValue - previousValue
        let pct: Double? = previousValue != 0 ? (delta / previousValue) * 100 : nil

        let direction: TrendDirection
        if abs(delta) < 0.3 {
            direction = .stable
        } else if delta > 0 {
            direction = .up
        } else {
            direction = .down
        }

        return BodyMeasurementTrend(
            currentValue: currentValue,
            currentDate: currentDate,
            previousValue: previousValue,
            absoluteDelta: delta,
            percentageDelta: pct,
            direction: direction
        )
    }

    // MARK: - Sparkline

    /// Liefert nicht-nil Datenpunkte für eine Sparkline, aufsteigend nach Datum sortiert.
    ///
    /// - Parameters:
    ///   - measurements: Liste aller Messungen
    ///   - keyPath: KeyPath auf das gewünschte Maß
    /// - Returns: Tupel-Array `(Date, Double)` aufsteigend nach Datum
    func sparklineData(
        for measurements: [BodyMeasurement],
        keyPath: KeyPath<BodyMeasurement, Double?>
    ) -> [(Date, Double)] {
        measurements
            .compactMap { m -> (Date, Double)? in
                guard let value = m[keyPath: keyPath] else { return nil }
                return (m.date, value)
            }
            .sorted { $0.0 < $1.0 }
    }
}
