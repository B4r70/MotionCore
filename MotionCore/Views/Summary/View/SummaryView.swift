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

    // MARK: - Environment

    @EnvironmentObject private var appSettings: AppSettings

    // MARK: - State

    @State private var selectedTimeframe: SummaryTimeframe = .week

    // MARK: - Computed Properties

    private var summaryCalc: SummaryCalcEngine {
        SummaryCalcEngine(
            cardio: cardioSessions,
            strength: strengthSessions,
            outdoor: outdoorSessions
        )
    }

    private var filteredCalc: SummaryCalcEngine {
        switch selectedTimeframe {
        case .week: return summaryCalc.thisWeek
        case .month: return summaryCalc.thisMonth
        case .year: return summaryCalc.thisYear
        case .all: return summaryCalc
        }
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
                    TimeframePicker(selection: $selectedTimeframe)

                    if summaryCalc.totalWorkouts > 0 {
                        StreakCard(
                            currentStreak: summaryCalc.currentStreak,
                            workoutsThisWeek: summaryCalc.workoutsThisWeek,
                            averagePerWeek: summaryCalc.averageWorkoutsPerWeek
                        )
                    }

                    LazyVGrid(columns: gridColumns, spacing: 20) {
                        StatisticGridCard(
                            icon: .system("figure.mixed.cardio"),
                            title: "Workouts",
                            valueView: Text("\(filteredCalc.totalWorkouts)"),
                            color: .blue
                        )

                        StatisticGridCard(
                            icon: .system("flame.fill"),
                            title: "Kalorien",
                            valueView: Text("\(filteredCalc.totalCalories)"),
                            color: .orange
                        )

                        StatisticGridCard(
                            icon: .system("clock.fill"),
                            title: "Trainingszeit",
                            valueView: Text(filteredCalc.formattedTotalDuration),
                            color: .purple
                        )

                        StatisticGridCard(
                            icon: .system("heart.fill"),
                            title: "⌀ Herzfrequenz",
                            valueView: Text("\(filteredCalc.averageHeartRate)"),
                            color: .red
                        )
                    }

                    if !filteredCalc.workoutTypeDistribution.isEmpty {
                        TypeBreakdownCard(distribution: filteredCalc.workoutTypeDistribution)
                    }

                    if filteredCalc.workoutTypeDistribution.count > 1 {
                        StatisticDonutChart(
                            title: "Workouts nach Typ",
                            data: filteredCalc.workoutTypeChartData
                        )
                    }

                    if summaryCalc.totalWorkouts > 0 {
                        RecordsCard(
                            highestCaloriesBurn: summaryCalc.highestCaloriesBurn,
                            longestWorkout: summaryCalc.longestWorkout,
                            longestStreak: summaryCalc.longestStreak
                        )
                    }
                }
                .scrollViewContentPadding()
            }
            .scrollIndicators(.hidden)

            if summaryCalc.totalWorkouts == 0 {
                EmptyState()
            }
        }
    }
}

// MARK: - Preview

#Preview("Summary") {
    SummaryView()
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
}
