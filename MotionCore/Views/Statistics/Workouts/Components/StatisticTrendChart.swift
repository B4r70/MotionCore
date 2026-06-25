//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StatisticsTrendChart.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 16.11.2025                                                       /
// Beschreibung  : Darstellung von Charts für diverse Werte                         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import Charts

struct StatisticTrendChart: View {
    let title: String
    let yLabel: String
    let data: [TrendPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

                // Titelzeile und Ausgabeeinheit
            HStack {
                Text(title)
                    .font(AppFont.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(yLabel)
                    .font(AppFont.body)
                    .foregroundStyle(Theme.textSecondary)
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
                .foregroundStyle(Theme.accent)

                PointMark(
                    x: .value("Datum", point.trendDate),
                    y: .value(yLabel, point.trendValue)
                )
                .symbol(.circle)
                .symbolSize(45)
                .foregroundStyle(Theme.accent)
            }
            .chartYAxis {
                AxisMarks {
                    AxisGridLine().foregroundStyle(Theme.chartGrid)
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .frame(minHeight: 250)
            .padding()
        }
        .card()
    }
}
