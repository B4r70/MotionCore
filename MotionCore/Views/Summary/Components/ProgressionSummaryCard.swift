//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : ProgressionSummaryCard.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-16                                                       /
// Beschreibung  : Dashboard-Karte mit Progressions-Empfehlungen                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Progressions-Zusammenfassungs-Karte

struct ProgressionSummaryCard: View {
    let analyses: [ProgressionAnalysis]

    private var ready: [ProgressionAnalysis] {
        analyses
            .filter { $0.hasRecommendation && $0.confidenceLevel != .low }
            .sorted { $0.confidence > $1.confidence }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: Header
            HStack(spacing: 10) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(Color.green)
                Text("Progressions-Empfehlungen")
                    .font(.headline)
                Spacer()
                if !ready.isEmpty {
                    Text("\(ready.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.gradient)
                        .clipShape(Capsule())
                }
            }

            GlassDivider.tight

            // MARK: Inhalt
            if ready.isEmpty {
                emptyState
            } else {
                progressionList
            }
        }
        .glassCard()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.secondary)
            Text("Aktuell keine Übungen bereit für Progression")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    // MARK: - Liste

    private var progressionList: some View {
        VStack(spacing: 0) {
            ForEach(Array(ready.prefix(3).enumerated()), id: \.offset) { index, analysis in
                ProgressionSummaryRow(analysis: analysis)

                if index < min(ready.count, 3) - 1 {
                    GlassDivider.compact
                }
            }

            if ready.count > 3 {
                GlassDivider.tight

                HStack {
                    Spacer()
                    Text("+ \(ready.count - 3) weitere")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Progressions-Zeile

private struct ProgressionSummaryRow: View {
    let analysis: ProgressionAnalysis

    var actionColor: Color {
        switch analysis.recommendedAction {
        case .increaseWeight: return Color.green
        case .increaseReps:   return .blue
        default:              return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Aktion-Icon
            Image(systemName: analysis.recommendedAction.icon)
                .font(.title3)
                .foregroundStyle(actionColor)
                .frame(width: 32)

            // Übungsname + Empfehlung
            VStack(alignment: .leading, spacing: 2) {
                Text(analysis.exerciseName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(analysis.summaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Gewicht
            if analysis.currentWeight > 0 {
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(analysis.currentWeight.formatted()) kg")
                        .font(.caption.monospacedDigit().weight(.medium))
                    Text("aktuell")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Preview

#Preview("Progressions-Empfehlungen") {
    ScrollView {
        VStack(spacing: 20) {
            ProgressionSummaryCard(analyses: [
                ProgressionAnalysis(
                    exerciseName: "Kniebeugen",
                    exerciseUUID: nil,
                    analysisDate: Date(),
                    currentWeight: 100,
                    currentRepsRange: 12...12,
                    targetRepsRange: 8...12,
                    trainingLevel: .advanced,
                    trend: .improving,
                    confidence: 0.88,
                    confidenceLevel: .high,
                    recommendedAction: .increaseWeight(kg: 2.5),
                    suggestedWeight: 102.5,
                    reasoningPoints: [],
                    sessionsAnalyzed: 4,
                    daysSinceLastSession: 5,
                    estimatedOneRepMax: 133.0,
                    oneRepMaxTrend: .improving,
                    repsProgress: 1.0,
                    isReadyForWeightIncrease: true
                ),
                ProgressionAnalysis(
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
                    reasoningPoints: [],
                    sessionsAnalyzed: 3,
                    daysSinceLastSession: 3,
                    estimatedOneRepMax: 98.0,
                    oneRepMaxTrend: .improving,
                    repsProgress: 0.75,
                    isReadyForWeightIncrease: false
                ),
                ProgressionAnalysis(
                    exerciseName: "Kreuzheben",
                    exerciseUUID: nil,
                    analysisDate: Date(),
                    currentWeight: 120,
                    currentRepsRange: 8...10,
                    targetRepsRange: 5...8,
                    trainingLevel: .advanced,
                    trend: .stable,
                    confidence: 0.55,
                    confidenceLevel: .medium,
                    recommendedAction: .increaseWeight(kg: 5.0),
                    suggestedWeight: 125.0,
                    reasoningPoints: [],
                    sessionsAnalyzed: 3,
                    daysSinceLastSession: 7,
                    estimatedOneRepMax: 150.0,
                    oneRepMaxTrend: .stable,
                    repsProgress: 1.0,
                    isReadyForWeightIncrease: true
                )
            ])

            ProgressionSummaryCard(analyses: [])
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .environmentObject(AppSettings.shared)
}
