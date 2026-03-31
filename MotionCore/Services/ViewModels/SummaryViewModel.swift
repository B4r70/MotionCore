//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : ViewModels                                                       /
// Datei . . . . : SummaryViewModel.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-18                                                       /
// Beschreibung  : Gecachte Summary-Daten — trennt vollständige von gefilterten     /
//                 Berechnungen und aktualisiert nur bei echten Datenänderungen.    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import Observation

@Observable
final class SummaryViewModel {

    // MARK: - Gecachte Werte (vollständige Datenmenge)

    private(set) var totalWorkouts: Int = 0
    private(set) var currentStreak: Int = 0
    private(set) var workoutsThisWeek: Int = 0
    private(set) var averageWorkoutsPerWeek: Double = 0
    private(set) var highestCaloriesBurn: (session: any CoreSession, type: WorkoutType)? = nil
    private(set) var longestWorkout: (session: any CoreSession, type: WorkoutType)? = nil
    private(set) var longestStreak: Int = 0
    private(set) var progressionAnalyses: [ProgressionAnalysis] = []

    // MARK: - Gecachte Werte (timeframe-gefiltert)

    private(set) var filteredTotalWorkouts: Int = 0
    private(set) var filteredTotalCalories: Int = 0
    private(set) var filteredFormattedDuration: String = ""
    private(set) var filteredAverageHeartRate: Int = 0
    private(set) var filteredWorkoutTypeDistribution: [SummaryCalcEngine.WorkoutTypeSummary] = []
    private(set) var filteredWorkoutTypeChartData: [DonutChartData] = []

    // MARK: - Neuberechnung (vollständige Datenmenge)

    /// Berechnet alle zeitraum-unabhängigen Werte neu.
    /// Aufrufen bei Änderung der Session-Arrays oder Exercise-Array.
    func recalculate(
        cardio: [CardioSession],
        strength: [StrengthSession],
        outdoor: [OutdoorSession],
        exercises: [Exercise],
        timeframe: SummaryTimeframe
    ) {
        let engine = SummaryCalcEngine(cardio: cardio, strength: strength, outdoor: outdoor)

        // Streak-Daten (immer über alle Sessions)
        self.totalWorkouts = engine.totalWorkouts
        self.currentStreak = engine.currentStreak
        self.workoutsThisWeek = engine.workoutsThisWeek
        self.averageWorkoutsPerWeek = engine.averageWorkoutsPerWeek
        self.highestCaloriesBurn = engine.highestCaloriesBurn
        self.longestWorkout = engine.longestWorkout
        self.longestStreak = engine.longestStreak

        // Progressions-Analysen (nur wenn Kraft-Sessions vorhanden)
        if !strength.isEmpty {
            let progressionEngine = ProgressionCalcEngine()
            self.progressionAnalyses = exercises
                .filter { $0.progressionStrategy != .manual && $0.category != .bodyweight }
                .map { progressionEngine.analyze(exercise: $0, sessions: strength) }
        } else {
            self.progressionAnalyses = []
        }

        // Gefilterte Werte direkt mitberechnen
        recalculateFiltered(engine: engine, timeframe: timeframe)
    }

    // MARK: - Neuberechnung (nur Timeframe-Wechsel)

    /// Berechnet nur die gefilterten Werte neu — günstiger als volle Neuberechnung.
    /// Aufrufen bei Änderung des Timeframes.
    func recalculateFiltered(
        cardio: [CardioSession],
        strength: [StrengthSession],
        outdoor: [OutdoorSession],
        timeframe: SummaryTimeframe
    ) {
        let engine = SummaryCalcEngine(cardio: cardio, strength: strength, outdoor: outdoor)
        recalculateFiltered(engine: engine, timeframe: timeframe)
    }

    // MARK: - Intern

    private func recalculateFiltered(engine: SummaryCalcEngine, timeframe: SummaryTimeframe) {
        let filtered: SummaryCalcEngine
        switch timeframe {
        case .week:  filtered = engine.thisWeek
        case .month: filtered = engine.thisMonth
        case .year:  filtered = engine.thisYear
        case .all:   filtered = engine
        }

        self.filteredTotalWorkouts = filtered.totalWorkouts
        self.filteredTotalCalories = filtered.totalCalories
        self.filteredFormattedDuration = filtered.formattedTotalDuration
        self.filteredAverageHeartRate = filtered.averageHeartRate
        self.filteredWorkoutTypeDistribution = filtered.workoutTypeDistribution
        self.filteredWorkoutTypeChartData = filtered.workoutTypeChartData
    }
}
