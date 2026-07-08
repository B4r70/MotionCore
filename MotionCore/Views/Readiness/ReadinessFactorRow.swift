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
        // Faktor-Balken (AP-1-Baustein): Name links, Wert + Gewicht rechts,
        // einfarbige Füllung nach Qualitäts-Ramp.
        FactorBar(
            label: factor.name,
            subLabel: "\(factor.valueDescription) · \(factor.weightPercent) %",
            value: factor.normalizedScore,
            tint: tintColor(for: factor.normalizedScore)
        )
        .padding(.vertical, Space.s1)
    }

    // MARK: - Hilfsmethoden

    /// Qualitäts-Ramp auf Status-Token (kein Regenbogen): niedrig → danger,
    /// mittel → warning, hoch → success.
    private func tintColor(for score: Double) -> Color {
        switch score {
        case 0.0..<0.35:  return Theme.danger
        case 0.35..<0.50: return Theme.warning
        case 0.50..<0.75: return Theme.warning
        default:          return Theme.success
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
