//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StrengthStatisticView.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-03                                                       /
// Beschreibung  : Hauptansicht für Kraft-Statistiken                               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct StrengthStatisticView: View {

    @Query(sort: \StrengthSession.date, order: .reverse)
    private var allSessions: [StrengthSession]

    @EnvironmentObject private var appSettings: AppSettings

    @State private var selectedTimeframe: SummaryTimeframe = .all

    private let gridColumns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    private var calc: StrengthStatisticCalcEngine {
        StrengthStatisticCalcEngine(sessions: allSessions).filtered(by: selectedTimeframe)
    }

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    TimeframePicker(selection: $selectedTimeframe)

                    LazyVGrid(columns: gridColumns, spacing: 20) {
                        StatisticGridCard(
                            icon: .system("figure.strengthtraining.traditional"),
                            title: "Kraft-Sessions",
                            valueView: Text("\(calc.totalSessions)"),
                            color: .blue
                        )
                        StatisticGridCard(
                            icon: .system("scalemass.fill"),
                            title: "Gesamt Volumen",
                            valueView: Text(formattedVolume(calc.totalVolume)),
                            color: .purple
                        )
                        StatisticGridCard(
                            icon: .system("chart.bar.fill"),
                            title: "⌀ Volumen",
                            valueView: Text(formattedVolume(calc.averageVolumePerSession)),
                            color: .indigo
                        )
                        StatisticGridCard(
                            icon: .system("list.number"),
                            title: "⌀ Sätze",
                            valueView: Text(String(format: "%.1f", calc.averageSetsPerSession)),
                            color: .teal
                        )
                    }

                    StrengthVolumeChart(data: calc.volumeTrend)

                    StrengthOneRMChart(
                        exerciseNames: calc.allTrainedExerciseNames,
                        calcEngine: calc
                    )
                }
                .scrollViewContentPadding()
            }
            .scrollIndicators(.hidden)

            if allSessions.isEmpty {
                EmptyState()
            }
        }
    }

    private func formattedVolume(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1f t", value / 1000)
        } else {
            return String(format: "%.0f kg", value)
        }
    }
}

#Preview("Kraft Statistiken") {
    StrengthStatisticView()
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
}
