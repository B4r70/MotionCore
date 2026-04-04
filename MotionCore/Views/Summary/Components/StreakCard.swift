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

// Zeigt Streak, wöchentliche Workouts und Durchschnitt.
// Optional: Milestone-Badge und Flammen-Glow bei aktiver Streak.
struct StreakCard: View {
    let currentStreak: Int
    let workoutsThisWeek: Int
    let averagePerWeek: Double

    // Neue optionale Parameter für Meilensteine
    var streakMilestone: StreakMilestone? = nil
    var nextMilestone: StreakMilestone? = nil

    @State private var glowActive: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            // Milestone-Badge (wenn aktiver Meilenstein vorhanden)
            if let milestone = streakMilestone {
                HStack(spacing: 6) {
                    Image(systemName: milestone.icon)
                        .foregroundStyle(Color.orange)
                    Text(milestone.text)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.orange)
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)
            }

            // Hauptzeile: Streak + Woche + Durchschnitt
            HStack(spacing: 20) {
                streakItem(
                    icon: "flame.fill",
                    iconColor: currentStreak > 0 ? .orange : .secondary,
                    value: "\(currentStreak)",
                    label: "Tage Streak"
                )
                .overlay(
                    // Flammen-Glow bei aktiver Streak (einmalig)
                    Group {
                        if currentStreak > 0 {
                            Circle()
                                .fill(Color.orange.opacity(glowActive ? 0 : 0.2))
                                .scaleEffect(glowActive ? 1.6 : 1.0)
                        }
                    }
                    .clipped()
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

            // Nächster Meilenstein-Hinweis
            if let next = nextMilestone, streakMilestone == nil {
                let remaining = next.rawValue - currentStreak
                if remaining > 0 && remaining <= 10 {
                    Text("Noch \(remaining) Tage bis \(next.text)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                }
            }
        }
        .glassCard()
        .task {
            guard currentStreak > 0 else { return }
            // Einmaliger Glow-Effekt beim Erscheinen
            withAnimation(.easeOut(duration: 0.8)) {
                glowActive = true
            }
        }
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

// MARK: - Preview

#Preview("StreakCard") {
    VStack(spacing: 20) {
        // Standard ohne Meilenstein
        StreakCard(
            currentStreak: 5,
            workoutsThisWeek: 3,
            averagePerWeek: 3.5
        )

        // Mit Meilenstein
        StreakCard(
            currentStreak: 30,
            workoutsThisWeek: 4,
            averagePerWeek: 4.0,
            streakMilestone: .month30,
            nextMilestone: .month60
        )

        // Mit "Fast am Ziel"-Hinweis
        StreakCard(
            currentStreak: 24,
            workoutsThisWeek: 2,
            averagePerWeek: 3.2,
            nextMilestone: .month30
        )
    }
    .padding()
    .environmentObject(AppSettings.shared)
}
