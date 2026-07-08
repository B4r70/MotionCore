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

// Sektion mit den wichtigsten Rekorden.
// Neuer Parameter: recentRecordDates — zeigt "Neu!"-Badge bei Rekorden aus den letzten 7 Tagen.
struct SummaryRecordsCard: View {
    let highestCaloriesBurn: (session: any CoreSession, type: WorkoutType)?
    let longestWorkout: (session: any CoreSession, type: WorkoutType)?
    let longestStreak: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rekorde")
                .font(.headline)
                .padding(.horizontal, 4)

            if let highest = highestCaloriesBurn {
                SummaryRecordRow(
                    icon: "flame.fill",
                    iconColor: Color.orange,
                    title: "Höchster Kalorienverbrauch",
                    value: "\(highest.session.calories) kcal",
                    subtitle: "\(highest.type.description) • \(highest.session.date.formatted(AppFormatters.dateGermanShort))",
                    isNew: isRecent(highest.session.date)
                )
            }

            if let longest = longestWorkout {
                SummaryRecordRow(
                    icon: "clock.fill",
                    iconColor: .purple,
                    title: "Längstes Workout",
                    value: "\(longest.session.duration) Min",
                    subtitle: "\(longest.type.description) • \(longest.session.date.formatted(AppFormatters.dateGermanShort))",
                    isNew: isRecent(longest.session.date)
                )
            }

            SummaryRecordRow(
                icon: "trophy.fill",
                iconColor: Color.yellow,
                title: "Längste Streak",
                value: "\(longestStreak) Tage",
                subtitle: "Aufeinanderfolgende Trainingstage",
                isNew: false
            )
        }
        .card()
    }

    // MARK: - Hilfsmethode

    /// Prüft ob ein Datum in den letzten 7 Tagen liegt
    private func isRecent(_ date: Date) -> Bool {
        guard let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else {
            return false
        }
        return date >= sevenDaysAgo
    }
}

// MARK: - Preview

#Preview("SummaryRecordsCard") {
    SummaryRecordsCard(
        highestCaloriesBurn: nil,
        longestWorkout: nil,
        longestStreak: 14
    )
    .padding()
    .environmentObject(AppSettings.shared)
}
