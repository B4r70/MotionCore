//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Summary / Components                                             /
// Datei . . . . : RollbackInsightCard.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Summary-Karte mit aggregierten Rollback-Vorschlaegen.            /
//                 Max 3 Uebungen pro Karte, drei Aktionen pro Zeile.               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct RollbackInsightCard: View {

    let suggestions: [SummaryViewModel.RollbackSuggestion]
    let onRollback: (ExerciseProgressionState) -> Void
    let onContinue: (ExerciseProgressionState) -> Void
    let onSwitchToAdvanced: (ExerciseProgressionState) -> Void

    private let maxVisible = 3

    private var visibleSuggestions: [SummaryViewModel.RollbackSuggestion] {
        Array(suggestions.prefix(maxVisible))
    }

    private var extraCount: Int {
        max(0, suggestions.count - maxVisible)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            // Begründung aus erster Suggestion als gemeinsamer Kontext
            if let reasoning = visibleSuggestions.first?.reasoning {
                Text(reasoning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(visibleSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                if index > 0 { Divider() }
                suggestionRow(suggestion)
            }

            if extraCount > 0 {
                Text("+ \(extraCount) weitere Vorschläge")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.title3)
            Text("Rollback vorgeschlagen")
                .font(.headline)
        }
    }

    // MARK: - Suggestion-Zeile

    private func suggestionRow(_ s: SummaryViewModel.RollbackSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Übungsname + Gewichts-Preview
            HStack {
                Text(s.exerciseName)
                    .font(.subheadline.bold())
                Spacer()
                if let prev = s.previousWeight {
                    Text("\(formatWeight(s.currentWeight)) → \(formatWeight(prev)) kg")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            // "Zurück auf X kg" — primäre Aktion (nur wenn previousWeight vorhanden)
            if let prev = s.previousWeight {
                Button {
                    onRollback(s.state)
                } label: {
                    Text("Zurück auf \(formatWeight(prev)) kg")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }

            // Sekundäre Aktionen
            HStack(spacing: 8) {
                Button("Weiter versuchen") {
                    onContinue(s.state)
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button("Ich trage selbst ein") {
                    onSwitchToAdvanced(s.state)
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Hilfsfunktionen

    private func formatWeight(_ w: Double) -> String {
        if w == w.rounded() {
            return String(format: "%.0f", w)
        }
        return String(format: "%.1f", w)
    }
}

// MARK: - Preview

#Preview {
    // Preview-Stub — erfordert SwiftData-Context fuer echte Daten
    Color.clear.frame(width: 300, height: 400)
}
