//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body                                                     /
// Datei . . . . : BodyAvoidCard.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               //
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Warnhinweis für Muskelgruppen die heute gemieden werden sollten   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - BodyAvoidCard

struct BodyAvoidCard: View {

    // MARK: - Eingaben

    let recommendation: RecoveryRecommendation

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HEUTE MEIDEN")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.warning)

            Text(recommendation.avoidTitle)
                .font(.headline)

            if !recommendation.avoidReason.isEmpty {
                Text(recommendation.avoidReason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.warning.opacity(0.10))
                .allowsHitTesting(false)
        )
    }
}

// MARK: - Preview

#Preview {
    BodyAvoidCard(
        recommendation: RecoveryRecommendation(
            recommendedGroups: [.chest],
            avoidGroups: [.legs, .glutes],
            recommendedTitle: "Brust",
            avoidTitle: "Beine · Gesäß",
            avoidReason: "Bei 42% Erholung steigt das Verletzungsrisiko."
        )
    )
    .padding()
}
