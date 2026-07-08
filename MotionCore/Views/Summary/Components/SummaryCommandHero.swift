//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Summary / Components                                     /
// Datei . . . . : SummaryCommandHero.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Ring-Hero (Tagesform) + StatTile-Reihe + Trainings-Empfehlung    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - SummaryCommandHero (Calm 2026 · Richtung A · Ring-Hero)

struct SummaryCommandHero: View {

    // MARK: Properties

    let readinessScore: Int?
    let readinessLabel: ReadinessLabel?
    let readinessIsCalibrating: Bool
    let recoveryPercent: Int
    let currentStreak: Int
    let averageHeartRate: Int?
    let recommendation: RecoveryRecommendation
    let onStartWorkoutTap: () -> Void

    // MARK: Body

    var body: some View {
        VStack(spacing: Space.s4) {
            heroCard
            statTileRow
        }
    }

    // MARK: - Hero-Card (Ring + Empfehlung + CTA)

    private var heroCard: some View {
        VStack(spacing: Space.s4) {
            HStack(spacing: Space.s5) {
                ProgressRing(
                    progress: ringProgress,
                    size: 104,
                    stroke: 9,
                    tint: Theme.accent,
                    centerValue: readinessIsCalibrating ? "—" : "\(readinessScore ?? 0)",
                    centerLabel: "Tagesform"
                )

                VStack(alignment: .leading, spacing: Space.s1) {
                    Text(heroEyebrow)
                        .font(AppFont.eyebrow)
                        .textCase(.uppercase)
                        .tracking(0.6)
                        .foregroundStyle(Theme.textTertiary)
                    Text(heroHeadline)
                        .font(AppFont.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let heroSubline {
                        Text(heroSubline)
                            .font(AppFont.callout)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button("Training starten", action: onStartWorkoutTap)
                .buttonStyle(.mcPrimary)
        }
        .card()
    }

    // MARK: - Stat-Kacheln (eine Leitfarbe je Kennzahl)

    private var statTileRow: some View {
        HStack(spacing: Space.s3) {
            StatTile(eyebrow: "Erholung", value: "\(recoveryPercent)", unit: "%", tint: Theme.success)
            StatTile(eyebrow: "Streak", value: "\(currentStreak)", unit: "Tage", tint: Theme.warning)
            StatTile(eyebrow: "Ø Puls", value: heartRateText,
                     unit: heartRateText == "—" ? nil : "bpm", tint: Theme.danger)
        }
    }

    // MARK: - Abgeleitete Werte

    private var ringProgress: Double {
        guard !readinessIsCalibrating, let score = readinessScore else { return 0 }
        return min(max(Double(score) / 100.0, 0), 1)
    }

    private var heartRateText: String {
        guard let hr = averageHeartRate, hr > 0 else { return "—" }
        return "\(hr)"
    }

    private var heroEyebrow: String {
        recommendation.recommendedGroups.isEmpty ? "Status" : "Empfohlen heute"
    }

    private var heroHeadline: String {
        if !recommendation.recommendedGroups.isEmpty {
            return recommendation.recommendedTitle
        }
        if readinessIsCalibrating { return "Kalibrierung läuft" }
        return readinessLabel?.localizedTitle ?? "Bereit fürs Training"
    }

    private var heroSubline: String? {
        guard !recommendation.recommendedGroups.isEmpty else { return nil }
        return "\(recommendation.recommendedGroups.count) Muskelgruppen erholt"
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Space.s4) {
            // Volle Daten
            SummaryCommandHero(
                readinessScore: 82,
                readinessLabel: .good,
                readinessIsCalibrating: false,
                recoveryPercent: 88,
                currentStreak: 10,
                averageHeartRate: 132,
                recommendation: RecoveryRecommendation(
                    recommendedGroups: [.chest, .shoulders],
                    avoidGroups: [.legs],
                    recommendedTitle: "Push: Brust · Schultern",
                    avoidTitle: "Beine",
                    avoidReason: "Bei 42% Erholung steigt das Verletzungsrisiko."
                ),
                onStartWorkoutTap: {}
            )

            // Kalibrierung
            SummaryCommandHero(
                readinessScore: nil,
                readinessLabel: nil,
                readinessIsCalibrating: true,
                recoveryPercent: 35,
                currentStreak: 3,
                averageHeartRate: nil,
                recommendation: .empty,
                onStartWorkoutTap: {}
            )
        }
        .padding()
    }
    .background(Theme.surfaceApp)
}
