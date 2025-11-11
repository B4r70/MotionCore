//---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : StatisticsCard.swift                                             /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 11.11.2025                                                       /
// Function . . : Statistik Card Ansicht mit diversen Werten                       /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
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
        .padding(.vertical, 40)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
    }
}
