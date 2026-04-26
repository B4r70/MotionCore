//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body                                                     /
// Datei . . . . : BodyReadinessFactorsCard.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Tagesform-Faktoren als Balken-Liste mit optionalem Score         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - BodyReadinessFactorsCard

struct BodyReadinessFactorsCard: View {

    // MARK: - Eingaben

    let factors: [ReadinessFactor]
    let score: Int?

    // MARK: - Hilfsmethoden

    // Puffer von ~0.03 um jede Schwelle verhindert Farb-Flip bei minimaler Float-Variation
    private func tintForScore(_ value: Double) -> Color {
        if value >= 0.72 { return MCColor.mcBody }
        if value >= 0.37 { return MCColor.mcEnergy }
        return MCColor.mcStreak
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Tagesform-Faktoren")
                    .font(.headline)
                Spacer()
                if let score {
                    Text("Score \(score)/100")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }

            if factors.isEmpty {
                EmptyState()
            } else {
                ForEach(factors, id: \.name) { factor in
                    MCFactorBar(
                        label: factor.name,
                        subLabel: factor.valueDescription,
                        value: factor.normalizedScore,
                        color: tintForScore(factor.normalizedScore)
                    )
                }
            }
        }
        .glassCard()
    }
}

// MARK: - Preview

#Preview("Mit Faktoren") {
    BodyReadinessFactorsCard(
        factors: [
            ReadinessFactor(
                metricType: .hrv,
                name: "HRV",
                valueDescription: "Gut",
                normalizedScore: 0.82,
                weightPercent: 30
            ),
            ReadinessFactor(
                metricType: .restingHR,
                name: "Ruhepuls",
                valueDescription: "Normal",
                normalizedScore: 0.55,
                weightPercent: 20
            ),
            ReadinessFactor(
                metricType: .sleep,
                name: "Schlaf",
                valueDescription: "Niedrig",
                normalizedScore: 0.28,
                weightPercent: 35
            )
        ],
        score: 64
    )
    .padding()
}

#Preview("Leer") {
    BodyReadinessFactorsCard(factors: [], score: nil)
        .padding()
}
