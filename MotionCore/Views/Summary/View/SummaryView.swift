//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : SummaryView.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 07.01.2026                                                       /
// Beschreibung  : Kombinierte Übersicht aller Workout-Typen                        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Diese View zeigt aggregierte Statistiken über CardioSession,      /
//                StrengthSession und OutdoorSession. Nutzt CoreSession-Protokoll.  /
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
                    TimeframePicker(selection: $selectedTimeframe)

                    if viewModel.totalWorkouts > 0 {
                        StreakCard(
                            currentStreak: viewModel.currentStreak,
                            workoutsThisWeek: viewModel.workoutsThisWeek,
                            averagePerWeek: viewModel.averageWorkoutsPerWeek
                        )
                    }

                    LazyVGrid(columns: gridColumns, spacing: 20) {
                        StatisticGridCard(
                            icon: .system("figure.mixed.cardio"),
                            title: "Workouts",
                            valueView: Text("\(viewModel.filteredTotalWorkouts)"),
                            color: .blue
                        )

                        StatisticGridCard(
                            icon: .system("flame.fill"),
                            title: "Kalorien",
                            valueView: Text("\(viewModel.filteredTotalCalories)"),
                            color: .orange
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
                            valueView: Text("\(viewModel.filteredAverageHeartRate)"),
                            color: .red
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

                    if !strengthSessions.isEmpty {
                        ProgressionSummaryCard(analyses: viewModel.progressionAnalyses)
                    }
                }
                .scrollViewContentPadding()
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
                timeframe: selectedTimeframe
            )
        }
        .onChange(of: cardioSessions) { _, new in
            viewModel.recalculate(
                cardio: new,
                strength: strengthSessions,
                outdoor: outdoorSessions,
                exercises: exercises,
                timeframe: selectedTimeframe
            )
        }
        .onChange(of: strengthSessions) { _, new in
            viewModel.recalculate(
                cardio: cardioSessions,
                strength: new,
                outdoor: outdoorSessions,
                exercises: exercises,
                timeframe: selectedTimeframe
            )
        }
        .onChange(of: outdoorSessions) { _, new in
            viewModel.recalculate(
                cardio: cardioSessions,
                strength: strengthSessions,
                outdoor: new,
                exercises: exercises,
                timeframe: selectedTimeframe
            )
        }
        .onChange(of: exercises) { _, new in
            viewModel.recalculate(
                cardio: cardioSessions,
                strength: strengthSessions,
                outdoor: outdoorSessions,
                exercises: new,
                timeframe: selectedTimeframe
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
    }
}

// MARK: - Preview

#Preview("Summary") {
    SummaryView()
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
}
