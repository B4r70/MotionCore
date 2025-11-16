// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : StatisticIntensityRow.swift                                      /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 16.11.2025                                                       /
// Function . . : Zeilen je Belastungsintensität                                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Intensity Stat Row

struct StatisticIntensityRow: View {
    let intensity: Intensity
    let count: Int
    let total: Int

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Sterne
            HStack(spacing: 2) {
                ForEach(0 ..< intensity.rawValue, id: \.self) { _ in
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
                        .fill(intensity.color)
                        .frame(width: geo.size.width * percentage)
                }
            }
            .frame(height: 6)

            // Count
            Text("\(count)")
                .font(.caption.bold())
                .frame(width: 30, alignment: .trailing)
        }
    }
}

#Preview {
    StatisticIntensityRow(intensity: .easy, count: 50, total: 100)
}
