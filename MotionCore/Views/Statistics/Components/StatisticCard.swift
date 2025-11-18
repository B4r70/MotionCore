// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Section  . . : Statistik                                                         /
// Filename . . : StatisticsCard.swift                                              /
// Author . . . : Bartosz Stryjewski                                                /
// Created on . : 11.11.2025                                                        /
// Function . . : Statistik Card Ansicht mit diversen Werten                        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
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
        VStack(spacing: 10) {

            // Icon oben
            Image(systemName: icon)
                .font(.system(size: 40))        
                .foregroundStyle(color)

            // Wert in groß, aber nicht riesig
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            // Subtitle klein
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120) // EINHEITLICHE HÖHE
        .glassCardStyle()
    }
}
