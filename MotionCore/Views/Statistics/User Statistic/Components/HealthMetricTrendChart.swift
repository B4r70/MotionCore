//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Gesundheitsdaten                                                 /
// Datei . . . . : HealthMetricTrendChart.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 23.11.2025                                                       /
// Beschreibung  : Darstellung von Charts für Gesundheitsdaten                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import Charts

struct HealthMetricTrendChart: View {
    let title: String
    let yLabel: String
    let data: [TrendPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

                // Titelzeile und Ausgabeeinheit
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(yLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()

                // Chart Bereich
            Chart(data) { point in
                LineMark(
                    x: .value("Datum", point.trendDate),
                    y: .value(yLabel, point.trendValue)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(.init(lineWidth: 2.5))

                PointMark(
                    x: .value("Datum", point.trendDate),
                    y: .value(yLabel, point.trendValue)
                )
                .symbol(.circle)
                .symbolSize(45)
            }
            .frame(minHeight: 250)
            .padding()
        }
        .glassCard()
    }
}
