// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Section  . . : Statistik                                                         /
// Filename . . : StatisticsTrendChart.swift                                        /
// Author . . . : Bartosz Stryjewski                                                /
// Created on . : 17.11.2025                                                        /
// Function . . : Statistik Trend Chart                                             /
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
            Text(title)
                .font(.headline)

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
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.vertical)
    }
}
