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
    private(set) var bestExerciseAnalysis: ProgressionAnalysis? = nil
    private(set) var bestExerciseTrendPoints: [TrendPoint] = []

    // MARK: - Gecachte Werte (timeframe-gefiltert)

    private(set) var filteredTotalWorkouts: Int = 0
    private(set) var filteredTotalCalories: Int = 0
    private(set) var filteredFormattedDuration: String = ""
    private(set) var filteredAverageHeartRate: Int = 0
    private(set) var filteredWorkoutTypeDistribution: [SummaryCalcEngine.WorkoutTypeSummary] = []
    private(set) var filteredWorkoutTypeChartData: [DonutChartData] = []
    private(set) var filteredHeatmapAnalysis: MuscleHeatmapAnalysis? = nil

    // MARK: - Neuberechnung (vollständige Datenmenge)

    /// Berechnet alle zeitraum-unabhängigen Werte neu.
    /// Aufrufen bei Änderung der Session-Arrays oder Exercise-Array.
    func recalculate(
        cardio: [CardioSession],
        strength: [StrengthSession],
        outdoor: [OutdoorSession],
        exercises: [Exercise],
        timeframe: SummaryTimeframe,
        weeklyGoalTarget: Int = 4
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

        // Progressions-Analysen (nur wenn Kraft-Sessions vorhanden)
        let progressionEngine = ProgressionCalcEngine()
        if !strength.isEmpty {
            // Trainierte Übungsnamen aus Sessions extrahieren (einmaliger O(sessions × sets)-Durchlauf)
            let trainedNames: Set<String> = Set(
                strength.flatMap { session in
                    session.safeExerciseSets.flatMap { s -> [String] in
                        var names: [String] = []
                        if !s.exerciseNameSnapshot.isEmpty { names.append(s.exerciseNameSnapshot) }
                        if !s.exerciseName.isEmpty { names.append(s.exerciseName) }
                        return names
                    }
                }
            )
            self.progressionAnalyses = exercises
                .filter { trainedNames.contains($0.name) }
                .filter { $0.progressionStrategy != .manual && $0.category != .bodyweight }
                .map { progressionEngine.analyze(exercise: $0, sessions: strength) }
        } else {
            self.progressionAnalyses = []
        }

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

        // Beste Übung der Woche (höchste Konfidenz)
        recalculateBestExercise(strength: strength, progressionEngine: progressionEngine)

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

    private func recalculateBestExercise(
        strength: [StrengthSession],
        progressionEngine: ProgressionCalcEngine
    ) {
        // Übung der Woche = höchste Konfidenz unter allen Analysen
        guard let best = progressionAnalyses
            .filter({ $0.sessionsAnalyzed >= 3 })
            .max(by: { $0.confidence < $1.confidence })
        else {
            self.bestExerciseAnalysis = nil
            self.bestExerciseTrendPoints = []
            return
        }

        self.bestExerciseAnalysis = best

        // TrendPoints aus den letzten 5 Snapshots berechnen
        let snapshots = progressionEngine
            .extractSnapshots(for: best.exerciseName, from: strength)
            .prefix(5)
            .reversed()

        self.bestExerciseTrendPoints = snapshots.map { snapshot in
            TrendPoint(
                trendDate: snapshot.date,
                trendValue: snapshot.estimatedOneRM ?? snapshot.totalVolume
            )
        }
    }
}
