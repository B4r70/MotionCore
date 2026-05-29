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
        // Section-Name ist die prominente Information; der App-Name steht als
        // dezentes Overline darüber (vorher invertiert: Brand groß, Section klein).
        VStack(spacing: 1) {
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .fixedSize()
            Text(subtitle)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .fixedSize()
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

    // MARK: - Preview
#Preview("Header") {
    HeaderView(title: "MotionCore", subtitle: "Workouts")
}
