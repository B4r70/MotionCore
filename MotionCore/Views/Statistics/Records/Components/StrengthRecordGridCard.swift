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
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            // Titel der Metrik
            Text(metricTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Optionaler Übungsname (bei Set-Level-Rekorden)
            if let exerciseName = record.exerciseName {
                Text(exerciseName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            // Datum des Rekords
            Text(record.session.date.formatted(AppFormatters.dateGermanShort))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: record.exerciseName != nil ? 140 : 120)
        .glassCard()
    }
}
