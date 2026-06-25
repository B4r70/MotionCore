//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body / BodyMeasurements                                  /
// Datei . . . . : BodyMeasurementsRatioCard.swift                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.05.2026                                                       /
// Beschreibung  : Karte für einen einzelnen Körpermaß-Verhältniswert mit          /
//                 Sparkline und Delta-Pille                                        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Charts
import SwiftUI

// MARK: - BodyMeasurementsRatioCard

struct BodyMeasurementsRatioCard: View {
    let title: String
    let description: String
    let trend: BodyMeasurementTrend
    let sparklineData: [(Date, Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Header
            HStack(alignment: .top) {
                Text(title)
                    .font(.headline)
                Spacer()
                RatioDeltaPill(trend: trend)
            }

            // Großer Ratio-Wert (2 Nachkommastellen)
            Text(formattedValue)
                .font(.system(size: 36, weight: .light, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .center)

            // Beschreibung
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Sparkline
            if sparklineData.count >= 2 {
                Chart(sparklineData, id: \.0) { item in
                    LineMark(
                        x: .value("Datum", item.0),
                        y: .value("Ratio", item.1)
                    )
                    .foregroundStyle(Color.accentColor)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 40)
            } else {
                Text("Mehr Daten nötig")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(height: 40)
            }
        }
        .card()
    }

    private var formattedValue: String {
        guard let v = trend.currentValue else { return "–" }
        return String(format: "%.2f", v)
    }
}

// MARK: - RatioDeltaPill

/// Delta-Pille für Verhältniswerte (2 Nachkommastellen, kein Einheits-Suffix)
private struct RatioDeltaPill: View {
    let trend: BodyMeasurementTrend

    var body: some View {
        if let delta = trend.absoluteDelta {
            let sign = delta >= 0 ? "+" : ""
            Text("\(sign)\(String(format: "%.2f", delta))")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(pillColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }

    private var pillColor: Color {
        switch trend.direction {
        case .up:               return .green
        case .down:             return .red
        case .stable, .unknown: return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        BodyMeasurementsRatioCard(
            title: "Taille-Hüfte (WHR)",
            description: "Gesundheits-Marker — niedrig ist günstig",
            trend: BodyMeasurementTrend(
                currentValue: 0.84,
                currentDate: Date(),
                previousValue: 0.86,
                absoluteDelta: -0.02,
                percentageDelta: -2.3,
                direction: .down
            ),
            sparklineData: []
        )
    }
    .padding()
}
