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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    // "Neu!"-Badge bei frischem Rekord
                    if isNew {
                        Text("Neu!")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .padding(.vertical, 2)
    }
}
