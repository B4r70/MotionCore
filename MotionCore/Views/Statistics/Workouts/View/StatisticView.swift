//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StatisticView.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 11.11.2025                                                       /
// Beschreibung  : Hauptdisplay für den Bereich Statistik (alle Workout-Typen)     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct StatisticView: View {

    // MARK: - Queries (alle drei Session-Typen)

    @Query(sort: \CardioSession.date, order: .reverse)
    private var cardioSessions: [CardioSession]

    @Query(sort: \StrengthSession.date, order: .reverse)
    private var strengthSessions: [StrengthSession]

    @Query(sort: \OutdoorSession.date, order: .reverse)
    private var outdoorSessions: [OutdoorSession]

    // MARK: - State

    @State private var selectedTimeframe: SummaryTimeframe = .month
    @State private var healthSectionExpanded: Bool = false
    @State private var viewModel = StatisticsViewModel()

    // MARK: - Environment

    @EnvironmentObject private var appSettings: AppSettings
    @ObservedObject private var healthKitManager = HealthKitManager.shared

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

                    // Zeitraum-Picker
                    TimeframePicker(selection: $selectedTimeframe)

                    // KPI-Grid (9 Cards, 2 Spalten)
                    kpiGrid

                    // Kraft-spezifische Charts
                    if !viewModel.allStrengthSessions.isEmpty {
                        strengthCharts
                    }

                    // Typübergreifende Trend-Charts
                    if !viewModel.allCardioSessions.isEmpty {
                        typeCrossCharts
                    }

                    // Cardio & Outdoor-Section
                    if !viewModel.allCardioSessions.isEmpty {
                        cardioSection
                    }

                    // Gesundheits-Section (HealthKit)
                    healthSection
                }
                .scrollViewContentPadding()
            }
            .scrollIndicators(.hidden)

            if viewModel.allSessionsEmpty {
                EmptyState()
            }
        }
        .task {
            viewModel.recalculate(
                cardio: cardioSessions,
                strength: strengthSessions,
                outdoor: outdoorSessions,
                timeframe: selectedTimeframe
            )
        }
        .onChange(of: cardioSessions) { _, new in
            viewModel.recalculate(
                cardio: new,
                strength: strengthSessions,
                outdoor: outdoorSessions,
                timeframe: selectedTimeframe
            )
        }
        .onChange(of: strengthSessions) { _, new in
            viewModel.recalculate(
                cardio: cardioSessions,
                strength: new,
                outdoor: outdoorSessions,
                timeframe: selectedTimeframe
            )
        }
        .onChange(of: outdoorSessions) { _, new in
            viewModel.recalculate(
                cardio: cardioSessions,
                strength: strengthSessions,
                outdoor: new,
                timeframe: selectedTimeframe
            )
        }
        .onChange(of: selectedTimeframe) { _, new in
            viewModel.recalculate(
                cardio: cardioSessions,
                strength: strengthSessions,
                outdoor: outdoorSessions,
                timeframe: new
            )
        }
    }

    // MARK: - KPI-Grid

    @ViewBuilder
    private var kpiGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 20) {

            // 1. Gesamt Workouts (alle Typen)
            StatisticGridCard(
                icon: .system("figure.run"),
                title: "Gesamt Workouts",
                valueView: Text("\(viewModel.totalWorkoutsAll)"),
                color: .blue
            )

            // 2. Gesamt Kalorien (alle Typen)
            StatisticGridCard(
                icon: .system("flame.fill"),
                title: "Gesamt Kalorien",
                valueView: Text("\(viewModel.totalCaloriesAll)"),
                color: .orange
            )

            // 3. Gesamt Volumen (Kraft)
            StatisticGridCard(
                icon: .system("scalemass.fill"),
                title: "Gesamt Volumen",
                valueView: Text(formattedVolume(viewModel.totalStrengthVolume)),
                color: .purple
            )

            // 4. Ø Herzfrequenz (alle Typen)
            StatisticGridCard(
                icon: .system("heart.fill"),
                title: "⌀ Herzfrequenz",
                valueView: Text("\(viewModel.averageHeartRateAll) bpm"),
                color: .red
            )

            // 5. Gesamt Sets (Kraft)
            StatisticGridCard(
                icon: .system("list.number"),
                title: "Gesamt Sets",
                valueView: Text("\(viewModel.totalStrengthSets)"),
                color: .teal
            )

            // 6. Ø Volumen/Session (Kraft)
            StatisticGridCard(
                icon: .system("chart.bar.fill"),
                title: "⌀ Volumen/Session",
                valueView: Text(formattedVolume(viewModel.averageStrengthVolumePerSession)),
                color: .indigo
            )

            // 7. Ø Dauer (alle Typen)
            StatisticGridCard(
                icon: .system("clock.fill"),
                title: "⌀ Dauer",
                valueView: Text("\(viewModel.averageDurationAll) min"),
                color: .cyan
            )

            // 8. Ø METs (Cardio-spezifisch)
            StatisticGridCard(
                icon: .system("bolt.fill"),
                title: "⌀ METs",
                valueView: Text(String(format: "%.1f", viewModel.averageMETS)),
                color: .yellow
            )

            // 9. Gesamt Strecke (Cardio + Outdoor)
            StatisticGridCard(
                icon: .system("arrow.left.and.right"),
                title: "Gesamt Strecke",
                valueView: Text(String(format: "%.2f km", viewModel.totalDistanceAll)),
                color: .green
            )
        }
    }

    // MARK: - Kraft-Charts

    @ViewBuilder
    private var strengthCharts: some View {
        VStack(spacing: 20) {
            // Volumen-Trend
            StrengthVolumeChart(data: viewModel.strengthVolumeTrend)

            // 1RM-Progression (interaktiv — Engine wird direkt übergeben)
            if !viewModel.strengthChartCalc.allTrainedExerciseNames.isEmpty {
                StrengthOneRMChart(
                    exerciseNames: viewModel.strengthChartCalc.allTrainedExerciseNames,
                    calcEngine: viewModel.strengthChartCalc
                )
            }
        }
    }

    // MARK: - Typübergreifende Trend-Charts

    @ViewBuilder
    private var typeCrossCharts: some View {
        VStack(spacing: 20) {
            StatisticTrendChart(
                title: "Herzfrequenz-Trend",
                yLabel: "Puls",
                data: viewModel.trendHeartRate
            )
            StatisticTrendChart(
                title: "Kalorien-Trend",
                yLabel: "kcal",
                data: viewModel.trendCalories
            )
        }
    }

    // MARK: - Cardio & Outdoor-Section

    @ViewBuilder
    private var cardioSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cardio & Outdoor")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Ø Belastungsintensität
            StatisticCard(
                icon: .system("figure.strengthtraining.traditional"),
                title: "⌀ Belastung",
                valueView: ShowStarRating(
                    starRating: viewModel.averageIntensity,
                    starMaxRating: Intensity.maxRating,
                    starColor: .orange
                ),
                color: .cyan
            )

            // Ø Kaloriendichte
            StatisticCard(
                icon: .system("flame.fill"),
                title: "⌀ Kaloriendichte",
                valueView: Text(String(format: "%.3f", viewModel.averageCaloricDensity)),
                color: .purple
            )

            // Geräte-Verteilung
            StatisticDeviceCard(allWorkouts: viewModel.allCardioSessions)

            // Intensitäts-Verteilung
            StatisticIntensityCard(allWorkouts: viewModel.allCardioSessions)
        }
    }

    // MARK: - Gesundheits-Section

    @ViewBuilder
    private var healthSection: some View {
        let hasSleep = healthKitManager.todaySleepSummary != nil
        let hasCalories = healthKitManager.activeBurnedCalories != nil

        if hasSleep || hasCalories {
            VStack(alignment: .leading, spacing: 16) {
                DisclosureGroup(
                    isExpanded: $healthSectionExpanded,
                    content: {
                        VStack(spacing: 16) {
                            // Aktive Kalorien aus HealthKit
                            if let activeCalories = healthKitManager.activeBurnedCalories {
                                StatisticCard(
                                    icon: .system("figure.run.circle.fill"),
                                    title: "Aktive Kalorien (heute)",
                                    valueView: Text("\(activeCalories) kcal"),
                                    color: .orange
                                )
                            }

                            // Schlafanalyse
                            if let sleepSummary = healthKitManager.todaySleepSummary {
                                HealthMetricSleepHeroCard(sleepSummary: sleepSummary)
                            }
                        }
                        .padding(.top, 12)
                    },
                    label: {
                        Text("Gesundheit")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    }
                )
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Hilfsmethoden

    private func formattedVolume(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1f t", value / 1000.0)
        } else {
            return String(format: "%.0f kg", value)
        }
    }
}

// MARK: - Preview

#Preview("Statistiken") {
    StatisticView()
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
}
