//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : ExerciseRatingCard.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 05.04.2026                                                       /
// Beschreibung  : Bewertungskarte — erscheint nach Abschluss einer Übung           /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

/// Karte zur subjektiven Qualitätsbewertung einer gerade abgeschlossenen Übung.
/// Nach Auswahl einer Bewertung wird 0,5 s gewartet, dann onSkip ausgelöst.
struct ExerciseRatingCard: View {
    let exerciseName: String
    let existingRating: ExerciseQualityRating?
    let onRate: (ExerciseQualityRating) -> Void
    let onSkip: () -> Void

    // Vorbelegt mit bestehendem Rating falls vorhanden (änderbar)
    @State private var selectedRating: ExerciseQualityRating?

    private let haptic = UIImpactFeedbackGenerator(style: .light)

    init(
        exerciseName: String,
        existingRating: ExerciseQualityRating?,
        onRate: @escaping (ExerciseQualityRating) -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.exerciseName = exerciseName
        self.existingRating = existingRating
        self.onRate = onRate
        self.onSkip = onSkip
        // Pre-select falls bereits bewertet
        self._selectedRating = State(initialValue: existingRating)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Titel
            Text("Wie war die Übung?")
                .font(.headline)
                .foregroundStyle(.primary)

            // Bewertungs-Buttons
            HStack(spacing: 20) {
                ForEach(ExerciseQualityRating.allCases) { rating in
                    Button {
                        haptic.impactOccurred()
                        selectedRating = rating
                        onRate(rating)
                        // 0,5 s Delay dann automatisch weiter
                        Task {
                            try? await Task.sleep(for: .milliseconds(500))
                            onSkip()
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: rating.icon)
                                .font(.title2)
                                .foregroundStyle(
                                    selectedRating == rating
                                    ? rating.color
                                    : Color.secondary.opacity(0.5)
                                )
                                .scaleEffect(selectedRating == rating ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedRating)

                            Text(rating.label)
                                .font(.caption)
                                .foregroundStyle(
                                    selectedRating == rating
                                    ? rating.color
                                    : Color.secondary.opacity(0.5)
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedRating == rating ? rating.color : Color.secondary.opacity(0.2),
                                    lineWidth: selectedRating == rating ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Überspringen-Button
            Button {
                onSkip()
            } label: {
                Text("Überspringen")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .onAppear { haptic.prepare() }
    }
}

#Preview {
    ExerciseRatingCard(
        exerciseName: "Bankdrücken",
        existingRating: nil,
        onRate: { _ in },
        onSkip: {}
    )
    .padding()
}
