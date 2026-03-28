//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : ViewModels                                                       /
// Datei . . . . : ProgressionViewModel.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-18                                                       /
// Beschreibung  : Gecachte Progressions-Analyse — einmal berechnen, O(1) lesen.  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import Observation
import SwiftData

@Observable
final class ProgressionViewModel {

    // MARK: - Gecachte Ergebnisse

    private(set) var trainedExercises: [Exercise] = []
    private(set) var analyses: [ProgressionAnalysis] = []
    private(set) var improvingCount: Int = 0
    private(set) var stableCount: Int = 0
    private(set) var decliningCount: Int = 0
    private(set) var needsDeload: Bool = false
    private(set) var oneRMTrendMap: [PersistentIdentifier: [TrendPoint]] = [:]
    private(set) var volumeTrendMap: [PersistentIdentifier: [TrendPoint]] = [:]
    private(set) var groupedByTrend: [(trend: PerformanceTrend, exercises: [(Exercise, ProgressionAnalysis)])] = []

    // MARK: - Neuberechnung

    /// Berechnet alle Progressions-Daten auf einmal und cached die Ergebnisse.
    /// Nur bei echten SwiftData-Änderungen aufrufen (via .task / .onChange).
    func recalculate(sessions: [StrengthSession], exercises: [Exercise]) {
        let engine = ProgressionAnalyseCalcEngine(sessions: sessions, exercises: exercises)

        // Einmaliger O(n·k)-Durchlauf für alle Analysen
        let allAnalyses = engine.allAnalyses
        let trained = engine.trainedExercises

        self.trainedExercises = trained
        self.analyses = allAnalyses
        self.improvingCount = allAnalyses.filter { $0.trend == .improving }.count
        self.stableCount = allAnalyses.filter { $0.trend == .stable || $0.trend == .volatile }.count
        self.decliningCount = allAnalyses.filter { $0.trend == .declining }.count
        self.needsDeload = self.decliningCount >= 3

        // Chart-Daten vorab berechnen — O(1)-Zugriff im Sheet (Key = persistentModelID)
        self.oneRMTrendMap = Dictionary(uniqueKeysWithValues: trained.map { ex -> (PersistentIdentifier, [TrendPoint]) in
            (ex.persistentModelID, engine.oneRMTrend(for: ex))
        })
        self.volumeTrendMap = Dictionary(uniqueKeysWithValues: trained.map { ex -> (PersistentIdentifier, [TrendPoint]) in
            (ex.persistentModelID, engine.volumeTrend(for: ex))
        })

        // Gruppierung nach Trend cachen — O(1) lesen in der View
        let trendOrder: [PerformanceTrend] = [.improving, .stable, .declining, .insufficient]
        let analysisMap = Dictionary(allAnalyses.map { ($0.exerciseName, $0) }, uniquingKeysWith: { first, _ in first })

        self.groupedByTrend = trendOrder.compactMap { trend in
            let matching = trained.compactMap { exercise -> (Exercise, ProgressionAnalysis)? in
                guard let analysis = analysisMap[exercise.name] else { return nil }
                let effectiveTrend: PerformanceTrend = analysis.trend == .volatile ? .stable : analysis.trend
                guard effectiveTrend == trend else { return nil }
                return (exercise, analysis)
            }
            .sorted { $0.0.name < $1.0.name }
            return matching.isEmpty ? nil : (trend: trend, exercises: matching)
        }
    }

    // MARK: - Lookup

    /// Gibt die gecachte Analyse für eine Übung zurück (O(n), reicht für diese Liste).
    func analysis(for exercise: Exercise) -> ProgressionAnalysis? {
        analyses.first { $0.exerciseName == exercise.name }
    }
}
