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

    @Query(sort: \Exercise.name)
    private var exercises: [Exercise]

    // MARK: - Environment

    @EnvironmentObject private var appSettings: AppSettings

    // MARK: - State

    @State private var selectedTimeframe: SummaryTimeframe = .week
    @State private var viewModel = SummaryViewModel()
    @State private var showCalendar: Bool = false
    @State private var displayedMonth: Date = Date()
    @State private var calendarGrid: [[ActivityDay?]] = []
    @State private var calendarStats: (trainingDays: Int, averagePerWeek: Double) = (0, 0.0)

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

                    // 7. Übung der Woche
                    if let bestExercise = viewModel.bestExerciseAnalysis {
                        SummaryBestExerciseCard(
                            analysis: bestExercise,
                            trendPoints: viewModel.bestExerciseTrendPoints
                        )
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

                    // 12. Progressions-Empfehlungen
                    if !strengthSessions.isEmpty {
                        ProgressionSummaryCard(analyses: viewModel.progressionAnalyses)
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
                exercises: exercises,
                timeframe: selectedTimeframe,
                weeklyGoalTarget: appSettings.weeklyWorkoutGoal
            )
            refreshCalendarData()
        }
        .onChange(of: cardioSessions) { _, new in
            viewModel.recalculate(
                cardio: new,
                strength: strengthSessions,
                outdoor: outdoorSessions,
                exercises: exercises,
                timeframe: selectedTimeframe,
                weeklyGoalTarget: appSettings.weeklyWorkoutGoal
            )
        }
        .onChange(of: strengthSessions) { _, new in
            viewModel.recalculate(
                cardio: cardioSessions,
                strength: new,
                outdoor: outdoorSessions,
                exercises: exercises,
                timeframe: selectedTimeframe,
                weeklyGoalTarget: appSettings.weeklyWorkoutGoal
            )
        }
        .onChange(of: outdoorSessions) { _, new in
            viewModel.recalculate(
                cardio: cardioSessions,
                strength: strengthSessions,
                outdoor: new,
                exercises: exercises,
                timeframe: selectedTimeframe,
                weeklyGoalTarget: appSettings.weeklyWorkoutGoal
            )
        }
        .onChange(of: exercises) { _, new in
            viewModel.recalculate(
                cardio: cardioSessions,
                strength: strengthSessions,
                outdoor: outdoorSessions,
                exercises: new,
                timeframe: selectedTimeframe,
                weeklyGoalTarget: appSettings.weeklyWorkoutGoal
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
                exercises: exercises,
                timeframe: selectedTimeframe,
                weeklyGoalTarget: appSettings.weeklyWorkoutGoal
            )
        }
        .onChange(of: displayedMonth) { _, _ in
            refreshCalendarData()
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
