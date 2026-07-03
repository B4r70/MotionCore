//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Watch App                                                        /
// Datei . . . . : IdleView.swift                                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.03.2026                                                       /
// Beschreibung  : Watch Idle Screen — zeigt Streak und Weekly Progress             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct IdleView: View {

    // Complications-Daten aus App Group UserDefaults — @AppStorage reagiert auf externe Änderungen
    @AppStorage(WatchComplicationKey.streakCount, store: WatchAppGroup.defaults)
    private var streakCount: Int = 0

    @AppStorage(WatchComplicationKey.weeklyWorkoutCount, store: WatchAppGroup.defaults)
    private var weeklyCount: Int = 0

    @AppStorage(WatchComplicationKey.weeklyWorkoutGoal, store: WatchAppGroup.defaults)
    private var weeklyGoalRaw: Int = 0

    private var weeklyGoal: Int { weeklyGoalRaw > 0 ? weeklyGoalRaw : 5 }  // Default 5 falls noch nicht gesetzt

    var body: some View {
        VStack(spacing: 12) {
            // Streak-Anzeige
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Theme.warning)
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(streakCount)")
                        .font(.system(.title2, design: .rounded).bold())
                        .monospacedDigit()
                    Text("Streak")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }

            Divider()

            // Wöchentlicher Fortschritt
            VStack(spacing: 4) {
                HStack {
                    Text("Diese Woche")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text("\(weeklyCount)/\(weeklyGoal)")
                        .font(.caption.bold())
                        .monospacedDigit()
                }
                ProgressView(value: Double(weeklyCount), total: Double(weeklyGoal))
                    .tint(Theme.accentHover)
            }

            Spacer(minLength: 4)

            // Status
            Text("Kein Workout aktiv")
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    IdleView()
}
