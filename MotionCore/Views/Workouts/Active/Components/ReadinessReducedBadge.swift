//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : ReadinessReducedBadge.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Inline-Badge das anzeigt wenn das Gewicht wegen reduzierter      /
//                 Tagesform (Readiness) angepasst wurde. Erscheint wenn            /
//                 ProgressionCalcEngine.Output.reasoning == .readinessReduced.     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

/// Kleines Inline-Chip-Badge für reduzierte Readiness-Gewichtsanpassung.
///
/// Integration in ActiveSetCard:
/// ```swift
/// // Direkt nach dem "Vorschlag"-Badge im Header-HStack einfügen:
/// if isReadinessReduced {
///     ReadinessReducedBadge()
/// }
/// ```
/// `isReadinessReduced` = `smartFill?.isReadinessReduced(for: activeSet) ?? false`
struct ReadinessReducedBadge: View {
    var body: some View {
        HStack(spacing: Space.s1) {
            Image(systemName: "moon.fill")
                .font(AppFont.caption)
                .foregroundStyle(Theme.warning)

            Text("Readiness reduziert")
                .font(AppFont.caption)
                .foregroundStyle(Theme.warning)
        }
        .padding(.horizontal, Space.s2)
        .padding(.vertical, Space.s1)
        .background(Theme.warning.opacity(0.15), in: Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        ReadinessReducedBadge()

        HStack(spacing: 6) {
            Text("Satz 1 von 3")
                .font(AppFont.body)
                .foregroundStyle(Theme.textSecondary)

            ReadinessReducedBadge()
        }
    }
    .padding()
}
