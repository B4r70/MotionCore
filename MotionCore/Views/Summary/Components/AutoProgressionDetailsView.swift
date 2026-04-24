//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Summary / Components                                             /
// Datei . . . . : AutoProgressionDetailsView.swift                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Detail-Sheet mit Einzeln-Undo pro Übung. (Phase 1.5)            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct AutoProgressionDetailsView: View {

    let suggestions: [SummaryViewModel.AutoProgressionSuggestion]
    let onUndoOne: (ExerciseProgressionState) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(suggestions) { s in
                VStack(alignment: .leading, spacing: 10) {
                    Text(s.exerciseName)
                        .font(.headline)

                    HStack {
                        Text("\(formatWeight(s.previousWeight)) → \(formatWeight(s.newWeight)) kg")
                            .font(.subheadline.monospacedDigit())
                        Spacer()
                        Text("+\(formatWeight(s.amount)) kg")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    Button("Nur diese Übung zurücksetzen") {
                        onUndoOne(s.state)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Gewichtserhöhungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }

    private func formatWeight(_ w: Double) -> String {
        w == w.rounded() ? String(format: "%.0f", w) : String(format: "%.1f", w)
    }
}
