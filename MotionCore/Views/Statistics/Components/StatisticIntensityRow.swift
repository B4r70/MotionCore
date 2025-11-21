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
                        .font(.caption2)
                }
            }
            .frame(width: 60, alignment: .leading)

            // Balken
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))

                    Capsule()
                        .fill(summary.intensity.color)
                        .frame(width: geo.size.width * percentage)
                }
            }
            .frame(height: 6)

            // Count
            Text("\(summary.count)")
                .font(.caption.bold())
                .frame(width: 30, alignment: .trailing)
        }
    }
}

#Preview {
    StatisticIntensityRow(
        summary: IntensitySummary(
            intensity: .easy,
            count: 5,
            total: 8
        )
    )
}
