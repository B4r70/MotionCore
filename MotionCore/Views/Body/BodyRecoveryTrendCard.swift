//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body                                                     /
// Datei . . . . : BodyRecoveryTrendCard.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : 14-Tage-Verlauf des Gesamt-Erholungswerts als Swift-Charts-Linie /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Charts
import SwiftUI

// MARK: - BodyRecoveryTrendCard

struct BodyRecoveryTrendCard: View {

    // MARK: - Eingaben

    let trend: [TrendPoint]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Erholungs-Trend · 14 Tage")
                .font(.headline)

            if RecoveryTrendCalcEngine.isEmpty(trend) || trend.count < 2 {
                EmptyState()
            } else {
                chart
            }
        }
        .frame(minHeight: 140)
        .glassCard()
    }

    // MARK: - Subviews

    private var chart: some View {
        Chart(trend) { point in
            LineMark(
                x: .value("Datum", point.trendDate, unit: .day),
                y: .value("Erholung", point.trendValue)
            )
            .foregroundStyle(MCColor.mcBody)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Datum", point.trendDate, unit: .day),
                y: .value("Erholung", point.trendValue)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [MCColor.mcBody.opacity(0.25), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(values: [0, 50, 100]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Int.self) {
                        Text("\(v)%")
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            }
        }
        .frame(minHeight: 200)
    }
}

// MARK: - Preview

#Preview {
    let now = Date()
    let cal = Calendar.current
    let sample = (0..<14).reversed().map { offset in
        TrendPoint(
            trendDate: cal.date(byAdding: .day, value: -offset, to: now)!,
            trendValue: Double(40 + offset * 3)
        )
    }
    return BodyRecoveryTrendCard(trend: sample)
        .padding()
}
