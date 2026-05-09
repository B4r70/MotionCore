//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Berechnung                                            /
// Datei . . . . : BodyMeasurementRatioCalcEngine.swift                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.05.2026                                                       /
// Beschreibung  : Verhältnis-Berechnung (WHR, Brust-Taille, Arm-Brust) aus        /
//                 Körpermaßen mit Trend und Sparkline-Reihen                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - BodyMeasurementRatios

struct BodyMeasurementRatios: Hashable {
    let waistToHip: BodyMeasurementTrend?
    let chestToWaist: BodyMeasurementTrend?
    let armToChest: BodyMeasurementTrend?
}

// MARK: - BodyMeasurementRatioCalcEngine

struct BodyMeasurementRatioCalcEngine {

    // MARK: - Öffentliche API

    /// Berechnet aktuelle Trends für alle 3 Verhältnisse.
    ///
    /// - Parameters:
    ///   - measurements: Liste aller gespeicherten Messungen
    ///   - comparisonDays: Vergleichszeitraum in Tagen (Standard: 30)
    func computeRatios(
        measurements: [BodyMeasurement],
        comparisonDays: Int = 30
    ) -> BodyMeasurementRatios {
        let whr = whrSeries(measurements: measurements)
        let ctw = chestToWaistSeries(measurements: measurements)
        let atc = armToChestSeries(measurements: measurements)

        return BodyMeasurementRatios(
            waistToHip: trend(from: whr, comparisonDays: comparisonDays),
            chestToWaist: trend(from: ctw, comparisonDays: comparisonDays),
            armToChest: trend(from: atc, comparisonDays: comparisonDays)
        )
    }

    /// Liefert Sparkline-Reihen für alle 3 Verhältnisse, aufsteigend nach Datum.
    func ratioSeries(
        measurements: [BodyMeasurement]
    ) -> (waistToHip: [(Date, Double)], chestToWaist: [(Date, Double)], armToChest: [(Date, Double)]) {
        (
            whrSeries(measurements: measurements),
            chestToWaistSeries(measurements: measurements),
            armToChestSeries(measurements: measurements)
        )
    }

    // MARK: - Reihen-Berechnung

    /// WHR: Taille / Hüfte
    private func whrSeries(measurements: [BodyMeasurement]) -> [(Date, Double)] {
        measurements
            .sorted { $0.date < $1.date }
            .compactMap { m in
                guard let w = m.waistCircumference, let h = m.hipCircumference, h > 0 else { return nil }
                return (m.date, w / h)
            }
    }

    /// Brust-Taille: Brust / Taille
    private func chestToWaistSeries(measurements: [BodyMeasurement]) -> [(Date, Double)] {
        measurements
            .sorted { $0.date < $1.date }
            .compactMap { m in
                guard let c = m.chestCircumference, let w = m.waistCircumference, w > 0 else { return nil }
                return (m.date, c / w)
            }
    }

    /// Arm-Brust: Arm-Durchschnitt / Brust
    private func armToChestSeries(measurements: [BodyMeasurement]) -> [(Date, Double)] {
        measurements
            .sorted { $0.date < $1.date }
            .compactMap { m in
                guard let a = m.armCircumferenceAverage, let c = m.chestCircumference, c > 0 else { return nil }
                return (m.date, a / c)
            }
    }

    // MARK: - Trend aus Reihe

    /// Berechnet Trend (aktuellster Wert vs. Vergleichswert) aus einer Datums-Reihe.
    /// Stable-Schwelle: abs(delta) < 0.01 (Ratios sind kleine Zahlen, nicht cm-Maße)
    private func trend(
        from series: [(Date, Double)],
        comparisonDays: Int
    ) -> BodyMeasurementTrend? {
        guard !series.isEmpty else { return nil }

        // Aufsteigend sortiert (Datum aufsteigend) — Series sind bereits sorted, defensive Sortierung
        let sorted = series.sorted { $0.0 < $1.0 }

        // Aktueller Wert = jüngster Eintrag
        guard let (currentDate, currentValue) = sorted.last else { return nil }

        // Zieldatum: comparisonDays vor aktuellem Datum
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: -comparisonDays, to: currentDate) ?? currentDate
        let tolerance: TimeInterval = 5 * 86400 // 5 Tage in Sekunden

        // Nächster Eintrag zum Zieldatum (nicht der aktuelle)
        let previousEntry = sorted
            .filter { abs($0.0.timeIntervalSince(targetDate)) <= tolerance && $0.0 != currentDate }
            .min { abs($0.0.timeIntervalSince(targetDate)) < abs($1.0.timeIntervalSince(targetDate)) }

        guard let (_, previousValue) = previousEntry else {
            // Kein Vergleichswert im Toleranzfenster → Trend ohne Delta
            return BodyMeasurementTrend(
                currentValue: currentValue,
                currentDate: currentDate,
                previousValue: nil,
                absoluteDelta: nil,
                percentageDelta: nil,
                direction: .unknown
            )
        }

        let delta = currentValue - previousValue
        let pct: Double? = previousValue != 0 ? (delta / previousValue * 100) : nil

        // Stable-Schwelle 0.01 (nicht 0.3 wie bei cm-Maßen)
        let direction: TrendDirection
        if abs(delta) < 0.01 {
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
}
