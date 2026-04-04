//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Progressions-Analyse                                             /
// Datei . . . . : ProgressionDetailView.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-17                                                       /
// Beschreibung  : Detail-Sheet pro Übung mit Charts und vollständiger Analyse      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ProgressionDetailView: View {
    let analysis: ProgressionAnalysis
    let oneRMData: [TrendPoint]
    let volumeData: [TrendPoint]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // 1RM-Trend (nur wenn genug Datenpunkte vorhanden)
                    if oneRMData.count >= 2 {
                        StatisticTrendChart(
                            title: "1RM-Entwicklung",
                            yLabel: "kg",
                            data: oneRMData
                        )
                    }

                    // Volumen-Trend
                    if volumeData.count >= 2 {
                        StatisticTrendChart(
                            title: "Volumen-Trend",
                            yLabel: "kg",
                            data: volumeData
                        )
                    }

                    // Haupt-Analyse-Card (Empfehlung, Rep-Fortschritt, Trend, Begründung)
                    ProgressionInsightCard(analysis: analysis)

                    // Trainings-Statistiken
                    statsCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(analysis.exerciseName)
                        .font(.headline)
                        .lineLimit(1)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "checkmark").foregroundStyle(Color.blue) }
                }
            }
        }
    }

    // MARK: - Stats-Card

    @ViewBuilder
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trainingsdetails")
                .font(.headline)
                .padding(.horizontal, 4)

            HStack {
                statItem(label: "Sessions", value: "\(analysis.sessionsAnalyzed)")
                Spacer()
                statItem(label: "Zuletzt", value: daysText)
                Spacer()
                statItem(label: "Level", value: analysis.trainingLevel.displayName)
            }
        }
        .glassCard()
    }

    private var daysText: String {
        let days = analysis.daysSinceLastSession
        if days == 0 { return "Heute" }
        if days == 1 { return "Gestern" }
        return "Vor \(days)d"
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
