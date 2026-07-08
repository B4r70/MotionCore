//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StatisticDonutChart.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 16.11.2025                                                       /
// Beschreibung  : Darstellung von Charts für diverse Werte                         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import Charts

struct StatisticDonutChart: View {
    let title: String
    let data: [DonutChartData]

    var body: some View {
            // Äußerer VStack umschließt nun ALLES (Titel & Inhalt)
        VStack(alignment: .leading, spacing: 16) {

                // 1. Titel (ist jetzt Teil des Hintergrunds)
            Text(title)
                .font(AppFont.headline)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 4)
                .padding(.top, 4)

                // 2. Inhalt (Chart und Legende)
            HStack {
                    // Chart
                Chart(data) { item in
                    SectorMark(
                        angle: .value("Anzahl", item.value),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .cornerRadius(5)
                    .foregroundStyle(by: .value("Kategorie", item.label))
                }
                .chartForegroundStyleScale(range: Theme.series)
                .frame(height: 200)

                    // Dynamische Legende (Top 4)
                VStack(alignment: .leading, spacing: Space.s2) {
                    ForEach(Array(data.prefix(4).enumerated()), id: \.element.id) { idx, item in
                        HStack {
                            Circle()
                                .fill(Theme.series[idx % Theme.series.count])
                                .frame(width: 8, height: 8)
                            Text(item.label)
                                .font(AppFont.callout)
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                            Spacer()
                            Text("\(item.value)")
                                .font(AppFont.callout)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                }
                .frame(width: 120)
            }
            .padding([.horizontal, .bottom]) // Fügt horizontalen und unteren Abstand zum Inhalt hinzu
        }
        .card()
    }
}
