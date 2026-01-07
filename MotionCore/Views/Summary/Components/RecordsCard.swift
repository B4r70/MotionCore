//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : RecordsCard.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 07.01.2026                                                       /
// Beschreibung  : Sektion mit den wichtigsten Rekorden                             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Records Card

// Sektion mit den wichtigsten Rekorden
struct RecordsCard: View {
    let highestCaloriesBurn: (session: any CoreSession, type: WorkoutType)?
    let longestWorkout: (session: any CoreSession, type: WorkoutType)?
    let longestStreak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rekorde")
                .font(.headline)
                .padding(.horizontal, 4)

            if let highest = highestCaloriesBurn {
                SummaryRecordRow(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: "Höchster Kalorienverbrauch",
                    value: "\(highest.session.calories) kcal",
                    subtitle: "\(highest.type.description) • \(highest.session.date.formatted(AppFormatters.dateGermanShort))"
                )
            }

            if let longest = longestWorkout {
                SummaryRecordRow(
                    icon: "clock.fill",
                    iconColor: .purple,
                    title: "Längstes Workout",
                    value: "\(longest.session.duration) Min",
                    subtitle: "\(longest.type.description) • \(longest.session.date.formatted(AppFormatters.dateGermanShort))"
                )
            }

            SummaryRecordRow(
                icon: "trophy.fill",
                iconColor: .yellow,
                title: "Längste Streak",
                value: "\(longestStreak) Tage",
                subtitle: "Aufeinanderfolgende Trainingstage"
            )
        }
        .glassCard()
    }
}
