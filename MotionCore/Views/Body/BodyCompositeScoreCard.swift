//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body                                                     /
// Datei . . . . : BodyCompositeScoreCard.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Hero-Card mit Gesamterholungswert und Trainingsempfehlung        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - BodyCompositeScoreCard

struct BodyCompositeScoreCard: View {

    // MARK: - Eingaben

    let recoveryPercent: Int
    let recommendation: RecoveryRecommendation
    let onStartWorkoutTap: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: Space.s5) {
            // Zentrierter Erholungs-Ring (kein Gradient-Wash mehr)
            ProgressRing(
                progress: Double(recoveryPercent) / 100.0,
                size: 140,
                stroke: 11,
                tint: Theme.success,
                centerValue: "\(recoveryPercent)",
                centerLabel: "Erholt"
            )

            VStack(alignment: .leading, spacing: Space.s2) {
                Text("Bereit für")
                    .font(AppFont.eyebrow)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .foregroundStyle(Theme.textTertiary)

                Text(recommendation.recommendedTitle)
                    .font(AppFont.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if !recommendation.recommendedGroups.isEmpty {
                    Text("\(recommendation.recommendedGroups.count) Gruppen erholt")
                        .font(AppFont.callout)
                        .monospacedDigit()
                        .foregroundStyle(Theme.textSecondary)

                    Button("Training starten", action: onStartWorkoutTap)
                        .buttonStyle(.mcPrimary)
                        .padding(.top, Space.s1)
                } else {
                    Text("Noch keine Empfehlung verfügbar")
                        .font(AppFont.callout)
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            Spacer(minLength: 0)
        }
        .card()
    }
}

// MARK: - Preview

#Preview("Mit Daten") {
    BodyCompositeScoreCard(
        recoveryPercent: 78,
        recommendation: RecoveryRecommendation(
            recommendedGroups: [.chest, .shoulders],
            avoidGroups: [.legs],
            recommendedTitle: "Push: Brust · Schultern",
            avoidTitle: "Beine",
            avoidReason: "Bei 42% Erholung steigt das Verletzungsrisiko."
        ),
        onStartWorkoutTap: {}
    )
    .padding()
}

#Preview("Leer") {
    BodyCompositeScoreCard(
        recoveryPercent: 100,
        recommendation: .empty,
        onStartWorkoutTap: {}
    )
    .padding()
}
