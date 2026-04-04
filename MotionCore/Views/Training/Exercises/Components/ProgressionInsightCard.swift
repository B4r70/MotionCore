//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Übungsbibliothek                                                 /
// Datei . . . . : ProgressionInsightCard.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-16                                                       /
// Beschreibung  : Detailkarte für Progressions-Analyse einer Übung                 /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ProgressionInsightCard: View {
    let analysis: ProgressionAnalysis

    @State private var detailsExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: Header
            HStack(spacing: 10) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Color.blue)
                Text("Progressions-Analyse")
                    .font(.headline)
                Spacer()
                ConfidenceBadge(level: analysis.confidenceLevel)
            }

            GlassDivider.tight

            // MARK: Haupt-Empfehlung
            RecommendationRow(action: analysis.recommendedAction)
                .padding(.bottom, 12)

            // MARK: Rep-Fortschritt (Double Progression)
            if let progress = analysis.repsProgress,
               analysis.recommendedAction == .increaseReps || analysis.isReadyForWeightIncrease {
                RepProgressBar(
                    progress: progress,
                    currentRange: analysis.currentRepsRange,
                    targetRange: analysis.targetRepsRange
                )
                .padding(.bottom, 12)
            }

            // MARK: Trend
            TrendRow(trend: analysis.trend)
                .padding(.bottom, 12)

            // MARK: Details (aufklappbar)
            GlassDivider.tight

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    detailsExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Details")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: detailsExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if detailsExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(analysis.reasoningPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(point)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassCard()
    }
}

// MARK: - Konfidenz-Badge

private struct ConfidenceBadge: View {
    let level: ProgressionConfidence

    var color: Color {
        switch level {
        case .insufficient: return .gray
        case .low:          return .orange
        case .medium:       return .yellow
        case .high:         return .green
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
                .font(.caption2)
            Text(level.displayName)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Empfehlungs-Zeile

private struct RecommendationRow: View {
    let action: ProgressionAction

    var accentColor: Color {
        switch action {
        case .increaseWeight: return .green
        case .increaseReps:   return .blue
        case .considerDeload: return .orange
        case .maintain:       return .secondary
        case .needMoreData:   return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: action.icon)
                .font(.title3)
                .foregroundStyle(accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("Empfehlung")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(action.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accentColor)
            }

            Spacer()
        }
        .padding(.top, 4)
    }
}

// MARK: - Rep-Fortschrittsbalken

private struct RepProgressBar: View {
    let progress: Double
    let currentRange: ClosedRange<Int>
    let targetRange: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Rep-Fortschritt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(currentRange.lowerBound)–\(currentRange.upperBound) / \(targetRange.upperBound) Wdh.")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * progress), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Trend-Zeile

private struct TrendRow: View {
    let trend: PerformanceTrend

    var color: Color {
        switch trend {
        case .improving:    return .green
        case .stable:       return .blue
        case .declining:    return .orange
        case .volatile:     return .yellow
        case .insufficient: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: trend.icon)
                .foregroundStyle(color)
            Text(trend.displayName)
                .font(.subheadline)
                .foregroundStyle(color)
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Progression Insight — Reps steigern") {
    ScrollView {
        ProgressionInsightCard(
            analysis: ProgressionAnalysis(
                exerciseName: "Bankdrücken",
                exerciseUUID: nil,
                analysisDate: Date(),
                currentWeight: 80,
                currentRepsRange: 11...12,
                targetRepsRange: 8...12,
                trainingLevel: .intermediate,
                trend: .improving,
                confidence: 0.65,
                confidenceLevel: .medium,
                recommendedAction: .increaseReps,
                suggestedWeight: nil,
                reasoningPoints: [
                    "3 Sessions analysiert",
                    "Ø RIR: 2.3 (Ziel: 2)",
                    "Geschätztes 1RM: 98.0 kg",
                    "Trend: Aufwärtstrend",
                    "Trainings-Level: Fortgeschritten"
                ],
                sessionsAnalyzed: 3,
                daysSinceLastSession: 3,
                estimatedOneRepMax: 98.0,
                oneRepMaxTrend: .improving,
                repsProgress: 0.75,
                isReadyForWeightIncrease: false
            )
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .environmentObject(AppSettings.shared)
}

#Preview("Progression Insight — Gewicht erhöhen") {
    ScrollView {
        ProgressionInsightCard(
            analysis: ProgressionAnalysis(
                exerciseName: "Kniebeugen",
                exerciseUUID: nil,
                analysisDate: Date(),
                currentWeight: 100,
                currentRepsRange: 12...12,
                targetRepsRange: 8...12,
                trainingLevel: .advanced,
                trend: .improving,
                confidence: 0.85,
                confidenceLevel: .high,
                recommendedAction: .increaseWeight(kg: 2.5),
                suggestedWeight: 102.5,
                reasoningPoints: [
                    "4 Sessions analysiert",
                    "Ø RIR: 3.1 (Ziel: 2)",
                    "Geschätztes 1RM: 133.0 kg",
                    "Trend: Aufwärtstrend",
                    "2× oberes Rep-Limit erreicht"
                ],
                sessionsAnalyzed: 4,
                daysSinceLastSession: 5,
                estimatedOneRepMax: 133.0,
                oneRepMaxTrend: .improving,
                repsProgress: 1.0,
                isReadyForWeightIncrease: true
            )
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .environmentObject(AppSettings.shared)
}
