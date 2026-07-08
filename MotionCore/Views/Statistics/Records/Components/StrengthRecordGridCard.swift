//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Rekorde                                                          /
// Datei . . . . : StrengthRecordGridCard.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-17                                                       /
// Beschreibung  : Kompakte Grid-Card für Kraft-Rekorde                             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

/// Kompakte Grid-Card für Kraft-Rekorde.
/// Zeigt Icon, Wert, Titel, optionalen Übungsnamen und Datum.
struct StrengthRecordGridCard: View {
    let record: StrengthRecord
    let metricTitle: String
    let metricIcon: IconTypes
    let metricColor: Color

    var body: some View {
        VStack(spacing: 5) {
            IconType(icon: metricIcon, color: metricColor, size: 30)
                .padding(.top, 10)

            // Rekordwert in groß
            Text(record.formattedValue)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            // Titel der Metrik
            Text(metricTitle)
                .font(AppFont.callout)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            // Optionaler Übungsname (bei Set-Level-Rekorden)
            if let exerciseName = record.exerciseName {
                Text(exerciseName)
                    .font(AppFont.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            // Datum des Rekords
            Text(record.session.date.formatted(AppFormatters.dateGermanShort))
                .font(AppFont.caption)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: record.exerciseName != nil ? 140 : 120)
        .card()
    }
}
