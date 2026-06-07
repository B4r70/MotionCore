//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Berechnung                                            /
// Datei . . . . : RecoveryTrendCalcEngine.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 07.06.2026                                                       /
// Beschreibung  : Rekonstruiert den 14-Tage-Verlauf des Gesamt-Erholungswerts      /
//                 durch rückwirkende MuscleRecoveryCalcEngine-Läufe                /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

/// Rekonstruiert den Verlauf des Gesamt-Erholungswerts über die letzten N Tage,
/// indem MuscleRecoveryCalcEngine für jeden Stichtag rückwirkend ausgeführt wird.
struct RecoveryTrendCalcEngine {

    // MARK: - Konstanten

    /// Anzahl der Stichtage (inkl. heute)
    static let defaultDays: Int = 14

    // MARK: - Haupt-Berechnung

    /// Liefert einen TrendPoint pro Tag (älteste zuerst, heute zuletzt).
    /// trendValue = overallRecoveryPercent zum jeweiligen Stichtag (0–100).
    static func trend(
        sessions: [StrengthSession],
        days: Int = defaultDays,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [TrendPoint] {
        guard days > 0 else { return [] }

        let startOfToday = calendar.startOfDay(for: now)
        var points: [TrendPoint] = []

        // Von (days-1) Tage zurück bis heute
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let dayStart = calendar.date(
                byAdding: .day, value: -offset, to: startOfToday
            ) else { continue }

            // Referenzzeitpunkt = Ende des Stichtags, damit Sessions
            // dieses Tages vollständig berücksichtigt werden.
            let reference = calendar.date(
                byAdding: .day, value: 1, to: dayStart
            )?.addingTimeInterval(-1) ?? dayStart

            let analysis = MuscleRecoveryCalcEngine.analyze(
                sessions: sessions,
                referenceDate: reference
            )

            points.append(TrendPoint(
                trendDate: dayStart,
                trendValue: analysis.overallRecoveryPercent
            ))
        }

        return points
    }

    // MARK: - Hilfsfunktionen

    /// True, wenn im gesamten Fenster keine Session trainiert wurde
    /// (alle Werte = 100 → keine sinnvolle Aussage).
    static func isEmpty(_ points: [TrendPoint]) -> Bool {
        points.allSatisfy { $0.trendValue >= 100.0 }
    }
}
