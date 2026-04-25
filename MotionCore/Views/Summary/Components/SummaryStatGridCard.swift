//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Summary / Components                                     /
// Datei . . . . : SummaryStatGridCard.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : 2×2 Statistik-Grid mit Sparkline-Slot und Delta-Anzeige         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/

import SwiftUI

// MARK: - SummaryStatGridCard

struct SummaryStatGridCard: View {

    // MARK: Properties

    let totalWorkouts: Int
    let totalCalories: Int
    let formattedDuration: String
    let averageHeartRate: Int
    let volumeTrend: TrendComparison
    let caloriesTrend: TrendComparison
    let durationTrend: TrendComparison

    // MARK: Body

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            SparkStatCard(
                icon: "figure.strengthtraining.traditional",
                title: "Workouts",
                value: "\(totalWorkouts)",
                unit: "Einheiten",
                tint: .purple,
                trend: nil
            )
            SparkStatCard(
                icon: "flame.fill",
                title: "Kalorien",
                value: "\(totalCalories)",
                unit: "kcal",
                tint: MCColor.mcStreak,
                trend: caloriesTrend
            )
            SparkStatCard(
                icon: "clock.fill",
                title: "Trainingszeit",
                value: formattedDuration,
                unit: "",
                tint: .purple,
                trend: durationTrend
            )
            SparkStatCard(
                icon: "heart.fill",
                title: "Ø Herzfrequenz",
                value: averageHeartRate > 0 ? "\(averageHeartRate)" : "—",
                unit: averageHeartRate > 0 ? "bpm" : "",
                tint: .red,
                trend: nil
            )
        }
    }
}

// MARK: - SparkStatCard (privater Sub-View)

private struct SparkStatCard: View {

    let icon: String
    let title: String
    let value: String
    let unit: String
    let tint: Color
    let trend: TrendComparison?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            // Header-Zeile: Icon + optionaler Delta-Text
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .font(.caption)
                Spacer()
                if let t = trend {
                    Text(formattedDelta(t))
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(deltaColor(t))
                }
            }

            // Hauptwert
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Einheit + Bezeichnung
            Text(unit.isEmpty ? title : "\(unit)  \(title)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Sparkline-Slot
            // TODO: 7-Tage-Series einbinden wenn TrendCalcEngine.timeSeries existiert
            MCSparkline(data: [], color: tint)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Delta-Hilfsfunktionen

    private func formattedDelta(_ trend: TrendComparison) -> String {
        let pct = trend.percentageChange
        if pct > 0.5 {
            return "+\(Int(pct.rounded()))%"
        } else if pct < -0.5 {
            return "\(Int(pct.rounded()))%"
        } else {
            return "±0%"
        }
    }

    private func deltaColor(_ trend: TrendComparison) -> Color {
        switch trend.trend {
        case .up:     return .green
        case .down:   return .red
        case .stable: return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        SummaryStatGridCard(
            totalWorkouts: 12,
            totalCalories: 4800,
            formattedDuration: "8h 30m",
            averageHeartRate: 138,
            volumeTrend: TrendComparison(
                currentValue: 48000,
                previousValue: 42000,
                percentageChange: 14.3,
                trend: .up
            ),
            caloriesTrend: TrendComparison(
                currentValue: 4800,
                previousValue: 5200,
                percentageChange: -7.7,
                trend: .down
            ),
            durationTrend: TrendComparison(
                currentValue: 30600,
                previousValue: 30600,
                percentageChange: 0.0,
                trend: .stable
            )
        )
        .padding()
    }
}
