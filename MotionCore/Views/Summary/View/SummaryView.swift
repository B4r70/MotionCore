//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : SummaryView.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 07.01.2026                                                       /
// Beschreibung  : Command-Center-Dashboard (Redesign 2026-04)                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct SummaryView: View {

    // MARK: - Callback

    let onStartWorkoutTap: () -> Void

    // MARK: - Data Queries

    @Query(sort: \CardioSession.date, order: .reverse)
    private var cardioSessions: [CardioSession]

    @Query(sort: \StrengthSession.date, order: .reverse)
    private var strengthSessions: [StrengthSession]

    @Query(sort: \OutdoorSession.date, order: .reverse)
    private var outdoorSessions: [OutdoorSession]

    @Query(sort: \ExerciseProgressionState.updatedAt, order: .reverse)
    private var progressionStates: [ExerciseProgressionState]

    @Query(sort: \SessionReadiness.capturedAt, order: .reverse)
    private var allReadiness: [SessionReadiness]

    // MARK: - Environment

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appSettings: AppSettings

    // MARK: - State

    @State private var selectedTimeframe: SummaryTimeframe = .week
    @State private var viewModel = SummaryViewModel()
    @State private var showCalendar: Bool = false
    @State private var showAutoProgressionDetails: Bool = false
    @State private var displayedMonth: Date = Date()
    @State private var calendarGrid: [[ActivityDay?]] = []
    @State private var calendarStats: (trainingDays: Int, averagePerWeek: Double) = (0, 0.0)
    @State private var recoveryDetailItem: MuscleRecoveryAnalysis? = nil

    // Readiness der neuesten Session (softlink über Query-Reihenfolge)
    private var latestSessionReadiness: SessionReadiness? {
        allReadiness.first
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 16) {
                    heroSection
                    chipRow
                    muscleRingsSection
                    statGrid
                    progressionInsights
                    TimeframePicker(selection: $selectedTimeframe)
                    detailCards
                    calendarSection
                    heatmapSection
                }
                .scrollViewContentPadding()
                .animation(.easeInOut(duration: 0.3), value: showCalendar)
            }
            .scrollIndicators(.hidden)

            if viewModel.totalWorkouts == 0 {
                EmptyState()
            }
        }
        .task {
            recalculateAll()
            refreshCalendarData()
        }
        .onChange(of: cardioSessions)        { _, _ in recalculateAll() }
        .onChange(of: strengthSessions)      { _, _ in recalculateAll() }
        .onChange(of: outdoorSessions)       { _, _ in recalculateAll() }
        .onChange(of: progressionStates)     { _, _ in recalculateAll() }
        .onChange(of: appSettings.weeklyWorkoutGoal) { _, _ in recalculateAll() }
        .onChange(of: selectedTimeframe) { _, new in
            // Nur gefilterte Werte neu berechnen — günstiger als volle Neuberechnung
            viewModel.recalculateFiltered(
                cardio: cardioSessions,
                strength: strengthSessions,
                outdoor: outdoorSessions,
                timeframe: new
            )
        }
        .onChange(of: displayedMonth) { _, _ in refreshCalendarData() }
        .sheet(isPresented: $showAutoProgressionDetails) {
            AutoProgressionDetailsView(
                suggestions: viewModel.autoProgressionSuggestions,
                onUndoOne: { state in
                    AutoProgressionApplier.undo(state: state, context: context)
                }
            )
        }
        .sheet(item: $recoveryDetailItem) { analysis in
            MuscleRecoveryDetailView(analysis: analysis)
                .environmentObject(appSettings)
        }
    }

    // MARK: - Hero + Chip

    private var heroSection: some View {
        SummaryCommandHero(
            readinessScore: latestSessionReadiness?.overallScore,
            readinessLabel: latestSessionReadiness.map { ReadinessLabel.from(score: $0.overallScore) },
            readinessIsCalibrating: latestSessionReadiness?.isCalibrating ?? false,
            recoveryPercent: Int(viewModel.recoveryAnalysis?.overallRecoveryPercent ?? 0),
            currentStreak: viewModel.currentStreak,
            nextStreakMilestone: viewModel.nextStreakMilestone,
            recommendation: viewModel.recommendation,
            onStartWorkoutTap: onStartWorkoutTap
        )
    }

    private var chipRow: some View {
        SummaryChipRow(
            xpLevel: viewModel.xpLevel,
            volumeTrend: viewModel.volumeTrend,
            averageHeartRate: viewModel.filteredAverageHeartRate,
            sleepDuration: nil  // SessionReadiness hat kein sleepDuration-Property
        )
    }

    // MARK: - Muskel-Rings

    @ViewBuilder
    private var muscleRingsSection: some View {
        if let analysis = viewModel.recoveryAnalysis {
            SummaryMuscleRingsCard(analysis: analysis) {
                recoveryDetailItem = analysis
            }
        }
    }

    // MARK: - Stat-Grid

    private var statGrid: some View {
        SummaryStatGridCard(
            totalWorkouts: viewModel.filteredTotalWorkouts,
            totalCalories: viewModel.filteredTotalCalories,
            formattedDuration: viewModel.filteredFormattedDuration,
            averageHeartRate: viewModel.filteredAverageHeartRate,
            volumeTrend: viewModel.volumeTrend,
            caloriesTrend: viewModel.caloriesTrend,
            durationTrend: viewModel.durationTrend
        )
    }

    // MARK: - Progression-Insights

    @ViewBuilder
    private var progressionInsights: some View {
        if !viewModel.rollbackSuggestions.isEmpty {
            RollbackInsightCard(
                suggestions: viewModel.rollbackSuggestions,
                onRollback: { state in
                    ProgressionRollbackService.applyRollback(state: state, in: context)
                },
                onContinue: { state in
                    ProgressionRollbackService.dismissSuggestion(state: state, in: context)
                },
                onSwitchToAdvanced: { state in
                    ProgressionRollbackService.switchToAdvanced(state: state, in: context)
                }
            )
        }
        if !viewModel.autoProgressionSuggestions.isEmpty {
            AutoProgressionInsightCard(
                suggestions: viewModel.autoProgressionSuggestions,
                onUndo: {
                    AutoProgressionApplier.undoAll(context: context)
                },
                onShowDetails: {
                    showAutoProgressionDetails = true
                }
            )
        }
    }

    // MARK: - Detail-Cards (timeframe-gefiltert)

    @ViewBuilder
    private var detailCards: some View {
        if !viewModel.ratingInsights.isEmpty {
            SummaryRatingInsightCard(insights: viewModel.ratingInsights)
        }
        if viewModel.totalWorkouts > 0 {
            StreakCard(
                currentStreak: viewModel.currentStreak,
                workoutsThisWeek: viewModel.workoutsThisWeek,
                averagePerWeek: viewModel.averageWorkoutsPerWeek,
                streakMilestone: viewModel.currentStreakMilestone,
                nextMilestone: viewModel.nextStreakMilestone
            )
            SummaryXPCard(
                xpLevel: viewModel.xpLevel,
                recentGains: viewModel.recentXPGains
            )
        }
        if !viewModel.filteredWorkoutTypeDistribution.isEmpty {
            TypeBreakdownCard(distribution: viewModel.filteredWorkoutTypeDistribution)
        }
        if viewModel.filteredWorkoutTypeDistribution.count > 1 {
            StatisticDonutChart(
                title: "Workouts nach Typ",
                data: viewModel.filteredWorkoutTypeChartData
            )
        }
        if viewModel.totalWorkouts > 0 {
            SummaryRecordsCard(
                highestCaloriesBurn: viewModel.highestCaloriesBurn,
                longestWorkout: viewModel.longestWorkout,
                longestStreak: viewModel.longestStreak
            )
        }
    }

    // MARK: - Kalender-Sektion

    private var calendarSection: some View {
        VStack(spacing: 8) {
            SummaryWeekStrip(
                days: viewModel.currentWeekStrip,
                showCalendar: $showCalendar
            )
            if showCalendar {
                SummaryActivityCalendar(
                    monthGrid: calendarGrid,
                    displayedMonth: $displayedMonth,
                    stats: calendarStats
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Heatmap-Sektion

    @ViewBuilder
    private var heatmapSection: some View {
        if let heatmap = viewModel.filteredHeatmapAnalysis {
            SummaryMuscleHeatmapCard(analysis: heatmap)
        }
    }

    // MARK: - Neuberechnung

    private func recalculateAll() {
        viewModel.recalculate(
            cardio: cardioSessions,
            strength: strengthSessions,
            outdoor: outdoorSessions,
            timeframe: selectedTimeframe,
            weeklyGoalTarget: appSettings.weeklyWorkoutGoal,
            progressionStates: progressionStates
        )
    }

    // MARK: - Kalender-Daten

    private func refreshCalendarData() {
        let result = viewModel.calendarData(
            for: displayedMonth,
            cardio: cardioSessions,
            strength: strengthSessions,
            outdoor: outdoorSessions
        )
        calendarGrid = result.grid
        calendarStats = result.stats
    }
}

// MARK: - Preview

#Preview("Summary") {
    SummaryView(onStartWorkoutTap: {})
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
}
