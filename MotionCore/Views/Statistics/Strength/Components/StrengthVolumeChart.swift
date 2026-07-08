//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StrengthVolumeChart.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-03                                                       /
// Beschreibung  : Balkendiagramm für Trainingsvolumen je Session                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import Charts

struct StrengthVolumeChart: View {
    let data: [TrendPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Volumen-Trend")
                    .font(AppFont.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("kg")
                    .font(AppFont.body)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding()

            if data.isEmpty {
                Text("Noch keine Daten vorhanden")
                    .font(AppFont.body)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .multilineTextAlignment(.center)
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("Datum", point.trendDate, unit: .day),
                        y: .value("Volumen", point.trendValue)
                    )
                    .foregroundStyle(Theme.series[0])
                    .cornerRadius(4)
                }
                .frame(minHeight: 220)
                .padding()
            }
        }
        .card()
    }
}
