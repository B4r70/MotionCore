//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body                                                     /
// Datei . . . . : BodyMeasurementsCard.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.05.2026                                                       /
// Beschreibung  : Teaser-Card für die Körpermaße-Ansicht im Body-Tab              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - BodyMeasurementsCard

struct BodyMeasurementsCard: View {

    // MARK: - Eingaben

    let measurements: [BodyMeasurement]
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Header
            HStack {
                Text("Körpermaße")
                    .font(AppFont.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(AppFont.callout)
                    .foregroundStyle(Theme.textSecondary)
            }

            // Sub-Header
            Text(subHeaderText)
                .font(AppFont.callout)
                .foregroundStyle(Theme.textSecondary)

            // Mini-Sparklines (nur wenn Daten vorhanden)
            if !measurements.isEmpty {
                HStack(spacing: 12) {
                    MiniSparklinePanel(
                        label: "Brust",
                        unit: "cm",
                        measurements: measurements,
                        keyPath: \.chestCircumference
                    )
                    MiniSparklinePanel(
                        label: "Taille",
                        unit: "cm",
                        measurements: measurements,
                        keyPath: \.waistCircumference
                    )
                    MiniSparklinePanel(
                        label: "Gewicht",
                        unit: "kg",
                        measurements: measurements,
                        keyPath: \.bodyWeight
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .card()
    }

    // MARK: - Hilfsfunktionen

    private var subHeaderText: String {
        guard let latest = measurements.max(by: { $0.date < $1.date }) else {
            return "Noch keine Messung — tippe auf +"
        }
        let days = Calendar.current.dateComponents([.day], from: latest.date, to: Date()).day ?? 0
        switch days {
        case 0:  return "Letzte Messung: heute"
        case 1:  return "Letzte Messung: gestern"
        default: return "Letzte Messung vor \(days) Tagen"
        }
    }
}

// MARK: - MiniSparklinePanel

private struct MiniSparklinePanel: View {
    let label: String
    let unit: String
    let measurements: [BodyMeasurement]
    let keyPath: KeyPath<BodyMeasurement, Double?>

    private let engine = BodyMeasurementTrendCalcEngine()

    var body: some View {
        let trend = engine.trend(for: measurements, keyPath: keyPath)
        let sparkline = engine.sparklineData(for: measurements, keyPath: keyPath)
        let yValues = sparkline.map(\.1)

        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFont.callout)
                .foregroundStyle(Theme.textSecondary)

            // Sparkline — Sparkline erwartet [Double] und Color
            if yValues.count >= 2 {
                Sparkline(data: yValues, color: Theme.accent, showFill: false)
                    .frame(height: 30)
            } else {
                Rectangle()
                    .fill(Theme.textSecondary.opacity(0.2))
                    .frame(height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            if let current = trend.currentValue {
                Text(String(format: "%.1f \(unit)", current))
                    .font(AppFont.caption.bold())
            } else {
                Text("–")
                    .font(AppFont.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    BodyMeasurementsCard(measurements: [], onTap: {})
        .padding()
}
