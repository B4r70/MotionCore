//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : SummaryBestExerciseCard.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-02                                                       /
// Beschreibung  : Zeigt die Übung der Woche mit Progressions-Info und Sparkline    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Summary Best Exercise Card

/// Zeigt nur wenn Progressionsdaten vorhanden (mind. 3 Snapshots).
struct SummaryBestExerciseCard: View {

    let analysis: ProgressionAnalysis
    let trendPoints: [TrendPoint]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Überschrift
            HStack {
                Text("Übung der Woche")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                // Trend-Icon
                trendBadge
            }

            // Übungsname + Gewicht
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(analysis.exerciseName)
                        .font(.headline)
                        .lineLimit(1)

                    // Aktuelles Gewicht
                    if analysis.currentWeight > 0 {
                        Text(String(format: "%.1f kg", analysis.currentWeight))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Zusammenfassung
                    Text(analysis.summaryText)
                        .font(.caption)
                        .foregroundStyle(summaryTextColor)
                        .lineLimit(2)
                }

                Spacer()

                // Sparkline (nur wenn genug Daten)
                if trendPoints.count >= 3 {
                    MiniSparkline(data: trendPoints, color: sparklineColor)
                        .frame(width: 70, height: 36)
                }
            }
        }
        .padding()
        .glassCard()
    }

    // MARK: - Trend-Badge

    private var trendBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: analysis.trend.icon)
                .font(.caption)
            Text(analysis.trend.displayName)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(trendBackground)
        .clipShape(Capsule())
    }

    // MARK: - Farben

    private var sparklineColor: Color {
        switch analysis.trend {
        case .improving: return Color.green
        case .stable:    return .blue
        case .declining: return Color.orange
        default:         return .secondary
        }
    }

    private var summaryTextColor: Color {
        analysis.hasRecommendation ? .blue : .secondary
    }

    private var trendBackground: Color {
        switch analysis.trend {
        case .improving: return Color.green.opacity(0.15)
        case .stable:    return Color.blue.opacity(0.15)
        default:         return Color.secondary.opacity(0.1)
        }
    }
}

// MARK: - Preview

#Preview("SummaryBestExerciseCard") {
    let mockAnalysis = ProgressionAnalysis(
        exerciseName: "Kniebeuge",
        exerciseUUID: nil,
        analysisDate: Date(),
        currentWeight: 100.0,
        currentRepsRange: 6...8,
        targetRepsRange: 6...10,
        trainingLevel: .intermediate,
        trend: .improving,
        confidence: 0.75,
        confidenceLevel: .high,
        recommendedAction: .increaseWeight(kg: 2.5),
        suggestedWeight: 102.5,
        reasoningPoints: ["6 Sessions analysiert"],
        sessionsAnalyzed: 6,
        daysSinceLastSession: 2,
        estimatedOneRepMax: 130.0,
        oneRepMaxTrend: .improving,
        repsProgress: 0.8,
        isReadyForWeightIncrease: true
    )

    let mockTrendPoints: [TrendPoint] = [
        TrendPoint(trendDate: Date().addingTimeInterval(-20 * 86400), trendValue: 90),
        TrendPoint(trendDate: Date().addingTimeInterval(-15 * 86400), trendValue: 92.5),
        TrendPoint(trendDate: Date().addingTimeInterval(-10 * 86400), trendValue: 95),
        TrendPoint(trendDate: Date().addingTimeInterval(-5 * 86400), trendValue: 97.5),
        TrendPoint(trendDate: Date(), trendValue: 100)
    ]

    SummaryBestExerciseCard(analysis: mockAnalysis, trendPoints: mockTrendPoints)
        .padding()
        .environmentObject(AppSettings.shared)
}
