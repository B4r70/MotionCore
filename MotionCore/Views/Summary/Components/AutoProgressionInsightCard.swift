//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Summary / Components                                             /
// Datei . . . . : AutoProgressionInsightCard.swift                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Karte nach Session-Abschluss — zeigt automatisch erhöhte        /
//                 Arbeitsgewichte mit Undo und Details. (Phase 1.5)               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct AutoProgressionInsightCard: View {

    let suggestions: [SummaryViewModel.AutoProgressionSuggestion]
    let onUndo: () -> Void
    let onShowDetails: () -> Void

    private let maxVisible = 3

    private var visible: [SummaryViewModel.AutoProgressionSuggestion] {
        Array(suggestions.prefix(maxVisible))
    }

    private var extraCount: Int { max(0, suggestions.count - maxVisible) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Text("\(suggestions.count) Arbeitsgewicht\(suggestions.count == 1 ? "" : "e") wurden erhöht")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(Array(visible.enumerated()), id: \.element.id) { index, s in
                if index > 0 { Divider() }
                HStack {
                    Text(s.exerciseName)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Spacer()
                    Text("\(formatWeight(s.previousWeight)) → \(formatWeight(s.newWeight)) kg")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            if extraCount > 0 {
                Text("+ \(extraCount) weitere")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Button("Details", action: onShowDetails)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                Button("Rückgängig", action: onUndo)
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.up.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
            Text("Arbeitsgewichte erhöht")
                .font(.headline)
        }
    }

    private func formatWeight(_ w: Double) -> String {
        w == w.rounded() ? String(format: "%.0f", w) : String(format: "%.1f", w)
    }
}
