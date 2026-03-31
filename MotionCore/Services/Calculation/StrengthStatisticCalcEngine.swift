//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StrengthStatisticCalcEngine.swift                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-03                                                       /
// Beschreibung  : Berechnungen für Kraft-Statistiken                               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

struct StrengthStatisticCalcEngine {

    // MARK: - Input

    let sessions: [StrengthSession]

    // MARK: - Initializer

    init(sessions: [StrengthSession]) {
        self.sessions = sessions
    }

    // MARK: - Timeframe-Filter

    func filtered(by timeframe: SummaryTimeframe) -> StrengthStatisticCalcEngine {
        let now = Date()
        let calendar = Calendar.current
        let filtered: [StrengthSession]

        switch timeframe {
        case .week:
            let start = calendar.date(byAdding: .day, value: -7, to: now)!
            filtered = sessions.filter { $0.date >= start }
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: now)!
            filtered = sessions.filter { $0.date >= start }
        case .year:
            let start = calendar.date(byAdding: .year, value: -1, to: now)!
            filtered = sessions.filter { $0.date >= start }
        case .all:
            filtered = sessions
        }

        return StrengthStatisticCalcEngine(sessions: filtered)
    }

    // MARK: - Kennzahlen

    var totalSessions: Int {
        sessions.count
    }

    var totalVolume: Double {
        sessions.reduce(0.0) { $0 + $1.totalVolume }
    }

    var averageVolumePerSession: Double {
        guard !sessions.isEmpty else { return 0 }
        return totalVolume / Double(sessions.count)
    }

    var averageSetsPerSession: Double {
        guard !sessions.isEmpty else { return 0 }
        let total = sessions.reduce(0) { $0 + $1.totalSets }
        return Double(total) / Double(sessions.count)
    }

    // MARK: - Trend-Daten

    var volumeTrend: [TrendPoint] {
        sessions
            .filter { $0.totalVolume > 0 }
            .sorted { $0.date < $1.date }
            .map { TrendPoint(trendDate: $0.date, trendValue: $0.totalVolume) }
    }

    // MARK: - Übungs-spezifisch

    var allTrainedExerciseNames: [String] {
        let names = sessions.flatMap { session in
            session.safeExerciseSets.map { $0.exerciseName }
        }
        return Array(Set(names)).sorted()
    }

    func estimatedOneRM(for exerciseName: String) -> [TrendPoint] {
        sessions
            .sorted { $0.date < $1.date }
            .compactMap { session -> TrendPoint? in
                let relevantSets = session.safeExerciseSets.filter {
                    $0.exerciseName == exerciseName
                        && $0.weight > 0
                        && $0.reps > 0
                        && $0.isCompleted
                }
                guard !relevantSets.isEmpty else { return nil }
                let maxOneRM = relevantSets
                    .map { $0.weight * (1.0 + Double($0.reps) / 30.0) }
                    .max() ?? 0
                return TrendPoint(trendDate: session.date, trendValue: maxOneRM)
            }
    }
}
