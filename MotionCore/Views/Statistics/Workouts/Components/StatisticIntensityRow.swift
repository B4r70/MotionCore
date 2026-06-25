//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StatisticIntensityRow.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 16.11.2025                                                       /
// Beschreibung  : Darstellung von Zeilen mit Workouts je Belastungsintensität      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Intensity Stat Row
struct StatisticIntensityRow: View {
    let summary: IntensitySummary

    private var percentage: Double {
        guard summary.total > 0 else { return 0 }
        return Double(summary.count) / Double(summary.total)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Sterne
            HStack(spacing: 2) {
                ForEach(0 ..< summary.intensity.rawValue, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(AppFont.caption)
                }
            }
            .frame(width: 60, alignment: .leading)

            // Balken
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.surfaceSunken)

                    Capsule()
                        .fill(summary.intensity.color)
                        .frame(width: geo.size.width * percentage)
                }
            }
            .frame(height: 6)

            // Count
            Text("\(summary.count)")
                .font(AppFont.callout.bold())
                .frame(width: 30, alignment: .trailing)
        }
    }
}

#Preview {
    StatisticIntensityRow(
        summary: IntensitySummary(
            intensity: .veryEasy,
            count: 10,
            total: 20
        )
    );
    StatisticIntensityRow(
        summary: IntensitySummary(
            intensity: .easy,
            count: 2,
            total: 20
        )
    );
    StatisticIntensityRow(
        summary: IntensitySummary(
            intensity: .medium,
            count: 2,
            total: 20
        )
    );
    StatisticIntensityRow(
        summary: IntensitySummary(
            intensity: .hard,
            count: 4,
            total: 20
        )
    );
    StatisticIntensityRow(
        summary: IntensitySummary(
            intensity: .veryHard,
            count: 2,
            total: 20
        )
    )
}
