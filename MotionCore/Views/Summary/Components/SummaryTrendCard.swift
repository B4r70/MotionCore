//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : SummaryTrendCard.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-02                                                       /
// Beschreibung  : Trend-Card mit Volumen, Kalorien und Dauer (diese Woche vs. vor) /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Summary Trend Card

struct SummaryTrendCard: View {

    let volumeTrend: TrendComparison
    let caloriesTrend: TrendComparison
    let durationTrend: TrendComparison

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Überschrift
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.purple)
                Text("Diese Woche vs. Vorwoche")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            // Trend-Zeilen
            TrendRow(
                icon: "scalemass.fill",
                iconColor: Color.orange,
                label: "Volumen",
                value: Int(volumeTrend.currentValue),
                suffix: " kg",
                comparison: volumeTrend
            )

            Divider().opacity(0.4)

            TrendRow(
                icon: "flame.fill",
                iconColor: Color.red,
                label: "Kalorien",
                value: Int(caloriesTrend.currentValue),
                suffix: " kcal",
                comparison: caloriesTrend
            )

            Divider().opacity(0.4)

            TrendRow(
                icon: "clock.fill",
                iconColor: .purple,
                label: "Dauer",
                value: Int(durationTrend.currentValue),
                suffix: " min",
                comparison: durationTrend
            )
        }
        .glassCard()
    }
}

// MARK: - Trend-Zeile

private struct TrendRow: View {

    let icon: String
    let iconColor: Color
    let label: String
    let value: Int
    let suffix: String
    let comparison: TrendComparison

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 20)

            // Label
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(minWidth: 60, alignment: .leading)

            // CountUp-Wert
            CountUpText(
                targetValue: value,
                duration: 0.6,
                font: .system(size: 16, weight: .bold, design: .rounded),
                suffix: suffix
            )

            Spacer()

            // Trend-Pfeil + Prozentzahl
            trendIndicator
        }
    }

    private var trendIndicator: some View {
        HStack(spacing: 3) {
            Image(systemName: trendIcon)
                .font(.caption)
                .foregroundStyle(trendColor)

            if abs(comparison.percentageChange) >= 1 {
                Text(String(format: "%.0f%%", abs(comparison.percentageChange)))
                    .font(.caption2)
                    .foregroundStyle(trendColor)
            }
        }
    }

    private var trendIcon: String {
        switch comparison.trend {
        case .up:     return "arrow.up"
        case .down:   return "arrow.down"
        case .stable: return "minus"
        }
    }

    private var trendColor: Color {
        switch comparison.trend {
        case .up:     return Color.green
        case .down:   return Color.red
        case .stable: return .secondary
        }
    }
}

// MARK: - Preview

#Preview("SummaryTrendCard") {
    SummaryTrendCard(
        volumeTrend: TrendComparison(
            currentValue: 12500,
            previousValue: 10800,
            percentageChange: 15.7,
            trend: .up
        ),
        caloriesTrend: TrendComparison(
            currentValue: 850,
            previousValue: 920,
            percentageChange: -7.6,
            trend: .down
        ),
        durationTrend: TrendComparison(
            currentValue: 270,
            previousValue: 265,
            percentageChange: 1.9,
            trend: .stable
        )
    )
    .padding()
    .environmentObject(AppSettings.shared)
}
