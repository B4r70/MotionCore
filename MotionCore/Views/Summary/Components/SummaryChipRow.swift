//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Summary / Components                                     /
// Datei . . . . : SummaryChipRow.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Horizontal scrollbare Chip-Leiste (Level, Volumen, HR, Schlaf)   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
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
            HStack(spacing: Space.s2) {
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

    // MARK: - Chips (neutrale AP-1 Chip)

    private var levelChip: some View {
        let progressPercent = Int(xpLevel.progressToNextLevel * 100)
        return Chip(title: "Lvl \(xpLevel.level) · \(progressPercent)%", systemImage: "star.fill")
    }

    private var volumeChip: some View {
        Chip(title: "\(formattedDelta(from: volumeTrend)) Volumen", systemImage: "chart.bar.fill")
    }

    private var heartRateChip: some View {
        Chip(title: "Ø \(averageHeartRate) bpm", systemImage: "heart.fill")
    }

    private func sleepChip(duration: TimeInterval) -> some View {
        Chip(title: "\(formattedSleep(duration)) Schlaf", systemImage: "bed.double.fill")
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
    VStack(spacing: Space.s5) {
        SummaryChipRow(
            xpLevel: XPLevel(
                level: 12, totalXP: 6200, xpForCurrentLevel: 200,
                xpRequiredForNextLevel: 800, rank: .warrior, progressToNextLevel: 0.65
            ),
            volumeTrend: TrendComparison(
                currentValue: 48000, previousValue: 42000, percentageChange: 14.3, trend: .up
            ),
            averageHeartRate: 134,
            sleepDuration: 6.5 * 3600
        )

        SummaryChipRow(
            xpLevel: XPLevel(
                level: 5, totalXP: 1800, xpForCurrentLevel: 300,
                xpRequiredForNextLevel: 500, rank: .athlet, progressToNextLevel: 0.2
            ),
            volumeTrend: TrendComparison(
                currentValue: 22000, previousValue: 30000, percentageChange: -26.7, trend: .down
            ),
            averageHeartRate: 0,
            sleepDuration: nil
        )
    }
    .padding(.vertical)
    .background(Theme.surfaceApp)
}
