//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : SummaryRecordRow.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 07.01.2026                                                       /
// Beschreibung  : Einzelne Zeile für einen Rekord                                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Summary Record Row

// Einzelne Zeile für einen Rekord.
// isNew: zeigt "Neu!"-Badge wenn true (Rekord aus den letzten 7 Tagen).
struct SummaryRecordRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    var isNew: Bool = false

    var body: some View {
        HStack(spacing: Space.s3) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(AppFont.body)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.textPrimary)

                    // "Neu!"-Badge bei frischem Rekord
                    if isNew {
                        Badge(text: "Neu!", style: .solid, color: Theme.warning)
                    }
                }

                Text(subtitle)
                    .font(AppFont.callout)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Text(value)
                .font(AppFont.headline)
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.vertical, Space.s1)
    }
}
