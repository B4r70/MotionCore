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

    // Complications-Daten aus App Group UserDefaults lesen
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.barto.motioncore")
    }

    private var streakCount: Int {
        sharedDefaults?.integer(forKey: WatchComplicationKey.streakCount) ?? 0
    }

    private var weeklyCount: Int {
        sharedDefaults?.integer(forKey: WatchComplicationKey.weeklyWorkoutCount) ?? 0
    }

    private var weeklyGoal: Int {
        let goal = sharedDefaults?.integer(forKey: WatchComplicationKey.weeklyWorkoutGoal) ?? 0
        return goal > 0 ? goal : 5  // Default 5 falls noch nicht gesetzt
    }

    var body: some View {
        VStack(spacing: 12) {
            // Streak-Anzeige
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.orange)
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(streakCount)")
                        .font(.title2.bold())
                    Text("Streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()

            // Wöchentlicher Fortschritt
            VStack(spacing: 4) {
                HStack {
                    Text("Diese Woche")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(weeklyCount)/\(weeklyGoal)")
                        .font(.caption.bold())
                }
                ProgressView(value: Double(weeklyCount), total: Double(weeklyGoal))
                    .tint(Color.blue)
            }

            Spacer(minLength: 4)

            // Status
            Text("Kein Workout aktiv")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    IdleView()
}
