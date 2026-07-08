//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Active / Components                                             /
// Datei . . . . : ReadinessCard.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Kompakte Readiness-Karte auf dem Workout-Start-Screen (Phase 2) /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ReadinessCard: View {

    let readiness: SessionReadiness?
    let onTap: () -> Void

    @EnvironmentObject private var appSettings: AppSettings

    private var score: Int {
        #if DEBUG
        if appSettings.debugReadinessScoreOverride >= 0 {
            return appSettings.debugReadinessScoreOverride
        }
        #endif
        return readiness?.overallScore ?? 50
    }
    private var isCalibrating: Bool { readiness?.isCalibrating ?? true }
    private var label: ReadinessLabel { ReadinessLabel.from(score: score) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: isCalibrating ? "clock.badge.questionmark" : label.systemIcon)
                    .font(.title2)
                    .foregroundStyle(isCalibrating ? .yellow : label.color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isCalibrating ? "Kalibriere noch" : label.localizedTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    if isCalibrating {
                        Text("Sammle Tagesform-Daten")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Readiness: \(score)/100")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .card()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Good") {
    let r = SessionReadiness()
    r.overallScore = 78
    r.isCalibrating = false
    r.hrvScore = 0.75
    r.sleepScore = 0.65
    return ReadinessCard(readiness: r) {}
        .padding()
        .background(Color(.systemGroupedBackground))
        .environmentObject(AppSettings.shared)
}

#Preview("Calibrating") {
    ReadinessCard(readiness: nil) {}
        .padding()
        .background(Color(.systemGroupedBackground))
        .environmentObject(AppSettings.shared)
}
