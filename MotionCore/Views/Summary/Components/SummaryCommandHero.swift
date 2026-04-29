//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Summary / Components                                     /
// Datei . . . . : SummaryCommandHero.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Hero-Card mit Tagesform, Erholung, Streak und Trainings-Empfehlung/
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/

import SwiftUI

// MARK: - SummaryCommandHero

struct SummaryCommandHero: View {

    // MARK: Properties

    let readinessScore: Int?
    let readinessLabel: ReadinessLabel?
    let readinessIsCalibrating: Bool
    let recoveryPercent: Int
    let currentStreak: Int
    let nextStreakMilestone: StreakMilestone?
    let recommendation: RecoveryRecommendation
    let onStartWorkoutTap: () -> Void

    // MARK: Body

    var body: some View {
        VStack(spacing: 10) {
            metricRow
            if !recommendation.recommendedGroups.isEmpty {
                todayTrainingBlock
            }
        }
        .glassCard()
    }

    // MARK: - Metric Row (3 Spalten)

    private var metricRow: some View {
        HStack(spacing: 8) {
            readinessCard
            recoveryCard
            streakCard
        }
    }

    // MARK: - Tagesform-Card

    private var readinessCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TAGESFORM")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text(readinessIsCalibrating ? "—" : "\(readinessScore ?? 0)")
                .font(.title.bold())
                .monospacedDigit()
                .foregroundStyle(MCColor.mcEnergy)
            Text(readinessIsCalibrating
                 ? "Kalibrierung läuft"
                 : (readinessLabel?.localizedTitle ?? "Keine Daten"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(10)
        .background(MCColor.mcEnergySoft, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Erholung-Card

    private var recoveryCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ERHOLUNG")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text("\(recoveryPercent)%")
                .font(.title.bold())
                .monospacedDigit()
                .foregroundStyle(MCColor.mcBody)
            Text(recoveryLabel(for: recoveryPercent))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(10)
        .background(MCColor.mcBodySoft, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Streak-Card

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("STREAK")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text("\(currentStreak) d")
                .font(.title.bold())
                .monospacedDigit()
                .foregroundStyle(MCColor.mcStreak)
            if let milestone = nextStreakMilestone {
                let distance = milestone.rawValue - currentStreak
                Text("\(distance) bis \(milestone.rawValue) d")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                ProgressView(value: milestoneProgress(milestone))
                    .tint(MCColor.mcStreak)
            } else {
                Text("Kein nächster Meilenstein")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(10)
        .background(MCColor.mcStreakSoft, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - "Heute trainieren"-Block

    private var todayTrainingBlock: some View {
        HStack(spacing: 10) {
            Image(systemName: "dumbbell.fill")
                .foregroundStyle(MCColor.mcStat)
            VStack(alignment: .leading, spacing: 1) {
                Text(recommendation.recommendedTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text("\(recommendation.recommendedGroups.count) Gruppen erholt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Start", action: onStartWorkoutTap)
                .buttonStyle(.bordered)
                .tint(MCColor.mcStat)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(MCColor.mcStatSoft, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Hilfsfunktionen

    private func recoveryLabel(for percent: Int) -> String {
        switch percent {
        case 85...: return "Sehr gut"
        case 60...: return "Mittel"
        default:    return "Niedrig"
        }
    }

    private func milestoneProgress(_ milestone: StreakMilestone) -> Double {
        let previous = previousMilestoneValue(before: milestone)
        let range = milestone.rawValue - previous
        guard range > 0 else { return 1.0 }
        let done = currentStreak - previous
        return min(max(Double(done) / Double(range), 0), 1)
    }

    /// Vorheriger Meilenstein-Wert als Ausgangspunkt des Fortschritts
    private func previousMilestoneValue(before milestone: StreakMilestone) -> Int {
        let sorted = StreakMilestone.allCases.sorted { $0.rawValue < $1.rawValue }
        guard let index = sorted.firstIndex(of: milestone), index > 0 else { return 0 }
        return sorted[index - 1].rawValue
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {

            // Szenario 1: Volle Daten
            SummaryCommandHero(
                readinessScore: 82,
                readinessLabel: .good,
                readinessIsCalibrating: false,
                recoveryPercent: 88,
                currentStreak: 10,
                nextStreakMilestone: .week14,
                recommendation: RecoveryRecommendation(
                    recommendedGroups: [.chest, .shoulders],
                    avoidGroups: [.legs],
                    recommendedTitle: "Push: Brust · Schultern",
                    avoidTitle: "Beine",
                    avoidReason: "Bei 42% Erholung steigt das Verletzungsrisiko."
                ),
                onStartWorkoutTap: {}
            )

            // Szenario 2: Kalibrierung + niedrige Recovery
            SummaryCommandHero(
                readinessScore: nil,
                readinessLabel: nil,
                readinessIsCalibrating: true,
                recoveryPercent: 35,
                currentStreak: 3,
                nextStreakMilestone: .week7,
                recommendation: .empty,
                onStartWorkoutTap: {}
            )

            // Szenario 3: Alles leer
            SummaryCommandHero(
                readinessScore: nil,
                readinessLabel: nil,
                readinessIsCalibrating: false,
                recoveryPercent: 0,
                currentStreak: 0,
                nextStreakMilestone: nil,
                recommendation: .empty,
                onStartWorkoutTap: {}
            )
        }
        .padding()
    }
}
