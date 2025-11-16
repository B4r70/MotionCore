// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : StatisticsCard.swift                                             /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 11.11.2025                                                       /
// Function . . : Statistik Card Ansicht mit diversen Werten                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct StatisticCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundStyle(color)

            VStack(spacing: 8) {
                Text(value)
                    .font(.system(size: 48, weight: .bold))

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCardStyle()
    }
}

// Alternativ im Grid Format 2 Cards pro Zeile
struct StatisticCardDoubleGrid: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Spacer()

                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)   // gut für 2-Spalten-Grid
        .glassCardStyle()
    }
}
