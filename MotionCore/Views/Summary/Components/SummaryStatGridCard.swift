//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Summary / Components                                     /
// Datei . . . . : SummaryStatGridCard.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : 2x2 Statistik-Grid mit Sparkline-Slot und Delta-Anzeige          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
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
            spacing: Space.s3
        ) {
            SparkStatCard(
                icon: "figure.strengthtraining.traditional",
                title: "Workouts",
                value: "\(totalWorkouts)",
                unit: "Einheiten",
                tint: Theme.accent,
                trend: nil
            )
            SparkStatCard(
                icon: "flame.fill",
                title: "Kalorien",
                value: "\(totalCalories)",
                unit: "kcal",
                tint: Theme.warning,
                trend: caloriesTrend
            )
            SparkStatCard(
                icon: "clock.fill",
                title: "Trainingszeit",
                value: formattedDuration,
                unit: "",
                tint: Theme.series[0],
                trend: durationTrend
            )
            SparkStatCard(
                icon: "heart.fill",
                title: "Ø Herzfrequenz",
                value: averageHeartRate > 0 ? "\(averageHeartRate)" : "—",
                unit: averageHeartRate > 0 ? "bpm" : "",
                tint: Theme.danger,
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
        VStack(alignment: .leading, spacing: Space.s1) {

            // Header-Zeile: Icon + optionaler Delta-Text
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .font(AppFont.caption)
                Spacer()
                if let t = trend {
                    Text(formattedDelta(t))
                        .font(AppFont.caption)
                        .monospacedDigit()
                        .foregroundStyle(deltaColor(t))
                }
            }

            // Hauptwert
            Text(value)
                .font(AppFont.title)
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Einheit + Bezeichnung
            Text(unit.isEmpty ? title : "\(unit)  \(title)")
                .font(AppFont.caption)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)

            // Sparkline-Slot (leer bis 7-Tage-Series verfügbar — Logik außerhalb AP 2)
            Sparkline(data: [], color: tint)
        }
        .card(padding: Space.s3)
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
        case .up:      return Theme.success
        case .down:    return Theme.danger
        case .stable:  return Theme.textSecondary
        case .unknown: return Theme.textSecondary
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
                currentValue: 48000, previousValue: 42000, percentageChange: 14.3, trend: .up
            ),
            caloriesTrend: TrendComparison(
                currentValue: 4800, previousValue: 5200, percentageChange: -7.7, trend: .down
            ),
            durationTrend: TrendComparison(
                currentValue: 30600, previousValue: 30600, percentageChange: 0.0, trend: .stable
            )
        )
        .padding()
    }
    .background(Theme.surfaceApp)
}
