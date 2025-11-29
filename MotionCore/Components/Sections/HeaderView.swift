//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Basis-Darstellungen                                              /
// Datei . . . . : HeaderView.swift                                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Darstellung des Display-Headers                                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct HeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.title)
                .fontWeight(.regular)
                .foregroundStyle(.primary)
                .fixedSize()
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize()
        }
    }
}

    // MARK: - Preview
#Preview("Header") {
    HeaderView(title: "MotionCore", subtitle: "Workouts")
}
