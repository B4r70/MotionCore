//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : TypeBreakdownCard.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 07.01.2026                                                       /
// Beschreibung  : Aufschlüsselung der Workouts nach Typ                            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Type Breakdown Card

// Aufschlüsselung der Workouts nach Typ
struct TypeBreakdownCard: View {
    let distribution: [SummaryCalcEngine.WorkoutTypeSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aufschlüsselung")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(distribution) { summary in
                WorkoutTypeRow(summary: summary)
            }
        }
        .glassCard()
    }
}
