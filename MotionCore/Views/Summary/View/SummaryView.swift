//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : SummaryView.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 07.01.2026                                                       /
// Beschreibung  : Gamifiziertes Trainings-Dashboard (Redesign 2026-04)             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct SummaryView: View {

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

    // Readiness der letzten Strength-Session (Soft-Link über sessionUUID)
    private var latestSessionReadiness: SessionReadiness? {
        guard let lastSession = strengthSessions.first else { return nil }
        let uuid = lastSession.sessionUUID.uuidString
        return allReadiness.first { $0.sessionUUID == uuid }
    }

    private let gridColumns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {

                    // 1. Hero Card
                    SummaryHeroCard(
                        motivationalContext: viewModel.motivationalContext,
                        xpLevel: viewModel.xpLevel
                    )

                    // 1b. Readiness-Card der letzten Session
                    if let readiness = latestSessionReadiness {
                        ReadinessSummaryCard(readiness: readiness)
                    }

                    // 2. 7-Tage-Strip + expandierbarer Kalender
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

                    // 3. Wochenziel-Ring + Trend-Stats (untereinander)
                    SummaryWeeklyGoalRing(goal: viewModel.weeklyGoal)

                    SummaryTrendCard(
                        volumeTrend: viewModel.volumeTrend,
                        caloriesTrend: viewModel.caloriesTrend,
                        durationTrend: viewModel.durationTrend
                    )

                    // 3b. Rollback-Insight-Karte (nur bei aktiven Vorschlägen)
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

                    // 3c. Auto-Progression-Karte (nur nach Auto-Progress, bis Undo oder neue Session)
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

                    // 4. TimeframePicker
                    TimeframePicker(selection: $selectedTimeframe)

                    // 5. Stat-Grid 2×2 (timeframe-gefiltert)
                    LazyVGrid(columns: gridColumns, spacing: 20) {
                        StatisticGridCard(
                            icon: .system("figure.mixed.cardio"),
                            title: "Workouts",
                            valueView: CountUpText(targetValue: viewModel.filteredTotalWorkouts),
                            color: .blue
                        )

                        StatisticGridCard(
                            icon: .system("flame.fill"),
                            title: "Kalorien",
                            valueView: CountUpText(
                                targetValue: viewModel.filteredTotalCalories,
                                suffix: " kcal"
                            ),
                            color: Color.orange
                        )

                        StatisticGridCard(
                            icon: .system("clock.fill"),
                            title: "Trainingszeit",
                            valueView: Text(viewModel.filteredFormattedDuration),
                            color: .purple
                        )

                        StatisticGridCard(
                            icon: .system("heart.fill"),
                            title: "⌀ Herzfrequenz",
                            valueView: CountUpText(
                                targetValue: viewModel.filteredAverageHeartRate,
                                suffix: " bpm"
                            ),
                            color: Color.red
                        )
                    }

                    // 6. Muskel-Heatmap (nur bei Kraft-Sessions)
                    if let heatmap = viewModel.filteredHeatmapAnalysis {
                        SummaryMuscleHeatmapCard(analysis: heatmap)
                    }

                    // 7. Rating-Insights (auffällige Bewertungsmuster)
                    if !viewModel.ratingInsights.isEmpty {
                        SummaryRatingInsightCard(insights: viewModel.ratingInsights)
                    }

                    // 8. Streak-Card
                    if viewModel.totalWorkouts > 0 {
                        StreakCard(
                            currentStreak: viewModel.currentStreak,
                            workoutsThisWeek: viewModel.workoutsThisWeek,
                            averagePerWeek: viewModel.averageWorkoutsPerWeek,
                            streakMilestone: viewModel.currentStreakMilestone,
                            nextMilestone: viewModel.nextStreakMilestone
                        )
                    }

                    // 9. XP & Rang Card
                    if viewModel.totalWorkouts > 0 {
                        SummaryXPCard(
                            xpLevel: viewModel.xpLevel,
                            recentGains: viewModel.recentXPGains
                        )
                    }

                    // 10. Typ-Aufschlüsselung
                    if !viewModel.filteredWorkoutTypeDistribution.isEmpty {
                        TypeBreakdownCard(distribution: viewModel.filteredWorkoutTypeDistribution)
                    }

                    if viewModel.filteredWorkoutTypeDistribution.count > 1 {
                        StatisticDonutChart(
                            title: "Workouts nach Typ",
                            data: viewModel.filteredWorkoutTypeChartData
                        )
                    }

                    // 11. Rekorde
                    if viewModel.totalWorkouts > 0 {
                        SummaryRecordsCard(
                            highestCaloriesBurn: viewModel.highestCaloriesBurn,
                            longestWorkout: viewModel.longestWorkout,
                            longestStreak: viewModel.longestStreak
                        )
                    }

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
            viewModel.recalculate(
                cardio: cardioSessions,
                strength: strengthSessions,
                outdoor: outdoorSessions,
                timeframe: selectedTimeframe,
                weeklyGoalTarget: appSettings.weeklyWorkoutGoal,
                progressionStates: progressionStates
            )
            refreshCalendarData()
        }
        .onChange(of: cardioSessions) { _, new in
            viewModel.recalculate(
                cardio: new,
                strength: strengthSessions,
                outdoor: outdoorSessions,
                timeframe: selectedTimeframe,
                weeklyGoalTarget: appSettings.weeklyWorkoutGoal,
                progressionStates: progressionStates
            )
        }
        .onChange(of: strengthSessions) { _, new in
            viewModel.recalculate(
                cardio: cardioSessions,
                strength: new,
                outdoor: outdoorSessions,
                timeframe: selectedTimeframe,
                weeklyGoalTarget: appSettings.weeklyWorkoutGoal,
                progressionStates: progressionStates
            )
        }
        .onChange(of: outdoorSessions) { _, new in
            viewModel.recalculate(
                cardio: cardioSessions,
                strength: strengthSessions,
                outdoor: new,
                timeframe: selectedTimeframe,
                weeklyGoalTarget: appSettings.weeklyWorkoutGoal,
                progressionStates: progressionStates
            )
        }
        .onChange(of: progressionStates) { _, _ in
            viewModel.recalculate(
                cardio: cardioSessions,
                strength: strengthSessions,
                outdoor: outdoorSessions,
                timeframe: selectedTimeframe,
                weeklyGoalTarget: appSettings.weeklyWorkoutGoal,
                progressionStates: progressionStates
            )
        }
        .onChange(of: selectedTimeframe) { _, new in
            // Nur gefilterte Werte neu berechnen — günstiger als volle Neuberechnung
            viewModel.recalculateFiltered(
                cardio: cardioSessions,
                strength: strengthSessions,
                outdoor: outdoorSessions,
                timeframe: new
            )
        }
        .onChange(of: appSettings.weeklyWorkoutGoal) { _, _ in
            viewModel.recalculate(
                cardio: cardioSessions,
                strength: strengthSessions,
                outdoor: outdoorSessions,
                timeframe: selectedTimeframe,
                weeklyGoalTarget: appSettings.weeklyWorkoutGoal,
                progressionStates: progressionStates
            )
        }
        .onChange(of: displayedMonth) { _, _ in
            refreshCalendarData()
        }
        .sheet(isPresented: $showAutoProgressionDetails) {
            AutoProgressionDetailsView(
                suggestions: viewModel.autoProgressionSuggestions,
                onUndoOne: { state in
                    AutoProgressionApplier.undo(state: state, context: context)
                }
            )
        }
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
    SummaryView()
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
}
