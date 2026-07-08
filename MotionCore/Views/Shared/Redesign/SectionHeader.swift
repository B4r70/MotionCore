//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Shared / Redesign                                        /
// Datei . . . . : SectionHeader.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.06.2026                                                       /
// Beschreibung  : Calm-2026 Abschnittstitel mit optionalem Eyebrow + Trailing      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - SectionHeader (DESIGN.md §3 / §9)

/// Abschnittstitel (Bold, tracking -0.5) mit optionalem Eyebrow und optionaler Trailing-Aktion.
struct SectionHeader<Trailing: View>: View {
    let title: String
    var eyebrow: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: Space.s1) {
                if let eyebrow {
                    Text(eyebrow)
                        .font(AppFont.eyebrow)
                        .textCase(.uppercase)
                        .tracking(0.6)
                        .foregroundStyle(Theme.textTertiary)
                }
                Text(title)
                    .font(AppFont.title)
                    .tracking(-0.5)
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer(minLength: Space.s3)
            trailing()
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(title: String, eyebrow: String? = nil) {
        self.init(title: title, eyebrow: eyebrow, trailing: { EmptyView() })
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Space.s5) {
        SectionHeader(title: "Statistik", eyebrow: "Woche")
        SectionHeader(title: "Workouts") {
            Button("Alle") {}.buttonStyle(.mcGhost)
        }
    }
    .padding()
    .background(Theme.surfaceApp)
}
