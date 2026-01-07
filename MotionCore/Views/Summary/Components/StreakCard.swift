//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : StreakCard.swift                                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 07.01.2026                                                       /
// Beschreibung  : Anzeige von Streak und wöchentlicher Trainingsaktivität          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Streak Card

// Zeigt Streak, wöchentliche Workouts und Durchschnitt
struct StreakCard: View {
    let currentStreak: Int
    let workoutsThisWeek: Int
    let averagePerWeek: Double

    var body: some View {
        HStack(spacing: 20) {
            streakItem(
                icon: "flame.fill",
                iconColor: .orange,
                value: "\(currentStreak)",
                label: "Tage Streak"
            )

            divider

            streakItem(
                icon: "calendar",
                iconColor: .blue,
                value: "\(workoutsThisWeek)",
                label: "Diese Woche"
            )

            divider

            streakItem(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: .green,
                value: String(format: "%.1f", averagePerWeek),
                label: "⌀ / Woche"
            )
        }
        .padding(.vertical, 8)
        .glassCard()
    }

    // MARK: - Private Helpers

    private func streakItem(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(.secondary.opacity(0.3))
            .frame(width: 1, height: 50)
    }
}
