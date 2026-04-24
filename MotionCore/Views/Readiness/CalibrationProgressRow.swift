//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Readiness                                               /
// Datei . . . . : CalibrationProgressRow.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Zeigt den Kalibrierungs-Fortschritt einer einzelnen Metrik      /
//                 (gesammelte Tage vs. benötigte Tage) mit gelbem ProgressView    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct CalibrationProgressRow: View {

    // MARK: - Parameter

    let metricName: String
    let sampleCount: Int
    let requiredSamples: Int

    // MARK: - Computed

    private var progress: Double {
        guard requiredSamples > 0 else { return 0 }
        return min(Double(sampleCount) / Double(requiredSamples), 1.0)
    }

    private var isComplete: Bool { sampleCount >= requiredSamples }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(metricName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if isComplete {
                    Label("Bereit", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("\(sampleCount)/\(requiredSamples) Tage")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(value: progress)
                .tint(isComplete ? .green : .yellow)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        CalibrationProgressRow(metricName: "HRV", sampleCount: 7, requiredSamples: 14)
        CalibrationProgressRow(metricName: "Schlaf", sampleCount: 14, requiredSamples: 14)
        CalibrationProgressRow(metricName: "Ruhepuls", sampleCount: 3, requiredSamples: 14)
        CalibrationProgressRow(metricName: "Aktivität", sampleCount: 0, requiredSamples: 14)
    }
    .padding()
}
