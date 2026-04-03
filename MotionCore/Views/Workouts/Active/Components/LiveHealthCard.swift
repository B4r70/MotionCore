//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : LiveHealthCard.swift                                             /
// Erstellt am . : 31.03.2026                                                       /
// Beschreibung  : GlassCard mit Live HR + Kalorien aus Watch-Tracking              /
//                 Wird nur angezeigt wenn mindestens ein Wert > 0                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct LiveHealthCard: View {
    let currentHR: Double
    let averageHR: Double
    let maxHR: Double
    let activeCalories: Double

    var body: some View {
        HStack(spacing: 0) {
                // Linke Hälfte: Herzfrequenz
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentHR > 0 ? "\(Int(currentHR))" : "–")
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(.primary)
                        Text("Ø \(averageHR > 0 ? String(Int(averageHR)) : "–") ↑ \(maxHR > 0 ? String(Int(maxHR)) : "–")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 36)
                    .padding(.horizontal, 8)

                // Rechte Hälfte: Kalorien
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(activeCalories > 0 ? "\(Int(activeCalories))" : "–")
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(.primary)
                        Text("kcal aktiv")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .glassCard()
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        LiveHealthCard(
            currentHR: 142,
            averageHR: 128,
            maxHR: 158,
            activeCalories: 287
        )

        // Nur Herzfrequenz (keine Kalorien)
        LiveHealthCard(
            currentHR: 118,
            averageHR: 112,
            maxHR: 130,
            activeCalories: 0
        )

        // Keine Daten → nicht anzeigen
        LiveHealthCard(
            currentHR: 0,
            averageHR: 0,
            maxHR: 0,
            activeCalories: 0
        )
    }
    .padding()
}
