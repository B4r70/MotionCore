//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Summary / Components                                     /
// Datei . . . . : SummaryChipRow.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Horizontal scrollbare Chip-Leiste mit Level, Volumen, HR, Schlaf /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/

import SwiftUI

// MARK: - SummaryChipRow

struct SummaryChipRow: View {

    // MARK: Properties

    let xpLevel: XPLevel
    let volumeTrend: TrendComparison
    let averageHeartRate: Int
    let sleepDuration: TimeInterval?

    // MARK: Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                levelChip
                volumeChip
                if averageHeartRate > 0 {
                    heartRateChip
                }
                if let sleep = sleepDuration {
                    sleepChip(duration: sleep)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Chips

    private var levelChip: some View {
        let nextLevel = xpLevel.level + 1
        let progressPercent = Int(xpLevel.progressToNextLevel * 100)
        return MCChip(
            icon: Image(systemName: "star.fill"),
            value: "Lvl \(xpLevel.level)",
            label: "\(progressPercent)% bis Lvl \(nextLevel)",
            tint: .purple
        )
    }

    private var volumeChip: some View {
        MCChip(
            icon: Image(systemName: "chart.bar.fill"),
            value: formattedDelta(from: volumeTrend),
            label: "Volumen vs. Vorw.",
            tint: trendColor(from: volumeTrend)
        )
    }

    private var heartRateChip: some View {
        MCChip(
            icon: Image(systemName: "heart.fill"),
            value: "\(averageHeartRate) bpm",
            label: "Ø HR",
            tint: .red
        )
    }

    private func sleepChip(duration: TimeInterval) -> some View {
        MCChip(
            icon: Image(systemName: "bed.double.fill"),
            value: formattedSleep(duration),
            label: "Schlaf",
            tint: .indigo
        )
    }

    // MARK: - Hilfsfunktionen

    private func formattedDelta(from trend: TrendComparison) -> String {
        let pct = trend.percentageChange
        if pct > 0.5 {
            return "+\(Int(pct.rounded()))%"
        } else if pct < -0.5 {
            return "\(Int(pct.rounded()))%"
        } else {
            return "±0%"
        }
    }

    private func trendColor(from trend: TrendComparison) -> Color {
        switch trend.trend {
        case .up:      return .green
        case .down:    return .red
        case .stable:  return .secondary
        case .unknown: return .secondary
        }
    }

    private func formattedSleep(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {

        // Szenario 1: Alle Chips aktiv, positiver Trend
        SummaryChipRow(
            xpLevel: XPLevel(
                level: 12,
                totalXP: 6200,
                xpForCurrentLevel: 200,
                xpRequiredForNextLevel: 800,
                rank: .warrior,
                progressToNextLevel: 0.65
            ),
            volumeTrend: TrendComparison(
                currentValue: 48000,
                previousValue: 42000,
                percentageChange: 14.3,
                trend: .up
            ),
            averageHeartRate: 134,
            sleepDuration: 6.5 * 3600
        )

        // Szenario 2: Negativer Trend, kein HR, kein Schlaf
        SummaryChipRow(
            xpLevel: XPLevel(
                level: 5,
                totalXP: 1800,
                xpForCurrentLevel: 300,
                xpRequiredForNextLevel: 500,
                rank: .athlet,
                progressToNextLevel: 0.2
            ),
            volumeTrend: TrendComparison(
                currentValue: 22000,
                previousValue: 30000,
                percentageChange: -26.7,
                trend: .down
            ),
            averageHeartRate: 0,
            sleepDuration: nil
        )

        // Szenario 3: Stabiler Trend, Schlaf exakt volle Stunden
        SummaryChipRow(
            xpLevel: XPLevel(
                level: 1,
                totalXP: 100,
                xpForCurrentLevel: 100,
                xpRequiredForNextLevel: 500,
                rank: .rookie,
                progressToNextLevel: 0.0
            ),
            volumeTrend: TrendComparison(
                currentValue: 15000,
                previousValue: 15000,
                percentageChange: 0.0,
                trend: .stable
            ),
            averageHeartRate: 68,
            sleepDuration: 8 * 3600
        )
    }
    .padding(.vertical)
}
