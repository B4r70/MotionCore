//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Rekorde                                                          /
// Datei . . . . : RecordDetailRow.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 11.11.2025                                                       /
// Beschreibung  : Darstellung von Details in den Cards für den Bereich Rekorde     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Detail Row Component

struct RecordDetailRow: View {
    let icon: IconTypes
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            // Unterscheidung Icon-Typen
            IconType(icon: icon, color: color, size: 15)

            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}
