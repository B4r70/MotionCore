//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Shared / Redesign                                        /
// Datei . . . . : StatTile.swift                                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.06.2026                                                       /
// Beschreibung  : Calm-2026 Stat-Kachel: Eyebrow + grosse Rounded-Zahl auf Toenung /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - StatTile (DESIGN.md §9)

/// Eyebrow + große Rounded-Zahl (monospaced) auf blasser Tönung, Radius `md`.
struct StatTile: View {
    let eyebrow: String
    let value: String
    var unit: String? = nil
    var tint: Color = Theme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s1) {
            Text(eyebrow)
                .font(AppFont.eyebrow)
                .textCase(.uppercase)
                .tracking(0.6)
                .foregroundStyle(Theme.textTertiary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppFont.metric)
                    .monospacedDigit()
                    .foregroundStyle(tint)
                if let unit {
                    Text(unit)
                        .font(AppFont.callout)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.s4)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: Space.s3) {
        StatTile(eyebrow: "Volumen", value: "12 480", unit: "kg", tint: Theme.series[0])
        StatTile(eyebrow: "Streak", value: "7", unit: "Tage", tint: Theme.warning)
    }
    .padding()
    .background(Theme.surfaceApp)
}
