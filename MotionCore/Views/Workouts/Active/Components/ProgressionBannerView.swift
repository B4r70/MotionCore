//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : ProgressionBannerView.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-08                                                       /
// Beschreibung  : Liquid Glass Banner für RIR-basierte Gewichtsempfehlung         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ProgressionBannerView: View {
    let recommendation: ProgressionRecommendation
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 3) {
                Text("Gewicht erhöhen · +\(formattedStep) kg")
                    .font(.headline.bold())
                    .foregroundStyle(.primary)

                Text(recommendation.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.5), Color.cyan.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.blue.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private var formattedStep: String {
        recommendation.progressionStep.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(recommendation.progressionStep))
            : String(format: "%.1f", recommendation.progressionStep)
    }
}

// MARK: - Preview

#Preview("Progression Banner") {
    ZStack {
        AnimatedBackground(showAnimatedBlob: true)

        VStack {
            ProgressionBannerView(
                recommendation: ProgressionRecommendation(
                    exerciseName: "Bankdrücken",
                    currentWeight: 80.0,
                    suggestedWeight: 82.5,
                    progressionStep: 2.5,
                    reason: "Ø RIR 3.5 > Ziel 2 in den letzten 3 Sessions",
                    sessionCount: 3
                ),
                onDismiss: {}
            )
            Spacer()
        }
        .padding(.top, 20)
    }
    .environmentObject(AppSettings.shared)
}
