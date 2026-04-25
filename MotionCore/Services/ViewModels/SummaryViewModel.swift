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
import SwiftData

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

    // MARK: - Gecachte Werte (Dashboard — zeitraum-unabhängig)

    private(set) var xpLevel: XPLevel = XPLevel(
        level: 0, totalXP: 0, xpForCurrentLevel: 0,
        xpRequiredForNextLevel: 500, rank: .rookie, progressToNextLevel: 0
    )
    private(set) var recentXPGains: [XPGain] = []
    private(set) var motivationalContext: MotivationalContext = MotivationalContext(
        greeting: "Hallo", motivationalText: "Los geht's!"
    )
    private(set) var currentStreakMilestone: StreakMilestone? = nil
    private(set) var nextStreakMilestone: StreakMilestone? = nil
    private(set) var weeklyGoal: WeeklyGoal = WeeklyGoal(
        target: 4, current: 0, averageLast4Weeks: 0,
        isReached: false, isAboveAverage: false, progressFraction: 0
    )
    private(set) var currentWeekStrip: [ActivityDay] = []
    private(set) var volumeTrend: TrendComparison = TrendComparison(
        currentValue: 0, previousValue: 0, percentageChange: 0, trend: .stable
    )
    private(set) var caloriesTrend: TrendComparison = TrendComparison(
        currentValue: 0, previousValue: 0, percentageChange: 0, trend: .stable
    )
    private(set) var durationTrend: TrendComparison = TrendComparison(
        currentValue: 0, previousValue: 0, percentageChange: 0, trend: .stable
    )

    // MARK: - Bewertungs-Insights

    private(set) var ratingInsights: [RatingInsightCalcEngine.ExerciseInsight] = []

    // MARK: - Rollback-Vorschläge

    struct RollbackSuggestion: Identifiable {
        let id: PersistentIdentifier
        let state: ExerciseProgressionState
        let exerciseName: String
        let currentWeight: Double
        let previousWeight: Double?
        let reasoning: String
    }

    private(set) var rollbackSuggestions: [RollbackSuggestion] = []

    // MARK: - Auto-Progression-Vorschläge (Phase 1.5)

    struct AutoProgressionSuggestion: Identifiable {
        let id: PersistentIdentifier
        let state: ExerciseProgressionState
        let exerciseName: String
        let previousWeight: Double
        let newWeight: Double
        let amount: Double
        let reasoning: String
    }

    private(set) var autoProgressionSuggestions: [AutoProgressionSuggestion] = []

    // MARK: - Gecachte Werte (timeframe-gefiltert)

    private(set) var filteredTotalWorkouts: Int = 0
    private(set) var filteredTotalCalories: Int = 0
    private(set) var filteredFormattedDuration: String = ""
    private(set) var filteredAverageHeartRate: Int = 0
    private(set) var filteredWorkoutTypeDistribution: [SummaryCalcEngine.WorkoutTypeSummary] = []
    private(set) var filteredWorkoutTypeChartData: [DonutChartData] = []
    private(set) var filteredHeatmapAnalysis: MuscleHeatmapAnalysis? = nil

    // MARK: - Muskel-Erholung (zeitraum-unabhängig, letzte 14 Tage)

    private(set) var recoveryAnalysis: MuscleRecoveryAnalysis? = nil

    // MARK: - Trainings-Empfehlung (abgeleitet aus recoveryAnalysis)

    private(set) var recommendation: RecoveryRecommendation = .empty

    // MARK: - Neuberechnung (vollständige Datenmenge)

    /// Berechnet alle zeitraum-unabhängigen Werte neu.
    /// Aufrufen bei Änderung der Session-Arrays oder Exercise-Array.
    func recalculate(
        cardio: [CardioSession],
        strength: [StrengthSession],
        outdoor: [OutdoorSession],
        timeframe: SummaryTimeframe,
        weeklyGoalTarget: Int = 4,
        progressionStates: [ExerciseProgressionState] = []
    ) {
        let engine = SummaryCalcEngine(cardio: cardio, strength: strength, outdoor: outdoor)

        // Basis-Statistiken
        self.totalWorkouts = engine.totalWorkouts
        self.currentStreak = engine.currentStreak
        self.workoutsThisWeek = engine.workoutsThisWeek
        self.averageWorkoutsPerWeek = engine.averageWorkoutsPerWeek
        self.highestCaloriesBurn = engine.highestCaloriesBurn
        self.longestWorkout = engine.longestWorkout
        self.longestStreak = engine.longestStreak

        // XP-System
        recalculateXP(cardio: cardio, strength: strength, outdoor: outdoor, weeklyGoalTarget: weeklyGoalTarget)

        // Streak-Meilensteine
        let streakEngine = StreakCalcEngine(allTrainingDays: engine.allTrainingDays)
        self.currentStreakMilestone = streakEngine.currentMilestone(streak: engine.currentStreak)
        self.nextStreakMilestone = streakEngine.nextMilestone(streak: engine.currentStreak)

        // Wochenziel
        let goalEngine = WeeklyGoalCalcEngine(
            cardioSessions: cardio,
            strengthSessions: strength,
            outdoorSessions: outdoor,
            weeklyGoal: weeklyGoalTarget
        )
        self.weeklyGoal = goalEngine.currentWeekGoal()

        // Aktivitäts-Strip
        let activityEngine = ActivityGridCalcEngine(
            cardioSessions: cardio,
            strengthSessions: strength,
            outdoorSessions: outdoor
        )
        self.currentWeekStrip = activityEngine.currentWeekStrip()

        // Trend-Berechnungen
        let trendEngine = TrendCalcEngine(
            cardioSessions: cardio,
            strengthSessions: strength,
            outdoorSessions: outdoor
        )
        self.volumeTrend = trendEngine.volumeTrend
        self.caloriesTrend = trendEngine.caloriesTrend
        self.durationTrend = trendEngine.durationTrend

        // Bewertungs-Insights (auffällige Muster aus den letzten Sessions)
        self.ratingInsights = RatingInsightCalcEngine().analyze(sessions: strength)

        // Rollback-Vorschläge (aktive States + Engine-Check)
        recalculateRollbackSuggestions(states: progressionStates, strengthSessions: strength)

        // Auto-Progression: States mit autoProgressionUndoable = true
        recalculateAutoProgressionSuggestions(states: progressionStates)

        // Motivations-Kontext
        let xpEngine = XPCalcEngine(
            cardioSessions: cardio,
            strengthSessions: strength,
            outdoorSessions: outdoor,
            weeklyGoal: weeklyGoalTarget,
            // TODO: Phase 2 — echte PR-Daten aus StrengthRecordCalcEngine übergeben (+250 XP)
            strengthRecordDates: []
        )
        self.motivationalContext = xpEngine.motivationalContext(
            streak: engine.currentStreak,
            workoutsThisWeek: engine.workoutsThisWeek,
            weeklyGoal: weeklyGoalTarget,
            lastWorkoutDate: engine.lastWorkoutDate
        )

        // Muskel-Erholung (letzte 14 Tage, timeframe-unabhängig)
        self.recoveryAnalysis = MuscleRecoveryCalcEngine.analyze(sessions: strength)

        // Trainings-Empfehlung aus Erholungsanalyse ableiten
        if let analysis = self.recoveryAnalysis {
            self.recommendation = RecoveryRecommendationCalcEngine.recommend(from: analysis)
        } else {
            self.recommendation = .empty
        }

        // Gefilterte Werte direkt mitberechnen
        recalculateFiltered(engine: engine, timeframe: timeframe, strength: strength)
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
        recalculateFiltered(engine: engine, timeframe: timeframe, strength: strength)
    }

    // MARK: - Kalender-Daten (on-demand)

    /// Gibt Grid und Statistiken für einen bestimmten Monat zurück.
    func calendarData(
        for month: Date,
        cardio: [CardioSession],
        strength: [StrengthSession],
        outdoor: [OutdoorSession]
    ) -> (grid: [[ActivityDay?]], stats: (trainingDays: Int, averagePerWeek: Double)) {
        let engine = ActivityGridCalcEngine(
            cardioSessions: cardio,
            strengthSessions: strength,
            outdoorSessions: outdoor
        )
        return (engine.monthGrid(for: month), engine.monthStats(for: month))
    }

    // MARK: - Intern

    private func recalculateFiltered(
        engine: SummaryCalcEngine,
        timeframe: SummaryTimeframe,
        strength: [StrengthSession]
    ) {
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

        // Muskel-Heatmap für gefilterten Zeitraum
        // Sessions sind bereits durch filtered.strengthSessions vorgefiltert → timeframe .all übergeben
        if !filtered.strengthSessions.isEmpty {
            let heatmapEngine = MuscleHeatmapCalcEngine()
            self.filteredHeatmapAnalysis = heatmapEngine.analyze(
                sessions: filtered.strengthSessions,
                timeframe: .all
            )
        } else {
            self.filteredHeatmapAnalysis = nil
        }
    }

    private func recalculateXP(
        cardio: [CardioSession],
        strength: [StrengthSession],
        outdoor: [OutdoorSession],
        weeklyGoalTarget: Int
    ) {
        let xpEngine = XPCalcEngine(
            cardioSessions: cardio,
            strengthSessions: strength,
            outdoorSessions: outdoor,
            weeklyGoal: weeklyGoalTarget,
            // TODO: Phase 2 — echte PR-Daten aus StrengthRecordCalcEngine übergeben (+250 XP)
            strengthRecordDates: []
        )
        let totalXP = xpEngine.calculateTotalXP()
        self.xpLevel = xpEngine.calculateLevel(totalXP: totalXP)
        self.recentXPGains = xpEngine.recentXPGains()
    }

    private func recalculateRollbackSuggestions(
        states: [ExerciseProgressionState],
        strengthSessions: [StrengthSession]
    ) {
        var result: [RollbackSuggestion] = []

        for state in states where state.isActive {
            // Guard: previousWorkingWeight muss existieren (Zeile wird sonst versteckt)
            guard state.previousWorkingWeight != nil else { continue }

            let groupKey = state.exerciseGroupKey

            // Letzte 2 abgeschlossene Sessions mit Sets dieses groupKey (neueste zuerst)
            let relevantSessionSets = strengthSessions
                .filter { $0.isCompleted }
                .sorted { $0.date > $1.date }
                .compactMap { session -> [ExerciseSet]? in
                    let sets = session.safeExerciseSets.filter { $0.groupKey == groupKey }
                    return sets.isEmpty ? nil : sets
                }
            let last2 = Array(relevantSessionSets.prefix(2))
            guard last2.count >= 2 else { continue }

            // Cooldown-Check: Karte nur zeigen wenn neueste Session nach lastRollbackDate liegt
            if let lastRollback = state.lastRollbackDate {
                let newestSessionDate = strengthSessions
                    .filter { $0.isCompleted && $0.safeExerciseSets.contains { $0.groupKey == groupKey } }
                    .map { $0.date }
                    .max()
                if let date = newestSessionDate, date <= lastRollback {
                    continue
                }
            }

            // Engine konsultieren
            let output = RollbackDetectionCalcEngine.detect(
                input: .init(progressionState: state, last2Sessions: last2)
            )
            guard output.shouldSuggestRollback else { continue }

            // Übungsname aus neuester Session
            let name = last2.first?.first?.exerciseNameSnapshot.isEmpty == false
                ? last2.first!.first!.exerciseNameSnapshot
                : groupKey

            result.append(RollbackSuggestion(
                id: state.persistentModelID,
                state: state,
                exerciseName: name,
                currentWeight: state.workingWeight,
                previousWeight: output.previousWeight,
                reasoning: output.reasoning
            ))
        }

        rollbackSuggestions = result
    }

    // MARK: - Auto-Progression-Berechnung

    private func recalculateAutoProgressionSuggestions(states: [ExerciseProgressionState]) {
        autoProgressionSuggestions = states
            .filter { $0.autoProgressionUndoable }
            .compactMap { state -> AutoProgressionSuggestion? in
                guard let prev = state.previousWorkingWeight,
                      let amount = state.lastAutoProgressionAmount else { return nil }
                return AutoProgressionSuggestion(
                    id: state.persistentModelID,
                    state: state,
                    exerciseName: state.exerciseGroupKey,
                    previousWeight: prev,
                    newWeight: state.workingWeight,
                    amount: amount,
                    reasoning: ""
                )
            }
    }

}
