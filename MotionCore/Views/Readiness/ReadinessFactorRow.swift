//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Readiness                                               /
// Datei . . . . : ReadinessFactorRow.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Kompakte Zeile für einen ReadinessFactor im Detail-Sheet         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ReadinessFactorRow: View {

    let factor: ReadinessFactor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(factor.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(factor.weightPercent) %")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(factor.valueDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressView(value: factor.normalizedScore)
                .progressViewStyle(.linear)
                .tint(tintColor(for: factor.normalizedScore))
                .frame(height: 4)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Hilfsmethoden

    private func tintColor(for score: Double) -> Color {
        switch score {
        case 0.0..<0.35: return .red
        case 0.35..<0.50: return .orange
        case 0.50..<0.75: return .yellow
        default:          return .green
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        ReadinessFactorRow(factor: ReadinessFactor(
            metricType: .hrv,
            name: "HRV",
            valueDescription: "leicht über Baseline",
            normalizedScore: 0.72,
            weightPercent: 40
        ))
        ReadinessFactorRow(factor: ReadinessFactor(
            metricType: .sleep,
            name: "Schlaf",
            valueDescription: "wenig",
            normalizedScore: 0.38,
            weightPercent: 30
        ))
        ReadinessFactorRow(factor: ReadinessFactor(
            metricType: .restingHR,
            name: "Ruhepuls",
            valueDescription: "normal",
            normalizedScore: 0.55,
            weightPercent: 20
        ))
    }
}
