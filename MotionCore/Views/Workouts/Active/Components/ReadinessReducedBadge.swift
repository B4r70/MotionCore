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
        HStack(spacing: 4) {
            Image(systemName: "moon.fill")
                .font(.caption2)
                .foregroundStyle(Color.yellow)

            Text("Readiness reduziert")
                .font(.caption2)
                .foregroundStyle(Color.yellow)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.yellow.opacity(0.15), in: Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        ReadinessReducedBadge()

        HStack(spacing: 6) {
            Text("Satz 1 von 3")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ReadinessReducedBadge()
        }
    }
    .padding()
}
