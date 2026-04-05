//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Progressions-Analyse                                             /
// Datei . . . . : ExerciseProgressionView.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-18                                                       /
// Beschreibung  : Detailansicht für die Progressions-Analyse einer einzelnen       /
//                 Übung — Vergleich letztes Workout + Insight-Card + Charts        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ExerciseProgressionView: View {

    // MARK: - Input

    let analysis: ProgressionAnalysis
    let lastSnapshot: SessionSnapshot?
    let oneRMData: [TrendPoint]
    let volumeData: [TrendPoint]

    // Aktueller Stand aus dem gerade betrachteten Workout
    let currentWeight: Double
    let currentReps: Int
    let currentVolume: Double

    // MARK: - Environment

    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

                ScrollView {
                    VStack(spacing: 16) {

                        // Vergleich mit letztem Workout
                        LastWorkoutCompareCard(
                            currentWeight: currentWeight,
                            currentReps: currentReps,
                            currentVolume: currentVolume,
                            lastSnapshot: lastSnapshot,
                            oneRMData: oneRMData
                        )

                        // Vollständige Progressions-Analyse
                        ProgressionInsightCard(analysis: analysis)

                        // Volumen-Verlauf (wenn genug Daten vorhanden)
                        if volumeData.count >= 3 {
                            volumeSparklineCard
                        }

                        // Trainingsdetails
                        statsCard
                    }
                    .scrollViewContentPadding()
                }
                .scrollIndicators(.hidden)
            }
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

    // MARK: - Volumen-Sparkline Card

    private var volumeSparklineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Color.green)
                Text("Volumen-Verlauf")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 4)

            MiniSparkline(data: volumeData, color: Color.green, lineWidth: 2.5)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .padding(.horizontal, 4)
        }
        .glassCard()
    }

    // MARK: - Stats-Card

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

// MARK: - Preview

#Preview("ExerciseProgressionView") {
    let mockSnapshot = SessionSnapshot(
        date: Date().addingTimeInterval(-7 * 86400),
        weight: 80,
        reps: [8, 8, 7],
        rpeValues: [8, 9, 9],
        totalVolume: 1880,
        estimatedOneRM: 100
    )

    let mockOneRM: [TrendPoint] = [
        TrendPoint(trendDate: Date().addingTimeInterval(-21 * 86400), trendValue: 95),
        TrendPoint(trendDate: Date().addingTimeInterval(-14 * 86400), trendValue: 97),
        TrendPoint(trendDate: Date().addingTimeInterval(-7 * 86400), trendValue: 100),
        TrendPoint(trendDate: Date().addingTimeInterval(-0 * 86400), trendValue: 103)
    ]

    let mockVolume: [TrendPoint] = [
        TrendPoint(trendDate: Date().addingTimeInterval(-21 * 86400), trendValue: 1760),
        TrendPoint(trendDate: Date().addingTimeInterval(-14 * 86400), trendValue: 1840),
        TrendPoint(trendDate: Date().addingTimeInterval(-7 * 86400), trendValue: 1880),
        TrendPoint(trendDate: Date().addingTimeInterval(-0 * 86400), trendValue: 2062)
    ]

    let mockAnalysis = ProgressionAnalysis(
        exerciseName: "Bankdrücken",
        exerciseUUID: nil,
        analysisDate: Date(),
        currentWeight: 82.5,
        currentRepsRange: 9...10,
        targetRepsRange: 8...12,
        trainingLevel: .intermediate,
        trend: .improving,
        confidence: 0.72,
        confidenceLevel: .medium,
        recommendedAction: .increaseReps,
        suggestedWeight: nil,
        reasoningPoints: [
            "4 Sessions analysiert",
            "Ø RIR: 2.1 (Ziel: 2)",
            "Trend: Aufwärtstrend"
        ],
        sessionsAnalyzed: 4,
        daysSinceLastSession: 7,
        estimatedOneRepMax: 103,
        oneRepMaxTrend: .improving,
        repsProgress: 0.25,
        isReadyForWeightIncrease: false
    )

    ExerciseProgressionView(
        analysis: mockAnalysis,
        lastSnapshot: mockSnapshot,
        oneRMData: mockOneRM,
        volumeData: mockVolume,
        currentWeight: 82.5,
        currentReps: 9,
        currentVolume: 2062.5
    )
    .environmentObject(AppSettings.shared)
}
