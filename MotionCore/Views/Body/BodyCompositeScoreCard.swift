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
        ZStack {
            // Subtiler radialer Farbakzent im Hintergrund
            RadialGradient(
                colors: [MCColor.mcBody.opacity(0.15), .clear],
                center: .leading,
                startRadius: 20,
                endRadius: 180
            )

            HStack(spacing: 16) {
                MCHeroRing(
                    value: recoveryPercent,
                    label: "Bereit",
                    subText: nil,
                    tint: MCColor.mcBody
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Bereit für")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(recommendation.recommendedTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    Text("\(recommendation.recommendedGroups.count) Gruppen erholt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()

                    if !recommendation.recommendedGroups.isEmpty {
                        Button("Heute trainieren →") {
                            onStartWorkoutTap()
                        }
                        .buttonStyle(.bordered)
                        .tint(MCColor.mcBody)
                        .font(.caption)
                    } else {
                        Text("Noch keine Empfehlung verfügbar")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .glassCard()
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
