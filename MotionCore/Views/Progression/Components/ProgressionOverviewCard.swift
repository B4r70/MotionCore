//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Progressions-Analyse                                            /
// Datei . . . . : ProgressionOverviewCard.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-17                                                       /
// Beschreibung  : Hero-Card mit aggregierter Progressions-Übersicht              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ProgressionOverviewCard: View {
    let improvingCount: Int
    let stableCount: Int
    let decliningCount: Int
    let needsDeload: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.blue)
                Text("Progressions-Übersicht")
                    .font(.headline)
            }
            .padding(.horizontal, 4)

            // Deload-Warnung
            if needsDeload {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Deload empfohlen — mindestens 3 Übungen mit Abwärtstrend")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .padding(10)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }

            // Trend-Counter (3 Spalten)
            HStack(spacing: 0) {
                overviewColumn(
                    value: improvingCount,
                    label: "Aufwärts",
                    icon: "arrow.up.right",
                    color: .green
                )
                Divider().frame(height: 44)
                overviewColumn(
                    value: stableCount,
                    label: "Stabil",
                    icon: "arrow.right",
                    color: .blue
                )
                Divider().frame(height: 44)
                overviewColumn(
                    value: decliningCount,
                    label: "Abwärts",
                    icon: "arrow.down.right",
                    color: .orange
                )
            }
        }
        .glassCard()
    }

    @ViewBuilder
    private func overviewColumn(
        value: Int,
        label: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProgressionOverviewCard(
        improvingCount: 4,
        stableCount: 3,
        decliningCount: 1,
        needsDeload: false
    )
    .padding()
}
