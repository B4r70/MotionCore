//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Shared / Redesign                                        /
// Datei . . . . : FactorBar.swift                                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.06.2026                                                       /
// Beschreibung  : Calm-2026 Faktor-Balken (einfarbig), Track surfaceSunken         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - FactorBar (DESIGN.md §9)

/// Horizontaler Faktor-Balken, einfarbig. Track `surfaceSunken`, Füllung `tint`
/// (Default `accent`), animierte Füllung. Löst `MCFactorBar` ab.
struct FactorBar: View {
    let label: String
    var subLabel: String? = nil
    let value: Double            // 0…1
    var tint: Color = Theme.accent

    @State private var animatedValue: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s1) {
            HStack {
                Text(label)
                    .font(AppFont.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if let subLabel {
                    Text(subLabel)
                        .font(AppFont.callout)
                        .monospacedDigit()
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceSunken)
                    Capsule()
                        .fill(tint)
                        .frame(width: geo.size.width * animatedValue)
                }
            }
            .frame(height: 6)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.36)) {
                animatedValue = max(0, min(1, value))
            }
        }
        .onChange(of: value) { _, newValue in
            withAnimation(.easeInOut(duration: 0.24)) {
                animatedValue = max(0, min(1, newValue))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Space.s5) {
        FactorBar(label: "Schlafqualität", subLabel: "Niedrig", value: 0.2, tint: Theme.warning)
        FactorBar(label: "HRV", subLabel: "Mittel", value: 0.55)
        FactorBar(label: "Muskel-Erholung", subLabel: "Hoch", value: 0.9, tint: Theme.success)
    }
    .padding()
    .background(Theme.surfaceApp)
}
